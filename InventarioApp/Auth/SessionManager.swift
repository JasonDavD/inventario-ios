import Foundation

final class SessionManager {
    static let shared = SessionManager()

    /// Token JWT vigente. Es la unica fuente de la que lee `APIClient`: puede
    /// venir del Keychain (sesion recordada) o vivir solo en memoria.
    private(set) var token: String?
    private(set) var isAuthenticated: Bool
    private(set) var username: String?
    private(set) var roles: [String]

    private let keychain = KeychainService.shared
    private let defaults = UserDefaults.standard
    private let usernameKey = "session.username"
    private let rolesKey = "session.roles"

    private init() {
        token = keychain.readToken()
        isAuthenticated = token != nil
        username = defaults.string(forKey: usernameKey)
        roles = defaults.stringArray(forKey: rolesKey) ?? []
    }

    /// - Parameter recordarSesion: lo controla el check "Mantener sesion
    ///   iniciada" del login. Si esta en `false`, el token vive solo en memoria
    ///   y no queda nada persistido al cerrar la app.
    func handleLogin(response: LoginResponse, recordarSesion: Bool) {
        token = response.token
        username = response.username
        roles = response.roles
        isAuthenticated = true

        if recordarSesion {
            keychain.saveToken(response.token)
            defaults.set(response.username, forKey: usernameKey)
            defaults.set(response.roles, forKey: rolesKey)
        } else {
            keychain.deleteToken()
            defaults.removeObject(forKey: usernameKey)
            defaults.removeObject(forKey: rolesKey)
        }
    }

    /// Se dispara cuando el backend contesta 401 a una request que iba con token:
    /// el JWT vencio o dejo de ser valido. La escucha `InicioTabBarController`,
    /// que es quien puede volver al Login.
    static let sesionExpirada = Notification.Name("SessionManager.sesionExpirada")

    /// Cierra la sesion y avisa a la UI. **El guard no es decorativo:** una
    /// sincronizacion dispara varias requests seguidas y todas van a fallar con
    /// 401 al vencer el token; sin el, se apilarian varios avisos encima del
    /// mismo problema.
    func manejarSesionExpirada() {
        guard isAuthenticated else { return }
        logout()
        NotificationCenter.default.post(name: Self.sesionExpirada, object: nil)
    }

    func logout() {
        keychain.deleteToken()
        defaults.removeObject(forKey: usernameKey)
        defaults.removeObject(forKey: rolesKey)
        token = nil
        username = nil
        roles = []
        isAuthenticated = false
    }

    /// Spring Security no es consistente con el prefijo `ROLE_`: segun como este
    /// armado el token, el mismo rol puede llegar como `ADMIN` o `ROLE_ADMIN`.
    /// Se comparan las dos formas sin el prefijo para no depender de eso.
    func hasRole(_ role: String) -> Bool {
        let buscado = Self.sinPrefijo(role)
        return roles.contains { Self.sinPrefijo($0) == buscado }
    }

    /// Categorias y proveedores son CRUD de ADMIN (ver la tabla de roles en
    /// PLAN.md). Las pantallas esconden las acciones de escritura si no lo es.
    var esAdmin: Bool { hasRole("ADMIN") }

    /// Crear/editar productos y manejar sus imagenes es de OPERADOR para arriba.
    /// Se chequean los dos roles y no solo OPERADOR: no hay garantia de que el
    /// backend le agregue OPERADOR a un ADMIN en el token.
    var puedeEditarProductos: Bool { esAdmin || hasRole("OPERADOR") }

    private static func sinPrefijo(_ role: String) -> String {
        let mayusculas = role.uppercased()
        return mayusculas.hasPrefix("ROLE_") ? String(mayusculas.dropFirst(5)) : mayusculas
    }
}
