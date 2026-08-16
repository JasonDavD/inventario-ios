import Foundation

/// Usuario tal como lo devuelve `GET /api/usuarios`.
///
/// **No tiene `password`, y eso es a proposito del backend**: `UsuarioResponse`
/// no lo expone nunca. La app tampoco lo guarda en ningun lado.
struct UsuarioDTO: Decodable {
    let id: Int64
    let username: String
    let enabled: Bool
    let roles: [String]
    let fechaCreacion: Date?
}

/// Cuerpo de POST/PUT de usuario.
///
/// `password` es opcional porque en la edicion se puede dejar vacio para no
/// cambiarlo: el backend solo lo pisa si viene con contenido. Al ser un
/// `Optional`, `JSONEncoder` omite la clave entera cuando es nil, que es
/// justo lo que ese chequeo espera.
struct UsuarioRequest: Encodable {
    let username: String
    let password: String?
    let enabled: Bool
    let roles: [String]
}

/// Los tres roles del backend (`RolNombre`). Se listan aca para que el
/// formulario los ofrezca sin inventarlos: si el backend suma uno, este enum es
/// el unico lugar a tocar.
enum RolDisponible: String, CaseIterable {
    case admin = "ADMIN"
    case operador = "OPERADOR"
    case lector = "LECTOR"

    var titulo: String {
        switch self {
        case .admin: return "Administrador"
        case .operador: return "Operador"
        case .lector: return "Lector"
        }
    }

    var descripcion: String {
        switch self {
        case .admin: return "Acceso total, incluido el ABM de usuarios"
        case .operador: return "Crea y edita productos, pero no los borra"
        case .lector: return "Solo lectura"
        }
    }

    /// El backend manda los roles con el prefijo de Spring (`ROLE_ADMIN`) en el
    /// login, pero los espera sin prefijo en el ABM porque ahi son el enum
    /// `RolNombre`. Se normaliza al leer para no depender de cual de las dos
    /// formas llego.
    static func desde(_ texto: String) -> RolDisponible? {
        let limpio = texto.uppercased().hasPrefix("ROLE_")
            ? String(texto.uppercased().dropFirst(5))
            : texto.uppercased()
        return RolDisponible(rawValue: limpio)
    }
}
