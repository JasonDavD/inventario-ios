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
    }
}
