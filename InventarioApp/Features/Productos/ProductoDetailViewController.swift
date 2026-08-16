import UIKit
import PhotosUI

final class ProductoDetailViewController: UIViewController {

    @IBOutlet weak var contentStack: UIStackView!

    @IBOutlet weak var nombreLabel: UILabel!
    @IBOutlet weak var precioLabel: UILabel!
    @IBOutlet weak var stockLabel: UILabel!
    @IBOutlet weak var categoriaLabel: UILabel!
    @IBOutlet weak var proveedorLabel: UILabel!
    @IBOutlet weak var estadoLabel: UILabel!

    @IBOutlet weak var fotosCaptionLabel: UILabel!
    @IBOutlet weak var contadorFotosLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sinFotosLabel: UILabel!
    @IBOutlet weak var agregarFotoButton: UIButton!
    @IBOutlet weak var avisoFotosLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    /// La setea `ProductoListViewController` en `prepare(for:sender:)`.
    private var producto: ProductoEntity!
    private var viewModel: ProductoDetailViewModel!

    func configurar(con producto: ProductoEntity) {
        self.producto = producto
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ProductoDetailViewModel(producto: producto)
        aplicarEstilos()
        configurarBotonEditar()
        configurarColeccion()
        bindViewModel()
        mostrarDatos()
    }

    /// Al volver del formulario el producto puede haber cambiado.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mostrarDatos()
        viewModel.recargarImagenes()
    }

    // MARK: - Configuracion

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surface
        aplicarAparienciaDeNavegacion(titulo: "Detalle")

        fotosCaptionLabel.aplicar(.labelLG, color: Theme.Color.charcoalMuted, texto: "Fotos")
        collectionView.backgroundColor = .clear
        activityIndicator.hidesWhenStopped = true

        agregarFotoButton.aplicarEstiloPrimario(titulo: "Agregar foto")

        contentStack.spacing = Theme.Spacing.xs
        // `estadoLabel` cierra el bloque de datos; despues empieza el de fotos,
        // y el DESIGN.md pide aire entre secciones.
        contentStack.setCustomSpacing(Theme.Spacing.md, after: estadoLabel)
    }

    /// Editar es de OPERADOR para arriba. Sin ese rol la pantalla queda de solo
    /// lectura, igual que las listas de categorias y proveedores con ADMIN.
    private func configurarBotonEditar() {
        guard SessionManager.shared.puedeEditarProductos else { return }
        let editar = UIBarButtonItem(
            title: "Editar",
            style: .plain,
            target: self,
            action: #selector(editarTapped)
        )
        editar.aplicarEstiloDeTexto(color: Theme.Color.charcoalDeep)
        navigationItem.rightBarButtonItem = editar
    }

    private func configurarColeccion() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 120, height: 120)
            layout.minimumLineSpacing = Theme.Spacing.xs
        }
    }

    private func bindViewModel() {
        viewModel.onCambio = { [weak self] in
            self?.actualizarSeccionDeFotos()
        }

        viewModel.onError = { [weak self] mensaje in
            self?.mostrarAlerta(titulo: "No se pudo completar", mensaje: mensaje)
        }

        viewModel.onLoadingChanged = { [weak self] cargando in
            guard let self else { return }
            self.agregarFotoButton.isEnabled = !cargando
            if cargando {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }

    // MARK: - Datos

    private func mostrarDatos() {
        guard isViewLoaded else { return }
        let producto = viewModel.producto

        nombreLabel.aplicar(
            .headlineMD,
            color: Theme.Color.charcoalDeep,
            texto: producto.nombre ?? "(sin nombre)"
        )
        precioLabel.aplicar(
            .bodyLG,
            color: Theme.Color.charcoalDeep,
            texto: Formato.precio(producto.precio)
        )

        let sinStock = producto.stock <= 0
        stockLabel.aplicar(
            .bodyMD,
            color: sinStock ? Theme.Color.industrialOrange : Theme.Color.charcoalMuted,
            texto: sinStock ? "Sin stock" : "\(producto.stock) unidades en stock"
        )
        categoriaLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: "Categoria: \(producto.categoria?.nombre ?? "sin categoria")"
        )
        proveedorLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: "Proveedor: \(producto.proveedor?.nombre ?? "sin proveedor")"
        )

        if producto.estadoSync == 0 || producto.apiId == nil {
            estadoLabel.aplicar(
                .bodyMD,
                color: Theme.Color.industrialOrange,
                texto: "Pendiente de sincronizar."
            )
        } else {
            estadoLabel.attributedText = nil
        }

        actualizarSeccionDeFotos()
    }

    private func actualizarSeccionDeFotos() {
        guard isViewLoaded else { return }
        collectionView.reloadData()

        contadorFotosLabel.aplicar(
            .labelMD,
            color: Theme.Color.charcoalMuted,
            texto: viewModel.textoContadorDeFotos,
            alineacion: .right
        )

        let sinFotos = viewModel.imagenes.isEmpty
        collectionView.isHidden = sinFotos
        sinFotosLabel.isHidden = !sinFotos
        sinFotosLabel.aplicar(
            .bodyMD,
            color: Theme.Color.outline,
            texto: "Este producto no tiene fotos."
        )

        // El boton solo aparece cuando realmente se puede subir. El motivo por el
        // que no se puede se explica abajo, en vez de dejar un boton que falla.
        let motivo = viewModel.motivoParaNoAgregar
        agregarFotoButton.isHidden = (motivo != nil)
        avisoFotosLabel.isHidden = (motivo == nil)
        avisoFotosLabel.aplicar(.bodyMD, color: Theme.Color.charcoalMuted, texto: motivo)
    }

    // MARK: - Acciones

    @objc private func editarTapped() {
        performSegue(withIdentifier: "irAFormularioProducto", sender: viewModel.producto)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "irAFormularioProducto",
              let destino = segue.destination as? ProductoFormViewController else { return }
        destino.configurar(con: sender as? ProductoEntity)
    }

    @IBAction func agregarFotoTapped(_ sender: UIButton) {
        var configuracion = PHPickerConfiguration()
        configuracion.filter = .images
        configuracion.selectionLimit = 1

        // PHPicker y no UIImagePickerController: corre fuera del proceso de la
        // app, asi que no necesita permiso de fototeca ni entrada en el
        // Info.plist. La app solo recibe la foto que el usuario eligio.
        let selector = PHPickerViewController(configuration: configuracion)
        selector.delegate = self
        present(selector, animated: true)
    }

    private func mostrarAlerta(titulo: String, mensaje: String) {
        let alert = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Entendido", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension ProductoDetailViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.imagenes.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let celda = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImagenCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        guard let celdaImagen = celda as? ImagenCollectionViewCell else { return celda }
        celdaImagen.configurar(urlTexto: viewModel.imagenes[indexPath.item].url ?? "")
        return celdaImagen
    }
}

// MARK: - UICollectionViewDelegate

extension ProductoDetailViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard viewModel.puedeGestionarImagenes else { return }

        let hoja = UIAlertController(title: "Foto", message: nil, preferredStyle: .actionSheet)
        hoja.addAction(UIAlertAction(title: "Eliminar foto", style: .destructive) { [weak self] _ in
            self?.confirmarBorrado(en: indexPath.item)
        })
        hoja.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // Obligatorio en iPad: sin esto el action sheet crashea por no tener
        // desde donde anclarse.
        let celda = collectionView.cellForItem(at: indexPath)
        hoja.popoverPresentationController?.sourceView = celda ?? collectionView
        hoja.popoverPresentationController?.sourceRect = (celda ?? collectionView).bounds

        present(hoja, animated: true)
    }

    private func confirmarBorrado(en indice: Int) {
        let alert = UIAlertController(
            title: "Eliminar foto",
            message: "Se borra del servidor ahora mismo. Esta accion no se puede deshacer.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.viewModel.borrar(en: indice)
        })
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ProductoDetailViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let proveedorDeItem = results.first?.itemProvider,
              proveedorDeItem.canLoadObject(ofClass: UIImage.self) else { return }

        proveedorDeItem.loadObject(ofClass: UIImage.self) { [weak self] objeto, _ in
            guard let imagen = objeto as? UIImage else { return }
            // `loadObject` contesta en una cola de fondo; todo lo que sigue toca
            // la UI y Core Data.
            DispatchQueue.main.async {
                self?.viewModel.subir(imagen)
            }
        }
    }
}
