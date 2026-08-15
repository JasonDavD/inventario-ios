import UIKit

/// Estilado que se repite en mas de una pantalla, traducido del DESIGN.md una
/// sola vez. Lo que es propio de una pantalla se queda en su `viewDidLoad`.
///
/// Va aca y no en el Storyboard porque el editor visual no expresa tracking
/// tipografico, bordes de 1px ni estados de foco (ver PLAN.md > Sistema de
/// diseño).

extension UIViewController {

    /// Barra de navegacion opaca sobre `surface-container-lowest`, con divisor
    /// de 1px en vez de sombra: el DESIGN.md marca profundidad con capas
    /// tonales, no con elevacion.
    func aplicarAparienciaDeNavegacion() {
        let apariencia = UINavigationBarAppearance()
        apariencia.configureWithOpaqueBackground()
        apariencia.backgroundColor = Theme.Color.surfaceContainerLowest
        apariencia.shadowColor = Theme.Color.borderSubtle
        apariencia.titleTextAttributes = Theme.TextStyle.headlineSM
            .attributes(color: Theme.Color.charcoalDeep, alineacion: .center)
        navigationItem.standardAppearance = apariencia
        navigationItem.scrollEdgeAppearance = apariencia
    }

    // NOTA — el titulo no queda centrado en todas las pantallas. En iOS 26 la
    // barra alinea el titulo a la izquierda y lo agranda cuando no hay boton a la
    // izquierda: Productos queda centrado porque tiene "Salir", y Categorias y
    // Proveedores no. Ese titulo grande ignora el `titleTextAttributes` de arriba,
    // asi que tampoco toma la tipografia del Theme.
    //
    // Probado y descartado: `largeTitleDisplayMode = .never` y
    // `prefersLargeTitles = false` no lo cambian — no es un large title clasico
    // sino el layout nuevo de la barra. Se arregla con un `titleView` propio, que
    // es lo que habria que hacer si el detalle molesta.
}

extension UITableView {

    /// Lista de alta densidad: divisores horizontales de 1px y nada mas que
    /// separe (DESIGN.md > Components > Lists).
    func aplicarEstiloDeLista() {
        backgroundColor = Theme.Color.surfaceContainerLowest
        separatorColor = Theme.Color.borderSubtle
        separatorInset = UIEdgeInsets(
            top: 0,
            left: Theme.Spacing.marginMobile,
            bottom: 0,
            right: Theme.Spacing.marginMobile
        )
        tableFooterView = UIView()
        rowHeight = UITableView.automaticDimension
    }
}

extension UIBarButtonItem {

    func aplicarEstiloDeTexto(color: UIColor) {
        setTitleTextAttributes(
            [.font: Theme.TextStyle.labelLG.font, .kern: Theme.TextStyle.labelLG.kern],
            for: .normal
        )
        tintColor = color
    }
}

extension UITextField {

    /// Campo blanco con borde de 1px. El foco lo maneja el `UITextFieldDelegate`
    /// de cada pantalla cambiando el color del borde a `charcoal-deep`.
    func aplicarEstiloDeCampo(placeholder: String) {
        backgroundColor = Theme.Color.surfaceContainerLowest
        aplicarBorde(radio: Theme.Radius.base)
        font = Theme.TextStyle.bodyMD.font
        textColor = Theme.Color.charcoalDeep
        tintColor = Theme.Color.charcoalDeep
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: Theme.TextStyle.bodyMD.font,
                .foregroundColor: Theme.Color.outline
            ]
        )
    }
}

extension UIButton {

    /// Boton primario: fondo charcoal con texto blanco, sin sombra
    /// (DESIGN.md > Components > Buttons > Primary).
    func aplicarEstiloPrimario(titulo: String) {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = Theme.Color.charcoalDeep
        config.baseForegroundColor = Theme.Color.onPrimary
        config.background.cornerRadius = Theme.Radius.base
        config.cornerStyle = .fixed
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        config.title = titulo
        config.titleTextAttributesTransformer = Theme.TextStyle.labelLG
            .transformadorTitulo(color: Theme.Color.onPrimary)
        configuration = config
        setTitle(nil, for: .normal)
    }
}
