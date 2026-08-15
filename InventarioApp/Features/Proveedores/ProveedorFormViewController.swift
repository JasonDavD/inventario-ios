import UIKit

final class ProveedorFormViewController: UIViewController {

    @IBOutlet weak var contentStack: UIStackView!

    @IBOutlet weak var nombreCaptionLabel: UILabel!
    @IBOutlet weak var nombreField: PaddedTextField!
    @IBOutlet weak var telefonoCaptionLabel: UILabel!
    @IBOutlet weak var telefonoField: PaddedTextField!
    @IBOutlet weak var direccionCaptionLabel: UILabel!
    @IBOutlet weak var direccionField: PaddedTextField!

    @IBOutlet weak var estadoLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var guardarButton: UIButton!

    /// La setea `ProveedorListViewController` en `prepare(for:sender:)`. `nil`
    /// significa alta.
    private var proveedorAEditar: ProveedorEntity?
    private var viewModel: ProveedorFormViewModel!

    func configurar(con proveedor: ProveedorEntity?) {
        proveedorAEditar = proveedor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ProveedorFormViewModel(proveedor: proveedorAEditar)
        title = viewModel.titulo
        aplicarEstilos()
        configurarEspaciados()
        cargarDatos()
    }

    // MARK: - Estilos

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surface

        nombreCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Nombre")
        telefonoCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Telefono")
        direccionCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Direccion")

        nombreField.aplicarEstiloDeCampo(placeholder: "Ej. Distribuidora Zamora")
        telefonoField.aplicarEstiloDeCampo(placeholder: "Opcional")
        direccionField.aplicarEstiloDeCampo(placeholder: "Opcional")
        [nombreField, telefonoField, direccionField].forEach { $0?.delegate = self }
        telefonoField.keyboardType = .phonePad

        guardarButton.aplicarEstiloPrimario(titulo: "Guardar")

        errorLabel.attributedText = nil
        estadoLabel.attributedText = nil

        let tap = UITapGestureRecognizer(target: self, action: #selector(cerrarTeclado))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func configurarEspaciados() {
        contentStack.spacing = 0
        let despues: [(UIView, CGFloat)] = [
            (nombreCaptionLabel, Theme.Spacing.unit),
            (nombreField, Theme.Spacing.md),
            (telefonoCaptionLabel, Theme.Spacing.unit),
            (telefonoField, Theme.Spacing.md),
            (direccionCaptionLabel, Theme.Spacing.unit),
            (direccionField, Theme.Spacing.lg),
            (estadoLabel, Theme.Spacing.xs),
            (errorLabel, Theme.Spacing.sm)
        ]
        for (vista, espacio) in despues where contentStack.arrangedSubviews.contains(vista) {
            contentStack.setCustomSpacing(espacio, after: vista)
        }
    }

    // MARK: - Datos

    private func cargarDatos() {
        if let proveedor = viewModel.proveedor {
            nombreField.text = proveedor.nombre
            telefonoField.text = proveedor.telefono
            direccionField.text = proveedor.direccion
        }
        actualizarEstado()
    }

    private func actualizarEstado() {
        guard viewModel.estaPendienteDeSincronizar else {
            estadoLabel.attributedText = nil
            return
        }
        estadoLabel.aplicar(
            .bodyMD,
            color: Theme.Color.industrialOrange,
            texto: "Pendiente de sincronizar. Todavia no existe en el servidor."
        )
    }

    private func mostrarError(_ mensaje: String?) {
        errorLabel.aplicar(.bodyMD, color: Theme.Color.error, texto: mensaje)
    }

    // MARK: - Acciones

    @IBAction func guardarTapped(_ sender: UIButton) {
        cerrarTeclado()
        mostrarError(nil)

        let error = viewModel.guardar(
            nombre: nombreField.text ?? "",
            telefono: telefonoField.text ?? "",
            direccion: direccionField.text ?? ""
        )

        if let error {
            mostrarError(error)
            return
        }
        // Se guardo local con estadoSync = 0. La subida al servidor la hace el
        // boton Sincronizar del listado.
        navigationController?.popViewController(animated: true)
    }

    @objc private func cerrarTeclado() {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate

extension ProveedorFormViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nombreField {
            telefonoField.becomeFirstResponder()
        } else if textField == telefonoField {
            direccionField.becomeFirstResponder()
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
