import UIKit

final class ProveedorListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sincronizarButton: UIBarButtonItem!

    private let viewModel = CatalogoListViewModel<ProveedorEntity>(
        cargar: { ProveedorService().todos() },
        borrar: {
            let nombre = $0.nombre ?? "(sin nombre)"
            ProveedorService().marcarParaEliminar($0)
            BitacoraService.shared.registrar(.elimino, sobre: .proveedor, nombre: nombre)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.cargarLocales()
    }

    // MARK: - Configuracion

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surfaceContainerLowest

        tableView.aplicarEstiloDeLista()
        aplicarAparienciaDeNavegacion(titulo: "Proveedores")
        sincronizarButton.aplicarEstiloDeTexto(color: Theme.Color.charcoalDeep)

        emptyLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: "Todavia no hay proveedores guardados.\nTocá Sincronizar para traerlos del servidor.",
            alineacion: .center
        )
        emptyLabel.isHidden = true
        activityIndicator.hidesWhenStopped = true
    }

    /// Igual que en categorias: crear proveedores es exclusivo de ADMIN, asi que
    /// el "+" no aparece para los demas roles.
    private func configurarBotonNuevo() {
        guard SessionManager.shared.esAdmin else { return }
        let nuevo = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(nuevoProveedorTapped)
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

    @objc private func nuevoProveedorTapped() {
        performSegue(withIdentifier: "irAFormularioProveedor", sender: nil)
    }

    /// `sender` nil = alta; con un `ProveedorEntity` = edicion.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "irAFormularioProveedor",
              let destino = segue.destination as? ProveedorFormViewController else { return }
        destino.configurar(con: sender as? ProveedorEntity)
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

extension ProveedorListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(
            withIdentifier: CatalogoTableViewCell.reuseIdentifier,
            for: indexPath
        )
        guard let celdaCatalogo = celda as? CatalogoTableViewCell else { return celda }

        let proveedor = viewModel.items[indexPath.row]
        celdaCatalogo.configurar(
            nombre: proveedor.nombre,
            detalle: Self.detalle(de: proveedor),
            chip: proveedor.estadoSync == 0 ? .pendiente : nil,
            imagenURL: proveedor.logoUrl
        )
        return celdaCatalogo
    }

    /// Telefono y direccion son los dos opcionales; se muestra lo que haya.
    private static func detalle(de proveedor: ProveedorEntity) -> String? {
        [proveedor.telefono, proveedor.direccion]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

// MARK: - UITableViewDelegate

extension ProveedorListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard SessionManager.shared.esAdmin else { return }
        performSegue(withIdentifier: "irAFormularioProveedor", sender: viewModel.items[indexPath.row])
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
        let proveedor = viewModel.items[indexPath.row]
        let alert = UIAlertController(
            title: "Eliminar proveedor",
            message: "\(proveedor.nombre ?? "Este proveedor") se va a borrar del servidor en la proxima sincronizacion. Los productos que lo usen quedan sin proveedor.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.viewModel.eliminar(en: indexPath.row)
        })
        present(alert, animated: true)
    }
}
