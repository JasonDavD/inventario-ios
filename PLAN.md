# Inventario iOS - Ferreteria Zamora

App iOS que consume la API REST de [`inventario-backend`](../inventario-backend) (Spring Boot + JWT + roles ADMIN/OPERADOR/LECTOR). Cliente independiente, sin relacion con el proyecto Android del mismo curso — aunque replica su mismo patron de sincronizacion offline-first.

**Requisito de curso (rubrica):** UIKit clasico (`UITableView`, `UITableViewCell`, `UITableViewDataSource`, `UITableViewDelegate`), Core Data (`NSManagedObjectModel`, `NSManagedObjectContext`, `NSPersistentStoreCoordinator`, `NSPersistentContainer`, `NSFetchRequest`) y `URLSession` con `dataTask` (completion handlers, no async/await). No SwiftUI.

## Stack

- UIKit con **Storyboard + `@IBOutlet`/`@IBAction` + segues** (asi se enseña en el curso — ver division de trabajo abajo)
- Patron MVVM: ViewModel con closures de callback (no Combine/`@Published`), ViewController implementa `UITableViewDataSource`/`Delegate` y se subscribe a los closures
- Core Data **con el modelo armado en el editor visual** (`InventarioModel.xcdatamodeld`) — ver esquema exacto mas abajo
- `URLSession` + `dataTask(with:completionHandler:)`
- Keychain para el JWT (sin cambios respecto al planteo original)

### Division de trabajo — Claude escribe todo, el usuario revisa en Xcode

**Actualizado (2026-08-12):** hay Xcode 26.3 instalado y funcionando en la Mac de trabajo, con runtime iOS 26.3 y simuladores disponibles. Esto invalida la premisa original de este plan ("entorno sin Xcode disponible"). El motivo para no escribir Storyboard ni `.xcdatamodeld` era no poder abrirlos ni validarlos; ahora se pueden escribir y **verificar compilando y corriendo en el simulador**, que es una validacion mas fuerte que la inspeccion visual.

- **Claude escribe:** toda la logica Swift, y tambien el `Main.storyboard` y el `InventarioModel.xcdatamodeld` (son XML). Compila con `xcodebuild`, corre en el simulador y verifica con screenshots antes de dar nada por hecho.
- **El usuario:** abre los archivos en Xcode para ver como quedaron, ajusta lo que quiera del diseño visual, y corre la app por su cuenta cuando quiere validar algo end-to-end.

Los nombres exactos de outlets/acciones/segues/entidades que cada fase especifica siguen siendo la referencia — no porque haya que conectarlos a mano, sino porque el codigo Swift y el XML del Storyboard tienen que coincidir, y ese desajuste sigue siendo la causa mas comun de crash.

### Sistema de diseño

Las pantallas siguen [`DESIGN.md`](DESIGN.md) ("Precision Minimalist"), que esta en la raiz del repo y es la fuente de verdad. Traducido a codigo en `DesignSystem/Theme.swift`: si cambia el DESIGN.md se toca ese archivo, no cada pantalla.

- **Tipografia:** el documento pide Inter; se usa la fuente del sistema (SF Pro) para no bundlear archivos de fuente. Se respetan tamaño, peso, interlineado y tracking de cada rol, que es lo que define la jerarquia. El `letterSpacing` viene en `em` y se convierte a puntos (`kern = em * size`).
- **Iconos:** los Material Symbols del mockup se mapean a SF Symbols, que ya vienen en iOS (`handyman` → `wrench.and.screwdriver`, `visibility_off` → `eye.slash`, `arrow_forward` → `arrow.right`).
- **Modo oscuro:** la paleta es solo modo claro, asi que la app fuerza `UIUserInterfaceStyle = Light` en el `Info.plist`. Sin eso los colores fijos del `Theme` conviven con los del sistema y la pantalla queda ilegible.
- **Reparto storyboard/codigo:** el storyboard tiene la estructura (jerarquia de vistas, constraints, outlets); el estilado va en `viewDidLoad` desde el `Theme`. Tracking tipografico, bordes de 1px, radios y estados de foco no se pueden expresar en el editor visual.

#### Dos trampas de UIKit que ya costaron tiempo

1. **`UIButton.Configuration` pisa la fuente del titulo.** Setear `config.attributedTitle` con una fuente NO alcanza: UIKit reaplica la suya y el titulo sale en el tamaño por defecto. El unico punto que respeta es `config.titleTextAttributesTransformer`. Sintoma: todo compila y corre, pero los botones se ven con la tipografia equivocada.
2. **Forzar `lineHeight` desalinea el texto verticalmente.** Al fijar `minimumLineHeight`/`maximumLineHeight` en el `NSParagraphStyle`, el texto queda pegado al borde superior; se compensa con `baselineOffset`.

### Entorno verificado

| Item | Valor |
|---|---|
| Xcode | 26.3 (build 17C529), en `/Applications/Xcode.app` |
| Runtime | iOS 26.3 (23D8133) |
| Simulador de trabajo | iPhone 16e |
| Deployment target | iOS 18.0 |
| Bundle id | `com.inventario.app` |

`xcode-select` apuntaba a las Command Line Tools; se corrigio con `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

## Backend consumido

**Se trabaja siempre contra produccion** (`https://ferreteria-zamora-api.onrender.com`) — las Mac del instituto no tienen forma de levantar el backend local. Render (plan gratuito) duerme el servicio tras inactividad: la primera request puede tardar 20-40s (importa mas ahora: el `SyncManager` debe tolerar ese timeout, no solo el login).

Repo backend: `https://github.com/JasonDavD/inventario-backend`. Si se retoma este plan desde otra cuenta/maquina sin memoria previa (Engram no viaja entre cuentas de Claude Code), **clonar tambien ese repo al lado de este**.

### Contrato de la API (referencia rapida)

Errores: `{ "status": Int, "error": String, "mensaje": String }`.

**Producto:**
```json
{
  "id": 1, "nombre": "...", "precio": 10.5, "stock": 20,
  "fechaRegistro": "2026-08-12T10:15:30",
  "categoria": { "id": 1, "nombre": "...", "descripcion": "..." },
  "proveedor": { "id": 1, "nombre": "...", "telefono": "...", "direccion": "...", "logoUrl": "...", "logoPublicId": "..." },
  "imagenes": [ { "id": 1, "url": "https://res.cloudinary.com/...", "publicId": "...", "orden": 0 } ]
}
```
`categoria`/`proveedor` pueden venir `null`. Al crear/editar (POST/PUT), el body solo necesita `nombre`, `precio`, `stock` y opcionalmente `categoria: {"id": N}` / `proveedor: {"id": N}`.

**Categoria:** `{ "id", "nombre", "descripcion" }`. **Proveedor:** `{ "id", "nombre", "telefono", "direccion", "logoUrl", "logoPublicId" }`.

| Metodo | Ruta | Rol minimo |
|---|---|---|
| POST | `/api/auth/login` | Publico |
| GET | `/api/productos`, `/api/categorias`, `/api/proveedores` | LECTOR |
| POST/PUT | `/api/productos/{id}` | OPERADOR |
| DELETE | `/api/productos/{id}` | ADMIN |
| POST/DELETE | `/api/productos/{id}/imagenes[/{imagenId}]` | OPERADOR |
| POST/PUT/DELETE | `/api/categorias`, `/api/proveedores` | ADMIN |
| POST | `/api/proveedores/{id}/logo` | ADMIN |

Subida de imagenes/logo: `multipart/form-data`, campo `archivo`. Maximo 5 imagenes por producto.

## Arquitectura de sincronizacion (espejo de `inventario-android`)

Cada entidad local de Core Data tiene:
- `localId` (String/UUID) — identidad local, existe desde que se crea offline
- `apiId` (Int64 opcional) — nil hasta que se sincroniza con el backend; una vez seteado, identifica el recurso en el servidor
- `estadoSync` (Int16: 0 = pendiente, 1 = sincronizado)
- `pendienteEliminar` (Bool) — soft delete: se marca localmente, se borra en el servidor al sincronizar, y RECIEN AHI se borra la fila local

`SyncManager` (Fase 4) hace, en este orden, lo mismo que ya resolviste en Android (`buscarPorIdApi`/`insertarDesdeApi`/`actualizarDesdeApi`/`marcarSincronizado`):
1. Sube lo pendiente: `estadoSync == 0` sin `pendienteEliminar` → POST (sin `apiId`) o PUT (con `apiId`) → al confirmar, guarda `apiId` (si vino de un POST) y pone `estadoSync = 1`
2. Procesa bajas pendientes: `pendienteEliminar == true` → DELETE contra el `apiId` → al confirmar, recien ahi borra la fila local
3. Baja del servidor: GET → upsert local por `apiId` (si existe localmente, actualiza; si no, inserta)

**Limitacion de diseño explicita:** las imagenes solo se pueden subir a un producto/proveedor que ya tenga `apiId` — el backend exige el id del recurso padre para asociarlas, no se puede hacer offline. Un producto creado sin conexion no muestra la opcion de agregar fotos hasta que sincroniza.

## Estructura de carpetas

```
InventarioApp/
├── App/                       AppDelegate.swift, SceneDelegate.swift
├── Main.storyboard             todas las escenas + segues
├── LaunchScreen.storyboard
├── CoreData/
│   ├── InventarioModel.xcdatamodeld   esquema abajo
│   └── PersistenceController.swift    carga el modelo desde el .xcdatamodeld + NSPersistentContainer
├── Networking/
│   ├── APIClient.swift         URLSession + dataTask, completion handlers
│   ├── Endpoint.swift, APIError.swift
├── Auth/                       KeychainService.swift, SessionManager.swift
├── Models/                     DTOs Codable del JSON de la API (distintos de las entidades de Core Data)
├── Services/                   AuthService, ProductoService (red + Core Data)
├── Sync/                       SyncManager.swift
├── Features/
│   ├── Auth/                   LoginViewController + LoginViewModel
│   ├── Productos/              ProductoListViewController + Cell, ProductoDetailViewController, ProductoFormViewController (+ ViewModels)
│   ├── Categorias/
│   └── Proveedores/
└── Resources/                   Assets.xcassets, Info.plist (excluido del copy de recursos)
```

## Convencion de checklist

`[ ]` pendiente, `[~]` escrito pero no compilado/verificado, `[x]` compilado y corrido de verdad en el simulador.

Con Xcode disponible ya no hay excusa para dejar cosas en `[~]`: cada fase se cierra compilando y corriendo. Un `[~]` que sobrevive al final de una fase es deuda, no estado normal.

## Metodo de trabajo por fase

1. Escribir el codigo Swift de la fase (y el XML de Storyboard / modelo si la fase lo toca)
2. `xcodebuild ... build` — cero errores antes de seguir
3. Instalar y lanzar en el simulador, y verificar con screenshot lo que la fase dice en "Funcional"
4. Recien ahi marcar `[x]` y pasar a la siguiente fase

Comando de build de referencia (desde la raiz del repo):

```
xcodebuild -project InventarioApp.xcodeproj -scheme InventarioApp \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

Si aparece un crash, lo primero a revisar sigue siendo que los nombres del Storyboard/modelo coincidan exactamente con los que el `@IBOutlet`/`@IBAction`/`@NSManaged` del codigo Swift espera.

---

## Fase 0 — Setup del proyecto

- [x] Repo `inventario-ios` en GitHub (`https://github.com/JasonDavD/inventario-ios`), rama `main`
- [x] `InventarioApp.xcodeproj` en la raiz del repo (target UIKit + Storyboard, Swift 5, iOS 18.0). Escrito a mano, no con el wizard — el `.pbxproj` usa `objectVersion = 77`
- [x] File system synchronized group apuntando a `InventarioApp/`: los archivos entran al target por estar en la carpeta, sin listarlos uno por uno en el `.pbxproj`
- [x] `App/AppDelegate.swift`, `App/SceneDelegate.swift`, `Resources/Assets.xcassets`, `Main.storyboard` y `LaunchScreen.storyboard` base
- [x] `Resources/Info.plist` explicito con el `UIApplicationSceneManifest` completo (ver nota abajo), excluido del copiado de recursos con `membershipExceptions` para que no se duplique en el bundle
- [x] **Funcional:** `BUILD SUCCEEDED`; los 13 `.swift` compilan y ambos storyboards entran al bundle como `.storyboardc`
- [x] **Probado:** corre en el simulador iPhone 16e, verificado por screenshot

> **Nota — por que el `Info.plist` es explicito y no autogenerado.** Con `GENERATE_INFOPLIST_FILE = YES` + `INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES`, Xcode genera el manifest con `UISceneConfigurations` **vacio**. Sin esa entrada UIKit no asocia el `SceneDelegate` ni `Main.storyboard` a la escena: la app levanta con la ventana sin root view controller y se ve una pantalla negra, sin ningun error en el build ni en consola. La solucion es el `Info.plist` a mano con `UISceneDelegateClassName = $(PRODUCT_MODULE_NAME).SceneDelegate` y `UISceneStoryboardFile = Main`.

## Fase 1 — Stack de Core Data

- [x] `CoreData/PersistenceController.swift`: carga `InventarioModel` desde el `.xcdatamodeld` (no arma el modelo en codigo), `NSPersistentContainer`, `saveContext()`
- [x] `InventarioModel.xcdatamodeld` con las 4 entidades del esquema de abajo, Codegen = "Class Definition" en cada una (`codeGenerationType="class"` en el XML) — `momc` genera las clases `NSManagedObject`, no hay `.swift` a mano para eso
- [x] Reenganchado `PersistenceController.shared.saveContext()` en `SceneDelegate.sceneDidEnterBackground`
- [x] **Funcional:** insert + `NSFetchRequest` + delete de una `CategoriaEntity` de prueba, y las 4 entidades aparecen en `managedObjectModel.entities`
- [x] **Probado:** corrido en el simulador iPhone 16e, verificado por screenshot

> **Temporal:** `Features/Debug/SmokeTestViewController.swift` es la escena que muestra el resultado de esa prueba en pantalla. Fase 2 la reemplaza por la de Login y ese archivo se borra.

> **Sobre los tipos generados.** `apiId` va con `usesScalarValueType="NO"`, asi se genera como `NSNumber?` y se puede distinguir "todavia no sincronizado" (nil) de `apiId = 0`. Los no opcionales (`estadoSync`, `pendienteEliminar`, `precio`, `stock`, `orden`) van con `usesScalarValueType="YES"` y `defaultValueString`, para que se generen como escalares (`Int16`, `Bool`, `Double`, `Int32`) y no fallen la validacion al guardar.

### Esquema de Core Data

Cada entidad lleva estos 4 atributos de control ademas de los propios — mismo patron `estadoSync`/`apiId` que ya usa `inventario-android`:

| Atributo comun | Tipo | Optional |
|---|---|---|
| `localId` | String | No |
| `apiId` | Integer 64 | Si |
| `estadoSync` | Integer 16 | No |
| `pendienteEliminar` | Boolean | No |

**CategoriaEntity:** `nombre` (String), `descripcion` (String, optional). Relacion `productos` → to-many → `ProductoEntity`, inversa `categoria`.

**ProveedorEntity:** `nombre` (String), `telefono` (String, optional), `direccion` (String, optional), `logoUrl` (String, optional), `logoPublicId` (String, optional). Relacion `productos` → to-many → `ProductoEntity`, inversa `proveedor`.

**ProductoEntity:** `nombre` (String), `precio` (Double), `stock` (Integer 32), `fechaRegistro` (Date, optional). Relaciones: `categoria` → to-one → `CategoriaEntity` (inversa `productos`, Delete Rule: Nullify), `proveedor` → to-one → `ProveedorEntity` (inversa `productos`, Delete Rule: Nullify), `imagenes` → to-many → `ProductoImagenEntity` (inversa `producto`, Delete Rule: **Cascade** — borrar un producto borra sus imagenes).

**ProductoImagenEntity:** `url` (String), `publicId` (String), `orden` (Integer 16). Relacion `producto` → to-one → `ProductoEntity` (inversa `imagenes`, Delete Rule: Nullify).

## Fase 2 — Networking (dataTask) + Login

- [x] `Networking/APIClient.swift` reescrito con `URLSession.dataTask(with:completionHandler:)` + `Result<T, APIError>`, agrega header `Authorization`, decodifica JSON, mapea errores HTTP, timeout 90s (arranque en frio de Render), despacha todos los `completion` a `DispatchQueue.main`
- [x] `Networking/Endpoint.swift`, `APIError.swift` (sin cambios, movidos a `Networking/` sin tocar contenido)
- [x] `Auth/KeychainService.swift` (sin cambios, movido a `Auth/` sin tocar contenido)
- [x] `Auth/SessionManager.swift` reescrito sin Combine/`ObservableObject` — singleton simple con propiedades planas
- [x] `Services/AuthService.swift` (login con completion handler)
- [x] `Features/Auth/LoginViewController.swift` + `LoginViewModel.swift` (closures, sin Combine)
- [x] Escena de Login en `Main.storyboard`, `Custom Class` = `LoginViewController`, Initial View Controller (reemplaza la escena placeholder de Fase 0). Los elementos van dentro de un `UIStackView` vertical centrado. Elementos y conexiones:

  | Elemento UI | Tipo | Conectar como |
  |---|---|---|
  | Campo usuario | `UITextField` | `@IBOutlet` `usernameField` |
  | Campo password (Secure Text Entry = ON en el Attributes Inspector) | `UITextField` | `@IBOutlet` `passwordField` |
  | Boton "Ingresar" | `UIButton` | `@IBOutlet` `loginButton` **y** `@IBAction` `loginButtonTapped(_:)` en Touch Up Inside |
  | Label de error (texto vacio por default, color rojo) | `UILabel` | `@IBOutlet` `errorLabel` |
  | Indicador de carga | `UIActivityIndicatorView` | `@IBOutlet` `activityIndicator` |

- [x] Fix: `APIClient` mapeaba **todo** 401 a `.unauthorized` ("Sesion expirada"). En el login un 401 es "credenciales malas", no sesion vencida. Ahora solo se mapea a `.unauthorized` si la request iba autenticada; en el login cae en `.server` y se muestra el `mensaje` del backend
- [x] **Funcional (verificado en simulador):** validacion local con campos vacios, indicador de carga activo con el boton deshabilitado durante la request, error de red visible al timeout, y credenciales invalidas muestran "Usuario o password incorrectos" — el mensaje real que manda el backend
- [x] **Funcional:** login exitoso contra produccion con credenciales reales — confirmado por el usuario corriendo la app desde Xcode
- [x] **Probado:** corrido en el simulador iPhone 16e, verificado por screenshot en cada paso

### Rediseño del Login (posterior al cierre de Fase 2)

Se rehizo la escena siguiendo `DESIGN.md`: card blanca sobre fondo `surface`, icono en circulo tonal, labels arriba de cada input, boton charcoal con flecha, divisor y links al pie.

- [x] `DesignSystem/Theme.swift` (colores, radios, espaciado, roles tipograficos) y `DesignSystem/PaddedTextField.swift` (insets, que `UITextField` no expone)
- [x] Ojito para ver/ocultar la contrasena (`eye` / `eye.slash`)
- [x] Check "Mantener sesion iniciada" **con comportamiento real**: tildado guarda el token en Keychain; destildado lo deja solo en memoria y se pierde al cerrar la app. Para eso `APIClient` pasa a leer el token de `SessionManager` y no del Keychain directo
- [x] Links "Recuperar acceso" / "Soporte tecnico": el backend no tiene esos endpoints, asi que abren un alert que lo dice en vez de simular que funcionan
- [x] Borde de foco en `charcoal-deep` al editar un campo, como pide el DESIGN.md
- [x] **Probado:** verificado por screenshot — tipografia por rol, ojito, check y alerts
- [ ] **Sin verificar:** el ajuste de la card cuando sube el teclado. El simulador usa el teclado fisico del Mac y el software no aparece, asi que no se pudo probar. Se prueba en dispositivo o desactivando el teclado fisico (I/O > Keyboard > Connect Hardware Keyboard)

> **Arranque en frio de Render, medido.** Con el servicio dormido, `POST /api/auth/login` no respondio en 90s y la app mostro "No se pudo conectar al servidor" — el timeout de 90s no alcanza. Ya despierto, la misma request responde en ~1.6s. `GET /` despierta el servicio y contesta 302 rapido, asi que sirve como ping de warm-up. A tener en cuenta para el `SyncManager` de Fase 4: conviene despertar el backend antes de sincronizar, o el primer sync del dia va a fallar por timeout.

## Fase 3 — Listado de productos offline-first

- [x] `Models/Inventario/ProductoDTO.swift` con los DTOs Codable de Producto/Categoria/Proveedor/Imagen
- [x] `Networking/FechaAPI.swift`: parseo propio de `fechaRegistro` (ver nota abajo)
- [x] `Services/ProductoService.swift`: lee de Core Data (fuente de verdad local), no directo de la red
- [x] `Sync/SyncManager.swift` con el **paso 3** (GET → upsert local por `apiId`), movido aca desde Fase 4
- [x] `Features/Productos/ProductoListViewController.swift` + `ProductoTableViewCell.swift` (`UITableViewDataSource`/`Delegate`, celda prototipo en el Storyboard con `Identifier` = `ProductoCell`)
- [x] Boton "Sincronizar" en la barra + pull to refresh, estado vacio y alert de error
- [x] Segue `irAProductos` desde el Login a un `UINavigationController`, reemplazando el alert placeholder
- [x] Auto-login al arrancar si hay sesion guardada (ver nota abajo)
- [x] **Funcional:** productos bajados del servidor y guardados en Core Data; **verificado sin servidor alcanzable** — la app arranca, entra y muestra la lista local, y Sincronizar falla con mensaje sin vaciar los datos
- [x] **Probado:** verificado por screenshot y leyendo el SQLite del simulador con `sqlite3`

> **Ajuste de alcance aplicado.** El paso 3 del `SyncManager` (bajada + upsert) se movio de Fase 4 a Fase 3: sin el nada llena Core Data y el listado no se puede demostrar. Fase 4 queda con la subida de pendientes y las bajas. **El orden importa:** cuando existan esos dos pasos tienen que correr ANTES de la bajada, o se pisan los cambios locales sin subir. Mientras tanto el upsert saltea toda fila con `estadoSync == 0` o `pendienteEliminar == true`.

> **`fechaRegistro` necesita parseo propio.** Viene como `2026-08-12T10:15:30`: ISO 8601 **sin zona horaria**, y `JSONDecoder.dateDecodingStrategy = .iso8601` lo rechaza justamente por eso. Una sola fecha que no parsee tumba el listado entero, asi que `FechaAPI` prueba tres formatos. Verificado contra datos reales: el registro quedo en el store con `2026-08-13 01:41:53`.

> **El auto-login no estaba y hacia inutil el check "Mantener sesion iniciada".** El token se guardaba en Keychain pero la app pedia login igual en cada arranque. Ahora `LoginViewController.viewDidAppear` dispara el segue si `SessionManager.isAuthenticated`, una sola vez por arranque.

> **Como se probo el modo offline.** Se apunto `Endpoint.baseURL` a `https://servidor-inalcanzable.invalid` (el TLD `.invalid` no resuelve nunca, por RFC 2606), se compilo y se corrio. Sirve para repetir la prueba sin tocar la red del Mac ni el simulador. **Acordarse de revertir la URL despues.**

## Fase 4 — CRUD local + sincronizacion bidireccional

- [x] `Networking/APIClient.swift`: suma PUT y DELETE, y `RespuestaVacia` para endpoints que contestan 204 sin cuerpo (sin eso, decodificar un body vacio falla aunque la operacion haya salido bien)
- [x] `Models/Inventario/ProductoRequest.swift`: cuerpo de POST/PUT. **No es el mismo shape que `ProductoDTO`** — el backend espera `nombre`, `precio`, `stock` y las relaciones como `{"id": N}`
- [x] `Sync/SyncManager.sincronizar()`: sube pendientes → procesa bajas → baja del servidor, en ese orden
- [x] `Features/Productos/ProductoFormViewController.swift` (alta/edicion), guarda en Core Data con `estadoSync = 0`
- [x] Eliminar producto = soft delete local (`pendienteEliminar = true`) hasta sincronizar. Un producto que nunca llego al servidor (`apiId == nil`) se borra directo
- [x] Chip PENDIENTE en la celda: sin eso la demo de offline no se puede leer
- [x] Reconciliacion de borrados del servidor (ver nota abajo)
- [x] **Funcional:** verificado el ciclo completo leyendo el SQLite en cada paso — alta local (`apiId` NULL, `estadoSync` 0) → sync → POST (`apiId` asignado, `estadoSync` 1); edicion → `estadoSync` 0 con `apiId` intacto → sync → PUT; baja → `pendienteEliminar` 1 con la fila todavia local → sync → DELETE y recien ahi se borra
- [x] **Funcional (offline):** producto creado con el servidor inalcanzable queda PENDIENTE, el sync falla sin perder nada, y al volver la conexion se sube y toma su `apiId`
- [ ] **Pendiente de confirmar:** verlo reflejado en el portal web Thymeleaf. El agente no puede entrar al portal; lo confirma el usuario

> **El orden de los tres pasos es lo que hace que el offline funcione.** Si la bajada corriera primero, pisaria con la version del servidor los cambios locales que todavia no se subieron. Como segunda linea de defensa, el upsert saltea toda fila con `estadoSync == 0` o `pendienteEliminar == true`.

> **Si falla la subida se corta y no se baja nada.** Bajar despues de una subida fallida mostraria la version del servidor como si el cambio local se hubiera perdido, cuando en realidad sigue pendiente.

> **Reconciliacion de borrados.** El upsert tambien borra las filas locales cuyo `apiId` ya no viene del servidor — sin eso, un producto borrado desde el portal web sobrevivia para siempre en el telefono. Solo toca filas con `estadoSync == 1` y `apiId` no nulo.

> **Tercera trampa de `UIButton.Configuration`** (van tres, ver la seccion de Sistema de diseño). Mutar `configuration?.title` por optional chaining no pisa el *state title* que quedo en el Storyboard, y como ese texto suele parecerse al real, el boton muestra un valor viejo que parece correcto. Sintoma real: el selector de categoria decia "Sin categoria" en un producto que SI tenia categoria — y se notaba solo porque el color del texto era el de valor seleccionado y no el de placeholder. Se resolvio con `UIButton.aplicarTitulo(_:estilo:color:)`, que rearma la struct entera y limpia el state title.

## Fase 5 — Imagenes (requiere producto ya sincronizado)

- [ ] `Features/Productos/ProductoDetailViewController.swift` con galeria de imagenes
- [ ] Subida de imagenes solo habilitada si `producto.apiId != nil`
- [ ] **Funcional:** producto sincronizado permite agregar hasta 5 fotos; producto sin sincronizar no muestra esa opcion
- [ ] **Probado:** pendiente de Mac

## Fase 6 — Categorias y Proveedores (+ logo)

- [ ] Mismo patron offline-first para `CategoriaEntity`/`ProveedorEntity` — CRUD solo ADMIN
- [ ] Subida de logo de proveedor (misma limitacion: requiere `apiId`)
- [ ] **Funcional:** gestion completa de categorias/proveedores, offline y sincronizado
- [ ] **Probado:** pendiente de Mac

## Fase 7 — Roles y pulido final

- [ ] Ocultar/deshabilitar acciones segun rol en las 3 listas
- [ ] Manejo de errores de red consistente + interceptar 401 (logout automatico)
- [ ] README.md del repo `inventario-ios` (setup, capturas, como correrlo)
- [ ] **Funcional:** demo completa de punta a punta contra produccion, con los 3 roles
- [ ] **Probado:** pendiente de Mac

---

## Historial de decisiones

- El plan original (commits `63d4ef3`..`e997f92`) usaba SwiftUI + async/await + sin persistencia local. Se descarto por completo al confirmarse que la rubrica del curso exige UIKit + Core Data + `dataTask`, con el mismo patron offline-first que ya tiene `inventario-android`.
- El primer intento de UIKit (commits `bf4b0cb`, `7b12bd0`) evitaba Storyboard y `.xcdatamodeld` armando todo por codigo (UI programatica, `NSManagedObjectModel` a mano), por no poder validar formatos de GUI de Xcode sin acceso a Mac. Se descarto al confirmarse que el curso enseña especificamente Storyboard + `@IBOutlet` + segues + el editor visual de Core Data, y que hay que trabajar igual. Quedo la division de trabajo de la seccion "Stack": Claude escribe la logica Swift, el usuario arma en Xcode lo que es puramente visual siguiendo instrucciones exactas.
- **2026-08-12 — cae la premisa de "sin Mac".** Se verifico que la Mac de trabajo tiene Xcode 26.3 instalado y funcional (solo faltaba apuntar `xcode-select`, que seguia en las Command Line Tools). Con eso se puede compilar, correr en simulador y verificar por screenshot desde la propia sesion. Decision del usuario: Claude escribe tambien el Storyboard y el `.xcdatamodeld` (son XML, y ahora se validan compilando y corriendo), y el usuario los revisa/ajusta en Xcode. Se reescribieron las secciones "Division de trabajo", "Convencion de checklist" y "Metodo de trabajo por fase" en consecuencia. Fase 0 quedo cerrada el mismo dia.
- **Ajuste de alcance entre Fase 3 y Fase 4 (pendiente de aplicar).** Fase 3 como esta escrita no es demostrable: pide una lista que lee de Core Data como fuente de verdad, pero nada llena Core Data hasta Fase 4. La propuesta es mover el paso 3 del `SyncManager` (GET del servidor → upsert local por `apiId`) a Fase 3, dejando Fase 4 con solo subida de pendientes y bajas. Asi Fase 3 cierra con algo verificable de punta a punta: bajar productos, cortar la red, y ver que la lista sigue.
