import UIKit

/// `UITextField` con padding interno. El DESIGN.md pide inputs con borde propio
/// y 16px de padding horizontal; con `borderStyle = .none` el texto queda pegado
/// al borde, y `UITextField` no expone insets.
///
/// El campo de contraseña sube `textInsets.right` para dejarle lugar al boton
/// del ojito.
final class PaddedTextField: UITextField {

    var textInsets = UIEdgeInsets(
        top: 12,
        left: Theme.Spacing.sm,
        bottom: 12,
        right: Theme.Spacing.sm
    )

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }
}
