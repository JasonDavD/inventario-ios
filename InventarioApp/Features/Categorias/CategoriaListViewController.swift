import UIKit

final class CategoriaListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sincronizarButton: UIBarButtonItem!

    private let viewModel = CatalogoListViewModel<CategoriaEntity>(
        cargar: { CategoriaService().todas() },
        borrar: {
            let nombre = $0.nombre ?? "(sin nombre)"
            CategoriaService().marcarParaEliminar($0)
            BitacoraService.shared.registrar(.elimino, sobre: .categoria, nombre: nombre)
        }
    )
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        aplicarEstilos()
        configurarBotonNuevo()
        configurarTabla()
        bindViewModel()
        viewModel.cargarLocales()
    }

    /// Al volver del formulario hay que releer: la categoria nueva o editada ya
    /// esta en Core Data.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.cargarLocales()
    }

    // MARK: - Configuracion

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surfaceContainerLowest

        tableView.aplicarEstiloDeLista()
        aplicarAparienciaDeNavegacion(titulo: "Categorias")
        sincronizarButton.aplicarEstiloDeTexto(color: Theme.Color.charcoalDeep)

        emptyLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: "Todavia no hay categorias guardadas.\nTocá Sincronizar para traerlas del servidor.",
            alineacion: .center
        )
        emptyLabel.isHidden = true
        activityIndicator.hidesWhenStopped = true
    }

    /// El "+" solo existe para ADMIN: es el unico rol que puede crear categorias
    /// (ver la tabla de roles en PLAN.md). Sin esto el formulario dejaria
    /// guardar local algo que despues el servidor rechaza con 403, y el usuario
    /// se enteraria recien al sincronizar.
    private func configurarBotonNuevo() {
        guard SessionManager.shared.esAdmin else { return }
        let nuevo = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(nuevaCategoriaTapped)
        )
        nuevo.tintColor = Theme.Color.charcoalDeep
        navigationItem.rightBarButtonItems = [nuevo, sincronizarButton]
    }

    private func configurarTabla() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 72

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

    @objc private func refrescar() {
        viewModel.sincronizar()
    }

    @objc private func nuevaCategoriaTapped() {
        performSegue(withIdentifier: "irAFormularioCategoria", sender: nil)
    }

    /// `sender` nil = alta; con una `CategoriaEntity` = edicion.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "irAFormularioCategoria",
              let destino = segue.destination as? CategoriaFormViewController else { return }
        destino.configurar(con: sender as? CategoriaEntity)
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

extension CategoriaListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(
            withIdentifier: CatalogoTableViewCell.reuseIdentifier,
            for: indexPath
        )
        guard let celdaCatalogo = celda as? CatalogoTableViewCell else { return celda }

        let categoria = viewModel.items[indexPath.row]
        celdaCatalogo.configurar(
            nombre: categoria.nombre,
            detalle: categoria.descripcion,
            chip: categoria.estadoSync == 0 ? .pendiente : nil
        )
        return celdaCatalogo
    }
}

// MARK: - UITableViewDelegate

extension CategoriaListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard SessionManager.shared.esAdmin else { return }
        performSegue(withIdentifier: "irAFormularioCategoria", sender: viewModel.items[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard SessionManager.shared.esAdmin else { return nil }

        let eliminar = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, listo in
            self?.confirmarEliminacion(en: indexPath)
            listo(true)
        }
        eliminar.backgroundColor = Theme.Color.error
        return UISwipeActionsConfiguration(actions: [eliminar])
    }

    private func confirmarEliminacion(en indexPath: IndexPath) {
        let categoria = viewModel.items[indexPath.row]
        let alert = UIAlertController(
            title: "Eliminar categoria",
            message: "\(categoria.nombre ?? "Esta categoria") se va a borrar del servidor en la proxima sincronizacion. Los productos que la usen quedan sin categoria.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.viewModel.eliminar(en: indexPath.row)
        })
        present(alert, animated: true)
    }
}
