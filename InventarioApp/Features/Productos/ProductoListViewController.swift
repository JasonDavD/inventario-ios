import UIKit

final class ProductoListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sincronizarButton: UIBarButtonItem!
    @IBOutlet weak var salirButton: UIBarButtonItem!

    private let viewModel = ProductoListViewModel()
    private let refreshControl = UIRefreshControl()
    private var yaSincronizoAlEntrar = false

    override func viewDidLoad() {
        super.viewDidLoad()
        aplicarEstilos()
        configurarBotonNuevo()
        configurarTabla()
        bindViewModel()
        viewModel.cargarLocales()
    }

    /// Al volver del formulario hay que releer: el producto nuevo o editado ya
    /// esta en Core Data.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.cargarLocales()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Sin datos locales la pantalla no muestra nada util, asi que la primera
        // vez se sincroniza sola. Despues queda a pedido, para no gastar una
        // request en cada entrada.
        guard !yaSincronizoAlEntrar, viewModel.estaVacio else { return }
        yaSincronizoAlEntrar = true
        viewModel.sincronizar()
    }

    // MARK: - Configuracion

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surfaceContainerLowest

        tableView.aplicarEstiloDeLista()
        aplicarAparienciaDeNavegacion(titulo: "Productos")

        emptyLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: "Todavia no hay productos guardados.\nTocá Sincronizar para traerlos del servidor.",
            alineacion: .center
        )
        emptyLabel.isHidden = true

        activityIndicator.hidesWhenStopped = true

        sincronizarButton.aplicarEstiloDeTexto(color: Theme.Color.charcoalDeep)
        salirButton.aplicarEstiloDeTexto(color: Theme.Color.charcoalMuted)
    }

    /// El "+" se agrega por codigo y no en el Storyboard: el editor visual no
    /// deja poner dos items a la derecha sin pelear con el XML, y esto es una
    /// linea.
    ///
    /// Solo aparece de OPERADOR para arriba, igual que en las otras dos listas:
    /// sin el rol, el formulario dejaria guardar en Core Data algo que el
    /// servidor rechaza con 403 al sincronizar.
    private func configurarBotonNuevo() {
        guard SessionManager.shared.puedeEditarProductos else { return }
        let nuevo = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(nuevoProductoTapped)
        )
        nuevo.tintColor = Theme.Color.charcoalDeep
        navigationItem.rightBarButtonItems = [nuevo, sincronizarButton]
    }

    private func configurarTabla() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 84

        refreshControl.addTarget(self, action: #selector(refrescar), for: .valueChanged)
        refreshControl.tintColor = Theme.Color.outline
        tableView.refreshControl = refreshControl
    }

    private func bindViewModel() {
        viewModel.onCambio = { [weak self] in
            guard let self else { return }
            self.tableView.reloadData()
            self.emptyLabel.isHidden = !self.viewModel.estaVacio
        }

        viewModel.onError = { [weak self] mensaje in
            self?.mostrarError(mensaje)
        }

        viewModel.onLoadingChanged = { [weak self] cargando in
            guard let self else { return }
            self.sincronizarButton.isEnabled = !cargando
            if cargando {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
            }
        }
    }

    // MARK: - Acciones

    @IBAction func sincronizarTapped(_ sender: UIBarButtonItem) {
        viewModel.sincronizar()
    }

    @IBAction func salirTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "Cerrar sesion",
            message: "Los productos descargados siguen guardados en el dispositivo.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Salir", style: .destructive) { [weak self] _ in
            SessionManager.shared.logout()
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func refrescar() {
        viewModel.sincronizar()
    }

    @objc private func nuevoProductoTapped() {
        performSegue(withIdentifier: "irAFormularioProducto", sender: nil)
    }

    /// Dos destinos: el "+" va derecho al formulario en modo alta, y tocar una
    /// fila va al detalle, que es desde donde se edita y se manejan las fotos.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "irAFormularioProducto":
            (segue.destination as? ProductoFormViewController)?.configurar(con: nil)
        case "irADetalleProducto":
            guard let producto = sender as? ProductoEntity else { return }
            (segue.destination as? ProductoDetailViewController)?.configurar(con: producto)
        default:
            break
        }
    }

    private func mostrarError(_ mensaje: String) {
        let alert = UIAlertController(
            title: "No se pudo sincronizar",
            message: mensaje,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Entendido", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ProductoListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.productos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(
            withIdentifier: ProductoTableViewCell.reuseIdentifier,
            for: indexPath
        )
        guard let celdaProducto = celda as? ProductoTableViewCell else { return celda }
        celdaProducto.configurar(con: viewModel.productos[indexPath.row])
        return celdaProducto
    }
}

// MARK: - UITableViewDelegate

extension ProductoListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "irADetalleProducto", sender: viewModel.productos[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // Borrar productos es de ADMIN, no de OPERADOR: es el unico verbo de la
        // tabla de roles de PLAN.md que pide mas que editar.
        guard SessionManager.shared.esAdmin else { return nil }

        let eliminar = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, listo in
            self?.confirmarEliminacion(en: indexPath)
            listo(true)
        }
        eliminar.backgroundColor = Theme.Color.error
        return UISwipeActionsConfiguration(actions: [eliminar])
    }

    private func confirmarEliminacion(en indexPath: IndexPath) {
        let producto = viewModel.productos[indexPath.row]
        let alert = UIAlertController(
            title: "Eliminar producto",
            message: "\(producto.nombre ?? "Este producto") se va a borrar del servidor en la proxima sincronizacion.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.viewModel.eliminar(en: indexPath.row)
        })
        present(alert, animated: true)
    }
}
