import Foundation

// Cada fase agrega los casos que efectivamente usa (ver PLAN.md).
enum Endpoint {
    static var baseURL = URL(string: "http://localhost:8080")!

    case login

    var url: URL {
        let path: String
        switch self {
        case .login:
            path = "/api/auth/login"
        }
        return URL(string: Endpoint.baseURL.absoluteString + path)!
    }
}
