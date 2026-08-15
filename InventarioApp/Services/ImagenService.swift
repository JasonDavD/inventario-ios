import UIKit

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
            Self.refrescarSiSalioBien(resultado, completion: completion)
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
            SyncManager.shared.descargarDelServidor(completion: completion)
        }
    }
}
