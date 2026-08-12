import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let authService = AuthService()
    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authService.login(username: username, password: password)
            session.handleLogin(response: response)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudo iniciar sesion"
        }
    }
}
