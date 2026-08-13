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
        title = "Productos"

        tableView.backgroundColor = Theme.Color.surfaceContainerLowest
        tableView.separatorColor = Theme.Color.borderSubtle
        tableView.separatorInset = UIEdgeInsets(
            top: 0,
            left: Theme.Spacing.marginMobile,
            bottom: 0,
            right: Theme.Spacing.marginMobile
        )
        // Listas de alta densidad: divisores horizontales de 1px, sin nada mas
        // que separe (DESIGN.md > Components > Lists).
        tableView.tableFooterView = UIView()

        emptyLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: "Todavia no hay productos guardados.\nTocá Sincronizar para traerlos del servidor.",
            alineacion: .center
        )
        emptyLabel.isHidden = true

        activityIndicator.hidesWhenStopped = true

        let apariencia = UINavigationBarAppearance()
        apariencia.configureWithOpaqueBackground()
        apariencia.backgroundColor = Theme.Color.surfaceContainerLowest
        apariencia.shadowColor = Theme.Color.borderSubtle
        apariencia.titleTextAttributes = Theme.TextStyle.headlineSM
            .attributes(color: Theme.Color.charcoalDeep, alineacion: .center)
        navigationItem.standardAppearance = apariencia
        navigationItem.scrollEdgeAppearance = apariencia

        [sincronizarButton, salirButton].forEach {
            $0?.setTitleTextAttributes(
                [.font: Theme.TextStyle.labelLG.font, .kern: Theme.TextStyle.labelLG.kern],
                for: .normal
            )
        }
        sincronizarButton.tintColor = Theme.Color.charcoalDeep
        salirButton.tintColor = Theme.Color.charcoalMuted
    }

    /// El "+" se agrega por codigo y no en el Storyboard: el editor visual no
    /// deja poner dos items a la derecha sin pelear con el XML, y esto es una
    /// linea.
    private func configurarBotonNuevo() {
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
        tableView.rowHeight = UITableView.automaticDimension
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

    /// `sender` nil = alta; con un `ProductoEntity` = edicion.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "irAFormularioProducto",
              let destino = segue.destination as? ProductoFormViewController else { return }
        destino.configurar(con: sender as? ProductoEntity)
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
        // Fase 5 mete el detalle en el medio; por ahora se va derecho a editar.
        performSegue(withIdentifier: "irAFormularioProducto", sender: viewModel.productos[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
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
