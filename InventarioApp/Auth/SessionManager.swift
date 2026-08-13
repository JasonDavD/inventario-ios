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

    func logout() {
        keychain.deleteToken()
        defaults.removeObject(forKey: usernameKey)
        defaults.removeObject(forKey: rolesKey)
        token = nil
        username = nil
        roles = []
        isAuthenticated = false
    }

    func hasRole(_ role: String) -> Bool {
        roles.contains(role)
    }
}
