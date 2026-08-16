import UIKit

final class UsuarioFormViewController: UIViewController {

    @IBOutlet weak var contentStack: UIStackView!

    @IBOutlet weak var usernameCaptionLabel: UILabel!
    @IBOutlet weak var usernameField: PaddedTextField!
    @IBOutlet weak var passwordCaptionLabel: UILabel!
    @IBOutlet weak var passwordField: PaddedTextField!
    @IBOutlet weak var passwordAyudaLabel: UILabel!

    @IBOutlet weak var opcionesCaptionLabel: UILabel!
    /// Vacio en el Storyboard: las filas de rol y la de estado se arman aca
    /// porque salen de `RolDisponible.allCases`. Si el backend suma un rol,
    /// aparece solo.
    @IBOutlet weak var opcionesStack: UIStackView!

    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var guardarButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    private var usuarioAEditar: UsuarioDTO?
    private var viewModel: UsuarioFormViewModel!

    /// Un switch por rol, para poder leerlos y prenderlos por nombre.
    private var switchesDeRol: [RolDisponible: UISwitch] = [:]
    private var activoSwitch: UISwitch!

    func configurar(con usuario: UsuarioDTO?) {
        usuarioAEditar = usuario
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = UsuarioFormViewModel(usuario: usuarioAEditar)
        aplicarEstilos()
        armarOpciones()
        configurarEspaciados()
        bindViewModel()
        cargarDatos()
    }

    // MARK: - Estilos

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surface
        aplicarAparienciaDeNavegacion(titulo: viewModel.titulo)

        usernameCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Usuario")
        passwordCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Contraseña")
        opcionesCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Roles y estado")

        usernameField.aplicarEstiloDeCampo(placeholder: "Ej. jperez")
        usernameField.autocapitalizationType = .none
        usernameField.delegate = self

        passwordField.aplicarEstiloDeCampo(
            placeholder: viewModel.esEdicion ? "Sin cambios" : "Contraseña inicial"
        )
        passwordField.isSecureTextEntry = true
        passwordField.autocapitalizationType = .none
        passwordField.delegate = self

        passwordAyudaLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: viewModel.ayudaDePassword
        )

        guardarButton.aplicarEstiloPrimario(titulo: "Guardar")
        activityIndicator.hidesWhenStopped = true
        errorLabel.attributedText = nil

        let tap = UITapGestureRecognizer(target: self, action: #selector(cerrarTeclado))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Roles y estado

    private func armarOpciones() {
        opcionesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        opcionesStack.axis = .vertical
        opcionesStack.spacing = Theme.Spacing.sm

        for rol in RolDisponible.allCases {
            let interruptor = UISwitch()
            interruptor.onTintColor = Theme.Color.charcoalDeep
            interruptor.isOn = viewModel.rolesSeleccionados.contains(rol)
            switchesDeRol[rol] = interruptor

            opcionesStack.addArrangedSubview(
                fila(titulo: rol.titulo, detalle: rol.descripcion, control: interruptor)
            )
        }

        activoSwitch = UISwitch()
        activoSwitch.onTintColor = Theme.Color.charcoalDeep
        activoSwitch.isOn = viewModel.habilitado
        opcionesStack.addArrangedSubview(
            fila(
                titulo: "Activo",
                detalle: "Si esta apagado, el usuario existe pero no puede entrar",
                control: activoSwitch
            )
        )
    }

    private func fila(titulo: String, detalle: String, control: UIView) -> UIView {
        let tituloLabel = UILabel()
        tituloLabel.aplicar(.bodyLG, color: Theme.Color.charcoalDeep, texto: titulo)

        let detalleLabel = UILabel()
        detalleLabel.numberOfLines = 0
        detalleLabel.aplicar(.bodyMD, color: Theme.Color.charcoalMuted, texto: detalle)

        let textos = UIStackView(arrangedSubviews: [tituloLabel, detalleLabel])
        textos.axis = .vertical

        let horizontal = UIStackView(arrangedSubviews: [textos, control])
        horizontal.axis = .horizontal
        horizontal.alignment = .center
        horizontal.spacing = Theme.Spacing.sm
        // Sin esto el switch se estira y los textos se comprimen.
        control.setContentHuggingPriority(.required, for: .horizontal)
        control.setContentCompressionResistancePriority(.required, for: .horizontal)
        return horizontal
    }

    private func configurarEspaciados() {
        contentStack.spacing = 0
        let despues: [(UIView, CGFloat)] = [
            (usernameCaptionLabel, Theme.Spacing.unit),
            (usernameField, Theme.Spacing.md),
            (passwordCaptionLabel, Theme.Spacing.unit),
            (passwordField, Theme.Spacing.xs),
            (passwordAyudaLabel, Theme.Spacing.lg),
            (opcionesCaptionLabel, Theme.Spacing.sm),
            (opcionesStack, Theme.Spacing.lg),
            (errorLabel, Theme.Spacing.sm)
        ]
        for (vista, espacio) in despues where contentStack.arrangedSubviews.contains(vista) {
            contentStack.setCustomSpacing(espacio, after: vista)
        }
    }

    private func bindViewModel() {
        viewModel.onGuardado = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        viewModel.onError = { [weak self] mensaje in
            self?.mostrarError(mensaje)
        }

        viewModel.onLoadingChanged = { [weak self] cargando in
            guard let self else { return }
            self.guardarButton.isEnabled = !cargando
            if cargando {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }

    private func cargarDatos() {
        guard let usuario = viewModel.usuario else { return }
        usernameField.text = usuario.username
    }

    private func mostrarError(_ mensaje: String?) {
        errorLabel.aplicar(.bodyMD, color: Theme.Color.error, texto: mensaje)
    }

    // MARK: - Acciones

    @IBAction func guardarTapped(_ sender: UIButton) {
        cerrarTeclado()
        mostrarError(nil)

        // Los switches son la fuente de verdad de lo que el usuario eligio; se
        // vuelcan al ViewModel recien al guardar.
        viewModel.rolesSeleccionados = Set(switchesDeRol.filter { $0.value.isOn }.keys)
        viewModel.habilitado = activoSwitch.isOn

        if let error = viewModel.guardar(
            username: usernameField.text ?? "",
            password: passwordField.text ?? ""
        ) {
            mostrarError(error)
        }
    }

    @objc private func cerrarTeclado() {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate

extension UsuarioFormViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {
            cerrarTeclado()
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
