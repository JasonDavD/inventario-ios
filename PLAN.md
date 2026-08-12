# Inventario iOS - Ferreteria Zamora

App iOS que consume la API REST de [`inventario-backend`](../inventario-backend) (Spring Boot + JWT + roles ADMIN/OPERADOR/LECTOR). Cliente independiente, sin relacion con el proyecto Android del mismo curso — aunque replica su mismo patron de sincronizacion offline-first.

**Requisito de curso (rubrica):** UIKit clasico (`UITableView`, `UITableViewCell`, `UITableViewDataSource`, `UITableViewDelegate`), Core Data (`NSManagedObjectModel`, `NSManagedObjectContext`, `NSPersistentStoreCoordinator`, `NSPersistentContainer`, `NSFetchRequest`) y `URLSession` con `dataTask` (completion handlers, no async/await). No SwiftUI.

## Stack

- UIKit con **Storyboard + `@IBOutlet`/`@IBAction` + segues** (asi se enseña en el curso — ver division de trabajo abajo)
- Patron MVVM: ViewModel con closures de callback (no Combine/`@Published`), ViewController implementa `UITableViewDataSource`/`Delegate` y se subscribe a los closures
- Core Data **con el modelo armado en el editor visual** (`InventarioModel.xcdatamodeld`) — ver esquema exacto mas abajo
- `URLSession` + `dataTask(with:completionHandler:)`
- Keychain para el JWT (sin cambios respecto al planteo original)

### Division de trabajo — por que algunas cosas las armas vos en Xcode

Storyboard, segues y `.xcdatamodeld` son formatos editados por GUI en Xcode. Este plan se escribe desde un entorno sin Xcode disponible, sin forma de abrir/validar esos archivos — escribirlos a mano a ciegas es un riesgo real de corrupcion. Como el curso los enseña asi (y son requisito), la division queda:

- **Claude escribe:** toda la logica Swift — `ViewController`s con los `@IBOutlet`/`@IBAction` ya declarados con nombres exactos, `ViewModel`s, `Service`s, Core Data, networking. Cada fase incluye el nombre exacto de cada outlet/accion/segue que el `ViewController` espera.
- **El usuario arma en Xcode:** las escenas del Storyboard (arrastrar UI, poner `Custom Class`, conectar outlets/acciones con Ctrl+arrastrar), los segues entre escenas (con el `Identifier` exacto que el codigo espera), y las entidades/atributos/relaciones en el editor visual de `InventarioModel.xcdatamodeld` (esquema exacto mas abajo, con Codegen en "Class Definition" — asi Xcode genera las clases `NSManagedObject` solo, sin archivos `.swift` manuales para eso).

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
├── Main.storyboard             armado en Xcode por el usuario (todas las escenas + segues)
├── CoreData/
│   ├── InventarioModel.xcdatamodeld   armado en Xcode por el usuario (editor visual, esquema abajo)
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
└── Resources/                   Assets.xcassets, Info.plist
```

## Convencion de checklist

`[ ]` pendiente, `[~]` escrito pero no compilado/verificado, `[x]` verificado de verdad en Xcode. Esta sesion corre sin acceso a Mac — ningun `[x]` de "Funcional"/"Probado" hasta que el usuario lo corra.

## Como ayudar una vez que hay Mac disponible

Cuando el usuario tenga Xcode abierto y quiera conectar Storyboard/segues/`.xcdatamodeld`, el agente (esta sesion u otra) **no debe tirar la lista de pasos entera de una** — el agente no puede clickear Xcode, el usuario si. El modo que funciona:

1. Un paso concreto por vez ("Object Library (Cmd+Shift+L), arrastra un UITextField al canvas")
2. Esperar confirmacion del usuario antes de seguir al siguiente paso
3. Usar los nombres EXACTOS de outlets/actions/segues/entidades que ya estan en este archivo (Fase 1 tiene el esquema de Core Data completo; cada fase siguiente especifica los nombres de outlets/actions al lado del `ViewController` correspondiente)
4. Si el usuario reporta un error o crash al correr, revisar primero que los nombres conectados en Xcode coincidan exactamente con los que el `@NSManaged`/`@IBOutlet`/`@IBAction` del codigo Swift espera — la causa mas comun de crash en este flujo es un typo entre lo que se conecto a mano en Xcode y lo que el codigo referencia

---

## Fase 0 — Setup del proyecto

- [x] Repo `inventario-ios` en GitHub (`https://github.com/JasonDavD/inventario-ios`), rama `main`
- [ ] **Bloqueado hasta tener Mac.** File > New Project > iOS > App. Product Name: `InventarioApp`. Interface: **Storyboard**. Guardar DENTRO de esta carpeta del repo (ya tiene `.git`, no crear uno nuevo)
- [ ] Estructura de carpetas del repo agregada como grupos en Xcode (file system synchronized groups, default en Xcode 16+)
- [ ] **Funcional:** la app compila y corre en el simulador con la pantalla default del template
- [ ] **Probado:** confirmado en Xcode por el usuario

## Fase 1 — Stack de Core Data

- [~] `CoreData/PersistenceController.swift`: carga `InventarioModel` desde el `.xcdatamodeld` (no arma el modelo en codigo), `NSPersistentContainer`, `saveContext()`
- [ ] **Bloqueado hasta tener Mac — armar en el editor visual** (`InventarioModel.xcdatamodeld`, File > New > Core Data Model si el wizard no lo creo solo): las 4 entidades del esquema de abajo, con Codegen = "Class Definition" en cada una (asi Xcode genera las clases `NSManagedObject` solo, no hace falta escribirlas a mano)
- [ ] **Funcional:** insertar y leer un registro de prueba (`NSFetchRequest`) confirma que el stack levanta sin crashear
- [ ] **Probado:** pendiente de Mac

### Esquema de Core Data (armar en el editor visual)

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

- [ ] `Networking/APIClient.swift` reescrito con `URLSession.dataTask(with:completionHandler:)`, agrega header `Authorization`, decodifica JSON, mapea errores HTTP
- [ ] `Networking/Endpoint.swift`, `APIError.swift` (siguen del planteo anterior, agnosticos a UI)
- [ ] `Auth/KeychainService.swift` (sin cambios — ya escrito, no depende de SwiftUI)
- [ ] `Auth/SessionManager.swift` reescrito sin Combine/`ObservableObject` (singleton simple con propiedades planas)
- [ ] `Services/AuthService.swift` (login con completion handler)
- [ ] `Features/Auth/LoginViewController.swift` (con `@IBOutlet`/`@IBAction` declarados) + `LoginViewModel.swift` (closures)
- [ ] **Bloqueado hasta tener Mac:** armar la escena de Login en `Main.storyboard` — dos `UITextField` (usuario/password) + un `UIButton`, `Custom Class` de la escena = `LoginViewController`, conectar los outlets/action con los nombres exactos que declara el codigo, marcarla como Initial View Controller
- [ ] **Funcional:** loguearse contra produccion, token en Keychain, error visible con credenciales invalidas, arranque en frio no se percibe como colgada
- [ ] **Probado:** pendiente de Mac

## Fase 3 — Listado de productos offline-first

- [ ] `Models/ProductoDTO.swift` + equivalentes de Categoria/Proveedor/Imagen (DTOs Codable del JSON de la API)
- [ ] `Services/ProductoService.swift`: lee de Core Data (fuente de verdad local), no directo de la red
- [ ] `Features/Productos/ProductoListViewController.swift` + `ProductoTableViewCell.swift` (`UITableViewDataSource`/`Delegate`, celda con `Identifier`/`Style`/`Class` programaticos)
- [ ] Boton "Sincronizar" que dispara `SyncManager` (placeholder en esta fase, logica completa en Fase 4)
- [ ] **Funcional:** ver productos guardados localmente en una `UITableView`, funciona sin conexion (si hay datos previos)
- [ ] **Probado:** pendiente de Mac

## Fase 4 — CRUD local + sincronizacion bidireccional

- [ ] `Sync/SyncManager.swift`: sube pendientes (`estadoSync == 0`), procesa bajas (`pendienteEliminar`), baja del servidor y hace upsert local — mismo patron que `insertarDesdeApi`/`actualizarDesdeApi`/`marcarSincronizado` de Android
- [ ] `Features/Productos/ProductoFormViewController.swift` (alta/edicion), guarda primero en Core Data con `estadoSync = 0`
- [ ] Eliminar producto = soft delete local (`pendienteEliminar = true`) hasta sincronizar
- [ ] **Funcional:** crear/editar/eliminar un producto sin conexion, despues sincronizar y verlo reflejado en el portal web Thymeleaf
- [ ] **Probado:** pendiente de Mac

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
