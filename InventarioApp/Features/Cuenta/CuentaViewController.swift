import UIKit

/// Menu de la seccion de cuenta y administracion.
///
/// Es a proposito un **indice y no un tablero**: cada cosa que se pueda
/// administrar entra como una fila que empuja su propia pantalla. Cuando
/// aparezca algo nuevo (auditoria, ajustes) va a ser una fila mas, no mas
/// controles apilados aca.
final class CuentaViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private enum Fila {
        case usuarios
        case bitacora
        case cerrarSesion

        var titulo: String {
            switch self {
            case .usuarios: return "Usuarios"
            case .bitacora: return "Bitacora"
            case .cerrarSesion: return "Cerrar sesion"
            }
        }

        var detalle: String? {
            switch self {
            case .usuarios: return "Dar de alta, editar roles y dar de baja"
            case .bitacora: return "Historial de altas, ediciones y bajas"
            case .cerrarSesion: return nil
            }
        }

        var icono: String {
            switch self {
            case .usuarios: return "person.2"
            case .bitacora: return "clock.arrow.circlepath"
            case .cerrarSesion: return "rectangle.portrait.and.arrow.right"
            }
        }
    }

    private struct Seccion {
        let titulo: String?
        let filas: [Fila]
    }

    private var secciones: [Seccion] = []

    private static let celdaID = "CuentaCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        aplicarEstilos()
        armarSecciones()
        configurarTabla()
    }

    // MARK: - Configuracion

    private func aplicarEstilos() {
        view.backgroundColor = Theme.Color.surface
        aplicarAparienciaDeNavegacion(titulo: "Cuenta")
        tableView.backgroundColor = Theme.Color.surface
        tableView.separatorColor = Theme.Color.borderSubtle
    }

    /// La seccion de administracion solo existe para ADMIN. No es solo estetica:
    /// `/api/usuarios` pide ese rol, asi que para cualquier otro la pantalla no
    /// tendria nada que mostrar mas que un 403.
    private func armarSecciones() {
        var armadas: [Seccion] = []

        if SessionManager.shared.esAdmin {
            armadas.append(Seccion(titulo: "Administracion", filas: [.usuarios, .bitacora]))
        }
        armadas.append(Seccion(titulo: nil, filas: [.cerrarSesion]))

        secciones = armadas
    }

    private func configurarTabla() {
        tableView.dataSource = self
        tableView.delegate = self
        // Celda del sistema: esta pantalla es un indice de navegacion, no
        // necesita una celda propia con su prototipo en el Storyboard.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.celdaID)
        tableView.tableHeaderView = encabezadoDeSesion()
    }

    /// Quien esta logueado y con que roles. Hasta ahora la app no lo mostraba en
    /// ningun lado, y es el dato que mas se necesita cuando algo no aparece por
    /// permisos.
    private func encabezadoDeSesion() -> UIView {
        let contenedor = UIView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Theme.Spacing.unit
        stack.translatesAutoresizingMaskIntoConstraints = false

        let usuario = UILabel()
        usuario.aplicar(
            .headlineSM,
            color: Theme.Color.charcoalDeep,
            texto: SessionManager.shared.username ?? "(sin usuario)"
        )

        let roles = UILabel()
        roles.numberOfLines = 0
        roles.aplicar(
            .bodyMD,
            color: Theme.Color.charcoalMuted,
            texto: Self.textoDeRoles()
        )

        stack.addArrangedSubview(usuario)
        stack.addArrangedSubview(roles)
        contenedor.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contenedor.leadingAnchor, constant: Theme.Spacing.marginMobile),
            contenedor.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: Theme.Spacing.marginMobile),
            stack.topAnchor.constraint(equalTo: contenedor.topAnchor, constant: Theme.Spacing.md),
            contenedor.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: Theme.Spacing.md)
        ])

        // Un tableHeaderView no participa de Auto Layout con la tabla: hay que
        // medirlo y darle un frame a mano o queda con altura cero.
        let ancho = UIScreen.main.bounds.width
        let alto = contenedor.systemLayoutSizeFitting(
            CGSize(width: ancho, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        contenedor.frame = CGRect(x: 0, y: 0, width: ancho, height: alto)
        return contenedor
    }

    private static func textoDeRoles() -> String {
        let roles = SessionManager.shared.roles
            .compactMap { RolDisponible.desde($0)?.titulo }
            .sorted()
        return roles.isEmpty ? "Sin roles asignados" : roles.joined(separator: " · ")
    }

    // MARK: - Acciones

    private func confirmarCerrarSesion() {
        let alert = UIAlertController(
            title: "Cerrar sesion",
            message: "Los datos descargados siguen guardados en el dispositivo.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Salir", style: .destructive) { [weak self] _ in
            SessionManager.shared.logout()
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CuentaViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        secciones.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        secciones[section].filas.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        secciones[section].titulo
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: Self.celdaID, for: indexPath)
        let fila = secciones[indexPath.section].filas[indexPath.row]

        var config = celda.defaultContentConfiguration()
        config.text = fila.titulo
        config.secondaryText = fila.detalle
        config.image = UIImage(systemName: fila.icono)

        config.textProperties.font = Theme.TextStyle.bodyLG.font
        config.secondaryTextProperties.font = Theme.TextStyle.bodyMD.font
        config.secondaryTextProperties.color = Theme.Color.charcoalMuted

        switch fila {
        case .usuarios, .bitacora:
            config.textProperties.color = Theme.Color.charcoalDeep
            config.imageProperties.tintColor = Theme.Color.charcoalDeep
            celda.accessoryType = .disclosureIndicator
        case .cerrarSesion:
            config.textProperties.color = Theme.Color.error
            config.imageProperties.tintColor = Theme.Color.error
            celda.accessoryType = .none
        }

        celda.contentConfiguration = config
        celda.backgroundColor = Theme.Color.surfaceContainerLowest
        return celda
    }
}

// MARK: - UITableViewDelegate

extension CuentaViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch secciones[indexPath.section].filas[indexPath.row] {
        case .usuarios:
            performSegue(withIdentifier: "irAUsuarios", sender: nil)
        case .bitacora:
            performSegue(withIdentifier: "irABitacora", sender: nil)
        case .cerrarSesion:
            confirmarCerrarSesion()
        }
    }
}
