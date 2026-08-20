# -*- coding: utf-8 -*-
"""Genera el PDF didactico de como se trabaja con Core Data en el proyecto."""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, Paragraph,
    Preformatted, Spacer, Table, TableStyle, KeepTogether,
)

# El PDF se genera al lado de este script, sea cual sea el directorio desde el
# que se lo invoque.
SALIDA = str(Path(__file__).resolve().parent / "CoreData.pdf")

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
CELDA = ParagraphStyle("CELDA", parent=base["Normal"], fontName="Helvetica",
                       fontSize=8.3, leading=11.5, textColor=TINTA, spaceAfter=0)
CELDA_TIT = ParagraphStyle("CELDA_TIT", parent=CELDA, fontName="Helvetica-Bold")

historia = []
ANCHO = 163 * mm
C = lambda s: "<font face='Courier'>%s</font>" % s


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


def tabla(filas, anchos):
    # Las celdas van como Paragraph: ReportLab solo hace salto de linea dentro
    # de un Paragraph. Con texto suelto, una celda larga se sale de la tabla.
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


# =====================================================================
p("Core Data en este proyecto", H1)
p("Que es, como esta modelado, y como se lee y se escribe. Con el codigo real de "
  "Inventario iOS.", SUBTITULO)

p("Ferreteria Zamora &mdash; App de gestion de inventario<br/>"
  "Modelo: %s &nbsp;|&nbsp; 4 entidades &nbsp;|&nbsp; Stack: %s"
  % (C("InventarioModel.xcdatamodeld"), C("NSPersistentContainer")),
  ParagraphStyle("META", parent=CUERPO, textColor=GRIS, fontSize=9, spaceAfter=14))

h2("Por que Core Data importa tanto en esta app")

p("Core Data no es un detalle de implementacion aca: es <b>la fuente de verdad de toda la "
  "interfaz</b>. Ninguna pantalla lee de la red. Todas leen de Core Data, y la red es un "
  "proceso aparte que lo actualiza.")

p("Eso es lo que hace que la app funcione sin conexion, y explica por que las entidades tienen "
  "campos que no son del negocio (%s, %s) y por que borrar no borra."
  % (C("estadoSync"), C("pendienteEliminar")))

nota("Que es Core Data, en una frase.",
     "No es una base de datos: es un <b>administrador de grafo de objetos</b> que sabe "
     "persistirse. Vos trabajas con objetos de Swift y sus relaciones; el guarda todo en un "
     "SQLite que casi nunca necesitas ver. Confundirlo con &quot;un SQLite con azucar&quot; "
     "lleva a pelearse con el.")

# =====================================================================
parte("I", "Las piezas", "Los cuatro objetos de Core Data que hay que distinguir.")

h2("1. Quien es quien")

tabla([
    ["Pieza", "Que es", "Donde aparece"],
    ["NSManagedObjectModel", "El esquema: entidades, atributos y relaciones",
     "El archivo .xcdatamodeld"],
    ["NSPersistentStoreCoordinator", "Conecta el modelo con el archivo en disco",
     "No se toca nunca"],
    ["NSManagedObjectContext", "El area de trabajo en memoria. Todo pasa por aca",
     "PersistenceController.viewContext"],
    ["NSPersistentContainer", "Arma las tres cosas anteriores por vos",
     "PersistenceController.container"],
], [42 * mm, 66 * mm, 55 * mm])

p("El unico que se usa a diario es el <b>contexto</b>. La imagen mental util es la de un "
  "borrador: creas y modificas objetos ahi, y nada toca el disco hasta que llamas a "
  "%s." % C("save()"))

codigo("""  Vos escribis            El contexto                 El disco
  ─────────────           ───────────                 ────────
  producto.precio = 45 →  cambio pendiente
  producto.stock  = 3  →  cambio pendiente
                          saveContext()          →    SQLite""")

h2("2. PersistenceController")

p("Toda la configuracion de Core Data del proyecto son 30 lineas:")

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

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            assertionFailure("Error guardando Core Data: \\(error)")
        }
    }
}""", "CoreData/PersistenceController.swift")

h3("Linea por linea")

bullets([
    "<b>%s</b> tiene que coincidir <b>exacto</b> con el nombre del "
    "archivo %s. Si no, la app crashea al arrancar." % (C('name: "InventarioModel"'), C(".xcdatamodeld")),
    "<b>%s</b> abre (o crea) el SQLite. Es lo unico que "
    "puede tardar en el arranque." % C("loadPersistentStores"),
    "<b>%s</b> es el contexto del hilo principal. Esta app usa uno solo, "
    "lo que simplifica todo enormemente." % C("viewContext"),
    "<b>%s</b> evita escribir al disco cuando no hay nada "
    "que escribir." % C("guard hasChanges"),
])

nota("El fatalError no es descuido.",
     "Si Core Data no carga, la app no tiene fuente de datos: no hay nada util que mostrar. "
     "Arrancar igual solo lleva a un crash mas confuso tres pantallas despues. Fallar fuerte y "
     "temprano es preferible a fallar raro y tarde.")

nota("Un solo contexto, un solo hilo.",
     "Los objetos de Core Data <b>no son seguros entre hilos</b>: un %s "
     "creado en el hilo principal no se puede tocar desde otro. Esta app usa unicamente el "
     "%s y todos los callbacks de red vuelven al hilo principal antes de "
     "escribir. Es la razon por la que nunca aparecen crashes raros de concurrencia."
     % (C("NSManagedObject"), C("viewContext")))

# =====================================================================
parte("II", "El modelo", "Las cuatro entidades, sus tipos y sus relaciones.")

h2("3. El mapa de entidades")

codigo("""   CategoriaEntity                      ProveedorEntity
        │ 1                                   │ 1
        │                                     │
        │ N                                   │ N
        └──────────► ProductoEntity ◄─────────┘
                          │ 1
                          │
                          │ N
                   ProductoImagenEntity""")

p("Un producto pertenece a una categoria y a un proveedor (los dos opcionales), y tiene "
  "muchas imagenes. Las relaciones son <b>bidireccionales</b>: desde una categoria se puede "
  "llegar a sus productos.")

h2("4. Los atributos de ProductoEntity")

tabla([
    ["Atributo", "Tipo", "Opcional", "Para que"],
    ["nombre", "String", "no", "Dato de negocio"],
    ["precio", "Double", "no", "Dato de negocio"],
    ["stock", "Integer 32", "no", "Dato de negocio"],
    ["fechaRegistro", "Date", "si", "Dato de negocio"],
    ["localId", "String", "no", "Control de sync"],
    ["apiId", "Integer 64", "si", "Control de sync"],
    ["estadoSync", "Integer 16", "no", "Control de sync"],
    ["pendienteEliminar", "Boolean", "no", "Control de sync"],
], [36 * mm, 27 * mm, 22 * mm, 78 * mm])

p("Los cuatro ultimos no existen en el backend: son <b>de la app</b>, y estan para sostener el "
  "modo offline. Se explican en la Parte IV.")

h3("El detalle que confunde a todos: usesScalarValueType")

p("En el XML del modelo hay una diferencia sutil entre dos atributos numericos:")

codigo("""<attribute name="apiId"      optional="YES" attributeType="Integer 64" usesScalarValueType="NO"/>
<attribute name="estadoSync"                attributeType="Integer 16" usesScalarValueType="YES"/>""",
       "InventarioModel.xcdatamodel/contents")

p("Esa bandera decide el tipo que Xcode genera en Swift:")

tabla([
    ["usesScalarValueType", "Tipo en Swift", "Puede ser nil"],
    ["YES (escalar)", "Int16", "No"],
    ["NO (objeto)", "NSNumber?", "Si"],
], [45 * mm, 55 * mm, 63 * mm])

p("Por eso %s puede estar vacio &mdash; un producto que todavia no se subio no "
  "tiene id de servidor &mdash; y por eso en el codigo aparece esta forma incomoda:" % C("apiId"))

codigo("""producto.apiId = NSNumber(value: dto.id)      // al escribir: hay que envolver
let id = apiId.int64Value                     // al leer: hay que desenvolver""")

nota("La regla practica.",
     "Si el numero <b>puede faltar</b>, va como objeto (%s) y en Swift es "
     "%s. Si siempre tiene valor, va escalar y queda como %s o "
     "%s, mucho mas comodo. Un escalar no puede ser nil aunque marques "
     "&quot;optional&quot; en el editor: Core Data le pone 0."
     % (C("usesScalarValueType=NO"), C("NSNumber?"), C("Int16"), C("Double")))

h2("5. Las relaciones y sus reglas de borrado")

p("Cada relacion define que pasa con el otro lado cuando se borra un objeto. El proyecto usa "
  "dos reglas distintas, y la eleccion no es casual:")

tabla([
    ["Relacion", "Regla", "Que significa"],
    ["Producto → imagenes", "Cascade", "Al borrar el producto se borran sus imagenes. Una "
                                       "imagen sin producto no tiene sentido: seria basura"],
    ["Producto → categoria", "Nullify", "Al borrar la categoria, los productos quedan sin "
                                        "categoria pero <b>siguen existiendo</b>"],
    ["Producto → proveedor", "Nullify", "Igual: se pierde el vinculo, no el producto"],
], [38 * mm, 22 * mm, 103 * mm])

codigo("""<relationship name="imagenes"  toMany="YES" deletionRule="Cascade"
              destinationEntity="ProductoImagenEntity" inverseName="producto"/>

<relationship name="categoria" maxCount="1" deletionRule="Nullify"
              destinationEntity="CategoriaEntity"     inverseName="productos"/>""")

nota("Si te equivocas de regla, perdes datos.",
     "Poner Cascade en la categoria significaria que borrar una categoria borra todos sus "
     "productos. Es un error silencioso y catastrofico: nadie lo nota hasta que falta media "
     "tabla. La UI de la app ademas lo advierte &mdash; al borrar una categoria avisa que "
     "&quot;los productos que la usen quedan sin categoria&quot;.")

h3("inverseName: siempre las dos puntas")

p("Toda relacion declara su inversa. Core Data usa eso para mantener la coherencia "
  "automaticamente: al hacer %s, el producto aparece solo "
  "dentro de %s. No hay que actualizar los dos lados a mano."
  % (C("producto.categoria = X"), C("X.productos")))

h2("6. Las clases las genera Xcode")

codigo("""<entity name="ProductoEntity" representedClassName="ProductoEntity"
        syncable="YES" codeGenerationType="class">""")

p("%s significa que <b>no hay ningun archivo "
  "%s escrito a mano</b> en el proyecto. Xcode lo genera al compilar, a "
  "partir del modelo." % (C('codeGenerationType="class"'), C("ProductoEntity.swift")))

p("Consecuencias practicas:")
bullets([
    "Si buscas %s en el repositorio, <b>no lo vas a encontrar</b>. "
    "Es normal." % C("ProductoEntity.swift"),
    "Agregar un atributo en el editor visual alcanza para poder usarlo en Swift.",
    "No se le pueden agregar metodos propios a la entidad por ese camino; para eso habria "
    "que cambiar a generacion manual o usar una extension.",
    "Es la razon de una rareza del codigo que se explica en la Parte V.",
])

# =====================================================================
parte("III", "Leer", "Consultas: NSFetchRequest, predicados y orden.")

h2("7. Anatomia de una consulta")

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

p("Si lo pensas en SQL, la traduccion es directa:")

codigo("""SELECT * FROM ProductoEntity           ← NSFetchRequest(entityName:)
WHERE pendienteEliminar = NO          ← request.predicate
ORDER BY nombre COLLATE NOCASE ASC    ← request.sortDescriptors""")

h3("El predicado")

p("%s se escribe con un formato de texto propio. Cuando hay valores "
  "variables, van con marcadores y <b>nunca</b> concatenando texto:" % C("NSPredicate"))

codigo("""NSPredicate(format: "pendienteEliminar == NO")              // literal
NSPredicate(format: "apiId == %@", NSNumber(value: apiId))  // con valor
NSPredicate(format: "estadoSync == 0 AND pendienteEliminar == NO")  // compuesto""")

p("El %s toma un objeto, por eso el %s. Para numeros "
  "escalares se usa %s. Es el mismo motivo por el que en SQL se usan "
  "parametros: evita errores de formato y de escapado." % (C("%@"), C("NSNumber"), C("%d")))

h3("El orden y el detalle del selector")

p("El %s no es adorno:" % C("selector:"))

codigo("""selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))""")

nota("Sin ese selector, el orden queda mal.",
     "La comparacion por defecto es binaria: ordena por el valor numerico de cada caracter. "
     "Eso pone todas las mayusculas antes que las minusculas (&quot;Zinc&quot; antes que "
     "&quot;acero&quot;) y manda las palabras con tilde al final. "
     "%s ordena como espera una persona." % C("localizedCaseInsensitiveCompare"))

h3("Por que try? y no do/catch")

p("%s convierte cualquier error de consulta en lista vacia. Es "
  "deliberado: si la lectura local falla, mostrar una lista vacia es mejor que crashear la "
  "app. El usuario puede sincronizar y recuperarse; un crash no deja salida." % C("(try? ...) ?? []"))

h2("8. Buscar uno solo")

codigo("""private func buscarPorApiId<T: NSManagedObject>(
    _ tipo: T.Type, nombreEntidad: String, apiId: Int64
) -> T? {
    let request = NSFetchRequest<T>(entityName: nombreEntidad)
    request.predicate = NSPredicate(format: "apiId == %@", NSNumber(value: apiId))
    request.fetchLimit = 1
    return try? contexto.fetch(request).first
}""", "Sync/SyncManager.swift")

p("%s es una optimizacion real: le dice a Core Data que "
  "pare de buscar apenas encuentre uno, en vez de traer todos los que coincidan y quedarse "
  "con el primero." % C("fetchLimit = 1"))

p("Esta funcion es el puente entre los dos mundos de ids: recibe el %s que "
  "mando el servidor y devuelve la fila local correspondiente." % C("apiId"))

h2("9. Navegar relaciones")

p("Las relaciones se leen como propiedades comunes:")

codigo("""producto.categoria?.nombre        // subir por la relacion
producto.proveedor?.logoUrl""")

p("Pero las relaciones <b>a muchos</b> tienen una trampa: Core Data las entrega como "
  "%s, que es un <b>conjunto sin orden</b>." % C("NSSet"))

codigo("""let imagenes = (producto.imagenes as? Set<ProductoImagenEntity>) ?? []
let principal = imagenes.sorted { $0.orden < $1.orden }.first""",
       "Features/Productos/ProductoTableViewCell.swift")

nota("Un Set no tiene primer elemento.",
     "Si tomaras %s directamente, la &quot;foto principal&quot; podria "
     "cambiar entre dos aperturas de la misma pantalla, sin que nadie haya tocado nada. Por eso "
     "existe el atributo %s y por eso siempre se ordena antes de usar. El mismo "
     "criterio se aplica en la galeria del detalle y en la miniatura del listado, para que las "
     "dos coincidan." % (C("imagenes.first"), C("orden")))

# =====================================================================
parte("IV", "Escribir", "Crear, actualizar, borrar, y los cuatro campos de control.")

h2("10. Los cuatro campos de control")

tabla([
    ["Campo", "Valores", "Significado"],
    ["localId", "UUID", "Identificador propio de la app. Existe desde el instante en que se "
                        "crea la fila, incluso sin conexion"],
    ["apiId", "Int64 o nil", "Id que asigno el servidor. nil = nunca se subio"],
    ["estadoSync", "0 o 1", "0 = tiene cambios sin subir (chip PENDIENTE). 1 = igual que en "
                            "el servidor"],
    ["pendienteEliminar", "true / false", "El usuario lo borro; el DELETE al servidor todavia "
                                          "no se confirmo"],
], [33 * mm, 25 * mm, 105 * mm])

p("Las cuatro entidades tienen estos cuatro campos. Es el precio de que la app funcione sin "
  "conexion: hay que recordar en el propio dato en que estado esta respecto del servidor.")

h2("11. Crear")

codigo("""let producto = ProductoEntity(context: contexto)
producto.localId = UUID().uuidString
// apiId queda nil: todavia no existe en el servidor. El SyncManager lo
// completa cuando el POST devuelve el id asignado.
producto.apiId = nil
producto.estadoSync = 0
producto.pendienteEliminar = false
producto.fechaRegistro = Date()

aplicar(nombre: nombre, precio: precio, stock: stock, ...)
PersistenceController.shared.saveContext()""", "Services/ProductoService.swift")

p("%s <b>inserta el objeto en el contexto</b> en el "
  "acto. No hace falta un &quot;insert&quot; aparte: crear el objeto ya lo agrega."
  % C("ProductoEntity(context:)"))

h2("12. Actualizar")

p("No hay ningun UPDATE. Se modifican las propiedades del objeto y se guarda:")

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

p("Core Data lleva la cuenta de que cambio (%s) y en el "
  "%s escribe solo lo necesario." % (C("hasChanges"), C("save()")))

nota("Ese estadoSync = 0 hace dos trabajos.",
     "El obvio: marcar la fila para que la proxima sincronizacion la suba, y dibujar el chip "
     "naranja. El menos obvio: <b>protege el cambio</b>. Cuando despues se bajan los datos del "
     "servidor, el upsert saltea todo lo que tenga %s, asi que la version "
     "del servidor no puede pisar lo que el usuario acaba de escribir sin conexion."
     % C("estadoSync == 0"))

h2("13. Borrar: por que casi nunca se borra")

codigo("""func marcarParaEliminar(_ producto: ProductoEntity) {
    if producto.apiId == nil {
        contexto.delete(producto)          // nunca llego al servidor: se va de verdad
    } else {
        producto.pendienteEliminar = true  // borrado logico
        producto.estadoSync = 0
    }
    PersistenceController.shared.saveContext()
}""")

p("El borrado es <b>logico</b>. La fila se marca y sigue en la base hasta que el servidor "
  "confirme el DELETE. Para el usuario desaparece igual, porque todas las consultas filtran "
  "con %s." % C("pendienteEliminar == NO"))

nota("Que pasaria sin el borrado logico.",
     "Si la fila se borrara del telefono al instante y la app estuviera sin conexion, no "
     "quedaria ningun rastro de que hay que avisarle al servidor. En la proxima sincronizacion "
     "el producto volveria a bajar, intacto, como si nunca lo hubieras borrado.")

h2("14. El upsert: la escritura mas delicada")

p("Al bajar del servidor hay que actualizar lo que ya existe e insertar lo nuevo. La busqueda "
  "es por %s, el unico id que las dos puntas comparten:" % C("apiId"))

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

p("El %s es la clave. Si la "
  "fila local tiene cambios sin subir o esta marcada para borrar, la funcion devuelve "
  "%s y el que llama la saltea. <b>Nunca se pisa trabajo offline.</b>"
  % (C("guard estadoSync == 1, !pendienteEliminar"), C("nil")))

p("La entidad nueva nace con %s porque viene del servidor: por "
  "definicion ya esta sincronizada." % C("estadoSync = 1"))

h3("Reconciliar lo borrado desde afuera")

codigo("""/// Borra lo que alguien elimino desde el portal web. Sin esto, un producto
/// borrado en el servidor sobreviviria para siempre en el telefono.
private func eliminarLocalesQueElServidorYaNoTiene(_ nombreEntidad: String,
                                                   apiIds: Set<Int64>) {
    let request = NSFetchRequest<NSManagedObject>(entityName: nombreEntidad)
    request.predicate = NSPredicate(format: "estadoSync == 1 AND apiId != nil")
    ...""")

p("El predicado vuelve a proteger lo pendiente: solo se miran filas ya sincronizadas y con "
  "%s. Lo que el usuario acaba de crear sin conexion no aparece en el "
  "servidor <i>todavia</i>, y borrarlo por eso seria un desastre." % C("apiId"))

h3("Un caso especial: las imagenes")

codigo("""/// Las imagenes todavia no se editan localmente (Fase 5), asi que la version
/// del servidor es la unica verdad: se borran las locales y se reinsertan.
private func reemplazarImagenes(de producto: ProductoEntity, con dtos: [ImagenDTO]) {
    if let existentes = producto.imagenes as? Set<ProductoImagenEntity> {
        existentes.forEach { contexto.delete($0) }
    }

    for dto in dtos {
        let imagen = ProductoImagenEntity(context: contexto)
        imagen.localId = UUID().uuidString
        imagen.apiId = NSNumber(value: dto.id)
        ...
        imagen.producto = producto        // basta con setear un lado
    }
}""")

p("Aca si se reemplaza todo, y es correcto: las imagenes no se editan sin conexion, asi que "
  "no hay trabajo offline que proteger. La ultima linea muestra la relacion bidireccional "
  "trabajando: al asignar %s, esa imagen aparece sola dentro de "
  "%s." % (C("imagen.producto"), C("producto.imagenes")))

# =====================================================================
parte("V", "Rarezas del codigo", "Dos cosas que sorprenden al leer, y por que estan.")

h2("15. Por que aparece setValue(forKey:)")

p("En algunos lugares el codigo no usa propiedades sino <b>KVC</b> (acceso por nombre de "
  "campo, en texto):")

codigo("""nueva.setValue(UUID().uuidString, forKey: "localId")
let estadoSync = existente.value(forKey: "estadoSync") as? Int16 ?? 0""")

p("Parece un retroceso &mdash; se pierde el chequeo del compilador &mdash; pero tiene una "
  "razon concreta, explicada en el propio codigo:")

codigo("""/// Lo que categorias y proveedores hacen igual. Se accede por KVC porque las dos
/// entidades comparten los atributos de control pero no un tipo comun: las
/// clases las genera `momc` desde el `.xcdatamodeld` y no hay donde meter un
/// protocolo a mano.
enum Catalogo {""", "Services/CatalogoService.swift")

p("Las cuatro entidades tienen %s, %s, %s y "
  "%s, pero como las clases las genera Xcode, no hay un archivo donde "
  "hacerlas conformar a un protocolo comun. Sin tipo comun, el codigo generico no puede "
  "escribir %s." % (C("localId"), C("apiId"), C("estadoSync"),
                    C("pendienteEliminar"), C("entidad.estadoSync")))

nota("El intercambio, dicho claro.",
     "Se gana no repetir la misma logica cuatro veces; se pierde el chequeo del compilador. "
     "Si alguien renombra %s en el editor visual, el codigo <b>compila igual</b> "
     "y falla en ejecucion. La alternativa &mdash; generacion manual de las clases y un "
     "protocolo &mdash; era mas codigo del que ahorraba." % C("estadoSync"))

h2("16. Los servicios son struct, no class")

codigo("""struct ProductoService {
    private var contexto: NSManagedObjectContext { PersistenceController.shared.viewContext }""")

p("Se instancian donde se usan (%s) sin guardarlos en ninguna "
  "propiedad. Pueden ser %s porque <b>no tienen estado</b>: el estado esta en "
  "Core Data, no en el servicio. Cada instancia es un envoltorio alrededor del mismo contexto "
  "compartido." % (C("ProductoService().todos()"), C("struct")))

# =====================================================================
parte("VI", "Practica", "Como mirar los datos y que errores evitar.")

h2("17. Inspeccionar la base a mano")

p("Core Data guarda en un SQLite comun. Durante el desarrollo se puede abrir y consultar "
  "directamente, que es la forma mas confiable de verificar que algo se guardo:")

codigo("""# Ubicar el archivo del simulador
find ~/Library/Developer/CoreSimulator/Devices -name "InventarioModel.sqlite" 2>/dev/null

# Consultarlo
sqlite3 <ruta> "SELECT ZNOMBRE, ZPRECIO, ZSTOCK, ZESTADOSYNC FROM ZPRODUCTOENTITY;" """,
       "Terminal")

nota("Los nombres llevan Z adelante.",
     "Core Data prefija tablas y columnas con %s: %s se convierte en "
     "%s, y %s en %s. Es un detalle interno "
     "&mdash; no hay que asumir que ese esquema es estable ni escribir en el a mano."
     % (C("Z"), C("ProductoEntity"), C("ZPRODUCTOENTITY"), C("nombre"), C("ZNOMBRE")))

h2("18. Errores clasicos que este proyecto evita")

tabla([
    ["Error", "Que pasa", "Como se evita aca"],
    ["Olvidarse el save()", "El cambio se ve en pantalla y desaparece al reiniciar",
     "Todos los metodos de escritura llaman a saveContext() al final"],
    ["Tocar objetos desde otro hilo", "Crashes raros e intermitentes",
     "Un solo contexto y todos los callbacks vuelven al hilo principal"],
    ["Cascade donde va Nullify", "Borrar una categoria borra sus productos",
     "Cascade solo en imagenes, que sin producto no tienen sentido"],
    ["Usar el primer elemento de un Set", "El orden cambia sin razon aparente",
     "Se ordena por el atributo orden antes de usar"],
    ["Cambiar el modelo sin migracion", "La app crashea al abrir con datos viejos",
     "Ver la nota de abajo"],
], [33 * mm, 55 * mm, 75 * mm])

h3("Sobre cambiar el modelo")

p("Agregar o renombrar atributos en un modelo que ya tiene datos guardados <b>rompe la app</b> "
  "si no se hace una migracion. Durante el desarrollo la salida practica es borrar la app del "
  "simulador y reinstalarla, que descarta el store viejo.")

p("En una app publicada eso no es opcion y hay que usar migracion (ligera o con mapeo). Este "
  "proyecto no la necesito porque el modelo quedo definido antes de tener datos que valiera la "
  "pena conservar.")

h2("19. Resumen")

tabla([
    ["Para...", "Se usa"],
    ["Leer una lista", "NSFetchRequest + predicate + sortDescriptors"],
    ["Leer uno solo", "El mismo, con fetchLimit = 1"],
    ["Crear", "Entidad(context:) y setear propiedades"],
    ["Actualizar", "Modificar propiedades del objeto"],
    ["Borrar de verdad", "contexto.delete(objeto)"],
    ["Borrar sincronizable", "pendienteEliminar = true (borrado logico)"],
    ["Confirmar cambios", "PersistenceController.shared.saveContext()"],
    ["Relacion a uno", "producto.categoria"],
    ["Relacion a muchos", "producto.imagenes as? Set<...>, y ordenar"],
], [50 * mm, 113 * mm])

nota("La idea que ordena todo.",
     "Core Data aca no es &quot;donde se guarda la copia&quot;: es <b>la fuente de verdad de la "
     "interfaz</b>. La red actualiza Core Data; la pantalla lee Core Data. Esa direccion unica "
     "es lo que hace que la app funcione sin conexion, y todo lo demas &mdash; los cuatro campos "
     "de control, el borrado logico, los guardas del upsert &mdash; existe para sostenerla.")


# =====================================================================
def pie_de_pagina(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(LINEA)
    canvas.setLineWidth(0.4)
    canvas.line(23 * mm, 15 * mm, 187 * mm, 15 * mm)
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(GRIS)
    canvas.drawString(23 * mm, 10.5 * mm, "Core Data en este proyecto — Inventario iOS")
    canvas.drawRightString(187 * mm, 10.5 * mm, "Pagina %d" % doc.page)
    canvas.restoreState()


doc = BaseDocTemplate(SALIDA, pagesize=A4,
                      leftMargin=23 * mm, rightMargin=23 * mm,
                      topMargin=20 * mm, bottomMargin=22 * mm,
                      title="Core Data en este proyecto - Inventario iOS",
                      author="Proyecto inventario-ios",
                      subject="Modelado, lectura y escritura con Core Data")

marco = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="cuerpo")
doc.addPageTemplates([PageTemplate(id="normal", frames=[marco], onPage=pie_de_pagina)])
doc.build(historia)
print("PDF generado:", SALIDA)
