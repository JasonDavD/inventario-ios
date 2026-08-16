import UIKit

final class UsuarioListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    private let viewModel = UsuarioListViewModel()
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        aplicarEstilos()
        configurarBotonNuevo()
        configurarTabla()
        bindViewModel()
    }

    /// Se recarga al aparecer y no solo una vez: esta pantalla no tiene copia
    /// local, asi que volver del formulario tiene que ir a buscar de nuevo.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.cargar()
    }

    // MARK: - Configuracion

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surfaceContainerLowest
        tableView.aplicarEstiloDeLista()
        aplicarAparienciaDeNavegacion(titulo: "Usuarios")

        emptyLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: "No se pudieron traer los usuarios.\nRevisá la conexion y deslizá para reintentar.",
            alineacion: .center
        )
        emptyLabel.isHidden = true
        activityIndicator.hidesWhenStopped = true
    }

    private func configurarBotonNuevo() {
        let nuevo = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(nuevoUsuarioTapped)
        )
        nuevo.tintColor = Theme.Color.charcoalDeep
        navigationItem.rightBarButtonItem = nuevo
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
            guard let self else { return }
            // Sin copia local, un error deja la pantalla vacia: el estado vacio
            // tiene que explicar que fue un problema de red y no que no haya
            // usuarios.
            self.emptyLabel.isHidden = !self.viewModel.estaVacio
            self.mostrarAlerta(titulo: "No se pudo completar", mensaje: mensaje)
        }

        viewModel.onLoadingChanged = { [weak self] cargando in
            guard let self else { return }
            if cargando {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
            }
        }
    }

    // MARK: - Acciones

    @objc private func refrescar() {
        viewModel.cargar()
    }

    @objc private func nuevoUsuarioTapped() {
        performSegue(withIdentifier: "irAFormularioUsuario", sender: nil)
    }

    /// `sender` nil = alta; con un `UsuarioDTO` = edicion.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "irAFormularioUsuario",
              let destino = segue.destination as? UsuarioFormViewController else { return }
        destino.configurar(con: sender as? UsuarioDTO)
    }

    private func mostrarAlerta(titulo: String, mensaje: String) {
        let alert = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Entendido", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension UsuarioListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.usuarios.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(
            withIdentifier: CatalogoTableViewCell.reuseIdentifier,
            for: indexPath
        )
        guard let celdaCatalogo = celda as? CatalogoTableViewCell else { return celda }

        let usuario = viewModel.usuarios[indexPath.row]
        celdaCatalogo.configurar(
            nombre: usuario.username,
            detalle: Self.detalle(de: usuario),
            chip: usuario.enabled ? nil : .inactivo
        )
        return celdaCatalogo
    }

    private static func detalle(de usuario: UsuarioDTO) -> String {
        let roles = usuario.roles
            .compactMap { RolDisponible.desde($0)?.titulo }
            .sorted()
        return roles.isEmpty ? "Sin roles asignados" : roles.joined(separator: " · ")
    }
}

// MARK: - UITableViewDelegate

extension UsuarioListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "irAFormularioUsuario", sender: viewModel.usuarios[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // El usuario de la sesion no se puede borrar a si mismo.
        guard !viewModel.esElUsuarioDeLaSesion(viewModel.usuarios[indexPath.row]) else { return nil }

        let eliminar = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, listo in
            self?.confirmarEliminacion(en: indexPath)
            listo(true)
        }
        eliminar.backgroundColor = Theme.Color.error
        return UISwipeActionsConfiguration(actions: [eliminar])
    }

    private func confirmarEliminacion(en indexPath: IndexPath) {
        let usuario = viewModel.usuarios[indexPath.row]
        let alert = UIAlertController(
            title: "Eliminar usuario",
            message: "\(usuario.username) no va a poder entrar mas. Se borra del servidor ahora mismo y no se puede deshacer.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.viewModel.eliminar(en: indexPath.row)
        })
        present(alert, animated: true)
    }
}
