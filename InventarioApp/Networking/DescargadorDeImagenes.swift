import UIKit

/// Baja las imagenes de Cloudinary y las cachea en memoria.
///
/// Usa `URLSession.dataTask` como el resto del cliente. No pasa por `APIClient`
/// porque estas URLs no son de la API: son publicas, no llevan el header de
/// `Authorization` y devuelven bytes de imagen, no JSON.
///
/// El cache importa mas de lo que parece: una celda que se reusa mientras
/// scrollea vuelve a pedir la misma URL, y sin cache cada scroll dispara
/// descargas repetidas.
final class DescargadorDeImagenes {

    static let shared = DescargadorDeImagenes()

    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        session = URLSession(configuration: configuration)
    }

    func imagenCacheada(_ urlTexto: String) -> UIImage? {
        cache.object(forKey: urlTexto as NSString)
    }

    /// El completion se despacha siempre en el hilo principal, igual que en
    /// `APIClient`. Devuelve `nil` si la descarga falla: una foto que no carga
    /// no es un error que valga interrumpir la pantalla.
    func descargar(_ urlTexto: String, completion: @escaping (UIImage?) -> Void) {
        if let cacheada = imagenCacheada(urlTexto) {
            completion(cacheada)
            return
        }

        guard let url = URL(string: urlTexto) else {
            completion(nil)
            return
        }

        let task = session.dataTask(with: url) { [weak self] datos, _, _ in
            guard let datos, let imagen = UIImage(data: datos) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.cache.setObject(imagen, forKey: urlTexto as NSString)
            DispatchQueue.main.async { completion(imagen) }
        }
        task.resume()
    }
}
