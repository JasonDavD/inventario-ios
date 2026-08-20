# -*- coding: utf-8 -*-
"""Genera el PDF didactico de la arquitectura completa de la app."""

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, Paragraph,
    Preformatted, Spacer, Table, TableStyle, KeepTogether,
)

from pathlib import Path

# El PDF se genera al lado de este script, sea cual sea el directorio desde el
# que se lo invoque.
SALIDA = str(Path(__file__).resolve().parent / "Arquitectura-App.pdf")

TINTA = colors.HexColor("#121417")
GRIS = colors.HexColor("#5B6167")
LINEA = colors.HexColor("#D7DBDF")
FONDO_CODIGO = colors.HexColor("#F5F6F7")
NARANJA = colors.HexColor("#C25E00")
FONDO_NOTA = colors.HexColor("#FBF3EA")
AZUL = colors.HexColor("#1B4D7A")
FONDO_PARTE = colors.HexColor("#EEF2F6")

base = getSampleStyleSheet()

H1 = ParagraphStyle("H1", parent=base["Title"], fontName="Helvetica-Bold",
                    fontSize=24, leading=29, textColor=TINTA, alignment=TA_LEFT, spaceAfter=2)
SUBTITULO = ParagraphStyle("SUB", parent=base["Normal"], fontName="Helvetica",
                           fontSize=11.5, leading=16, textColor=GRIS, spaceAfter=16)
PARTE = ParagraphStyle("PARTE", parent=base["Heading1"], fontName="Helvetica-Bold",
                       fontSize=13, leading=17, textColor=AZUL, spaceBefore=4, spaceAfter=4)
H2 = ParagraphStyle("H2", parent=base["Heading1"], fontName="Helvetica-Bold",
                    fontSize=14.5, leading=18, textColor=TINTA, spaceBefore=18, spaceAfter=6)
H3 = ParagraphStyle("H3", parent=base["Heading2"], fontName="Helvetica-Bold",
                    fontSize=11.2, leading=15, textColor=TINTA, spaceBefore=12, spaceAfter=4)
CUERPO = ParagraphStyle("CUERPO", parent=base["Normal"], fontName="Helvetica",
                        fontSize=9.8, leading=14.5, textColor=TINTA, spaceAfter=8)
LISTA = ParagraphStyle("LISTA", parent=CUERPO, leftIndent=13, bulletIndent=3, spaceAfter=4)
CODIGO = ParagraphStyle("CODIGO", parent=base["Code"], fontName="Courier",
                        fontSize=7.4, leading=9.9, textColor=TINTA,
                        leftIndent=0, rightIndent=0, firstLineIndent=0,
                        backColor=None, borderWidth=0, borderPadding=0,
                        spaceBefore=0, spaceAfter=0)
NOTA = ParagraphStyle("NOTA", parent=CUERPO, fontSize=9.4, leading=13.8, spaceAfter=0)

historia = []
ANCHO = 163 * mm


def p(txt, estilo=CUERPO):
    historia.append(Paragraph(txt, estilo))


def h2(txt):
    historia.append(Paragraph(txt, H2))


def h3(txt):
    historia.append(Paragraph(txt, H3))


def parte(numero, titulo, bajada):
    t = Table([[[Paragraph("PARTE %s" % numero, ParagraphStyle(
                    "PN", parent=CUERPO, fontName="Helvetica-Bold", fontSize=8,
                    textColor=GRIS, spaceAfter=2)),
                 Paragraph(titulo, PARTE),
                 Paragraph(bajada, ParagraphStyle("PB", parent=CUERPO, fontSize=9,
                                                  textColor=GRIS, spaceAfter=0))]]],
              colWidths=[ANCHO])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), FONDO_PARTE),
        ("LEFTPADDING", (0, 0), (-1, -1), 11),
        ("RIGHTPADDING", (0, 0), (-1, -1), 11),
        ("TOPPADDING", (0, 0), (-1, -1), 10),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
    ]))
    historia.append(Spacer(1, 12))
    historia.append(t)
    historia.append(Spacer(1, 10))


def bullets(items):
    for it in items:
        historia.append(Paragraph(it, LISTA, bulletText="•"))
    historia.append(Spacer(1, 6))


def numerados(items):
    for i, it in enumerate(items, 1):
        historia.append(Paragraph(it, LISTA, bulletText="%d." % i))
    historia.append(Spacer(1, 6))


def _caja_codigo(txt):
    t = Table([[Preformatted(txt, CODIGO)]], colWidths=[ANCHO])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), FONDO_CODIGO),
        ("BOX", (0, 0), (-1, -1), 0.5, LINEA),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
    ]))
    return t


def codigo(txt, titulo=None):
    bloque = []
    if titulo:
        bloque.append(Paragraph(titulo, ParagraphStyle(
            "CT", parent=CUERPO, fontName="Helvetica-Bold", fontSize=8.4,
            textColor=GRIS, spaceAfter=3)))
    bloque.append(_caja_codigo(txt))
    if len(txt.splitlines()) < 22:
        historia.append(KeepTogether(bloque))
    else:
        historia.extend(bloque)
    historia.append(Spacer(1, 10))


def nota(titulo, texto):
    t = Table([[[Paragraph("<b>%s</b> %s" % (titulo, texto), NOTA)]]], colWidths=[ANCHO])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), FONDO_NOTA),
        ("LINEBEFORE", (0, 0), (0, -1), 2.2, NARANJA),
        ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    historia.append(t)
    historia.append(Spacer(1, 11))


CELDA = ParagraphStyle("CELDA", parent=base["Normal"], fontName="Helvetica",
                       fontSize=8.3, leading=11.5, textColor=TINTA, spaceAfter=0)
CELDA_TIT = ParagraphStyle("CELDA_TIT", parent=CELDA, fontName="Helvetica-Bold")


def tabla(filas, anchos):
    # Las celdas van como Paragraph y no como texto plano: ReportLab solo hace
    # salto de linea dentro de un Paragraph. Con texto suelto, una celda larga
    # se sale de la tabla y se pisa con el margen.
    envueltas = [
        [Paragraph(str(c), CELDA_TIT if fila == 0 else CELDA) for c in f]
        for fila, f in enumerate(filas)
    ]
    t = Table(envueltas, colWidths=anchos, repeatRows=1)
    t.setStyle(TableStyle([
        ("TEXTCOLOR", (0, 0), (-1, -1), TINTA),
        ("BACKGROUND", (0, 0), (-1, 0), FONDO_CODIGO),
        ("LINEBELOW", (0, 0), (-1, -1), 0.4, LINEA),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    historia.append(t)
    historia.append(Spacer(1, 11))


C = lambda s: "<font face='Courier'>%s</font>" % s

# =====================================================================
p("Como funciona la app por dentro", H1)
p("Recorrido por el codigo de Inventario iOS, siguiendo los procesos reales: "
  "arrancar, entrar, leer, guardar, sincronizar.", SUBTITULO)

p("Ferreteria Zamora &mdash; App de gestion de inventario<br/>"
  "UIKit + Storyboard &nbsp;|&nbsp; Core Data &nbsp;|&nbsp; URLSession con dataTask &nbsp;|&nbsp; MVVM",
  ParagraphStyle("META", parent=CUERPO, textColor=GRIS, fontSize=9, spaceAfter=14))

h2("Como leer este documento")
p("No esta organizado por carpetas sino por <b>procesos</b>. Cada parte sigue una accion "
  "completa del usuario desde que la dispara hasta que termina, atravesando todas las capas "
  "que hagan falta. Es la forma en que realmente se entiende un codigo: viendo el camino que "
  "hace un dato, no la lista de archivos.")

p("La integracion con Firebase tiene su propio documento aparte "
  "(%s) y aca solo se menciona donde encaja." % C("Firebase-Implementacion.pdf"))

nota("Una sola idea para llevarse.",
     "Si tuvieras que quedarte con una frase de todo el documento: <b>la pantalla nunca lee de "
     "la red</b>. Lee de una base local, y la red es un proceso aparte que la actualiza. Todo "
     "lo demas &mdash; los campos raros de Core Data, el orden de la sincronizacion, los chips "
     "naranjas &mdash; existe para sostener esa decision.")

# =====================================================================
parte("I", "El esqueleto", "Donde vive cada cosa y como se conectan las capas.")

h2("1. Las capas")

p("El codigo se organiza en cinco capas. Una pantalla nunca salta capas: siempre habla con "
  "la de abajo.")

codigo_capas = """  ┌──────────────────────────────────────────────────┐
  │  ViewController        dibuja y recibe toques    │   Features/
  ├──────────────────────────────────────────────────┤
  │  ViewModel             decide, no dibuja         │   Features/
  ├──────────────────────────────────────────────────┤
  │  Service               lee/escribe datos         │   Services/
  ├─────────────────────────┬────────────────────────┤
  │  Core Data              │  APIClient             │   CoreData/  Networking/
  │  (base local)           │  (red)                 │
  └─────────────────────────┴────────────────────────┘"""
codigo(codigo_capas)

tabla([
    ["Carpeta", "Que contiene"],
    ["App/", "AppDelegate y SceneDelegate: el arranque"],
    ["Auth/", "SessionManager y KeychainService: quien esta logueado"],
    ["CoreData/", "El modelo .xcdatamodeld y PersistenceController"],
    ["Networking/", "APIClient, Endpoint, APIError, FechaAPI"],
    ["Models/", "DTOs: el reflejo del JSON que manda la API"],
    ["Services/", "Leen y escriben: unos en Core Data, otros contra la red"],
    ["Sync/", "SyncManager: la sincronizacion bidireccional"],
    ["Features/", "Una carpeta por pantalla, con su ViewController y ViewModel"],
    ["DesignSystem/", "Theme y estilos compartidos"],
], [30 * mm, 133 * mm])

h3("Que es MVVM aca")
p("El %s solo dibuja y reenvia toques. El %s tiene la logica y avisa de los cambios con "
  "<b>closures</b>, no con Combine ni delegados:" % (C("ViewController"), C("ViewModel")))

codigo("""final class ProductoListViewModel {

    var onCambio: (() -> Void)?          // "los datos cambiaron, redibuja"
    var onError: ((String) -> Void)?     // "algo fallo, mostra este mensaje"
    var onLoadingChanged: ((Bool) -> Void)?  // "prendé/apagá el spinner"

    private(set) var productos: [ProductoEntity] = []""",
       "Features/Productos/ProductoListViewModel.swift")

p("El %s se suscribe una vez en %s y a partir de ahi solo reacciona. "
  "El %s significa que la pantalla puede <i>leer</i> la lista pero no modificarla."
  % (C("ViewController"), C("viewDidLoad"), C("private(set)")))

h2("2. El arranque")

p("Cuando el usuario toca el icono de la app, esto es lo que pasa en orden:")

numerados([
    "<b>%s</b> corre %s: arranca Firebase." % (C("AppDelegate"), C("didFinishLaunching")),
    "<b>%s</b> se instancia la primera vez que alguien lo pide, y ahi carga la "
    "base local (ver abajo)." % C("PersistenceController"),
    "<b>%s</b> se instancia leyendo el Keychain: si hay un token guardado, la "
    "sesion ya esta iniciada." % C("SessionManager"),
    "<b>El Storyboard</b> presenta la pantalla inicial, que es el <b>Login</b>.",
    "Si %s es verdadero, el Login dispara solo el segue a la app "
    "(auto-login)." % C("SessionManager.isAuthenticated"),
])

h3("PersistenceController: la base local")

codigo("""final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "InventarioModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("No se pudo cargar Core Data: \\(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    func saveContext() {
        guard viewContext.hasChanges else { return }
        do { try viewContext.save() }
        catch { assertionFailure("Error guardando Core Data: \\(error)") }
    }
}""", "CoreData/PersistenceController.swift")

p("%s es el objeto de Core Data que junta el modelo, el coordinador y el "
  "contexto. El <b>contexto</b> (%s) es donde viven los objetos en memoria: se "
  "modifican ahi y recien con %s se escriben al disco."
  % (C("NSPersistentContainer"), C("viewContext"), C("save()")))

nota("El fatalError no es descuido.",
     "Si Core Data no carga, la app no tiene fuente de datos: no hay nada util que mostrar. "
     "Arrancar igual solo lleva a un crash mas confuso tres pantallas despues, cuando ya no se "
     "ve la causa.")

p("El %s guarda al mandar la app a background, por si quedo algo sin persistir:" % C("SceneDelegate"))

codigo("""func sceneDidEnterBackground(_ scene: UIScene) {
    // Persistir cambios pendientes al mandar la app a background.
    PersistenceController.shared.saveContext()
}""", "App/SceneDelegate.swift")

# =====================================================================
parte("II", "Proceso 1: entrar a la app",
      "Del boton Acceder al token guardado. Toca Login, AuthService, APIClient, Keychain y SessionManager.")

h2("3. El recorrido completo del login")

codigo("""  LoginViewController          el usuario toca "Acceder"
         │
         ▼
  LoginViewModel               valida que los campos no esten vacios
         │
         ▼
  AuthService.login()          arma el cuerpo { username, password }
         │
         ▼
  APIClient.post(.login)       POST /api/auth/login   (sin token: todavia no hay)
         │
         ▼
  LoginResponse                { token, username, roles }
         │
         ▼
  SessionManager.handleLogin() guarda token, usuario y roles
         │
         ▼
  segue "irAProductos"         entra a la app""")

h3("AuthService: la capa mas fina de todas")

codigo("""struct AuthService {
    func login(username: String, password: String,
               completion: @escaping (Result<LoginResponse, APIError>) -> Void) {
        let body = LoginRequest(username: username, password: password)
        APIClient.shared.post(.login, body: body, authenticated: false, completion: completion)
    }
}""", "Services/AuthService.swift")

p("Son cuatro lineas y aun asi vale la pena que exista: el %s no sabe que el "
  "login es un POST a %s. Si el backend cambiara ese contrato, se toca "
  "aca y nada mas." % (C("ViewModel"), C("/api/auth/login")))

p("El %s es la clave: es la unica peticion de toda la app que "
  "va sin token, porque justamente lo esta pidiendo." % C("authenticated: false"))

h2("4. APIClient: como se hace una peticion")

p("Todas las llamadas al backend pasan por aca. Expone un metodo por verbo HTTP y todos "
  "terminan en el mismo lugar:")

codigo("""func get<Response: Decodable>(
    _ endpoint: Endpoint,
    authenticated: Bool = true,
    completion: @escaping (Result<Response, APIError>) -> Void
) {
    var request = URLRequest(url: endpoint.url)
    request.httpMethod = "GET"
    attachAuthIfNeeded(&request, authenticated: authenticated)
    send(request, authenticated: authenticated, completion: completion)
}""", "Networking/APIClient.swift")

p("El %s es lo que permite que un solo metodo sirva "
  "para cualquier respuesta: el tipo lo decide quien llama, y Swift lo deduce del "
  "contexto. Por eso en el %s se ve esta forma rara:" % (C("<Response: Decodable>"), C("SyncManager")))

codigo("""APIClient.shared.get(.categorias) { (resultado: Result<[CategoriaDTO], APIError>) in""")

p("Ese tipo escrito a mano no es adorno: es lo que le dice al compilador en que tipo hay "
  "que decodificar el JSON. Sin eso no podria deducirlo.")

h3("El token se agrega solo")

codigo("""private func attachAuthIfNeeded(_ request: inout URLRequest, authenticated: Bool) {
    // Se lee de SessionManager y no del Keychain directo: con "mantener
    // sesion iniciada" desactivado el token vive solo en memoria.
    guard authenticated, let token = SessionManager.shared.token else { return }
    request.setValue("Bearer \\(token)", forHTTPHeaderField: "Authorization")
}""")

p("Ninguna pantalla arma cabeceras de autenticacion: es imposible olvidarse el token, y "
  "tambien imposible mandarlo a donde no va.")

h3("El manejo de la respuesta")

codigo("""guard (200...299).contains(httpResponse.statusCode) else {
    // Un 401 solo significa "sesion vencida" si la request iba con token.
    // En el login (authenticated: false) significa credenciales malas, y
    // ahi lo que sirve es el `mensaje` que manda el backend.
    if httpResponse.statusCode == 401, authenticated {
        DispatchQueue.main.async {
            SessionManager.shared.manejarSesionExpirada()
            completion(.failure(.unauthorized))
        }
        return
    }
    let mensaje = (try? JSONDecoder().decode(BackendErrorBody.self, from: data))?.mensaje
    DispatchQueue.main.async {
        completion(.failure(.server(status: httpResponse.statusCode,
                                    message: mensaje ?? "Error del servidor")))
    }
    return
}""")

nota("El detalle fino del 401.",
     "El mismo codigo significa dos cosas distintas segun el contexto. Con token, es "
     "&quot;tu sesion vencio&quot; y hay que sacar al usuario. Sin token &mdash; o sea en el "
     "login &mdash; es &quot;usuario o contrasena incorrectos&quot;, y sacarlo no tendria "
     "sentido porque todavia no entro. Por eso el %s del %s no es opcional."
     % (C("authenticated"), C("if")))

p("Todos los %s van dentro de %s. El "
  "%s corre en un hilo de fondo, y tocar la interfaz fuera del hilo principal "
  "es una de las formas mas comunes de crashear una app iOS."
  % (C("completion"), C("DispatchQueue.main.async"), C("dataTask")))

h3("Dos respuestas especiales")

codigo("""/// Respuesta para endpoints que no devuelven cuerpo (tipicamente DELETE con
/// 204 No Content). Sin esto, `send` intentaria decodificar un body vacio y
/// fallaria con un error de decoding aunque la operacion haya salido bien.
struct RespuestaVacia: Decodable {}

/// Respuesta cuyo contenido no interesa: la operacion se confirma por el status
/// HTTP y el estado real se vuelve a bajar del servidor despues.
struct RespuestaIgnorada: Decodable {
    init(from decoder: Decoder) throws {}
}""")

p("%s resuelve un problema real: un DELETE exitoso devuelve 204 sin cuerpo, y "
  "%s con un cuerpo vacio lanza error. La operacion salio bien pero la app "
  "diria que fallo." % (C("RespuestaVacia"), C("JSONDecoder")))

h2("5. Donde se guarda el token")

p("El check <b>&quot;Mantener sesion iniciada&quot;</b> del login no es cosmetico: cambia "
  "donde vive el token.")

tabla([
    ["Check", "Donde vive el token", "Al cerrar la app"],
    ["Marcado", "Keychain (cifrado por iOS)", "Sigue ahi: no vuelve a pedir login"],
    ["Sin marcar", "Solo en memoria", "Se pierde: vuelve a pedir login"],
], [24 * mm, 62 * mm, 77 * mm])

codigo("""func handleLogin(response: LoginResponse, recordarSesion: Bool) {
    token = response.token
    username = response.username
    roles = response.roles
    isAuthenticated = true

    if recordarSesion {
        keychain.saveToken(response.token)
        defaults.set(response.username, forKey: usernameKey)
        defaults.set(response.roles, forKey: rolesKey)
    } else {
        keychain.deleteToken()
        defaults.removeObject(forKey: usernameKey)
        defaults.removeObject(forKey: rolesKey)
    }
}""", "Auth/SessionManager.swift")

nota("Por que Keychain y no UserDefaults.",
     "%s es un archivo de texto plano dentro de la app: cualquiera con acceso al "
     "dispositivo o a un backup puede leerlo. El <b>Keychain</b> lo cifra el sistema operativo. "
     "El token es una credencial &mdash; con el se puede operar como el usuario &mdash; asi que va ahi. "
     "El nombre y los roles, que no son secretos, si van en %s."
     % (C("UserDefaults"), C("UserDefaults")))

p("Notar que <b>la contrasena nunca se guarda</b>, en ningun lado. Se usa una vez para pedir el "
  "token y se descarta.")

# =====================================================================
parte("III", "Proceso 2: ver el listado de productos",
      "El caso mas importante: como se muestra una lista sin tocar la red.")

h2("6. La regla de oro")

p("Cuando el usuario abre la pestana Productos, la app <b>no llama al servidor</b>. "
  "Lee de Core Data:")

codigo("""  ProductoListViewController.viewDidLoad()
         │
         ▼
  viewModel.cargarLocales()
         │
         ▼
  ProductoService.productosLocales()      <- NSFetchRequest a Core Data
         │
         ▼
  onCambio?()                             <- el closure avisa a la pantalla
         │
         ▼
  tableView.reloadData()""")

p("La red no aparece por ningun lado. Por eso la lista funciona en el deposito sin senal, y "
  "por eso aparece instantaneamente en vez de mostrar un spinner.")

h2("7. ProductoService: la consulta")

codigo("""func productosLocales() -> [ProductoEntity] {
    let request = NSFetchRequest<ProductoEntity>(entityName: "ProductoEntity")
    request.predicate = NSPredicate(format: "pendienteEliminar == NO")
    request.sortDescriptors = [
        NSSortDescriptor(
            key: "nombre",
            ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
        )
    ]
    return (try? contexto.fetch(request)) ?? []
}""", "Services/ProductoService.swift")

p("Tres cosas para mirar:")

bullets([
    "<b>%s</b> es la consulta. Es el equivalente a un SELECT." % C("NSFetchRequest"),
    "<b>%s</b> es el WHERE. Aca esconde los productos que el usuario ya "
    "borro pero que siguen locales esperando que el servidor confirme la baja." % C("predicate"),
    "<b>%s</b> ordena alfabeticamente ignorando "
    "mayusculas y tildes; sin ese selector, &quot;Ácido&quot; quedaria despues de "
    "&quot;Zinc&quot;." % C("localizedCaseInsensitiveCompare"),
])

p("El %s convierte cualquier error en lista vacia. Es una decision "
  "deliberada: si la consulta local falla, mostrar la lista vacia es mejor que crashear."
  % C("(try? ...) ?? []"))

h3("DTO y Entity: dos cosas distintas con el mismo nombre")

p("Es la confusion mas comun al leer este codigo. Hay dos representaciones de un producto:")

tabla([
    ["", "ProductoDTO", "ProductoEntity"],
    ["Que es", "Reflejo del JSON de la API", "Fila de la base local"],
    ["Donde vive", "Models/Inventario/", "Core Data (generado)"],
    ["Campos extra", "ninguno", "localId, apiId, estadoSync, pendienteEliminar"],
    ["Para que", "Decodificar la respuesta HTTP", "Todo lo que muestra la app"],
], [24 * mm, 62 * mm, 77 * mm])

p("El %s convierte de uno a otro. La pantalla <b>solo</b> ve %s."
  % (C("SyncManager"), C("Entity")))

# =====================================================================
parte("IV", "Proceso 3: guardar un producto",
      "Que pasa al tocar Guardar, y los cuatro campos que hacen posible el offline.")

h2("8. Los cuatro campos de sincronizacion")

p("Cada entidad local tiene, ademas de sus datos de negocio, cuatro campos tecnicos. "
  "Entender estos cuatro campos es entender toda la sincronizacion:")

tabla([
    ["Campo", "Tipo", "Para que sirve"],
    ["localId", "String", "Identificador que la app genera. Existe siempre, incluso "
                          "antes de que el servidor conozca el registro"],
    ["apiId", "Int64?", "Id que asigno el servidor. Es nil mientras el registro no se "
                        "haya subido nunca"],
    ["estadoSync", "Int16", "0 = tiene cambios sin subir. 1 = igual que en el servidor"],
    ["pendienteEliminar", "Bool", "El usuario lo borro, pero el DELETE todavia no se "
                                  "confirmo contra el servidor"],
], [30 * mm, 18 * mm, 115 * mm])

nota("Por que dos ids.",
     "Un producto creado sin conexion todavia no existe para el servidor, asi que no puede "
     "tener su id. Pero la app necesita identificarlo <i>ya</i> para mostrarlo, editarlo o "
     "borrarlo. %s cubre ese hueco; %s se completa despues, cuando el "
     "POST vuelve con el id asignado." % (C("localId"), C("apiId")))

h2("9. Crear")

codigo("""@discardableResult
func crear(nombre: String, precio: Double, stock: Int32,
           categoria: CategoriaEntity?, proveedor: ProveedorEntity?) -> ProductoEntity {
    let producto = ProductoEntity(context: contexto)
    producto.localId = UUID().uuidString
    // apiId queda nil: todavia no existe en el servidor. El SyncManager lo
    // completa cuando el POST devuelve el id asignado.
    producto.apiId = nil
    producto.estadoSync = 0
    producto.pendienteEliminar = false
    producto.fechaRegistro = Date()

    aplicar(nombre: nombre, precio: precio, stock: stock,
            categoria: categoria, proveedor: proveedor, a: producto)
    PersistenceController.shared.saveContext()
    return producto
}""", "Services/ProductoService.swift")

p("Se escribe en Core Data y listo. <b>No hay ninguna llamada a la red.</b> El producto "
  "queda con %s, que es lo que dibuja el chip naranja PENDIENTE en la "
  "lista." % C("estadoSync = 0"))

h3("El detalle de aplicar()")

codigo("""private func aplicar(..., a producto: ProductoEntity) {
    producto.nombre = nombre
    producto.precio = precio
    producto.stock = stock
    producto.categoria = categoria
    producto.proveedor = proveedor
    // Marca la fila como pendiente de subir. Tambien protege el cambio: el
    // upsert de la bajada saltea todo lo que tenga estadoSync == 0.
    producto.estadoSync = 0
}""")

p("Ese %s al final es el que hace que <b>editar</b> tambien marque "
  "pendiente. Y como dice el comentario, cumple una segunda funcion defensiva que se "
  "entiende en la Parte V." % C("estadoSync = 0"))

h2("10. Borrar: por que no se borra")

codigo("""func marcarParaEliminar(_ producto: ProductoEntity) {
    if producto.apiId == nil {
        contexto.delete(producto)
    } else {
        producto.pendienteEliminar = true
        producto.estadoSync = 0
    }
    PersistenceController.shared.saveContext()
}""")

p("El borrado es <b>logico</b>, no fisico. La fila se marca y sigue en la base hasta que el "
  "servidor confirme el DELETE. Para el usuario desaparece igual, porque "
  "%s la filtra." % C("productosLocales()"))

p("El %s cubre el caso del producto que nunca se subio: no hay nada que "
  "borrar del otro lado, asi que se elimina de una." % C("if apiId == nil"))

nota("Por que no borrar y listo.",
     "Si la fila se borrara del telefono al instante y la app estuviera sin conexion, nadie "
     "recordaria que hay que avisarle al servidor. En la proxima sincronizacion el producto "
     "volveria a bajar, intacto, como si nunca lo hubieras borrado.")

# =====================================================================
parte("V", "Proceso 4: sincronizar",
      "El corazon de la app. Tres pasos, y el orden entre ellos es todo.")

h2("11. Los tres pasos")

p("%s hace tres cosas, siempre en este orden:" % C("SyncManager.sincronizar()"))

codigo("""  1. SUBIR      lo que tiene estadoSync == 0     POST (si no hay apiId) / PUT
         │
         ▼
  2. BAJAS      lo que tiene pendienteEliminar   DELETE, y recien ahi borrar local
         │
         ▼
  3. BAJAR      traer todo del servidor          y hacer upsert local por apiId""")

nota("El orden es la decision de diseno mas importante de la app.",
     "Si el paso 3 corriera primero, pisaria con la version del servidor los cambios locales "
     "que todavia no se subieron: se perderia todo el trabajo hecho sin conexion. Subir "
     "primero y bajar al final es lo que hace que el offline realmente funcione.")

h3("Y dentro de cada paso, tambien importa")

p("La documentacion del propio metodo lo explica:")

codigo("""/// - **Al subir**, categorias y proveedores van antes que productos. Un
///   producto creado sin conexion puede apuntar a una categoria tambien
///   creada sin conexion, y `ProductoRequest` solo referencia las que ya
///   tienen `apiId`. Si el producto subiera primero, se subiria sin
///   categoria y el vinculo se perderia sin ningun error visible.
/// - **Al borrar**, productos van antes. Borrar una categoria que todavia
///   tiene productos colgando es pedirle al backend un conflicto evitable.""",
       "Sync/SyncManager.swift")

p("&quot;Se perderia sin ningun error visible&quot; es lo peligroso de ese caso: no "
  "crashea, no avisa, simplemente el producto queda sin categoria y nadie se entera.")

h2("12. Como se encadenan los pasos")

p("Siete operaciones asincronas seguidas, cortando en la primera que falle. Anidar siete "
  "%s era ilegible, asi que se resolvio con recursion sobre una cola:" % C("completion"))

codigo("""private func encadenar(
    _ pasos: [(@escaping (Result<Void, APIError>) -> Void) -> Void],
    completion: @escaping (Result<Void, APIError>) -> Void
) {
    var cola = pasos
    guard !cola.isEmpty else {
        completion(.success(()))
        return
    }
    let paso = cola.removeFirst()
    paso { [weak self] resultado in
        guard let self else { return }
        switch resultado {
        case .failure(let error):
            completion(.failure(error))       // corta la cadena
        case .success:
            self.encadenar(cola, completion: completion)   // sigue con el resto
        }
    }
}""")

p("Cada paso se saca del frente de la cola, se ejecuta, y en su respuesta se llama de nuevo "
  "con el resto. Si uno falla, se corta y no se ejecuta ninguno de los siguientes. Es, en "
  "esencia, lo que %s hace por vos en codigo moderno &mdash; pero la rubrica "
  "del curso pide completion handlers." % C("async/await"))

h2("13. Paso 2: las bajas y el 404")

codigo("""APIClient.shared.delete(recurso(apiId.int64Value)) { resultado in
    switch resultado {
    case .success:
        self.contexto.delete(entidad)
        self.borrarSiguiente(cola, recurso: recurso, completion: completion)
    case .failure(let error):
        // Un 404 significa que en el servidor ya no esta: el objetivo
        // ya se cumplio, asi que se borra la fila local igual. Sin esto
        // la baja quedaria trabada para siempre reintentando.
        if case .server(let status, _) = error, status == 404 {
            self.contexto.delete(entidad)
            self.borrarSiguiente(cola, recurso: recurso, completion: completion)
        } else {
            completion(.failure(error))
        }
    }
}""")

nota("Un 404 al borrar es un exito, no un error.",
     "Si el servidor dice &quot;ese registro no existe&quot;, el objetivo ya esta cumplido: no "
     "existe. Tratarlo como fallo deja la baja trabada para siempre &mdash; cada reintento "
     "devuelve 404 otra vez. Este mismo criterio se repite en "
     "%s al borrar fotos, donde antes causaba un bug real: la pantalla decia "
     "&quot;Error del servidor&quot; sobre una foto que <b>si</b> se habia borrado." % C("ImagenService"))

h2("14. Paso 3: el upsert y sus dos defensas")

p("&quot;Upsert&quot; es actualizar si existe, insertar si no. La busqueda es por "
  "%s, que es el unico id que las dos puntas comparten:" % C("apiId"))

codigo("""private func entidadParaUpsert<T: NSManagedObject>(
    _ tipo: T.Type, nombreEntidad: String, apiId: Int64
) -> T? {
    if let existente = buscarPorApiId(tipo, nombreEntidad: nombreEntidad, apiId: apiId) {
        let estadoSync = existente.value(forKey: "estadoSync") as? Int16 ?? 0
        let pendienteEliminar = existente.value(forKey: "pendienteEliminar") as? Bool ?? false
        guard estadoSync == 1, !pendienteEliminar else { return nil }
        return existente
    }

    let nueva = T(context: contexto)
    nueva.setValue(UUID().uuidString, forKey: "localId")
    nueva.setValue(NSNumber(value: apiId), forKey: "apiId")
    nueva.setValue(Int16(1), forKey: "estadoSync")
    nueva.setValue(false, forKey: "pendienteEliminar")
    return nueva
}""", "Sync/SyncManager.swift")

p("Ese %s es <b>la segunda linea de "
  "defensa</b> del offline. Aunque el orden de los pasos ya deberia garantizar que no queda "
  "nada pendiente, si por lo que fuera quedara, el upsert lo saltea "
  "(%s) en vez de pisarlo." % (C("guard estadoSync == 1, !pendienteEliminar"), C("return nil")))

p("Es defensa en profundidad: dos mecanismos independientes protegiendo el mismo dato.")

h3("Reconciliar borrados hechos desde afuera")

codigo("""/// Borra lo que alguien elimino desde el portal web. Sin esto, un producto
/// borrado en el servidor sobreviviria para siempre en el telefono.
///
/// Solo toca filas ya sincronizadas y con `apiId`: lo pendiente de subir no
/// se toca, y lo que nunca se subio no existe alla por definicion.
private func eliminarLocalesQueElServidorYaNoTiene(_ nombreEntidad: String,
                                                   apiIds: Set<Int64>) {
    let request = NSFetchRequest<NSManagedObject>(entityName: nombreEntidad)
    request.predicate = NSPredicate(format: "estadoSync == 1 AND apiId != nil")
    let locales = (try? contexto.fetch(request)) ?? []
    ...""")

p("Sin esto, un producto borrado desde el portal web seguiria apareciendo en el telefono para "
  "siempre. El predicado vuelve a proteger lo pendiente: solo mira filas ya sincronizadas.")

h2("15. Que ve el usuario cuando falla")

codigo("""func sincronizar() {
    onLoadingChanged?(true)
    SyncManager.shared.sincronizar { [weak self] resultado in
        guard let self else { return }
        self.onLoadingChanged?(false)
        switch resultado {
        case .success:
            self.cargarLocales()
        case .failure(let error):
            // Los datos locales siguen en pantalla: que falle el sync no
            // vacia la lista.
            self.onError?(error.errorDescription ?? "No se pudo sincronizar")
        }
    }
}""", "Features/Productos/ProductoListViewModel.swift")

p("Una sincronizacion fallida muestra un mensaje y <b>nada mas</b>. La lista sigue como "
  "estaba, con sus datos locales. Es coherente con toda la arquitectura: la red es un extra, "
  "no una dependencia para funcionar.")

# =====================================================================
parte("VI", "Proceso 5: fotos de producto",
      "La unica parte de la app que no es offline-first, y por que.")

h2("16. Por que las fotos son online")

p("Subir una foto necesita el %s del producto: el backend la asocia al recurso "
  "por su id. Un producto creado sin conexion todavia no tiene ese id, asi que la operacion "
  "<b>no se puede encolar</b>." % C("apiId"))

p("En vez de dejar un boton que falla, la app <b>no lo muestra</b> y explica por que en "
  "pantalla. La limitacion se convierte en informacion.")

h3("El cuerpo multipart, armado a mano")

codigo("""/// Arma el cuerpo multipart a mano. El formato es sensible a los saltos de
/// linea: van CRLF (`\\r\\n`) y no `\\n`, y la ultima frontera lleva `--` al
/// final. Un solo salto de linea mal puesto hace que el servidor no
/// encuentre el archivo y conteste 400 sin explicar por que.
private static func cuerpoMultipart(...) -> Data {
    var cuerpo = Data()
    let salto = "\\r\\n"

    cuerpo.append("--\\(frontera)\\(salto)")
    cuerpo.append("Content-Disposition: form-data; name=\\"\\(campo)\\"; filename=...")
    cuerpo.append("Content-Type: \\(mimeType)\\(salto)")
    cuerpo.append(salto)
    cuerpo.append(archivo)
    cuerpo.append(salto)
    cuerpo.append("--\\(frontera)--\\(salto)")

    return cuerpo
}""", "Networking/APIClient.swift")

p("Es el unico lugar donde el cuerpo no es JSON. La <b>frontera</b> es un separador aleatorio "
  "que marca donde empieza y termina cada parte del formulario.")

h3("Las fotos no se guardan en el telefono")

p("Se suben a <b>Cloudinary</b> y lo que queda local es la URL. Para mostrarlas hay un "
  "descargador con cache en memoria:")

codigo("""if let cacheada = DescargadorDeImagenes.shared.imagenCacheada(urlTexto) {
    mostrarFoto(cacheada)
    return
}

mostrarPlaceholder()
DescargadorDeImagenes.shared.descargar(urlTexto) { [weak self] imagen in
    guard let self, self.urlActual == urlTexto, let imagen else { return }
    self.mostrarFoto(imagen)
}""", "Features/Productos/ProductoTableViewCell.swift")

nota("El guard que evita fotos cruzadas.",
     "%s es la trampa clasica de las listas. Las celdas se "
     "reusan al hacer scroll: si empezaste a bajar la foto del producto A y esa celda ya se "
     "reciclo para el producto B, pintar la imagen mostraria la foto de A en la fila de B. "
     "Comparar la URL antes de pintar es lo que lo evita." % C("self.urlActual == urlTexto"))

# =====================================================================
parte("VII", "Proceso 6: roles y seguridad",
      "Quien puede hacer que, y donde se decide de verdad.")

h2("17. Los tres roles")

tabla([
    ["Rol", "Productos", "Categorias y proveedores", "Usuarios"],
    ["LECTOR", "Solo ver", "Solo ver", "No accede"],
    ["OPERADOR", "Crear, editar, fotos", "Solo ver", "No accede"],
    ["ADMIN", "Todo, incluido borrar", "Todo", "Todo"],
], [24 * mm, 45 * mm, 52 * mm, 42 * mm])

codigo("""/// Spring Security no es consistente con el prefijo `ROLE_`: segun como este
/// armado el token, el mismo rol puede llegar como `ADMIN` o `ROLE_ADMIN`.
/// Se comparan las dos formas sin el prefijo para no depender de eso.
func hasRole(_ role: String) -> Bool {
    let buscado = Self.sinPrefijo(role)
    return roles.contains { Self.sinPrefijo($0) == buscado }
}

var esAdmin: Bool { hasRole("ADMIN") }

/// Crear/editar productos y manejar sus imagenes es de OPERADOR para arriba.
/// Se chequean los dos roles y no solo OPERADOR: no hay garantia de que el
/// backend le agregue OPERADOR a un ADMIN en el token.
var puedeEditarProductos: Bool { esAdmin || hasRole("OPERADOR") }""",
       "Auth/SessionManager.swift")

p("La normalizacion del prefijo no es paranoia: se confirmo leyendo el backend, donde "
  "%s arma las authorities como %s."
  % (C("CustomUserDetailsService"), C('"ROLE_" + rol.name()')))

h2("18. Esconder botones no es seguridad")

p("La app usa esos flags para <b>ocultar</b> lo que no corresponde. Por ejemplo, el swipe "
  "para eliminar un producto:")

codigo("""func tableView(_ tableView: UITableView,
               trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
) -> UISwipeActionsConfiguration? {
    // Borrar productos es de ADMIN, no de OPERADOR: es el unico verbo de la
    // tabla de roles de PLAN.md que pide mas que editar.
    guard SessionManager.shared.esAdmin else { return nil }
    ...
}""", "Features/Productos/ProductoListViewController.swift")

nota("Esto es comodidad, no seguridad.",
     "Cualquiera puede llamar a la API por fuera de la app. Lo que realmente protege es el "
     "<b>backend</b>, que valida el rol en cada peticion y responde <b>403</b> si no "
     "corresponde. El gating de la app existe para no ofrecer botones que van a fallar &mdash; "
     "es buena experiencia de usuario, no una barrera.")

h2("19. Cuando el token vence")

p("Un JWT tiene fecha de vencimiento. Cuando pasa, el backend empieza a responder 401 y la "
  "app tiene que reaccionar sola:")

codigo("""/// Cierra la sesion y avisa a la UI. **El guard no es decorativo:** una
/// sincronizacion dispara varias requests seguidas y todas van a fallar con
/// 401 al vencer el token; sin el, se apilarian varios avisos encima del
/// mismo problema.
func manejarSesionExpirada() {
    guard isAuthenticated else { return }
    logout()
    NotificationCenter.default.post(name: Self.sesionExpirada, object: nil)
}""", "Auth/SessionManager.swift")

p("La notificacion la escucha el %s, y no cada pantalla. Es el "
  "controlador que el Login presento, asi que es el unico que puede volver atras de una sola "
  "vez, sin importar en que tab o en que formulario este parado el usuario."
  % C("InicioTabBarController"))

# =====================================================================
parte("VIII", "Detalles transversales",
      "Piezas chicas que aparecen en todos lados.")

h2("20. Las fechas del backend")

codigo("""/// `fechaRegistro` viene como `2026-08-12T10:15:30`: ISO 8601 **sin zona horaria
/// ni fracciones de segundo**. `JSONDecoder.dateDecodingStrategy = .iso8601` lo
/// rechaza justamente por no traer zona, y un decode fallido de una sola fecha
/// tumba el listado entero — por eso se parsea a mano.
enum FechaAPI {
    private static let formatos = [
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
    ]""", "Networking/FechaAPI.swift")

p("Se prueban tres formatos porque el backend no es consistente. Y hay un detalle que arruina "
  "apps en produccion:")

codigo("""/// `en_US_POSIX` es obligatorio: sin eso el formato depende de la config
/// regional del telefono y el parseo falla en dispositivos con calendario o
/// idioma distintos.
formateador.locale = Locale(identifier: "en_US_POSIX")""")

nota("El bug que no ves en tu telefono.",
     "Sin %s, un usuario con el calendario budista o japones configurado "
     "obtiene fechas que no parsean, y la lista entera queda vacia. En el simulador del "
     "desarrollador nunca pasa." % C("en_US_POSIX"))

h2("21. El sistema de diseno")

p("Los colores, tipografias y espaciados no estan escritos en cada pantalla: viven en "
  "%s, que traduce el documento de diseno a codigo." % C("DesignSystem/Theme.swift"))

p("Si cambia el diseno se toca ese archivo y nada mas. Las pantallas piden "
  + C("Theme.Color.charcoalDeep") + " o " + C("Theme.TextStyle.bodyLG")
  + ", nunca un color ni un tamano literal.")

h2("22. Donde encaja Firebase")

p("Firebase guarda <b>una sola cosa</b>: la bitacora de auditoria. No participa de ninguno de "
  "los procesos anteriores &mdash; no toca Core Data, no pasa por el %s y no usa "
  "%s." % (C("SyncManager"), C("APIClient")))

p("Los seis puntos donde el usuario modifica datos llaman a %s "
  "despues de guardar. Esta explicado en detalle en %s."
  % (C("BitacoraService.registrar()"), C("Firebase-Implementacion.pdf")))

# =====================================================================
h2("23. Resumen: donde mirar segun que quieras entender")

tabla([
    ["Si queres entender...", "Abri este archivo"],
    ["Como arranca la app", "App/AppDelegate.swift"],
    ["Como se carga la base local", "CoreData/PersistenceController.swift"],
    ["Como se hace cualquier peticion HTTP", "Networking/APIClient.swift"],
    ["Que endpoints existen", "Networking/Endpoint.swift"],
    ["Como se guarda la sesion", "Auth/SessionManager.swift + KeychainService.swift"],
    ["Como se lee de la base local", "Services/ProductoService.swift"],
    ["Como funciona el offline", "Sync/SyncManager.swift (el archivo mas importante)"],
    ["Como se suben fotos", "Services/ImagenService.swift"],
    ["Como se decide que ve cada rol", "Auth/SessionManager.swift"],
    ["Como se ve una pantalla por dentro", "Features/Productos/ (VC + ViewModel + Cell)"],
    ["Los colores y tipografias", "DesignSystem/Theme.swift"],
], [62 * mm, 101 * mm])

nota("Si vas a leer un solo archivo, que sea SyncManager.",
     "Ahi esta condensada la logica que da sentido a todo lo demas: por que las entidades "
     "tienen cuatro campos tecnicos, por que el borrado es logico, por que existe el chip "
     "naranja y por que el orden de las operaciones es el que es.")


# =====================================================================
def pie_de_pagina(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(LINEA)
    canvas.setLineWidth(0.4)
    canvas.line(23 * mm, 15 * mm, 187 * mm, 15 * mm)
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(GRIS)
    canvas.drawString(23 * mm, 10.5 * mm, "Como funciona la app por dentro — Inventario iOS")
    canvas.drawRightString(187 * mm, 10.5 * mm, "Pagina %d" % doc.page)
    canvas.restoreState()


doc = BaseDocTemplate(SALIDA, pagesize=A4,
                      leftMargin=23 * mm, rightMargin=23 * mm,
                      topMargin=20 * mm, bottomMargin=22 * mm,
                      title="Como funciona la app por dentro - Inventario iOS",
                      author="Proyecto inventario-ios",
                      subject="Arquitectura y recorrido del codigo")

marco = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="cuerpo")
doc.addPageTemplates([PageTemplate(id="normal", frames=[marco], onPage=pie_de_pagina)])
doc.build(historia)
print("PDF generado:", SALIDA)
