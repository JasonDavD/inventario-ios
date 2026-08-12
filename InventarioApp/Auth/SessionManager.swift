import Foundation

final class SessionManager {
    static let shared = SessionManager()

    private(set) var isAuthenticated: Bool
    private(set) var username: String?
    private(set) var roles: [String]

    private let keychain = KeychainService.shared
    private let defaults = UserDefaults.standard
    private let usernameKey = "session.username"
    private let rolesKey = "session.roles"

    private init() {
        isAuthenticated = keychain.readToken() != nil
        username = defaults.string(forKey: usernameKey)
        roles = defaults.stringArray(forKey: rolesKey) ?? []
    }

    func handleLogin(response: LoginResponse) {
        keychain.saveToken(response.token)
        defaults.set(response.username, forKey: usernameKey)
        defaults.set(response.roles, forKey: rolesKey)
        username = response.username
        roles = response.roles
        isAuthenticated = true
    }

    func logout() {
        keychain.deleteToken()
        defaults.removeObject(forKey: usernameKey)
        defaults.removeObject(forKey: rolesKey)
        username = nil
        roles = []
        isAuthenticated = false
    }

    func hasRole(_ role: String) -> Bool {
        roles.contains(role)
    }
}
