import UIKit

/// Tokens del sistema de diseño "Precision Minimalist" (ver DESIGN.md en la raiz
/// del repo). Los valores de este archivo son la traduccion literal de ese
/// documento; si cambia el DESIGN.md, se cambia aca y no en cada pantalla.
///
/// La paleta es solo modo claro, por eso la app fuerza `UIUserInterfaceStyle =
/// Light` en el Info.plist. Sin eso, en modo oscuro los colores fijos de aca
/// conviven con los colores del sistema y la pantalla queda ilegible.
enum Theme {

    // MARK: - Colores

    enum Color {
        static let surface = UIColor(hex: 0xF8F9FA)
        static let surfaceContainerLowest = UIColor(hex: 0xFFFFFF)
        static let surfaceTonal = UIColor(hex: 0xF1F3F5)
        static let borderSubtle = UIColor(hex: 0xE9ECEF)
        static let outline = UIColor(hex: 0x76777B)
        static let charcoalDeep = UIColor(hex: 0x121417)
        static let charcoalMuted = UIColor(hex: 0x343A40)
        static let industrialOrange = UIColor(hex: 0xE85D04)
        static let error = UIColor(hex: 0xBA1A1A)
        static let onPrimary = UIColor(hex: 0xFFFFFF)
    }

    // MARK: - Radios

    enum Radius {
        static let sm: CGFloat = 4
        static let base: CGFloat = 8    // botones, inputs, cards chicas
        static let md: CGFloat = 12
        static let lg: CGFloat = 16     // contenedores grandes
        static let full: CGFloat = 9999 // pill
    }

    // MARK: - Espaciado (ritmo de 4px)

    enum Spacing {
        static let unit: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 40
        static let xl: CGFloat = 64
        static let marginMobile: CGFloat = 20
    }

    // MARK: - Tipografia

    /// El DESIGN.md pide Inter. Se usa la fuente del sistema (SF Pro) para no
    /// bundlear archivos de fuente: se respetan tamaño, peso, interlineado y
    /// tracking de cada rol, que es lo que define la jerarquia visual.
    ///
    /// El `letterSpacing` del documento viene en `em`, que es relativo al tamaño
    /// de fuente. UIKit lo expresa en puntos absolutos via `kern`, de ahi la
    /// multiplicacion por `size`.
    enum TextStyle {
        case headlineXL
        case headlineLG
        case headlineLGMobile
        case headlineMD
        case headlineSM
        case bodyLG
        case bodyMD
        case labelLG
        case labelMD

        var size: CGFloat {
            switch self {
            case .headlineXL: return 40
            case .headlineLG: return 32
            case .headlineLGMobile: return 28
            case .headlineMD: return 24
            case .headlineSM: return 20
            case .bodyLG: return 16
            case .bodyMD: return 14
            case .labelLG: return 13
            case .labelMD: return 11
            }
        }

        var weight: UIFont.Weight {
            switch self {
            case .headlineXL, .headlineLG, .headlineLGMobile, .headlineMD, .headlineSM,
                 .labelLG, .labelMD:
                return .semibold
            case .bodyLG, .bodyMD:
                return .regular
            }
        }

        /// letterSpacing del DESIGN.md, en em.
        var trackingEm: CGFloat {
            switch self {
            case .headlineXL, .headlineLG, .headlineLGMobile: return -0.02
            case .headlineMD, .headlineSM: return -0.01
            case .bodyLG, .bodyMD: return 0.01
            case .labelLG: return 0.05
            case .labelMD: return 0.08
            }
        }

        var lineHeight: CGFloat {
            switch self {
            case .headlineXL: return 48
            case .headlineLG: return 40
            case .headlineLGMobile: return 36
            case .headlineMD: return 32
            case .headlineSM: return 28
            case .bodyLG: return 24
            case .bodyMD: return 20
            case .labelLG: return 18
            case .labelMD: return 16
            }
        }

        var font: UIFont { .systemFont(ofSize: size, weight: weight) }

        var kern: CGFloat { trackingEm * size }

        func attributes(color: UIColor, alineacion: NSTextAlignment) -> [NSAttributedString.Key: Any] {
            let parrafo = NSMutableParagraphStyle()
            parrafo.alignment = alineacion
            parrafo.minimumLineHeight = lineHeight
            parrafo.maximumLineHeight = lineHeight
            return [
                .font: font,
                .foregroundColor: color,
                .kern: kern,
                .paragraphStyle: parrafo,
                // Sin esto el texto queda pegado al borde superior cuando se
                // fuerza el lineHeight.
                .baselineOffset: (lineHeight - font.lineHeight) / 4
            ]
        }
    }
}

// MARK: - Helpers

extension Theme.TextStyle {
    /// Tipografia del titulo de un `UIButton` con `Configuration`.
    ///
    /// Ojo: setear la fuente en `config.attributedTitle` NO alcanza —
    /// `UIButton.Configuration` reaplica su propia fuente por encima y el titulo
    /// termina en el tamaño por defecto del sistema. El unico punto que UIKit
    /// respeta es este transformer.
    func transformadorTitulo(color: UIColor) -> UIConfigurationTextAttributesTransformer {
        UIConfigurationTextAttributesTransformer { entrante in
            var saliente = entrante
            saliente.font = font
            saliente.kern = kern
            saliente.foregroundColor = color
            return saliente
        }
    }
}

extension UIColor {
    /// `UIColor(hex: 0xE85D04)` — los colores del DESIGN.md vienen en hex.
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension UILabel {
    /// Aplica un rol tipografico del DESIGN.md. Usa `attributedText` porque el
    /// tracking y el interlineado no se pueden expresar con `font` sola.
    func aplicar(
        _ estilo: Theme.TextStyle,
        color: UIColor,
        texto: String?,
        alineacion: NSTextAlignment = .left
    ) {
        font = estilo.font
        textColor = color
        textAlignment = alineacion
        guard let texto, !texto.isEmpty else {
            attributedText = nil
            return
        }
        attributedText = NSAttributedString(
            string: texto,
            attributes: estilo.attributes(color: color, alineacion: alineacion)
        )
    }
}

extension UIView {
    /// Borde de 1px + esquinas redondeadas. El DESIGN.md define la profundidad
    /// con capas tonales y bordes sutiles, no con sombras.
    func aplicarBorde(radio: CGFloat, color: UIColor = Theme.Color.borderSubtle) {
        layer.cornerRadius = radio
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = color.cgColor
    }
}
