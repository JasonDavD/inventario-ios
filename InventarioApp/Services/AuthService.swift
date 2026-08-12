import Foundation

struct AuthService {
    func login(username: String, password: String, completion: @escaping (Result<LoginResponse, APIError>) -> Void) {
        let body = LoginRequest(username: username, password: password)
        APIClient.shared.post(.login, body: body, authenticated: false, completion: completion)
    }
}
