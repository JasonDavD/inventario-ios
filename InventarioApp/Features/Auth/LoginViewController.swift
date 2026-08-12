import UIKit

// Outlets/action que hay que conectar en Main.storyboard (ver PLAN.md, Fase 2):
// usernameField, passwordField, loginButton, errorLabel, activityIndicator,
// y loginButtonTapped(_:) en el Touch Up Inside del boton.
final class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    private let viewModel = LoginViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.text = nil
        activityIndicator.hidesWhenStopped = true
        bindViewModel()
    }

    private func bindViewModel() {
        viewModel.onLoginSuccess = { [weak self] in
            self?.showLoginSuccessPlaceholder()
        }
        viewModel.onLoginError = { [weak self] message in
            self?.errorLabel.text = message
        }
        viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self else { return }
            self.loginButton.isEnabled = !isLoading
            isLoading ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
        }
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        errorLabel.text = nil
        viewModel.login(username: usernameField.text ?? "", password: passwordField.text ?? "")
    }

    // Placeholder temporal — Fase 3 lo reemplaza por un segue real a ProductoListViewController.
    private func showLoginSuccessPlaceholder() {
        let alert = UIAlertController(
            title: "Sesion iniciada",
            message: "Bienvenido, \(SessionManager.shared.username ?? "")",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
