import UIKit

/// Escena de Login. La estructura (jerarquia de vistas y outlets) vive en
/// Main.storyboard; el estilado sale de `Theme` en `viewDidLoad`, porque el
/// tracking tipografico, los bordes de 1px y los radios del DESIGN.md no se
/// pueden expresar en el editor visual.
final class LoginViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentStack: UIStackView!

    @IBOutlet weak var iconContainerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var usernameCaptionLabel: UILabel!
    @IBOutlet weak var usernameField: PaddedTextField!
    @IBOutlet weak var passwordCaptionLabel: UILabel!
    @IBOutlet weak var passwordContainerView: UIView!
    @IBOutlet weak var passwordField: PaddedTextField!
    @IBOutlet weak var passwordToggleButton: UIButton!

    @IBOutlet weak var rememberButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!

    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var recuperarButton: UIButton!
    @IBOutlet weak var separadorPuntoView: UIView!
    @IBOutlet weak var soporteButton: UIButton!
    @IBOutlet weak var footerLabel: UILabel!

    // MARK: - Estado

    private let viewModel = LoginViewModel()
    private var recordarSesion = true
    private var yaEvaluoSesionGuardada = false

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        aplicarEstilos()
        configurarEspaciados()
        configurarCampos()
        actualizarCheckRecordar()
        activityIndicator.hidesWhenStopped = true
        errorLabel.attributedText = nil
        bindViewModel()
        observarTeclado()
    }

    // MARK: - Estilos

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surface

        cardView.backgroundColor = Theme.Color.surfaceContainerLowest
        cardView.aplicarBorde(radio: Theme.Radius.lg)

        iconContainerView.backgroundColor = Theme.Color.surfaceTonal
        iconContainerView.layer.cornerRadius = 32 // 64x64 -> circulo
        iconImageView.image = UIImage(
            systemName: "wrench.and.screwdriver",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .light)
        )
        iconImageView.tintColor = Theme.Color.charcoalDeep
        iconImageView.contentMode = .scaleAspectFit

        titleLabel.aplicar(
            .headlineLGMobile,
            color: Theme.Color.charcoalDeep,
            texto: "Ferreteria Zamora",
            alineacion: .center
        )
        subtitleLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: "Gestion de Inventario",
            alineacion: .center
        )

        usernameCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Usuario")
        passwordCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Contrasena")

        [usernameField, passwordField].forEach { campo in
            campo?.backgroundColor = Theme.Color.surfaceContainerLowest
            campo?.aplicarBorde(radio: Theme.Radius.base)
            campo?.font = Theme.TextStyle.bodyMD.font
            campo?.textColor = Theme.Color.charcoalDeep
            campo?.tintColor = Theme.Color.charcoalDeep
        }
        // Deja lugar para el boton del ojito.
        passwordField.textInsets.right = 44

        configurarBotonLogin()
        configurarBotonOjito()
        configurarBotonRecordar()
        configurarLinks()

        dividerView.backgroundColor = Theme.Color.borderSubtle
        separadorPuntoView.backgroundColor = Theme.Color.borderSubtle
        separadorPuntoView.layer.cornerRadius = 2

        footerLabel.aplicar(
            .labelMD,
            color: Theme.Color.outline,
            texto: "\u{00A9} 2026 Ferreteria Zamora. Sistema de uso exclusivo.",
            alineacion: .center
        )
    }

    private func configurarBotonLogin() {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = Theme.Color.charcoalDeep
        config.baseForegroundColor = Theme.Color.onPrimary
        config.background.cornerRadius = Theme.Radius.base
        config.cornerStyle = .fixed
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        config.image = UIImage(
            systemName: "arrow.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )
        config.imagePlacement = .trailing
        config.imagePadding = Theme.Spacing.xs

        config.title = "Acceder"
        config.titleTextAttributesTransformer = Theme.TextStyle.labelLG
            .transformadorTitulo(color: Theme.Color.onPrimary)

        loginButton.configuration = config
    }

    private func configurarBotonOjito() {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.baseForegroundColor = Theme.Color.outline
        passwordToggleButton.configuration = config
        actualizarIconoOjito()
    }

    private func configurarBotonRecordar() {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.imagePadding = Theme.Spacing.xs
        rememberButton.configuration = config
        rememberButton.contentHorizontalAlignment = .leading
    }

    private func configurarLinks() {
        [recuperarButton, soporteButton].forEach { boton in
            var config = UIButton.Configuration.plain()
            config.contentInsets = .zero
            config.baseForegroundColor = Theme.Color.charcoalMuted
            boton?.configuration = config
        }
        aplicarTituloLink(recuperarButton, texto: "Recuperar acceso")
        aplicarTituloLink(soporteButton, texto: "Soporte tecnico")
    }

    private func aplicarTituloLink(_ boton: UIButton, texto: String) {
        boton.aplicarTitulo(texto, estilo: .labelMD, color: Theme.Color.charcoalMuted)
    }

    /// El DESIGN.md define el ritmo vertical por bloque; se aplica con
    /// `setCustomSpacing` para no repartir un unico `spacing` uniforme.
    private func configurarEspaciados() {
        contentStack.spacing = 0
        let despues: [(UIView, CGFloat)] = [
            (iconContainerView.superview ?? iconContainerView, Theme.Spacing.md),
            (titleLabel, Theme.Spacing.unit),
            (subtitleLabel, Theme.Spacing.lg),
            (usernameCaptionLabel, Theme.Spacing.unit),
            (usernameField, Theme.Spacing.md),
            (passwordCaptionLabel, Theme.Spacing.unit),
            (passwordContainerView, Theme.Spacing.md),
            (rememberButton, Theme.Spacing.sm),
            (loginButton, Theme.Spacing.sm),
            (activityIndicator, Theme.Spacing.xs),
            (errorLabel, Theme.Spacing.lg),
            (dividerView, Theme.Spacing.md)
        ]
        for (vista, espacio) in despues where contentStack.arrangedSubviews.contains(vista) {
            contentStack.setCustomSpacing(espacio, after: vista)
        }
    }

    private func configurarCampos() {
        usernameField.delegate = self
        passwordField.delegate = self
        aplicarPlaceholder(usernameField, texto: "Ingrese su usuario")
        aplicarPlaceholder(passwordField, texto: "\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}")

        let tap = UITapGestureRecognizer(target: self, action: #selector(cerrarTeclado))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func aplicarPlaceholder(_ campo: UITextField, texto: String) {
        campo.attributedPlaceholder = NSAttributedString(
            string: texto,
            attributes: [
                .font: Theme.TextStyle.bodyMD.font,
                .foregroundColor: Theme.Color.outline
            ]
        )
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onLoginSuccess = { [weak self] in
            self?.performSegue(withIdentifier: "irAInicio", sender: nil)
        }
        viewModel.onLoginError = { [weak self] message in
            self?.mostrarError(message)
        }
        viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self else { return }
            self.loginButton.isEnabled = !isLoading
            isLoading ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
        }
    }

    private func mostrarError(_ mensaje: String?) {
        errorLabel.aplicar(
            .bodyMD,
            color: Theme.Color.error,
            texto: mensaje,
            alineacion: .center
        )
    }

    // MARK: - Acciones

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        cerrarTeclado()
        mostrarError(nil)
        viewModel.login(
            username: usernameField.text ?? "",
            password: passwordField.text ?? "",
            recordarSesion: recordarSesion
        )
    }

    @IBAction func passwordToggleTapped(_ sender: UIButton) {
        passwordField.isSecureTextEntry.toggle()
        actualizarIconoOjito()
    }

    @IBAction func rememberTapped(_ sender: UIButton) {
        recordarSesion.toggle()
        actualizarCheckRecordar()
    }

    @IBAction func recuperarTapped(_ sender: UIButton) {
        mostrarNoDisponible(
            titulo: "Recuperar acceso",
            mensaje: "Todavia no esta disponible desde la app. Pedile al administrador que restablezca tu contrasena."
        )
    }

    @IBAction func soporteTapped(_ sender: UIButton) {
        mostrarNoDisponible(
            titulo: "Soporte tecnico",
            mensaje: "Todavia no esta disponible desde la app. Comunicate con el administrador del sistema."
        )
    }

    private func mostrarNoDisponible(titulo: String, mensaje: String) {
        let alert = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Entendido", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Estado visual

    private func actualizarIconoOjito() {
        let nombre = passwordField.isSecureTextEntry ? "eye.slash" : "eye"
        passwordToggleButton.configuration?.image = UIImage(
            systemName: nombre,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        )
    }

    private func actualizarCheckRecordar() {
        let nombre = recordarSesion ? "checkmark.square.fill" : "square"
        rememberButton.configuration?.image = UIImage(
            systemName: nombre,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        )
        rememberButton.configuration?.baseForegroundColor = recordarSesion
            ? Theme.Color.charcoalDeep
            : Theme.Color.outline

        rememberButton.aplicarTitulo(
            "Mantener sesion iniciada",
            estilo: .bodyMD,
            color: Theme.Color.charcoalMuted
        )
    }

    // MARK: - Teclado

    private func observarTeclado() {
        let centro = NotificationCenter.default
        centro.addObserver(
            self,
            selector: #selector(tecladoCambio(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        centro.addObserver(
            self,
            selector: #selector(tecladoCambio(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    /// Sube la card lo justo para que no la tape el teclado, en vez de un
    /// desplazamiento fijo que en pantallas grandes deja la card cortada arriba.
    @objc private func tecladoCambio(_ noti: Notification) {
        guard
            let frameTeclado = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }

        let duracion = noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        var desplazamiento: CGFloat = 0

        if noti.name == UIResponder.keyboardWillShowNotification {
            let topeTeclado = view.bounds.height - frameTeclado.height
            let excedente = cardView.frame.maxY + Theme.Spacing.sm - topeTeclado
            desplazamiento = max(0, excedente)
        }

        cardCenterYConstraint.constant = -desplazamiento
        UIView.animate(withDuration: duracion) { self.view.layoutIfNeeded() }
    }

    @objc private func cerrarTeclado() {
        view.endEditing(true)
    }

    /// Deja los campos limpios para el proximo login: al volver de cerrar sesion
    /// la pantalla no puede seguir mostrando la contrasena del usuario anterior.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !SessionManager.shared.isAuthenticated else { return }
        usernameField.text = nil
        passwordField.text = nil
        mostrarError(nil)
    }

    /// Con "Mantener sesion iniciada" tildado el token queda en el Keychain, asi
    /// que al abrir la app se entra derecho. Sin esto la opcion no serviria de
    /// nada: guardaba el token pero igual pedia login en cada arranque.
    ///
    /// Solo se evalua una vez, en el arranque. Al volver aca despues de cerrar
    /// sesion `isAuthenticated` ya es `false`, pero la bandera evita cualquier
    /// riesgo de rebote entre las dos pantallas.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !yaEvaluoSesionGuardada else { return }
        yaEvaluoSesionGuardada = true
        guard SessionManager.shared.isAuthenticated else { return }
        performSegue(withIdentifier: "irAInicio", sender: nil)
    }
}

// MARK: - UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {
            cerrarTeclado()
            loginButtonTapped(loginButton)
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderColor = Theme.Color.charcoalDeep.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderColor = Theme.Color.borderSubtle.cgColor
    }
}
