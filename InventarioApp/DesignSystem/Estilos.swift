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
    /// - Parameter titulo: se setea tambien en `title`, que es de donde sale el
    ///   texto del boton "atras" de la pantalla siguiente. El `titleView` solo
    ///   cambia lo que se dibuja en esta.
    func aplicarAparienciaDeNavegacion(titulo: String) {
        title = titulo

        let apariencia = UINavigationBarAppearance()
        apariencia.configureWithOpaqueBackground()
        apariencia.backgroundColor = Theme.Color.surfaceContainerLowest
        apariencia.shadowColor = Theme.Color.borderSubtle
        apariencia.titleTextAttributes = Theme.TextStyle.headlineSM
            .attributes(color: Theme.Color.charcoalDeep, alineacion: .center)
        navigationItem.standardAppearance = apariencia
        navigationItem.scrollEdgeAppearance = apariencia

        // NOTA — el titulo queda alineado a la izquierda en Categorias y
        // Proveedores, y centrado en Productos. No es un bug de esta app: iOS 26
        // alinea el titulo al borde cuando la barra tiene lugar de sobra, y
        // Productos queda centrado solo porque el boton "Salir" le come el
        // espacio de la izquierda.
        //
        // Probado y descartado, en este orden:
        //   1. `largeTitleDisplayMode = .never` — sin efecto, no es un large
        //      title clasico sino el layout nuevo de la barra.
        //   2. `prefersLargeTitles = false` — sin efecto, por lo mismo.
        //   3. Un `titleView` propio — se dibuja (verificado pintandole el fondo)
        //      y respeta la tipografia del Theme, pero la barra lo alinea a la
        //      izquierda igual. Centrarlo pedia darle un ancho fijo calculado a
        //      mano, que se rompe en cuanto cambia el tamaño de pantalla o la
        //      cantidad de botones.
        //
        // Se deja el comportamiento nativo. Si en algun momento molesta de
        // verdad, la salida limpia es darle a las tres listas la misma
        // estructura de botones, no pelearle a la barra.
    }
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
