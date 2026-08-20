# Inventario iOS - Ferreteria Zamora

App iOS en UIKit (Storyboard + Core Data + `URLSession.dataTask`) para el sistema de inventario de Ferreteria Zamora. Consume la API REST de [`inventario-backend`](https://github.com/JasonDavD/inventario-backend) (Spring Boot + JWT + roles ADMIN/OPERADOR/LECTOR).

Es **offline-first**: la UI lee siempre de Core Data, nunca de la red directo. Se puede navegar, dar de alta, editar y borrar sin conexion; los cambios quedan marcados como pendientes y suben en la proxima sincronizacion.

Ver [`PLAN.md`](PLAN.md) para el detalle de arquitectura y el plan por fases, y [`DESIGN.md`](DESIGN.md) para el sistema de diseño.

## Estado

Fases 0 a 7 cerradas. Lo que anda hoy:

- Login contra produccion con JWT en Keychain, y check de "mantener sesion iniciada" con comportamiento real
- Listado de productos, categorias y proveedores en tabs, cada uno offline-first
- CRUD completo de las tres entidades, con chip PENDIENTE para lo que todavia no subio
- Sincronizacion bidireccional: sube pendientes, procesa bajas y baja del servidor, en ese orden
- Fotos de producto (hasta 5) y logo de proveedor, con subida `multipart/form-data` a Cloudinary
- Acciones ocultas segun el rol del usuario, y logout automatico si el token vence

Pendiente: probar con usuarios OPERADOR y LECTOR reales — el gating esta verificado forzando el rol en la app, pero el backend no tiene usuarios de esos roles para probarlo de punta a punta.

## Como correrlo

Requiere Xcode 26.3 o superior. Abrir `InventarioApp.xcodeproj` y correr con Cmd+R, o desde la terminal:

```
xcodebuild -project InventarioApp.xcodeproj -scheme InventarioApp \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

**Se trabaja siempre contra produccion** (`https://ferreteria-zamora-api.onrender.com`); no hace falta levantar el backend. Render duerme el servicio tras un rato de inactividad, asi que **la primera request del dia puede tardar 20-40s o incluso fallar por timeout**. Si el login da "No se pudo conectar al servidor", esperar unos segundos y reintentar: el primer intento despierta el servicio.

Para apuntar a un backend local, cambiar `Endpoint.baseURL` en [`Networking/Endpoint.swift`](InventarioApp/Networking/Endpoint.swift) (y agregar una excepcion de ATS en el `Info.plist`, porque `localhost` va por http).

## Como esta armado

```
InventarioApp/
├── App/            AppDelegate, SceneDelegate
├── Auth/           Keychain y sesion
├── CoreData/       modelo .xcdatamodeld y el stack
├── DesignSystem/   Theme y estilos compartidos (traduccion del DESIGN.md)
├── Models/         DTOs Codable de la API
├── Networking/     APIClient (dataTask), Endpoint, descarga de imagenes
├── Services/       lectura/escritura en Core Data
├── Sync/           SyncManager
└── Features/       una carpeta por pantalla, MVVM con closures
```

Dos decisiones que explican casi todo lo demas:

- **Core Data es la fuente de verdad de la UI.** Ninguna pantalla lee de la red. Toda escritura local deja la fila en `estadoSync = 0` y el `SyncManager` la levanta despues.
- **El orden de la sincronizacion no es casual.** Primero sube lo pendiente, despues procesa las bajas, y recien al final baja del servidor. Si bajara primero, pisaria los cambios locales que todavia no se subieron.

Las imagenes son la excepcion: se suben online y en el momento, porque el backend las asocia al recurso por su id y no hay forma de encolarlas sin `apiId`. Un producto creado sin conexion no ofrece agregarle fotos hasta que sincroniza, y la pantalla explica por que.

## Bitacora en Firebase

La app guarda **una** entidad fuera de Core Data y fuera del backend propio: la bitacora de auditoria, en **Firebase Realtime Database**. Cada alta, edicion o baja de producto, categoria o proveedor deja una entrada con que se hizo, quien lo hizo y cuando. Se ve en Cuenta - Bitacora, solo para ADMIN.

Se eligio una entidad que ninguna de las otras dos fuentes tiene: el backend guarda el estado actual de cada registro, la bitacora guarda como se llego a el. Asi no hay dos fuentes de verdad para el mismo dato.

**Se usa el SDK oficial** (`firebase-ios-sdk`, solo el producto `FirebaseDatabase`), agregado por Swift Package Manager. Xcode lo resuelve solo al abrir el proyecto. La configuracion sale del `GoogleService-Info.plist` (`Resources/`) via `FirebaseApp.configure()`, asi que no hay ninguna URL de Firebase escrita en el codigo.

El resto de la app no cambia: todo el consumo del backend de Spring sigue con `URLSession` y `dataTask`. El SDK se usa unicamente para Firebase.

> Las reglas de la base estan en modo de prueba (abiertas). Es una app de curso y no guarda datos reales de clientes.

## Curso

Desarrollo de Aplicaciones Moviles I - CIBERTEC (Ciclo V)

Requisito de la rubrica: UIKit clasico (`UITableView`, `UITableViewDataSource`/`Delegate`), Core Data (`NSPersistentContainer`, `NSFetchRequest`) y `URLSession` con `dataTask` y completion handlers. Sin SwiftUI, sin async/await, sin Combine.
