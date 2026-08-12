import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {
        // Render (plan gratuito) "duerme" el servicio tras inactividad: la primera
        // request tras eso puede tardar 20-40s en responder. 60s (el default de
        // URLSession) raspa justo, asi que se sube el margen.
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 90
        self.session = URLSession(configuration: configuration)
    }

    func get<Response: Decodable>(_ endpoint: Endpoint, authenticated: Bool = true) async throws -> Response {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "GET"
        attachAuthIfNeeded(&request, authenticated: authenticated)
        return try await send(request)
    }

    func post<Body: Encodable, Response: Decodable>(
        _ endpoint: Endpoint,
        body: Body,
        authenticated: Bool = true
    ) async throws -> Response {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        attachAuthIfNeeded(&request, authenticated: authenticated)
        return try await send(request)
    }

    private func attachAuthIfNeeded(_ request: inout URLRequest, authenticated: Bool) {
        guard authenticated, let token = KeychainService.shared.readToken() else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            let mensaje = (try? JSONDecoder().decode(BackendErrorBody.self, from: data))?.mensaje
            throw APIError.server(status: httpResponse.statusCode, message: mensaje ?? "Error del servidor")
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

private struct BackendErrorBody: Decodable {
    let mensaje: String?
}
