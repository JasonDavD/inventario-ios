import Foundation

/// Parseo de las fechas que manda el backend.
///
/// `fechaRegistro` viene como `2026-08-12T10:15:30`: ISO 8601 **sin zona horaria
/// ni fracciones de segundo**. `JSONDecoder.dateDecodingStrategy = .iso8601` lo
/// rechaza justamente por no traer zona, y un decode fallido de una sola fecha
/// tumba el listado entero — por eso se parsea a mano.
enum FechaAPI {

    private static let formatos = [
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
    ]

    /// `en_US_POSIX` es obligatorio: sin eso el formato depende de la config
    /// regional del telefono y el parseo falla en dispositivos con calendario o
    /// idioma distintos.
    ///
    /// Se asume UTC porque el backend no manda zona. Solo afecta la hora que se
    /// muestra, no la identidad del registro.
    private static let formateadores: [DateFormatter] = formatos.map { formato in
        let formateador = DateFormatter()
        formateador.locale = Locale(identifier: "en_US_POSIX")
        formateador.timeZone = TimeZone(secondsFromGMT: 0)
        formateador.dateFormat = formato
        return formateador
    }

    static func parsear(_ texto: String) -> Date? {
        for formateador in formateadores {
            if let fecha = formateador.date(from: texto) {
                return fecha
            }
        }
        return nil
    }
}
