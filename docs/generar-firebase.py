# -*- coding: utf-8 -*-
"""Genera el PDF didactico de la implementacion de Firebase."""

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageBreak, PageTemplate, Paragraph,
    Preformatted, Spacer, Table, TableStyle, KeepTogether,
)

from pathlib import Path

# El PDF se genera al lado de este script, sea cual sea el directorio desde el
# que se lo invoque.
SALIDA = str(Path(__file__).resolve().parent / "Firebase-Implementacion.pdf")

TINTA = colors.HexColor("#121417")
GRIS = colors.HexColor("#5B6167")
LINEA = colors.HexColor("#D7DBDF")
FONDO_CODIGO = colors.HexColor("#F5F6F7")
NARANJA = colors.HexColor("#C25E00")
FONDO_NOTA = colors.HexColor("#FBF3EA")

base = getSampleStyleSheet()

H1 = ParagraphStyle("H1", parent=base["Title"], fontName="Helvetica-Bold",
                    fontSize=24, leading=29, textColor=TINTA, alignment=TA_LEFT,
                    spaceAfter=2)
SUBTITULO = ParagraphStyle("SUB", parent=base["Normal"], fontName="Helvetica",
                           fontSize=11.5, leading=16, textColor=GRIS, spaceAfter=18)
H2 = ParagraphStyle("H2", parent=base["Heading1"], fontName="Helvetica-Bold",
                    fontSize=15, leading=19, textColor=TINTA,
                    spaceBefore=20, spaceAfter=7)
H3 = ParagraphStyle("H3", parent=base["Heading2"], fontName="Helvetica-Bold",
                    fontSize=11.5, leading=15, textColor=TINTA,
                    spaceBefore=13, spaceAfter=4)
CUERPO = ParagraphStyle("CUERPO", parent=base["Normal"], fontName="Helvetica",
                        fontSize=9.8, leading=14.6, textColor=TINTA, spaceAfter=8)
LISTA = ParagraphStyle("LISTA", parent=CUERPO, leftIndent=13, bulletIndent=3, spaceAfter=4)
CODIGO = ParagraphStyle("CODIGO", parent=base["Code"], fontName="Courier",
                        fontSize=7.4, leading=9.9, textColor=TINTA,
                        leftIndent=0, rightIndent=0, firstLineIndent=0,
                        backColor=None, borderWidth=0, borderPadding=0,
                        spaceBefore=0, spaceAfter=0)
NOTA = ParagraphStyle("NOTA", parent=CUERPO, fontSize=9.4, leading=13.8,
                      textColor=TINTA, spaceAfter=0)
PIE = ParagraphStyle("PIE", parent=base["Normal"], fontName="Helvetica",
                     fontSize=7.5, textColor=GRIS)

historia = []


def p(txt, estilo=CUERPO):
    historia.append(Paragraph(txt, estilo))


def h2(txt):
    historia.append(Paragraph(txt, H2))


def h3(txt):
    historia.append(Paragraph(txt, H3))


def bullets(items):
    for it in items:
        historia.append(Paragraph(it, LISTA, bulletText="•"))
    historia.append(Spacer(1, 6))


def _caja_codigo(txt):
    t = Table([[Preformatted(txt, CODIGO)]], colWidths=[163 * mm])
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

    # Los bloques cortos viajan enteros a la pagina siguiente si no entran; los
    # largos tienen que poder partirse o no entrarian en ningun lado.
    if len(txt.splitlines()) < 22:
        historia.append(KeepTogether(bloque))
    else:
        historia.extend(bloque)
    historia.append(Spacer(1, 10))


def codigo_simple(txt):
    historia.append(_caja_codigo(txt))
    historia.append(Spacer(1, 10))


def nota(titulo, texto):
    interno = [Paragraph("<b>%s</b> %s" % (titulo, texto), NOTA)]
    t = Table([[interno]], colWidths=[163 * mm])
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


def tabla(filas, anchos):
    t = Table(filas, colWidths=anchos, repeatRows=1)
    t.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 8.3),
        ("LEADING", (0, 0), (-1, -1), 11.5),
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


# =====================================================================
# PORTADA
# =====================================================================
p("Firebase en Inventario iOS", H1)
p("Como se implemento la bitacora de auditoria con Realtime Database. "
  "Recorrido por el codigo, archivo por archivo.", SUBTITULO)

p("Ferreteria Zamora &mdash; App de gestion de inventario<br/>"
  "Proyecto: <font face='Courier'>inventario-ios</font> &nbsp;|&nbsp; "
  "SDK: <font face='Courier'>firebase-ios-sdk 12.18.0</font> &nbsp;|&nbsp; "
  "Producto: <font face='Courier'>FirebaseDatabase</font>",
  ParagraphStyle("META", parent=CUERPO, textColor=GRIS, fontSize=9, spaceAfter=16))

h2("Que vas a encontrar aca")
p("Este documento explica <b>por que</b> la app usa Firebase, <b>que</b> guarda ahi y "
  "<b>como</b> esta escrito el codigo que lo hace. Cada seccion muestra el codigo real del "
  "proyecto y lo desarma linea por linea.")
p("El orden sigue el camino que recorre un dato: primero se instala el SDK, despues se "
  "configura, se modela el dato, se escribe, se lee, y por ultimo se muestra en pantalla.")

nota("Antes de empezar.",
     "La app ya tenia un backend propio (Spring Boot) y una base local (Core Data). Firebase no "
     "reemplaza a ninguno de los dos: se suma para guardar una cosa que los otros dos no guardan. "
     "Entender esa division es la clave de todo lo demas.")

# =====================================================================
h2("1. El problema: que guardar en Firebase")

p("La app ya tenia dos lugares donde viven los datos:")
bullets([
    "<b>El backend de Spring</b> (una API REST): es la fuente de verdad de productos, "
    "categorias, proveedores y usuarios.",
    "<b>Core Data</b> (base local en el telefono): copia local de todo eso, para que la app "
    "funcione sin conexion. Un <font face='Courier'>SyncManager</font> las mantiene sincronizadas.",
])

p("Meter en Firebase una copia de los productos habria sido un error: quedarian "
  "<b>dos fuentes de verdad para el mismo dato</b>, y cuando difieran no hay forma de saber "
  "cual tiene razon.")

p("Entonces la pregunta correcta no es <i>&quot;que copio a Firebase&quot;</i> sino "
  "<i>&quot;que informacion no tiene hoy ningun lado&quot;</i>. Y hay una respuesta clara: "
  "<b>el historial</b>. El backend guarda que un producto <i>hoy</i> cuesta S/ 45, pero no guarda "
  "quien le puso ese precio, cuando, ni cual era antes.")

nota("La entidad elegida: bitacora de auditoria.",
     "Cada alta, edicion y baja de producto, categoria o proveedor deja una entrada con que se "
     "hizo, sobre que, quien y cuando. Es informacion nueva, no duplicada, y ademas es "
     "<i>append-only</i>: solo se agrega, nunca se edita ni se borra. Eso hace la implementacion "
     "mucho mas simple, porque no hay updates, ni conflictos, ni cola offline que resolver.")

h3("Por que Realtime Database y no Firestore")
p("Firebase ofrece dos bases distintas. Se eligio <b>Realtime Database</b> porque el dato es "
  "una lista plana de eventos que solo crece. Firestore aporta consultas complejas y "
  "subcolecciones que aca no hacen falta, y su modelo de documentos es mas verboso para algo "
  "tan simple. Son productos separados dentro de la misma consola: si abris Firestore, la base "
  "va a estar vacia.")


# =====================================================================
h2("2. Mapa de la implementacion")
p("Toda la integracion son <b>cinco archivos nuevos</b> y unos pocos retoques. Esta es la "
  "lista completa:")

tabla([
    ["Archivo", "Que hace"],
    ["App/AppDelegate.swift", "Arranca Firebase al abrir la app (2 lineas)"],
    ["Resources/GoogleService-Info.plist", "Configuracion que genera la consola de Firebase"],
    ["Models/Bitacora/EventoBitacora.swift", "El dato: que campos tiene un evento"],
    ["Services/BitacoraService.swift", "Escribe y lee contra Firebase"],
    ["Features/Bitacora/BitacoraListViewModel.swift", "Pide los datos y avisa a la pantalla"],
    ["Features/Bitacora/BitacoraListViewController.swift", "Dibuja la lista"],
    ["(6 ViewModels ya existentes)", "Llaman a registrar() cuando el usuario modifica algo"],
], [72 * mm, 91 * mm])

p("El flujo completo, de punta a punta:")

codigo_simple(
"""  El usuario guarda una categoria
            |
            v
  CategoriaFormViewModel.guardar()          <- logica que ya existia
            |
            +--> service.crear(...)          --> Core Data (y luego Spring)
            |
            +--> BitacoraService.registrar() --> Firebase
                        |
                        v
              Firebase Realtime Database
                        |
                        v
  BitacoraListViewModel.cargar()  <-- BitacoraService.todos()
            |
            v
  BitacoraListViewController  (la pantalla)""")

nota("Fijate en la bifurcacion.",
     "Guardar en Core Data y registrar en Firebase son dos caminos independientes. Si Firebase "
     "falla, la categoria igual quedo guardada. Eso no es casualidad: es una decision de diseno "
     "que se explica en la seccion 5.")


# =====================================================================
h2("3. Paso 1: instalar el SDK")

p("Firebase se agrega con <b>Swift Package Manager</b>, el gestor de dependencias que ya "
  "trae Xcode. En la interfaz seria <i>File &gt; Add Package Dependencies</i>, pegando la URL "
  "del repositorio de Firebase.")

p("El SDK de Firebase es un <b>monorepo</b>: un solo paquete que contiene muchos productos "
  "(Database, Firestore, Analytics, Auth, Storage, Messaging...). Al agregarlo, Xcode "
  "pregunta cuales queres. Este proyecto usa <b>solo uno</b>:")

tabla([
    ["Producto", "Se incluye", "Por que"],
    ["FirebaseDatabase", "Si", "Es el que da acceso a Realtime Database"],
    ["FirebaseAnalytics", "No", "No aporta nada a la app y arrastra GoogleAppMeasurement"],
    ["Firestore, Auth, Storage...", "No", "No se usan"],
], [45 * mm, 22 * mm, 96 * mm])

p("Aunque solo se elija un producto, SPM descarga las dependencias que ese producto necesita. "
  "Por eso en el proyecto quedan fijados <b>13 paquetes</b> (GoogleUtilities, leveldb, nanopb, "
  "Promises, etc.). Es normal: son piezas internas del SDK, no hay que tocarlas.")

h3("Que queda registrado en el proyecto")
p("La eleccion se guarda en dos archivos:")
bullets([
    "<font face='Courier'>project.pbxproj</font>: la referencia al paquete y la version pedida "
    "(<font face='Courier'>upToNextMajorVersion 12.18.0</font>, o sea &quot;cualquier 12.x, "
    "nunca 13&quot;).",
    "<font face='Courier'>Package.resolved</font>: las versiones <b>exactas</b> que se "
    "descargaron. Este archivo se commitea a propocito, para que el proyecto compile igual en "
    "cualquier otra maquina.",
])

nota("Si clonas el repo en otra Mac.",
     "Xcode va a tardar la primera vez: esta descargando los 13 paquetes. No hay que instalar "
     "nada a mano ni correr comandos; con abrir el proyecto alcanza.")


# =====================================================================
h2("4. Paso 2: el plist y el arranque")

h3("GoogleService-Info.plist")
p("Es un archivo que <b>genera la consola de Firebase</b> cuando registras la app. No se "
  "escribe a mano. Contiene las credenciales publicas del proyecto y, sobre todo, la URL de "
  "la base:")

codigo_simple(
"""BUNDLE_ID     com.inventario.app
PROJECT_ID    inventario-ios
DATABASE_URL  https://inventario-ios-default-rtdb.firebaseio.com
API_KEY       (identificador de cliente, no es un secreto)""")

nota("El BUNDLE_ID tiene que coincidir.",
     "Al registrar la app en la consola hay que escribir exactamente el bundle id del proyecto "
     "(<font face='Courier'>com.inventario.app</font>). Si no coincide, el plist no sirve y "
     "Firebase no arranca.")

p("El archivo va en <font face='Courier'>Resources/</font> y entra al bundle de la app "
  "automaticamente. <b>Importante:</b> la URL de la base no esta escrita en ningun lado del "
  "codigo Swift. Sale siempre de este archivo, asi que cambiar de proyecto Firebase es "
  "reemplazar el plist y nada mas.")

h3("FirebaseApp.configure()")
p("El SDK necesita arrancar antes de que alguien lo use. Eso se hace en el "
  "<font face='Courier'>AppDelegate</font>, que es lo primero que corre al abrir la app:")

codigo(
"""import FirebaseCore
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Tiene que correr antes que cualquier uso del SDK. Lee el
        // `GoogleService-Info.plist` del bundle por su cuenta: por eso la app no
        // tiene ninguna URL de Firebase escrita en el codigo.
        FirebaseApp.configure()
        return true
    }
}""", "App/AppDelegate.swift")

p("Son literalmente dos lineas: el <font face='Courier'>import</font> y la llamada. "
  "<font face='Courier'>configure()</font> busca el plist en el bundle, lo lee y deja el SDK "
  "listo. Si el plist faltara, la app crashearia en el arranque con un mensaje explicito &mdash; "
  "no falla en silencio.")

nota("Ojo con los ejemplos de la documentacion oficial.",
     "La documentacion de Firebase muestra la version para <b>SwiftUI</b>, que usa "
     "<font face='Courier'>@main struct App</font> y "
     "<font face='Courier'>@UIApplicationDelegateAdaptor</font>. Este proyecto es <b>UIKit</b>: "
     "ya tiene un AppDelegate de verdad, asi que la llamada va directo adentro y ese adaptador "
     "no hace falta. Copiar el ejemplo de SwiftUI romperia la app.")


# =====================================================================
h2("5. Paso 3: el modelo del dato")

p("Antes de escribir nada hay que decidir que campos tiene un evento. El modelo vive en "
  "<font face='Courier'>EventoBitacora.swift</font>.")

h3("Los dos enums")
p("En vez de guardar textos sueltos, la accion y la entidad son <b>enums</b>. Asi el compilador "
  "impide escribir <font face='Courier'>&quot;creado&quot;</font> en un lado y "
  "<font face='Courier'>&quot;creo&quot;</font> en otro:")

codigo(
"""enum AccionBitacora: String {
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

enum EntidadBitacora: String {
    case producto = "Producto"
    case categoria = "Categoria"
    case proveedor = "Proveedor"
}""", "Models/Bitacora/EventoBitacora.swift")

p("El <font face='Courier'>: String</font> le da a cada caso un valor crudo, que es lo que "
  "efectivamente viaja a Firebase. <font face='Courier'>descripcion</font> es aparte porque lo "
  "que se guarda y lo que se muestra no tienen por que ser iguales.")

h3("Los campos del evento")

codigo(
"""struct EventoBitacora {
    let accion: AccionBitacora
    let entidad: EntidadBitacora
    let nombre: String       // nombre del registro afectado
    let usuario: String      // quien lo hizo
    let fechaISO: String     // fecha legible si mirás el arbol en la consola
    let timestamp: Double    // segundos desde 1970; es por lo que se ordena

    init(accion: AccionBitacora, entidad: EntidadBitacora,
         nombre: String, usuario: String, fecha: Date = Date()) {
        self.accion = accion
        self.entidad = entidad
        self.nombre = nombre
        self.usuario = usuario
        self.fechaISO = Self.formateador.string(from: fecha)
        self.timestamp = fecha.timeIntervalSince1970
    }
}""")

p("Dos decisiones que parecen menores y no lo son:")

bullets([
    "<b>Se guarda el nombre, no solo un id.</b> Si guardaramos "
    "<font face='Courier'>productoId: 42</font> y despues ese producto se borra, la entrada "
    "quedaria diciendo &quot;se elimino el producto 42&quot; sin forma de saber cual era. El "
    "nombre congela como se llamaba en el momento del hecho.",
    "<b>Hay dos campos de fecha.</b> <font face='Courier'>timestamp</font> es un numero, sirve "
    "para ordenar y comparar. <font face='Courier'>fechaISO</font> es texto, y existe para que "
    "el dato crudo se entienda si lo mirás desde la consola de Firebase.",
])


h3("Traduccion a diccionario")
p("El SDK de Firebase no trabaja con structs de Swift: manda y recibe "
  "<font face='Courier'>[String: Any]</font>, o sea diccionarios. Asi que el modelo sabe "
  "convertirse en las dos direcciones.")

p("<b>De Swift a Firebase</b> (para escribir):")

codigo(
"""var comoDiccionario: [String: Any] {
    [
        "accion": accion.rawValue,
        "entidad": entidad.rawValue,
        "nombre": nombre,
        "usuario": usuario,
        "fechaISO": fechaISO,
        "timestamp": timestamp
    ]
}""")

p("<b>De Firebase a Swift</b> (para leer). Notar que es un "
  "<font face='Courier'>init?</font>, o sea que puede fallar y devolver "
  "<font face='Courier'>nil</font>:")

codigo(
"""init?(diccionario: [String: Any]) {
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
}""")

nota("Por que el init puede fallar.",
     "Firebase no valida la forma de los datos: cualquiera con acceso a la base podria escribir "
     "un nodo con campos raros. Si eso pasa, este init devuelve <font face='Courier'>nil</font> y "
     "esa entrada <b>se saltea</b>, en vez de tumbar la lista entera. Un dato corrupto se pierde "
     "una fila, no la pantalla.")

p("Fijate que <font face='Courier'>fechaISO</font> es el unico campo con "
  "<font face='Courier'>?? &quot;&quot;</font> en vez de estar en el "
  "<font face='Courier'>guard</font>: es opcional porque solo sirve para mostrar. Si falta, la "
  "entrada sigue siendo utilizable, porque la fecha real se reconstruye del "
  "<font face='Courier'>timestamp</font>.")


# =====================================================================
h2("6. Paso 4: escribir en Firebase")

p("Toda la conversacion con Firebase esta encerrada en un solo archivo: "
  "<font face='Courier'>BitacoraService.swift</font>. Ninguna pantalla habla con Firebase "
  "directamente.")

h3("La referencia a la rama")

codigo(
"""import FirebaseDatabase

final class BitacoraService {

    static let shared = BitacoraService()

    /// Rama del arbol donde vive la bitacora. En Realtime Database no hay
    /// tablas: el arbol entero es un JSON y cada rama se direcciona por su ruta.
    private var referencia: DatabaseReference {
        Database.database().reference(withPath: "bitacora")
    }

    private init() {}""", "Services/BitacoraService.swift")

p("Realtime Database <b>no tiene tablas</b>. Toda la base es un unico JSON gigante, y para "
  "trabajar apuntas a una rama por su ruta. Aca la ruta es "
  "<font face='Courier'>bitacora</font>, que seria el equivalente conceptual a una tabla.")

p("<font face='Courier'>Database.database()</font> no recibe ninguna URL: la saca de la "
  "configuracion que dejo <font face='Courier'>FirebaseApp.configure()</font> al leer el plist.")

h3("El metodo que registra")

codigo(
"""func registrar(_ accion: AccionBitacora, sobre entidad: EntidadBitacora, nombre: String) {
    let evento = EventoBitacora(
        accion: accion,
        entidad: entidad,
        nombre: nombre,
        usuario: SessionManager.shared.username ?? "desconocido"
    )

    // `childByAutoId` genera la clave ordenada por tiempo que el SDK usa para
    // las listas. `setValue` sin completion es exactamente "dispara y
    // olvida": el SDK reintenta solo si el envio no llega.
    referencia.childByAutoId().setValue(evento.comoDiccionario)
}""")

p("Tres cosas para mirar de cerca:")

h3("1. El usuario no se recibe por parametro")
p("Sale de <font face='Courier'>SessionManager.shared.username</font>, adentro del servicio. Si "
  "fuera un parametro, cualquier pantalla podria registrar un evento a nombre de otra persona &mdash; "
  "y en una auditoria eso la invalida por completo.")

h3("2. childByAutoId()")
p("Genera una clave unica como <font face='Courier'>-P-Rr7FpHThqMvBWXwFv</font>. No son "
  "aleatorias: llevan el tiempo codificado adentro, asi que ordenar las claves alfabeticamente "
  "las ordena cronologicamente. Ademas evita colisiones si dos usuarios escriben al mismo tiempo.")

h3("3. setValue sin completion")
p("El metodo <b>no devuelve error y no tiene callback</b>. Es a proposito: registrar es un "
  "efecto secundario. Si Firebase no contesta, el producto ya se guardo igual y no tendria "
  "sentido molestar al usuario con un error sobre algo que a el no le importa. El SDK ademas "
  "reintenta por su cuenta si el envio no llega.")

nota("La regla que ordena todo esto.",
     "La bitacora <b>nunca</b> puede romper una operacion del usuario. Por eso "
     "<font face='Courier'>registrar</font> no devuelve nada: es imposible que alguien, por error, "
     "escriba codigo que cancele un guardado porque fallo la auditoria.")


# =====================================================================
h2("7. Paso 5: leer de Firebase")

codigo(
"""func todos(completion: @escaping (Result<[EventoBitacora], APIError>) -> Void) {
    referencia.queryOrdered(byChild: "timestamp").observeSingleEvent(of: .value) { snapshot in
        var eventos: [EventoBitacora] = []

        for hijo in snapshot.children {
            guard let hijo = hijo as? DataSnapshot,
                  let diccionario = hijo.value as? [String: Any],
                  let evento = EventoBitacora(diccionario: diccionario) else { continue }
            eventos.append(evento)
        }

        // El SDK ya entrega en el hilo principal, pero el orden viene
        // ascendente.
        completion(.success(eventos.reversed()))
    } withCancel: { error in
        completion(.failure(.server(status: 0, message: error.localizedDescription)))
    }
}""", "Services/BitacoraService.swift")

h3("queryOrdered(byChild:)")
p("Le pide a Firebase que devuelva los hijos ordenados por el campo "
  "<font face='Courier'>timestamp</font>. Sin esto, el orden no esta garantizado.")

h3("observeSingleEvent y no observe")
p("Firebase ofrece dos formas de leer:")
tabla([
    ["Metodo", "Comportamiento"],
    ["observe(...)", "Queda escuchando: cada cambio en la base vuelve a llamar al codigo"],
    ["observeSingleEvent(...)", "Lee una vez y se desuscribe solo"],
], [45 * mm, 118 * mm])

p("Se usa el segundo porque la pantalla no necesita actualizarse en vivo, y porque una "
  "suscripcion viva hay que darla de baja al salir de la pantalla &mdash; si te olvidas, queda "
  "escuchando para siempre y perdes memoria. Para refrescar alcanza con deslizar hacia abajo.")

h3("El recorrido del snapshot")
p("<font face='Courier'>snapshot</font> es el nodo <font face='Courier'>bitacora</font> entero, "
  "y <font face='Courier'>snapshot.children</font> son las entradas. De cada una se saca el "
  "diccionario y se lo pasa al <font face='Courier'>init?</font> del modelo. El "
  "<font face='Courier'>continue</font> del <font face='Courier'>guard</font> es el que "
  "implementa el &quot;saltear la entrada corrupta&quot;.")

h3("reversed()")
p("<font face='Courier'>queryOrdered</font> devuelve de menor a mayor, o sea lo mas viejo "
  "primero. En pantalla interesa lo ultimo primero, asi que se invierte.")

nota("Sobre el rendimiento.",
     "Este metodo baja la bitacora completa cada vez. Para una app de curso con decenas o "
     "cientos de eventos esta perfecto. Si algun dia fueran miles, la solucion es agregar "
     "<font face='Courier'>.queryLimited(toLast: 50)</font> para traer solo los ultimos.")


# =====================================================================
h2("8. Paso 6: donde se disparan los eventos")

p("El servicio no se llama solo. Hay <b>seis puntos</b> en la app donde el usuario modifica "
  "datos, y en cada uno se agrego una linea. Ejemplo con categorias:")

codigo(
"""func guardar(nombre: String, descripcion: String) -> String? {
    // ... validaciones ...

    let esAlta = categoria == nil

    if let categoria {
        service.actualizar(categoria, nombre: nombreLimpio, descripcion: descripcionFinal)
    } else {
        categoria = service.crear(nombre: nombreLimpio, descripcion: descripcionFinal)
    }

    BitacoraService.shared.registrar(esAlta ? .creo : .edito,
                                     sobre: .categoria, nombre: nombreLimpio)
    return nil
}""", "Features/Categorias/CategoriaFormViewModel.swift")

p("El mismo formulario sirve para alta y para edicion, y se distinguen por si "
  "<font face='Courier'>categoria</font> ya existia. Por eso "
  "<font face='Courier'>esAlta</font> se calcula <b>antes</b> del "
  "<font face='Courier'>if</font>: despues de crear, la variable ya no es "
  "<font face='Courier'>nil</font> y la pregunta daria siempre lo mismo.")

p("Y el registro va <b>despues</b> de guardar, no antes: la bitacora deja constancia de lo que "
  "efectivamente paso, no de lo que se iba a intentar.")

h3("El caso de las bajas: un detalle facil de arruinar")

codigo(
"""func eliminar(en indice: Int) {
    guard productos.indices.contains(indice) else { return }
    let producto = productos[indice]

    // El nombre se lee ANTES de marcar la baja: despues la fila puede no
    // estar mas y la entrada de la bitacora quedaria sin con que nombrarla.
    let nombre = producto.nombre ?? "(sin nombre)"

    ProductoService().marcarParaEliminar(producto)
    BitacoraService.shared.registrar(.elimino, sobre: .producto, nombre: nombre)
    cargarLocales()
}""", "Features/Productos/ProductoListViewModel.swift")

nota("El orden importa.",
     "Si leyeras <font face='Courier'>producto.nombre</font> despues de "
     "<font face='Courier'>marcarParaEliminar</font>, el objeto podria estar ya invalidado y "
     "obtendrias vacio o un crash. La entrada quedaria como &quot;Elimino Producto &middot; "
     "(sin nombre)&quot;, justo el dato que mas interesa cuando alguien borro algo.")

p("Los seis puntos son: alta/edicion y baja de <b>producto</b>, de <b>categoria</b> y de "
  "<b>proveedor</b>.")


# =====================================================================
h2("9. Paso 7: la pantalla")

p("La app usa el patron <b>MVVM</b>: el ViewModel pide los datos y avisa por closures; el "
  "ViewController solo dibuja.")

h3("El ViewModel")

codigo(
"""final class BitacoraListViewModel {

    var onCambio: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private(set) var eventos: [EventoBitacora] = []
    private let service = BitacoraService.shared

    var estaVacio: Bool { eventos.isEmpty }

    func cargar() {
        onLoadingChanged?(true)
        service.todos { [weak self] resultado in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch resultado {
            case .success(let eventos):
                self.eventos = eventos
                self.onCambio?()
            case .failure(let error):
                self.onError?(error.errorDescription ?? "No se pudo cargar la bitacora")
            }
        }
    }
}""", "Features/Bitacora/BitacoraListViewModel.swift")

p("<font face='Courier'>[weak self]</font> evita un ciclo de retencion: sin eso, el ViewModel "
  "se quedaria vivo esperando una respuesta aunque el usuario ya se haya ido de la pantalla.")

p("<font face='Courier'>private(set)</font> significa que cualquiera puede <i>leer</i> "
  "<font face='Courier'>eventos</font>, pero solo el ViewModel puede <i>modificarlo</i>. La "
  "pantalla no puede ensuciar el estado por accidente.")

h3("La celda")
p("La pantalla <b>reusa</b> la celda del catalogo, porque la estructura es la misma: un titulo "
  "y un detalle debajo.")

codigo(
"""celdaCatalogo.configurar(
    nombre: evento.resumen,                                   // "Edito Producto - Taladro"
    detalle: "\\(evento.usuario) - \\(evento.fechaLegible)",     // "admin - 19/08/2026 20:37"
    chip: nil                                                 // sin chip
)""", "Features/Bitacora/BitacoraListViewController.swift")

p("<font face='Courier'>resumen</font> y <font face='Courier'>fechaLegible</font> son "
  "propiedades calculadas del modelo. Que el modelo sepa como presentarse evita repetir ese "
  "armado de texto en cada pantalla que lo muestre.")

h3("Quien puede verla")
p("La fila vive en <b>Cuenta &gt; Bitacora</b>, dentro de la seccion Administracion, y solo "
  "aparece si el usuario es <b>ADMIN</b>. Una auditoria es justamente para quien controla lo "
  "que hacen los demas.")


# =====================================================================
h2("10. Como se ve el dato en Firebase")

p("Asi queda el arbol en la consola (<i>Compilacion &gt; Realtime Database &gt; Datos</i>):")

codigo_simple(
"""inventario-ios-default-rtdb
└── bitacora
    ├── -P-Ro3ZRO0Whl9W3WywG
    │   ├── accion: "creo"
    │   ├── entidad: "Categoria"
    │   ├── fechaISO: "2026-08-20T01:36:46Z"
    │   ├── nombre: "Prueba Bitacora"
    │   ├── timestamp: 1787189806.866634
    │   └── usuario: "admin"
    └── -P-Rr7FpHThqMvBWXwFv
        ├── accion: "elimino"
        └── ...""")

p("Cada clave rara es la que genero <font face='Courier'>childByAutoId()</font>. Los seis "
  "campos son exactamente los que arma <font face='Courier'>comoDiccionario</font>.")

nota("Truco para demostrar que funciona.",
     "Deja la consola abierta en esa pantalla y crea una categoria desde la app. El nodo nuevo "
     "aparece <b>solo, sin recargar</b>, y se resalta unos segundos: la consola escucha en tiempo "
     "real. Es la forma mas directa de mostrar que la app esta escribiendo ahi.")

# =====================================================================
h2("11. Como verificarlo desde la terminal")

p("Realtime Database tambien tiene API REST, asi que se puede consultar sin abrir la consola. "
  "Es muy comodo para verificar rapido:")

codigo(
"""# Ver toda la bitacora
curl -s "https://inventario-ios-default-rtdb.firebaseio.com/bitacora.json"

# Una bitacora vacia responde: null""", "Terminal")

p("Esto sirve para confirmar que un evento llego <b>de verdad</b> a la base, sin depender de lo "
  "que muestre la pantalla &mdash; si la app y el curl coinciden, el circuito completo funciona.")


# =====================================================================
h2("12. Decisiones de diseno, resumidas")

tabla([
    ["Decision", "Motivo"],
    ["Guardar una entidad nueva\n(no copiar productos)",
     "Copiar datos del backend crearia dos fuentes de verdad para el mismo dato"],
    ["Realtime Database\n(no Firestore)",
     "El dato es una lista plana que solo crece;\nFirestore agrega complejidad que no se usa"],
    ["Solo FirebaseDatabase\n(sin Analytics)",
     "Analytics no aporta a la app y arrastra dependencias pesadas"],
    ["registrar() sin completion",
     "La auditoria nunca puede romper una operacion del usuario"],
    ["El usuario sale de SessionManager",
     "Si fuera parametro, una pantalla podria registrar a nombre de otro"],
    ["Se guarda el nombre, no solo el id",
     "La entrada tiene que seguir siendo legible cuando el registro ya no exista"],
    ["Leer el nombre antes de borrar",
     "Despues de marcar la baja el objeto puede estar invalidado"],
    ["observeSingleEvent",
     "La pantalla no necesita tiempo real, y una suscripcion viva hay que darla de baja"],
    ["init? que devuelve nil",
     "Una entrada corrupta se saltea en vez de tumbar la lista entera"],
    ["Todo encerrado en BitacoraService",
     "Ninguna pantalla habla con Firebase; cambiar de backend toca un solo archivo"],
], [52 * mm, 111 * mm])

nota("Sobre el ultimo punto, un caso real.",
     "Esta implementacion se escribio primero con la <b>API REST</b> de Firebase, sin SDK. Cuando "
     "hubo que migrar al SDK oficial, el cambio fue reescribir "
     "<font face='Courier'>BitacoraService</font> por dentro: ni el modelo, ni los seis puntos que "
     "registran, ni la pantalla se enteraron. Eso es lo que compra encapsular bien.")

# =====================================================================
h2("13. Seguridad y limitaciones")

h3("Las reglas de la base estan abiertas")
p("La base se creo en <b>modo de prueba</b>: cualquiera que conozca la URL puede leer y "
  "escribir. Firebase las cierra solo a los 30 dias de creada, y cuando eso pase la app va a "
  "empezar a fallar al escribir.")

p("Para un trabajo de curso alcanza, pero conviene tener presente:")
bullets([
    "<b>No guardar datos reales de clientes</b> en esa base.",
    "<b>Borrar el proyecto de Firebase</b> al cerrar la materia.",
])

h3("El plist esta en el repositorio publico")
p("Eso es lo normal en iOS: el <font face='Courier'>GoogleService-Info.plist</font> esta pensado "
  "para viajar dentro de la app, y su <font face='Courier'>API_KEY</font> es un identificador de "
  "cliente, no una contrasena. Cualquiera que descargue una app de iPhone puede sacarlo.")

nota("La idea importante.",
     "Lo que protege una base de Firebase son <b>las reglas</b>, no esconder el archivo de "
     "configuracion. Con reglas abiertas, el riesgo existe aunque el plist fuera secreto; con "
     "reglas bien puestas, publicarlo no es problema.")

h3("La bitacora no funciona sin conexion")
p("A diferencia del resto de la app, que es <i>offline-first</i>, los eventos van a la red en el "
  "momento. Es deliberado: un registro de auditoria que se encola en el telefono y se sube "
  "cuando quiere no sirve como rastro confiable. Si no hay conexion, el SDK reintenta solo; si "
  "aun asi no llega, se pierde ese evento &mdash; pero la operacion del usuario nunca se ve afectada.")


# =====================================================================
def pie_de_pagina(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(LINEA)
    canvas.setLineWidth(0.4)
    canvas.line(23 * mm, 15 * mm, 187 * mm, 15 * mm)
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(GRIS)
    canvas.drawString(23 * mm, 10.5 * mm, "Firebase en Inventario iOS")
    canvas.drawRightString(187 * mm, 10.5 * mm, "Pagina %d" % doc.page)
    canvas.restoreState()


doc = BaseDocTemplate(SALIDA, pagesize=A4,
                      leftMargin=23 * mm, rightMargin=23 * mm,
                      topMargin=20 * mm, bottomMargin=22 * mm,
                      title="Firebase en Inventario iOS",
                      author="Proyecto inventario-ios",
                      subject="Implementacion de Firebase Realtime Database")

marco = Frame(doc.leftMargin, doc.bottomMargin,
              doc.width, doc.height, id="cuerpo")
doc.addPageTemplates([PageTemplate(id="normal", frames=[marco], onPage=pie_de_pagina)])
doc.build(historia)
print("PDF generado:", SALIDA)
