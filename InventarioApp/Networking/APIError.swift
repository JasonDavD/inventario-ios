import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "No se pudo conectar al servidor"
        case .unauthorized:
            return "Sesion expirada, volve a iniciar sesion"
        case .server(_, let message):
            return message
        case .decoding:
            return "Respuesta inesperada del servidor"
        }
    }
}
