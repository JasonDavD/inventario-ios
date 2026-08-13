import UIKit

final class ProductoFormViewController: UIViewController {

    @IBOutlet weak var contentStack: UIStackView!

    @IBOutlet weak var nombreCaptionLabel: UILabel!
    @IBOutlet weak var nombreField: PaddedTextField!
    @IBOutlet weak var precioCaptionLabel: UILabel!
    @IBOutlet weak var precioField: PaddedTextField!
    @IBOutlet weak var stockCaptionLabel: UILabel!
    @IBOutlet weak var stockField: PaddedTextField!

    @IBOutlet weak var categoriaCaptionLabel: UILabel!
    @IBOutlet weak var categoriaButton: UIButton!
    @IBOutlet weak var proveedorCaptionLabel: UILabel!
    @IBOutlet weak var proveedorButton: UIButton!

    @IBOutlet weak var estadoLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var guardarButton: UIButton!

    /// La setea `ProductoListViewController` en `prepare(for:sender:)`. `nil`
    /// significa alta.
    private var productoAEditar: ProductoEntity?
    private var viewModel: ProductoFormViewModel!

    func configurar(con producto: ProductoEntity?) {
        productoAEditar = producto
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ProductoFormViewModel(producto: productoAEditar)
        title = viewModel.titulo
        aplicarEstilos()
        configurarEspaciados()
        cargarDatos()
    }

    // MARK: - Estilos

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surface

        nombreCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Nombre")
        precioCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Precio")
        stockCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Stock")
        categoriaCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Categoria")
        proveedorCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Proveedor")

        [nombreField, precioField, stockField].forEach { campo in
            campo?.backgroundColor = Theme.Color.surfaceContainerLowest
            campo?.aplicarBorde(radio: Theme.Radius.base)
            campo?.font = Theme.TextStyle.bodyMD.font
            campo?.textColor = Theme.Color.charcoalDeep
            campo?.tintColor = Theme.Color.charcoalDeep
            campo?.delegate = self
        }
        precioField.keyboardType = .decimalPad
        stockField.keyboardType = .numberPad

        aplicarPlaceholder(nombreField, texto: "Ej. Martillo de carpintero")
        aplicarPlaceholder(precioField, texto: "0.00")
        aplicarPlaceholder(stockField, texto: "0")

        [categoriaButton, proveedorButton].forEach { boton in
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 12, leading: Theme.Spacing.sm, bottom: 12, trailing: Theme.Spacing.sm
            )
            boton?.configuration = config
            boton?.contentHorizontalAlignment = .leading
            boton?.backgroundColor = Theme.Color.surfaceContainerLowest
            boton?.aplicarBorde(radio: Theme.Radius.base)
        }

        var configGuardar = UIButton.Configuration.filled()
        configGuardar.baseBackgroundColor = Theme.Color.charcoalDeep
        configGuardar.baseForegroundColor = Theme.Color.onPrimary
        configGuardar.background.cornerRadius = Theme.Radius.base
        configGuardar.cornerStyle = .fixed
        configGuardar.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        configGuardar.title = "Guardar"
        configGuardar.titleTextAttributesTransformer = Theme.TextStyle.labelLG
            .transformadorTitulo(color: Theme.Color.onPrimary)
        guardarButton.configuration = configGuardar

        errorLabel.attributedText = nil
        estadoLabel.attributedText = nil

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

    private func configurarEspaciados() {
        contentStack.spacing = 0
        let despues: [(UIView, CGFloat)] = [
            (nombreCaptionLabel, Theme.Spacing.unit),
            (nombreField, Theme.Spacing.md),
            (precioCaptionLabel, Theme.Spacing.unit),
            (precioField, Theme.Spacing.md),
            (stockCaptionLabel, Theme.Spacing.unit),
            (stockField, Theme.Spacing.md),
            (categoriaCaptionLabel, Theme.Spacing.unit),
            (categoriaButton, Theme.Spacing.md),
            (proveedorCaptionLabel, Theme.Spacing.unit),
            (proveedorButton, Theme.Spacing.lg),
            (estadoLabel, Theme.Spacing.xs),
            (errorLabel, Theme.Spacing.sm)
        ]
        for (vista, espacio) in despues where contentStack.arrangedSubviews.contains(vista) {
            contentStack.setCustomSpacing(espacio, after: vista)
        }
    }

    // MARK: - Datos

    private func cargarDatos() {
        if let producto = viewModel.producto {
            nombreField.text = producto.nombre
            precioField.text = String(format: "%.2f", producto.precio)
            stockField.text = "\(producto.stock)"
        }
        actualizarSelectores()
        actualizarEstado()
    }

    private func actualizarSelectores() {
        aplicarTituloSelector(
            categoriaButton,
            texto: viewModel.categoriaSeleccionada?.nombre ?? "Sin categoria",
            esPlaceholder: viewModel.categoriaSeleccionada == nil
        )
        aplicarTituloSelector(
            proveedorButton,
            texto: viewModel.proveedorSeleccionado?.nombre ?? "Sin proveedor",
            esPlaceholder: viewModel.proveedorSeleccionado == nil
        )
    }

    private func aplicarTituloSelector(_ boton: UIButton, texto: String, esPlaceholder: Bool) {
        boton.aplicarTitulo(
            texto,
            estilo: .bodyMD,
            color: esPlaceholder ? Theme.Color.outline : Theme.Color.charcoalDeep
        )
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
            precioTexto: precioField.text ?? "",
            stockTexto: stockField.text ?? ""
        )

        if let error {
            mostrarError(error)
            return
        }
        // Se guardo local con estadoSync = 0. La subida al servidor la hace el
        // boton Sincronizar del listado.
        navigationController?.popViewController(animated: true)
    }

    @IBAction func categoriaTapped(_ sender: UIButton) {
        cerrarTeclado()
        let opciones = viewModel.categorias()
        mostrarSelector(
            titulo: "Categoria",
            vacio: "Sin categoria",
            nombres: opciones.map { $0.nombre ?? "(sin nombre)" },
            desde: sender
        ) { [weak self] indice in
            self?.viewModel.categoriaSeleccionada = indice.map { opciones[$0] }
            self?.actualizarSelectores()
        }
    }

    @IBAction func proveedorTapped(_ sender: UIButton) {
        cerrarTeclado()
        let opciones = viewModel.proveedores()
        mostrarSelector(
            titulo: "Proveedor",
            vacio: "Sin proveedor",
            nombres: opciones.map { $0.nombre ?? "(sin nombre)" },
            desde: sender
        ) { [weak self] indice in
            self?.viewModel.proveedorSeleccionado = indice.map { opciones[$0] }
            self?.actualizarSelectores()
        }
    }

    /// `indice == nil` en el callback significa "ninguno".
    private func mostrarSelector(
        titulo: String,
        vacio: String,
        nombres: [String],
        desde origen: UIView,
        alElegir: @escaping (Int?) -> Void
    ) {
        let hoja = UIAlertController(title: titulo, message: nil, preferredStyle: .actionSheet)

        hoja.addAction(UIAlertAction(title: vacio, style: .default) { _ in alElegir(nil) })
        for (indice, nombre) in nombres.enumerated() {
            hoja.addAction(UIAlertAction(title: nombre, style: .default) { _ in alElegir(indice) })
        }
        hoja.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // Obligatorio en iPad: sin esto el action sheet crashea por no tener
        // desde donde anclarse.
        hoja.popoverPresentationController?.sourceView = origen
        hoja.popoverPresentationController?.sourceRect = origen.bounds

        present(hoja, animated: true)
    }

    @objc private func cerrarTeclado() {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate

extension ProductoFormViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nombreField {
            precioField.becomeFirstResponder()
        } else if textField == precioField {
            stockField.becomeFirstResponder()
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
