import Foundation
import CoreData

/// Sincronizacion con el backend. Mismo patron que `inventario-android`.
///
/// El plan completo (PLAN.md, Fase 4) tiene tres pasos, en este orden:
///   1. Subir pendientes (`estadoSync == 0`) — todavia no implementado
///   2. Procesar bajas (`pendienteEliminar`) — todavia no implementado
///   3. Bajar del servidor y hacer upsert local — **esto es lo que hay acá**
///
/// El paso 3 se adelanto a Fase 3 porque sin el no hay forma de llenar Core Data
/// y el listado no se puede demostrar.
///
/// **El orden importa:** cuando existan los pasos 1 y 2, tienen que correr antes
/// del 3. Bajar primero pisaria los cambios locales que todavia no se subieron.
/// Mientras tanto, `upsert` protege lo pendiente salteando toda fila con
/// `estadoSync == 0` o `pendienteEliminar == true`.
final class SyncManager {

    static let shared = SyncManager()

    private var contexto: NSManagedObjectContext { PersistenceController.shared.viewContext }

    private init() {}

    // MARK: - Bajada del servidor

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
    }

    /// Las imagenes todavia no se editan localmente (Fase 5), asi que la version
    /// del servidor es la unica verdad: se borran las locales y se reinsertan.
    /// La regla de borrado de la relacion es Cascade, pero se borran explicito
    /// para no depender de eso al reasignar el set.
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
