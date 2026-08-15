import UIKit
import PhotosUI

final class ProveedorFormViewController: UIViewController {

    @IBOutlet weak var contentStack: UIStackView!

    @IBOutlet weak var nombreCaptionLabel: UILabel!
    @IBOutlet weak var nombreField: PaddedTextField!
    @IBOutlet weak var telefonoCaptionLabel: UILabel!
    @IBOutlet weak var telefonoField: PaddedTextField!
    @IBOutlet weak var direccionCaptionLabel: UILabel!
    @IBOutlet weak var direccionField: PaddedTextField!

    @IBOutlet weak var logoCaptionLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var subirLogoButton: UIButton!
    @IBOutlet weak var avisoLogoLabel: UILabel!
    @IBOutlet weak var logoActivityIndicator: UIActivityIndicatorView!

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
        bindViewModel()
        cargarDatos()
    }

    private func bindViewModel() {
        viewModel.onLogoCambio = { [weak self] in
            self?.actualizarLogo()
        }

        viewModel.onError = { [weak self] mensaje in
            let alert = UIAlertController(title: "No se pudo subir el logo", message: mensaje, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Entendido", style: .default))
            self?.present(alert, animated: true)
        }

        viewModel.onLoadingChanged = { [weak self] cargando in
            guard let self else { return }
            self.subirLogoButton.isEnabled = !cargando
            if cargando {
                self.logoActivityIndicator.startAnimating()
            } else {
                self.logoActivityIndicator.stopAnimating()
            }
        }
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

        logoCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Logo")
        logoImageView.contentMode = .scaleAspectFill
        logoImageView.clipsToBounds = true
        logoImageView.backgroundColor = Theme.Color.surfaceTonal
        logoImageView.aplicarBorde(radio: Theme.Radius.base)
        logoActivityIndicator.hidesWhenStopped = true
        subirLogoButton.aplicarEstiloPrimario(titulo: "Subir logo")

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
            (logoCaptionLabel, Theme.Spacing.unit),
            (logoImageView, Theme.Spacing.xs),
            (subirLogoButton, Theme.Spacing.xs),
            (avisoLogoLabel, Theme.Spacing.lg),
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
        actualizarLogo()
    }

    /// El logo vive en Cloudinary y solo existe si el proveedor ya se sincronizo;
    /// mientras no se pueda subir, se explica por que en vez de dejar un boton
    /// que va a fallar.
    private func actualizarLogo() {
        let motivo = viewModel.motivoParaNoSubirLogo
        subirLogoButton.isHidden = (motivo != nil)
        avisoLogoLabel.isHidden = (motivo == nil)
        avisoLogoLabel.aplicar(.bodyMD, color: Theme.Color.charcoalMuted, texto: motivo)

        guard let url = viewModel.logoUrl, !url.isEmpty else {
            logoImageView.isHidden = true
            return
        }

        logoImageView.isHidden = false
        subirLogoButton.aplicarEstiloPrimario(titulo: "Cambiar logo")
        DescargadorDeImagenes.shared.descargar(url) { [weak self] imagen in
            self?.logoImageView.image = imagen
        }
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

    @IBAction func subirLogoTapped(_ sender: UIButton) {
        cerrarTeclado()

        var configuracion = PHPickerConfiguration()
        configuracion.filter = .images
        configuracion.selectionLimit = 1

        let selector = PHPickerViewController(configuration: configuracion)
        selector.delegate = self
        present(selector, animated: true)
    }

    @objc private func cerrarTeclado() {
        view.endEditing(true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ProveedorFormViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let proveedorDeItem = results.first?.itemProvider,
              proveedorDeItem.canLoadObject(ofClass: UIImage.self) else { return }

        proveedorDeItem.loadObject(ofClass: UIImage.self) { [weak self] objeto, _ in
            guard let imagen = objeto as? UIImage else { return }
            // `loadObject` contesta en una cola de fondo.
            DispatchQueue.main.async {
                self?.viewModel.subirLogo(imagen)
            }
        }
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
