import UIKit

final class CategoriaFormViewController: UIViewController {

    @IBOutlet weak var contentStack: UIStackView!

    @IBOutlet weak var nombreCaptionLabel: UILabel!
    @IBOutlet weak var nombreField: PaddedTextField!
    @IBOutlet weak var descripcionCaptionLabel: UILabel!
    @IBOutlet weak var descripcionField: PaddedTextField!

    @IBOutlet weak var estadoLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var guardarButton: UIButton!

    /// La setea `CategoriaListViewController` en `prepare(for:sender:)`. `nil`
    /// significa alta.
    private var categoriaAEditar: CategoriaEntity?
    private var viewModel: CategoriaFormViewModel!

    func configurar(con categoria: CategoriaEntity?) {
        categoriaAEditar = categoria
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = CategoriaFormViewModel(categoria: categoriaAEditar)
        title = viewModel.titulo
        aplicarEstilos()
        configurarEspaciados()
        cargarDatos()
    }

    // MARK: - Estilos

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surface

        nombreCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Nombre")
        descripcionCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Descripcion")

        nombreField.aplicarEstiloDeCampo(placeholder: "Ej. Herramientas manuales")
        descripcionField.aplicarEstiloDeCampo(placeholder: "Opcional")
        [nombreField, descripcionField].forEach { $0?.delegate = self }

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
            (descripcionCaptionLabel, Theme.Spacing.unit),
            (descripcionField, Theme.Spacing.lg),
            (estadoLabel, Theme.Spacing.xs),
            (errorLabel, Theme.Spacing.sm)
        ]
        for (vista, espacio) in despues where contentStack.arrangedSubviews.contains(vista) {
            contentStack.setCustomSpacing(espacio, after: vista)
        }
    }

    // MARK: - Datos

    private func cargarDatos() {
        if let categoria = viewModel.categoria {
            nombreField.text = categoria.nombre
            descripcionField.text = categoria.descripcion
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
            descripcion: descripcionField.text ?? ""
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

extension CategoriaFormViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nombreField {
            descripcionField.becomeFirstResponder()
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
