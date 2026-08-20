import Foundation

/// Que se le hizo a un registro. El texto crudo es lo que se guarda en Firebase.
enum AccionBitacora: String {
    case creo = "creo"
    case edito = "edito"
    case elimino = "elimino"

    var descripcion: String {
        switch self {
        case .creo: return "Creo"
        case .edito: return "Edito"
        case .elimino: return "Elimino"
        }
    }
}

/// Sobre que tipo de registro se actuo.
enum EntidadBitacora: String {
    case producto = "Producto"
    case categoria = "Categoria"
    case proveedor = "Proveedor"
}

/// Una entrada de la bitacora de auditoria: quien hizo que, sobre que y cuando.
///
/// **Vive en Firebase, no en Core Data ni en el backend propio.** Es la unica
/// entidad de la app cuyo almacenamiento es Firebase Realtime Database. Se
/// eligio asi porque es informacion que ninguna de las otras dos fuentes tiene:
/// el backend guarda el estado actual de cada registro, pero no el rastro de
/// como llego a ese estado.
///
/// **Es append-only.** No se edita ni se borra una entrada: eso es lo que hace
/// que sirva como auditoria, y de paso es lo que hace que la integracion sea
/// tan simple — no hay updates, ni conflictos, ni cola offline que resolver.
///
/// **No es `Codable` sino diccionario.** El SDK de Firebase trabaja con
/// `[String: Any]` en `setValue` y devuelve lo mismo en el snapshot, asi que
/// pasar por `JSONEncoder` seria traducir dos veces para nada.
struct EventoBitacora {
    let accion: AccionBitacora
    let entidad: EntidadBitacora
    /// Nombre del registro afectado, tal como lo veia el usuario al operar.
    /// Se guarda el nombre y no solo el id porque la entrada tiene que seguir
    /// siendo legible aunque el registro despues se borre.
    let nombre: String
    let usuario: String
    /// Fecha ya formateada en ISO 8601. Es la que hace legible el dato crudo si
    /// alguien mira el arbol desde la consola de Firebase.
    let fechaISO: String
    /// Segundos desde 1970. Es el campo por el que se ordena.
    let timestamp: Double

    init(accion: AccionBitacora, entidad: EntidadBitacora, nombre: String, usuario: String, fecha: Date = Date()) {
        self.accion = accion
        self.entidad = entidad
        self.nombre = nombre
        self.usuario = usuario
        self.fechaISO = Self.formateador.string(from: fecha)
        self.timestamp = fecha.timeIntervalSince1970
    }

    /// Reconstruye una entrada leida de Firebase. Devuelve `nil` si el nodo no
    /// tiene la forma esperada: una entrada corrupta se saltea en vez de tumbar
    /// la lista entera.
    init?(diccionario: [String: Any]) {
        guard let accionTexto = diccionario["accion"] as? String,
              let accion = AccionBitacora(rawValue: accionTexto),
              let entidadTexto = diccionario["entidad"] as? String,
              let entidad = EntidadBitacora(rawValue: entidadTexto),
              let nombre = diccionario["nombre"] as? String,
              let usuario = diccionario["usuario"] as? String,
              let timestamp = diccionario["timestamp"] as? Double else { return nil }

        self.accion = accion
        self.entidad = entidad
        self.nombre = nombre
        self.usuario = usuario
        self.fechaISO = diccionario["fechaISO"] as? String ?? ""
        self.timestamp = timestamp
    }

    /// Lo que se manda a `setValue`.
    var comoDiccionario: [String: Any] {
        [
            "accion": accion.rawValue,
            "entidad": entidad.rawValue,
            "nombre": nombre,
            "usuario": usuario,
            "fechaISO": fechaISO,
            "timestamp": timestamp
        ]
    }

    /// Texto de una linea para la lista: "Edito Producto · Taladro percutor".
    var resumen: String {
        "\(accion.descripcion) \(entidad.rawValue) · \(nombre)"
    }

    /// "19/08/2026 20:31" — la fecha local, para mostrar.
    var fechaLegible: String {
        let fecha = Date(timeIntervalSince1970: timestamp)
        return Self.formateadorLegible.string(from: fecha)
    }

    private static let formateador: ISO8601DateFormatter = {
        let formateador = ISO8601DateFormatter()
        formateador.formatOptions = [.withInternetDateTime]
        return formateador
    }()

    private static let formateadorLegible: DateFormatter = {
        let formateador = DateFormatter()
        formateador.dateFormat = "dd/MM/yyyy HH:mm"
        return formateador
    }()
}
