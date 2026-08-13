import Foundation

// Cada fase agrega los casos que efectivamente usa (ver PLAN.md).
enum Endpoint {
    // Produccion (Render) por default: en las Mac del instituto no hay forma de
    // levantar el backend local. Si en algun momento se prueba con backend local,
    // cambiar a "http://localhost:8080" (y agregar una excepcion de ATS en
    // Info.plist, ya que ese es http y no https).
    static var baseURL = URL(string: "https://ferreteria-zamora-api.onrender.com")!

    case login
    case productos
    case producto(apiId: Int64)
    case categorias
    case proveedores

    var url: URL {
        let path: String
        switch self {
        case .login:
            path = "/api/auth/login"
        case .productos:
            path = "/api/productos"
        case .producto(let apiId):
            path = "/api/productos/\(apiId)"
        case .categorias:
            path = "/api/categorias"
        case .proveedores:
            path = "/api/proveedores"
        }
        return URL(string: Endpoint.baseURL.absoluteString + path)!
    }
}
