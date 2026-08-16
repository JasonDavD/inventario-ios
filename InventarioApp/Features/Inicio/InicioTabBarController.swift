import UIKit

/// Contenedor de las tres listas (Productos, Categorias, Proveedores). Cada tab
/// tiene su propio `UINavigationController`, asi la pila de cada seccion es
/// independiente: entrar a un formulario en Productos no afecta a las otras.
///
/// Existe solo para estilar la barra: el DESIGN.md no define tab bar, asi que se
/// arma con los mismos tokens que la barra de navegacion — fondo
/// `surface-container-lowest`, divisor de 1px y `charcoal-deep` como color
/// activo.
final class InicioTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let apariencia = UITabBarAppearance()
        apariencia.configureWithOpaqueBackground()
        apariencia.backgroundColor = Theme.Color.surfaceContainerLowest
        apariencia.shadowColor = Theme.Color.borderSubtle

        // Los titulos de tab son metadata tecnica: `label-md`, el mismo rol que
        // usan los chips de las listas.
        let atributos: [NSAttributedString.Key: Any] = [
            .font: Theme.TextStyle.labelMD.font,
            .kern: Theme.TextStyle.labelMD.kern
        ]
        for item in [apariencia.stackedLayoutAppearance,
                     apariencia.inlineLayoutAppearance,
                     apariencia.compactInlineLayoutAppearance] {
            item.normal.iconColor = Theme.Color.outline
            item.normal.titleTextAttributes = atributos.merging(
                [.foregroundColor: Theme.Color.outline]
            ) { _, nuevo in nuevo }
            item.selected.iconColor = Theme.Color.charcoalDeep
            item.selected.titleTextAttributes = atributos.merging(
                [.foregroundColor: Theme.Color.charcoalDeep]
            ) { _, nuevo in nuevo }
        }

        tabBar.standardAppearance = apariencia
        tabBar.scrollEdgeAppearance = apariencia

        observarSesionExpirada()
    }

    // MARK: - Sesion expirada

    /// Escucha aca y no en cada lista: este es el controlador que el Login
    /// presento, asi que es el unico que puede volver atras de una sola vez, sin
    /// importar en que tab o en que formulario este parado el usuario.
    private func observarSesionExpirada() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sesionExpirada),
            name: SessionManager.sesionExpirada,
            object: nil
        )
    }

    @objc private func sesionExpirada() {
        // Si hay un formulario o un selector abierto, el alert tiene que ir
        // arriba de eso; `presentedViewController` es quien esta al frente.
        let alFrente = presentedViewController ?? self

        let alert = UIAlertController(
            title: "Tu sesion expiro",
            message: "Volvé a ingresar para seguir. Los datos descargados siguen guardados en el dispositivo.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ingresar de nuevo", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        alFrente.present(alert, animated: true)
    }
}
