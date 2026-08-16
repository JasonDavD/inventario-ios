import UIKit
import CoreData

/// Subida y baja de imagenes de producto y del logo de proveedor.
///
/// **Estas operaciones son online, no offline-first**, y es a proposito: el
/// backend asocia el archivo al recurso padre por su id, asi que no hay forma de
/// encolarlas sin un `apiId`. Un producto creado sin conexion no muestra la
/// opcion de agregar fotos hasta que sincroniza (ver la limitacion de diseño en
/// PLAN.md).
///
/// Por eso tampoco pasan por `SyncManager`: se hacen contra el servidor en el
/// momento y despues se vuelve a bajar el producto para que Core Data quede
/// igual que el servidor.
struct ImagenService {

    /// Tope del backend. Se valida tambien aca para no gastar una subida que ya
    /// se sabe que va a volver rechazada.
    static let maximoPorProducto = 5

    /// Calidad del JPEG. Las fotos de camara pesan varios MB en PNG y la subida
    /// contra Render se hace eterna; 0.8 en JPEG baja el peso un orden de
    /// magnitud sin que se note en pantalla.
    private static let calidadJPEG: CGFloat = 0.8

    // MARK: - Imagenes de producto

    /// - Parameter apiId: el del producto en el servidor. Quien llama ya
    ///   verifico que no sea nil.
    func subirImagen(
        _ imagen: UIImage,
        aProductoConApiId apiId: Int64,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let datos = imagen.jpegData(compressionQuality: Self.calidadJPEG) else {
            completion(.failure(.invalidResponse))
            return
        }

        APIClient.shared.upload(
            .imagenesDeProducto(apiId: apiId),
            archivo: datos,
            nombreArchivo: "foto.jpg",
            mimeType: "image/jpeg"
        ) { (resultado: Result<RespuestaIgnorada, APIError>) in
            Self.refrescarSiSalioBien(resultado, completion: completion)
        }
    }

    func borrarImagen(
        imagenId: Int64,
        deProductoConApiId apiId: Int64,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        APIClient.shared.delete(
            .imagenDeProducto(apiId: apiId, imagenId: imagenId)
        ) { (resultado: Result<RespuestaVacia, APIError>) in
            switch resultado {
            case .success:
                Self.borrarFilaLocal(imagenId: imagenId)
                Self.refrescar(completion)
            case .failure(let error):
                // Un 404 significa que en el servidor ya no esta: el objetivo ya
                // se cumplio. Es el mismo criterio que usa `SyncManager` con las
                // bajas de entidades, y sin esto el borrado queda trabado —
                // reintentar siempre devuelve 404 y se ve como "Error del
                // servidor" aunque la foto ya no exista.
                if case .server(let status, _) = error, status == 404 {
                    Self.borrarFilaLocal(imagenId: imagenId)
                    Self.refrescar(completion)
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Logo de proveedor

    func subirLogo(
        _ imagen: UIImage,
        aProveedorConApiId apiId: Int64,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let datos = imagen.jpegData(compressionQuality: Self.calidadJPEG) else {
            completion(.failure(.invalidResponse))
            return
        }

        APIClient.shared.upload(
            .logoDeProveedor(apiId: apiId),
            archivo: datos,
            nombreArchivo: "logo.jpg",
            mimeType: "image/jpeg"
        ) { (resultado: Result<RespuestaIgnorada, APIError>) in
            Self.refrescarSiSalioBien(resultado, completion: completion)
        }
    }

    // MARK: - Interno

    /// El servidor es la fuente de verdad de las imagenes: no se arma la fila
    /// local a mano con lo que devolvio la subida, se vuelve a bajar. Asi los
    /// `apiId` de imagen y las URLs de Cloudinary son siempre las reales.
    private static func refrescarSiSalioBien<T>(
        _ resultado: Result<T, APIError>,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        switch resultado {
        case .failure(let error):
            completion(.failure(error))
        case .success:
            refrescar(completion)
        }
    }

    /// Vuelve a bajar del servidor, **pero el resultado de esa bajada no decide
    /// si la operacion salio bien**.
    ///
    /// Antes esto encadenaba el `Result` de la bajada directo al completion, y
    /// era un error: para cuando se llama, la subida o el borrado contra el
    /// servidor YA ocurrieron. Si la bajada fallaba —y con Render dormido falla
    /// seguido— la pantalla decia "no se pudo completar" sobre algo que si se
    /// habia hecho. Peor: el usuario reintentaba, el DELETE devolvia 404 porque
    /// la foto ya no estaba, y volvia a ver un error.
    ///
    /// Si la bajada falla, la copia local queda desactualizada hasta la proxima
    /// sincronizacion, que es un problema mucho menor que mentir sobre el
    /// resultado.
    private static func refrescar(_ completion: @escaping (Result<Void, APIError>) -> Void) {
        SyncManager.shared.descargarDelServidor { _ in
            completion(.success(()))
        }
    }

    /// Saca la fila local sin esperar a la bajada, para que la galeria quede
    /// bien aunque el refresh no llegue a correr.
    private static func borrarFilaLocal(imagenId: Int64) {
        let contexto = PersistenceController.shared.viewContext
        let request = NSFetchRequest<ProductoImagenEntity>(entityName: "ProductoImagenEntity")
        request.predicate = NSPredicate(format: "apiId == %@", NSNumber(value: imagenId))

        let existentes = (try? contexto.fetch(request)) ?? []
        existentes.forEach { contexto.delete($0) }
        PersistenceController.shared.saveContext()
    }
}
