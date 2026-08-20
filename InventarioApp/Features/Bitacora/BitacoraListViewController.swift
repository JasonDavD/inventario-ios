import UIKit

/// Historial de auditoria: que se creo, edito o elimino, quien lo hizo y cuando.
///
/// Es la unica pantalla de la app que muestra datos guardados en Firebase. No
/// tiene botones: la bitacora es append-only y se escribe sola desde los
/// ViewModels que modifican datos (ver `BitacoraService`).
final class BitacoraListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    private let viewModel = BitacoraListViewModel()
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        aplicarEstilos()
        configurarTabla()
        bindViewModel()
    }

    /// Se recarga al aparecer: sin copia local, volver a esta pantalla tiene que
    /// ir a buscar de nuevo.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.cargar()
    }

    // MARK: - Configuracion

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surfaceContainerLowest
        tableView.aplicarEstiloDeLista()
        aplicarAparienciaDeNavegacion(titulo: "Bitacora")

        emptyLabel.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: "Todavia no hay movimientos registrados.\nSe anotan solos al crear, editar o eliminar.",
            alineacion: .center
        )
        emptyLabel.isHidden = true
        activityIndicator.hidesWhenStopped = true
    }

    private func configurarTabla() {
        tableView.dataSource = self
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

    private func mostrarAlerta(titulo: String, mensaje: String) {
        let alert = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Entendido", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BitacoraListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.eventos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(
            withIdentifier: CatalogoTableViewCell.reuseIdentifier,
            for: indexPath
        )
        guard let celdaCatalogo = celda as? CatalogoTableViewCell,
              let evento = viewModel.evento(en: indexPath.row) else { return celda }

        // Se reusa la celda del catalogo: la estructura es la misma (un titulo y
        // un detalle). El chip va en nil, que es lo que lo esconde.
        celdaCatalogo.configurar(
            nombre: evento.resumen,
            detalle: "\(evento.usuario) · \(evento.fechaLegible)",
            chip: nil
        )
        return celdaCatalogo
    }
}
