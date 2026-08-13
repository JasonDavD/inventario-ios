import Foundation

enum Formato {

    private static let numero: NumberFormatter = {
        let formateador = NumberFormatter()
        formateador.numberStyle = .decimal
        formateador.minimumFractionDigits = 2
        formateador.maximumFractionDigits = 2
        formateador.locale = Locale(identifier: "es_PE")
        return formateador
    }()

    /// Precio con separador de miles y 2 decimales. El simbolo va fijo porque el
    /// backend maneja una sola moneda: no depende de la config del telefono.
    static func precio(_ valor: Double) -> String {
        let texto = numero.string(from: NSNumber(value: valor)) ?? String(format: "%.2f", valor)
        return "S/ \(texto)"
    }
}
