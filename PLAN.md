# Inventario iOS - Ferreteria Zamora

App iOS que consume la API REST de [`inventario-backend`](../inventario-backend) (Spring Boot + JWT + roles ADMIN/OPERADOR/LECTOR). Cliente independiente, sin relacion con el proyecto Android del mismo curso — aunque replica su mismo patron de sincronizacion offline-first.

**Requisito de curso (rubrica):** UIKit clasico (`UITableView`, `UITableViewCell`, `UITableViewDataSource`, `UITableViewDelegate`), Core Data (`NSManagedObjectModel`, `NSManagedObjectContext`, `NSPersistentStoreCoordinator`, `NSPersistentContainer`, `NSFetchRequest`) y `URLSession` con `dataTask` (completion handlers, no async/await). No SwiftUI.

## Stack

- UIKit **programatico, sin Storyboards** (ver nota tecnica abajo)
- Patron MVVM: ViewModel con closures de callback (no Combine/`@Published` — no forma parte de lo pedido), ViewController implementa `UITableViewDataSource`/`Delegate` y se subscribe a los closures
- Core Data **con el modelo armado 100% en codigo** (`NSManagedObjectModel` via `NSEntityDescription`/`NSAttributeDescription`/`NSRelationshipDescription`), sin archivo `.xcdatamodeld`
- `URLSession` + `dataTask(with:completionHandler:)`
- Keychain para el JWT (sin cambios respecto al planteo original)

### Nota tecnica — por que sin Storyboard ni `.xcdatamodeld`

Ambos son formatos editados por GUI en Xcode (XML de Interface Builder / editor visual de entidades). Este plan se escribe desde un entorno sin Xcode disponible, sin forma de abrir/validar esos archivos. Escribirlos a mano a ciegas es un riesgo real de corrupcion. La alternativa — UIKit programatico y `NSManagedObjectModel` armado en codigo — es una tecnica igual de valida y soportada por Apple, y es texto Swift plano que se puede escribir con confianza sin depender del editor visual.

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
├── App/                       AppDelegate.swift, SceneDelegate.swift (sin Main.storyboard)
├── CoreData/
│   ├── PersistenceController.swift   NSManagedObjectModel armado en codigo + NSPersistentContainer
│   └── Entities/               ProductoEntity, CategoriaEntity, ProveedorEntity, ProductoImagenEntity (NSManagedObject a mano)
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

---

## Fase 0 — Setup del proyecto (sin Storyboard)

- [x] Repo `inventario-ios` en GitHub (`https://github.com/JasonDavD/inventario-ios`), rama `main`
- [ ] **Bloqueado hasta tener Mac.** Pasos exactos para crear el proyecto sin Storyboard (el wizard de Xcode no ofrece "programatico" como opcion directa):
  1. File > New Project > iOS > App. Product Name: `InventarioApp`. Interface: **Storyboard** (unica opcion UIKit del wizard). Guardar DENTRO de esta carpeta del repo (ya tiene `.git`, no crear uno nuevo)
  2. Borrar `Main.storyboard` del proyecto (Move to Trash)
  3. En el target > General > "Main Interface", dejarlo vacio. En Info.plist, borrar la key `UIMainStoryboardFile` / "Main storyboard file base name" si aparece
  4. En `SceneDelegate.swift`, dentro de `scene(_:willConnectTo:options:)`, crear la `UIWindow` y asignar `window.rootViewController` a mano (un `UINavigationController` envolviendo la primera pantalla)
  5. `LaunchScreen.storyboard` se puede dejar como esta (es solo la imagen de arranque, no cuenta como "UI real")
- [ ] Estructura de carpetas del repo agregada como grupos en Xcode (file system synchronized groups, default en Xcode 16+)
- [ ] **Funcional:** la app compila y abre una pantalla en blanco sin storyboard
- [ ] **Probado:** confirmado en Xcode por el usuario

## Fase 1 — Stack de Core Data

- [~] `CoreData/PersistenceController.swift`: `NSManagedObjectModel` armado en codigo (4 entidades + relaciones con inversa), `NSPersistentContainer`, `saveContext()`
- [~] `CoreData/Entities/CategoriaEntity.swift`, `ProveedorEntity.swift`, `ProductoEntity.swift`, `ProductoImagenEntity.swift` (subclases `NSManagedObject` escritas a mano, sin codegen de Xcode)
- [ ] **Funcional:** insertar y leer un registro de prueba (`NSFetchRequest`) confirma que el stack levanta sin crashear
- [ ] **Probado:** pendiente de Mac

## Fase 2 — Networking (dataTask) + Login

- [ ] `Networking/APIClient.swift` reescrito con `URLSession.dataTask(with:completionHandler:)`, agrega header `Authorization`, decodifica JSON, mapea errores HTTP
- [ ] `Networking/Endpoint.swift`, `APIError.swift` (siguen del planteo anterior, agnosticos a UI)
- [ ] `Auth/KeychainService.swift` (sin cambios — ya escrito, no depende de SwiftUI)
- [ ] `Auth/SessionManager.swift` reescrito sin Combine/`ObservableObject` (singleton simple con propiedades planas)
- [ ] `Services/AuthService.swift` (login con completion handler)
- [ ] `Features/Auth/LoginViewController.swift` + `LoginViewModel.swift` (UIKit programatico, closures)
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
