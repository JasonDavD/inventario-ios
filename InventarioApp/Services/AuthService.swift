import Foundation

struct AuthService {
    func login(username: String, password: String) async throws -> LoginResponse {
        let body = LoginRequest(username: username, password: password)
        return try await APIClient.shared.post(.login, body: body, authenticated: false)
    }
}
