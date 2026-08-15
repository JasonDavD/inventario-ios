import Foundation

/// Respuesta para endpoints que no devuelven cuerpo (tipicamente DELETE con
/// 204 No Content). Sin esto, `send` intentaria decodificar un body vacio y
/// fallaria con un error de decoding aunque la operacion haya salido bien.
struct RespuestaVacia: Decodable {}

/// Respuesta cuyo contenido no interesa: la operacion se confirma por el status
/// HTTP y el estado real se vuelve a bajar del servidor despues.
///
/// Se usa en la subida de imagenes. No hay una copia del backend al lado para
/// saber si `POST /api/productos/{id}/imagenes` devuelve la imagen creada, el
/// producto entero o una lista, y atarse a una de esas formas seria adivinar: un
/// `init(from:)` vacio decodifica cualquiera de las tres sin fallar.
struct RespuestaIgnorada: Decodable {
    init(from decoder: Decoder) throws {}
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let encoder = JSONEncoder()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decodificador in
            let contenedor = try decodificador.singleValueContainer()
            let texto = try contenedor.decode(String.self)
            guard let fecha = FechaAPI.parsear(texto) else {
                throw DecodingError.dataCorruptedError(
                    in: contenedor,
                    debugDescription: "Fecha con formato inesperado: \(texto)"
                )
            }
            return fecha
        }
        return decoder
    }()

    private init() {
        // Render (plan gratuito) "duerme" el servicio tras inactividad: la primera
        // request tras eso puede tardar 20-40s. 60s (el default de URLSession)
        // raspa justo, asi que se sube el margen.
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 90
        session = URLSession(configuration: configuration)
    }

    // MARK: - Verbos

    func get<Response: Decodable>(
        _ endpoint: Endpoint,
        authenticated: Bool = true,
        completion: @escaping (Result<Response, APIError>) -> Void
    ) {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "GET"
        attachAuthIfNeeded(&request, authenticated: authenticated)
        send(request, authenticated: authenticated, completion: completion)
    }

    func post<Body: Encodable, Response: Decodable>(
        _ endpoint: Endpoint,
        body: Body,
        authenticated: Bool = true,
        completion: @escaping (Result<Response, APIError>) -> Void
    ) {
        enviarConCuerpo(endpoint, metodo: "POST", body: body, authenticated: authenticated, completion: completion)
    }

    func put<Body: Encodable, Response: Decodable>(
        _ endpoint: Endpoint,
        body: Body,
        authenticated: Bool = true,
        completion: @escaping (Result<Response, APIError>) -> Void
    ) {
        enviarConCuerpo(endpoint, metodo: "PUT", body: body, authenticated: authenticated, completion: completion)
    }

    func delete<Response: Decodable>(
        _ endpoint: Endpoint,
        authenticated: Bool = true,
        completion: @escaping (Result<Response, APIError>) -> Void
    ) {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "DELETE"
        attachAuthIfNeeded(&request, authenticated: authenticated)
        send(request, authenticated: authenticated, completion: completion)
    }

    /// Sube un archivo como `multipart/form-data`.
    ///
    /// Es el unico camino para las imagenes: el backend las recibe en un campo
    /// de formulario (`archivo`), no como JSON. Por eso no reusa
    /// `enviarConCuerpo`, que siempre serializa a JSON.
    ///
    /// - Parameter campo: nombre del campo del formulario. El backend usa
    ///   `archivo` tanto para las imagenes de producto como para el logo de
    ///   proveedor (ver el contrato en PLAN.md).
    func upload<Response: Decodable>(
        _ endpoint: Endpoint,
        archivo: Data,
        nombreArchivo: String,
        mimeType: String,
        campo: String = "archivo",
        completion: @escaping (Result<Response, APIError>) -> Void
    ) {
        let frontera = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(frontera)", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.cuerpoMultipart(
            archivo: archivo,
            nombreArchivo: nombreArchivo,
            mimeType: mimeType,
            campo: campo,
            frontera: frontera
        )
        attachAuthIfNeeded(&request, authenticated: true)
        send(request, authenticated: true, completion: completion)
    }

    /// Arma el cuerpo multipart a mano. El formato es sensible a los saltos de
    /// linea: van CRLF (`\r\n`) y no `\n`, y la ultima frontera lleva `--` al
    /// final. Un solo salto de linea mal puesto hace que el servidor no
    /// encuentre el archivo y conteste 400 sin explicar por que.
    private static func cuerpoMultipart(
        archivo: Data,
        nombreArchivo: String,
        mimeType: String,
        campo: String,
        frontera: String
    ) -> Data {
        var cuerpo = Data()
        let salto = "\r\n"

        cuerpo.append("--\(frontera)\(salto)")
        cuerpo.append("Content-Disposition: form-data; name=\"\(campo)\"; filename=\"\(nombreArchivo)\"\(salto)")
        cuerpo.append("Content-Type: \(mimeType)\(salto)")
        cuerpo.append(salto)
        cuerpo.append(archivo)
        cuerpo.append(salto)
        cuerpo.append("--\(frontera)--\(salto)")

        return cuerpo
    }

    // MARK: - Interno

    private func enviarConCuerpo<Body: Encodable, Response: Decodable>(
        _ endpoint: Endpoint,
        metodo: String,
        body: Body,
        authenticated: Bool,
        completion: @escaping (Result<Response, APIError>) -> Void
    ) {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = metodo
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            completion(.failure(.decoding(error)))
            return
        }
        attachAuthIfNeeded(&request, authenticated: authenticated)
        send(request, authenticated: authenticated, completion: completion)
    }

    private func attachAuthIfNeeded(_ request: inout URLRequest, authenticated: Bool) {
        // Se lee de SessionManager y no del Keychain directo: con "mantener
        // sesion iniciada" desactivado el token vive solo en memoria.
        guard authenticated, let token = SessionManager.shared.token else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func send<Response: Decodable>(
        _ request: URLRequest,
        authenticated: Bool,
        completion: @escaping (Result<Response, APIError>) -> Void
    ) {
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if error != nil {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, let data else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                // Un 401 solo significa "sesion vencida" si la request iba con token.
                // En el login (authenticated: false) significa credenciales malas, y
                // ahi lo que sirve es el `mensaje` que manda el backend.
                if httpResponse.statusCode == 401, authenticated {
                    DispatchQueue.main.async { completion(.failure(.unauthorized)) }
                    return
                }
                let mensaje = (try? JSONDecoder().decode(BackendErrorBody.self, from: data))?.mensaje
                DispatchQueue.main.async {
                    completion(.failure(.server(status: httpResponse.statusCode, message: mensaje ?? "Error del servidor")))
                }
                return
            }

            // 204 / cuerpo vacio: exito sin nada que decodificar.
            if data.isEmpty, let vacia = RespuestaVacia() as? Response {
                DispatchQueue.main.async { completion(.success(vacia)) }
                return
            }

            do {
                let decoded = try self.decoder.decode(Response.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(.decoding(error))) }
            }
        }
        task.resume()
    }
}

private struct BackendErrorBody: Decodable {
    let mensaje: String?
}

private extension Data {
    /// Append de texto en UTF-8. El cuerpo multipart mezcla texto y bytes
    /// crudos, asi que se arma sobre `Data` y no sobre `String`.
    mutating func append(_ texto: String) {
        guard let datos = texto.data(using: .utf8) else { return }
        append(datos)
    }
}
