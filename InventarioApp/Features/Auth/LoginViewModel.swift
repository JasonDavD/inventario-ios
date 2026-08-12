import Foundation

final class LoginViewModel {
    var onLoginSuccess: (() -> Void)?
    var onLoginError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private let authService = AuthService()

    func login(username: String, password: String) {
        guard !username.isEmpty, !password.isEmpty else {
            onLoginError?("Completa usuario y contrasena")
            return
        }

        onLoadingChanged?(true)
        authService.login(username: username, password: password) { [weak self] result in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch result {
            case .success(let response):
                SessionManager.shared.handleLogin(response: response)
                self.onLoginSuccess?()
            case .failure(let error):
                self.onLoginError?(error.errorDescription ?? "No se pudo iniciar sesion")
            }
        }
    }
}
