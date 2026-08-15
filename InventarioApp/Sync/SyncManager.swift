import Foundation
import CoreData

/// Sincronizacion bidireccional con el backend. Mismo patron que
/// `inventario-android`.
///
/// `sincronizar()` corre tres pasos, **en este orden y no en otro**:
///   1. Sube lo pendiente (`estadoSync == 0`): POST si no tiene `apiId`, PUT si lo tiene
///   2. Procesa las bajas (`pendienteEliminar`): DELETE y recien ahi borra la fila local
///   3. Baja del servidor y hace upsert local por `apiId`
///
/// El orden es lo que hace que el offline funcione. Si el paso 3 corriera
/// primero, pisaria con la version del servidor los cambios locales que todavia
/// no se subieron — se perderia el trabajo hecho sin conexion.
///
/// Como segunda linea de defensa, el upsert saltea toda fila con
/// `estadoSync == 0` o `pendienteEliminar == true`.
final class SyncManager {

    static let shared = SyncManager()

    private var contexto: NSManagedObjectContext { PersistenceController.shared.viewContext }

    private init() {}

    // MARK: - Entrada

    /// Si falla la subida, se corta y no se baja nada: bajar despues de una
    /// subida fallida mostraria la version del servidor como si el cambio local
    /// se hubiera perdido, cuando en realidad sigue pendiente.
    ///
    /// Dentro de cada paso el orden entre entidades tampoco es casual:
    ///
    /// - **Al subir**, categorias y proveedores van antes que productos. Un
    ///   producto creado sin conexion puede apuntar a una categoria tambien
    ///   creada sin conexion, y `ProductoRequest` solo referencia las que ya
    ///   tienen `apiId`. Si el producto subiera primero, se subiria sin
    ///   categoria y el vinculo se perderia sin ningun error visible.
    /// - **Al borrar**, productos van antes. Borrar una categoria que todavia
    ///   tiene productos colgando es pedirle al backend un conflicto evitable.
    func sincronizar(completion: @escaping (Result<Void, APIError>) -> Void) {
        encadenar([
            { self.subirPendientesDe(
                CategoriaEntity.self,
                nombreEntidad: "CategoriaEntity",
                coleccion: .categorias,
                recurso: Endpoint.categoria(apiId:),
                cuerpo: CategoriaRequest.init(entidad:),
                idDeLaRespuesta: { (dto: CategoriaDTO) in dto.id },
                completion: $0
            ) },
            { self.subirPendientesDe(
                ProveedorEntity.self,
                nombreEntidad: "ProveedorEntity",
                coleccion: .proveedores,
                recurso: Endpoint.proveedor(apiId:),
                cuerpo: ProveedorRequest.init(entidad:),
                idDeLaRespuesta: { (dto: ProveedorDTO) in dto.id },
                completion: $0
            ) },
            { self.subirPendientesDe(
                ProductoEntity.self,
                nombreEntidad: "ProductoEntity",
                coleccion: .productos,
                recurso: Endpoint.producto(apiId:),
                cuerpo: ProductoRequest.init(entidad:),
                idDeLaRespuesta: { (dto: ProductoDTO) in dto.id },
                completion: $0
            ) },
            { self.procesarBajasDe("ProductoEntity", recurso: Endpoint.producto(apiId:), completion: $0) },
            { self.procesarBajasDe("CategoriaEntity", recurso: Endpoint.categoria(apiId:), completion: $0) },
            { self.procesarBajasDe("ProveedorEntity", recurso: Endpoint.proveedor(apiId:), completion: $0) },
            { self.descargarDelServidor(completion: $0) }
        ], completion: completion)
    }

    /// Corre los pasos en secuencia y corta en el primero que falle. Encadenar a
    /// mano siete completion handlers anidados era ilegible.
    private func encadenar(
        _ pasos: [(@escaping (Result<Void, APIError>) -> Void) -> Void],
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        var cola = pasos
        guard !cola.isEmpty else {
            completion(.success(()))
            return
        }
        let paso = cola.removeFirst()
        paso { [weak self] resultado in
            guard let self else { return }
            switch resultado {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self.encadenar(cola, completion: completion)
            }
        }
    }

    // MARK: - Paso 1: subir pendientes

    /// - Parameters:
    ///   - coleccion: endpoint del POST (alta).
    ///   - recurso: endpoint del PUT (edicion), armado con el `apiId`.
    ///   - cuerpo: arma el JSON que espera el backend para esa entidad.
    ///   - idDeLaRespuesta: saca el `id` del DTO que devuelve el servidor.
    private func subirPendientesDe<T: NSManagedObject, Cuerpo: Encodable, Respuesta: Decodable>(
        _ tipo: T.Type,
        nombreEntidad: String,
        coleccion: Endpoint,
        recurso: @escaping (Int64) -> Endpoint,
        cuerpo: @escaping (T) -> Cuerpo,
        idDeLaRespuesta: @escaping (Respuesta) -> Int64,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let request = NSFetchRequest<T>(entityName: nombreEntidad)
        request.predicate = NSPredicate(format: "estadoSync == 0 AND pendienteEliminar == NO")
        let pendientes = (try? contexto.fetch(request)) ?? []
        subirSiguiente(
            pendientes,
            coleccion: coleccion,
            recurso: recurso,
            cuerpo: cuerpo,
            idDeLaRespuesta: idDeLaRespuesta,
            completion: completion
        )
    }

    /// Se sube de a uno y en secuencia, no en paralelo: cada POST devuelve el
    /// `apiId` que hay que guardar, y disparar todo junto contra un backend
    /// dormido en Render es la forma mas rapida de que todo timeoutee.
    private func subirSiguiente<T: NSManagedObject, Cuerpo: Encodable, Respuesta: Decodable>(
        _ restantes: [T],
        coleccion: Endpoint,
        recurso: @escaping (Int64) -> Endpoint,
        cuerpo: @escaping (T) -> Cuerpo,
        idDeLaRespuesta: @escaping (Respuesta) -> Int64,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        var cola = restantes
        guard let entidad = cola.popLast() else {
            PersistenceController.shared.saveContext()
            completion(.success(()))
            return
        }

        let alTerminar: (Result<Respuesta, APIError>) -> Void = { [weak self] resultado in
            guard let self else { return }
            switch resultado {
            case .failure(let error):
                completion(.failure(error))
            case .success(let respuesta):
                // En un POST este es el id que asigno el servidor; en un PUT es
                // el mismo que ya tenia. Se guarda igual en los dos casos.
                entidad.setValue(NSNumber(value: idDeLaRespuesta(respuesta)), forKey: "apiId")
                entidad.setValue(Int16(1), forKey: "estadoSync")
                self.subirSiguiente(
                    cola,
                    coleccion: coleccion,
                    recurso: recurso,
                    cuerpo: cuerpo,
                    idDeLaRespuesta: idDeLaRespuesta,
                    completion: completion
                )
            }
        }

        if let apiId = entidad.value(forKey: "apiId") as? NSNumber {
            APIClient.shared.put(recurso(apiId.int64Value), body: cuerpo(entidad), completion: alTerminar)
        } else {
            APIClient.shared.post(coleccion, body: cuerpo(entidad), completion: alTerminar)
        }
    }

    // MARK: - Paso 2: procesar bajas

    private func procesarBajasDe(
        _ nombreEntidad: String,
        recurso: @escaping (Int64) -> Endpoint,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let request = NSFetchRequest<NSManagedObject>(entityName: nombreEntidad)
        request.predicate = NSPredicate(format: "pendienteEliminar == YES")
        let bajas = (try? contexto.fetch(request)) ?? []
        borrarSiguiente(bajas, recurso: recurso, completion: completion)
    }

    private func borrarSiguiente(
        _ restantes: [NSManagedObject],
        recurso: @escaping (Int64) -> Endpoint,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        var cola = restantes
        guard let entidad = cola.popLast() else {
            PersistenceController.shared.saveContext()
            completion(.success(()))
            return
        }

        guard let apiId = entidad.value(forKey: "apiId") as? NSNumber else {
            // Nunca llego al servidor: no hay nada que borrar alla.
            contexto.delete(entidad)
            borrarSiguiente(cola, recurso: recurso, completion: completion)
            return
        }

        APIClient.shared.delete(recurso(apiId.int64Value)) { [weak self] (resultado: Result<RespuestaVacia, APIError>) in
            guard let self else { return }
            switch resultado {
            case .success:
                self.contexto.delete(entidad)
                self.borrarSiguiente(cola, recurso: recurso, completion: completion)
            case .failure(let error):
                // Un 404 significa que en el servidor ya no esta: el objetivo
                // ya se cumplio, asi que se borra la fila local igual. Sin esto
                // la baja quedaria trabada para siempre reintentando.
                if case .server(let status, _) = error, status == 404 {
                    self.contexto.delete(entidad)
                    self.borrarSiguiente(cola, recurso: recurso, completion: completion)
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Paso 3: bajada del servidor

    /// Baja categorias, proveedores y productos, en ese orden: un producto
    /// referencia a los otros dos, asi que tienen que existir localmente antes.
    func descargarDelServidor(completion: @escaping (Result<Void, APIError>) -> Void) {
        APIClient.shared.get(.categorias) { [weak self] (resultado: Result<[CategoriaDTO], APIError>) in
            guard let self else { return }
            switch resultado {
            case .failure(let error):
                completion(.failure(error))
            case .success(let categorias):
                self.upsertCategorias(categorias)
                self.descargarProveedores(completion: completion)
            }
        }
    }

    private func descargarProveedores(completion: @escaping (Result<Void, APIError>) -> Void) {
        APIClient.shared.get(.proveedores) { [weak self] (resultado: Result<[ProveedorDTO], APIError>) in
            guard let self else { return }
            switch resultado {
            case .failure(let error):
                completion(.failure(error))
            case .success(let proveedores):
                self.upsertProveedores(proveedores)
                self.descargarProductos(completion: completion)
            }
        }
    }

    private func descargarProductos(completion: @escaping (Result<Void, APIError>) -> Void) {
        APIClient.shared.get(.productos) { [weak self] (resultado: Result<[ProductoDTO], APIError>) in
            guard let self else { return }
            switch resultado {
            case .failure(let error):
                completion(.failure(error))
            case .success(let productos):
                self.upsertProductos(productos)
                PersistenceController.shared.saveContext()
                completion(.success(()))
            }
        }
    }

    // MARK: - Upsert

    private func upsertCategorias(_ dtos: [CategoriaDTO]) {
        for dto in dtos {
            guard let entidad = entidadParaUpsert(
                CategoriaEntity.self,
                nombreEntidad: "CategoriaEntity",
                apiId: dto.id
            ) else { continue }

            entidad.nombre = dto.nombre
            entidad.descripcion = dto.descripcion
        }
        eliminarLocalesQueElServidorYaNoTiene("CategoriaEntity", apiIds: Set(dtos.map(\.id)))
    }

    private func upsertProveedores(_ dtos: [ProveedorDTO]) {
        for dto in dtos {
            guard let entidad = entidadParaUpsert(
                ProveedorEntity.self,
                nombreEntidad: "ProveedorEntity",
                apiId: dto.id
            ) else { continue }

            entidad.nombre = dto.nombre
            entidad.telefono = dto.telefono
            entidad.direccion = dto.direccion
            entidad.logoUrl = dto.logoUrl
            entidad.logoPublicId = dto.logoPublicId
        }
        eliminarLocalesQueElServidorYaNoTiene("ProveedorEntity", apiIds: Set(dtos.map(\.id)))
    }

    private func upsertProductos(_ dtos: [ProductoDTO]) {
        for dto in dtos {
            guard let entidad = entidadParaUpsert(
                ProductoEntity.self,
                nombreEntidad: "ProductoEntity",
                apiId: dto.id
            ) else { continue }

            entidad.nombre = dto.nombre
            entidad.precio = dto.precio
            entidad.stock = dto.stock
            entidad.fechaRegistro = dto.fechaRegistro

            entidad.categoria = dto.categoria.flatMap {
                buscarPorApiId(CategoriaEntity.self, nombreEntidad: "CategoriaEntity", apiId: $0.id)
            }
            entidad.proveedor = dto.proveedor.flatMap {
                buscarPorApiId(ProveedorEntity.self, nombreEntidad: "ProveedorEntity", apiId: $0.id)
            }

            reemplazarImagenes(de: entidad, con: dto.imagenes ?? [])
        }
        eliminarLocalesQueElServidorYaNoTiene("ProductoEntity", apiIds: Set(dtos.map(\.id)))
    }

    /// Las imagenes todavia no se editan localmente (Fase 5), asi que la version
    /// del servidor es la unica verdad: se borran las locales y se reinsertan.
    private func reemplazarImagenes(de producto: ProductoEntity, con dtos: [ImagenDTO]) {
        if let existentes = producto.imagenes as? Set<ProductoImagenEntity> {
            existentes.forEach { contexto.delete($0) }
        }

        for dto in dtos {
            let imagen = ProductoImagenEntity(context: contexto)
            imagen.localId = UUID().uuidString
            imagen.apiId = NSNumber(value: dto.id)
            imagen.estadoSync = 1
            imagen.pendienteEliminar = false
            imagen.url = dto.url
            imagen.publicId = dto.publicId
            imagen.orden = dto.orden ?? 0
            imagen.producto = producto
        }
    }

    // MARK: - Helpers de Core Data

    /// Devuelve la entidad lista para escribirle los datos del servidor: la
    /// existente si ya estaba, o una nueva insertada.
    ///
    /// Devuelve `nil` cuando la fila local tiene cambios sin subir
    /// (`estadoSync == 0`) o esta marcada para borrar. En esos casos hay que
    /// dejarla como esta: pisarla perderia el trabajo offline del usuario.
    private func entidadParaUpsert<T: NSManagedObject>(
        _ tipo: T.Type,
        nombreEntidad: String,
        apiId: Int64
    ) -> T? {
        if let existente = buscarPorApiId(tipo, nombreEntidad: nombreEntidad, apiId: apiId) {
            let estadoSync = existente.value(forKey: "estadoSync") as? Int16 ?? 0
            let pendienteEliminar = existente.value(forKey: "pendienteEliminar") as? Bool ?? false
            guard estadoSync == 1, !pendienteEliminar else { return nil }
            return existente
        }

        let nueva = T(context: contexto)
        nueva.setValue(UUID().uuidString, forKey: "localId")
        nueva.setValue(NSNumber(value: apiId), forKey: "apiId")
        nueva.setValue(Int16(1), forKey: "estadoSync")
        nueva.setValue(false, forKey: "pendienteEliminar")
        return nueva
    }

    /// Borra lo que alguien elimino desde el portal web. Sin esto, un producto
    /// borrado en el servidor sobreviviria para siempre en el telefono.
    ///
    /// Solo toca filas ya sincronizadas y con `apiId`: lo pendiente de subir no
    /// se toca, y lo que nunca se subio no existe alla por definicion.
    private func eliminarLocalesQueElServidorYaNoTiene(_ nombreEntidad: String, apiIds: Set<Int64>) {
        let request = NSFetchRequest<NSManagedObject>(entityName: nombreEntidad)
        request.predicate = NSPredicate(format: "estadoSync == 1 AND apiId != nil")
        let locales = (try? contexto.fetch(request)) ?? []

        for local in locales {
            guard let apiId = local.value(forKey: "apiId") as? NSNumber else { continue }
            if !apiIds.contains(apiId.int64Value) {
                contexto.delete(local)
            }
        }
    }

    private func buscarPorApiId<T: NSManagedObject>(
        _ tipo: T.Type,
        nombreEntidad: String,
        apiId: Int64
    ) -> T? {
        let request = NSFetchRequest<T>(entityName: nombreEntidad)
        request.predicate = NSPredicate(format: "apiId == %@", NSNumber(value: apiId))
        request.fetchLimit = 1
        return try? contexto.fetch(request).first
    }
}
