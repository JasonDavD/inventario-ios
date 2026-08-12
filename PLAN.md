# Inventario iOS - Ferreteria Zamora

App iOS (SwiftUI) que consume la API REST de [`inventario-backend`](../inventario-backend) (Spring Boot + JWT + roles ADMIN/OPERADOR/LECTOR). Cliente independiente, sin relacion con el proyecto Android del mismo curso.

## Stack

- Swift + SwiftUI (iOS 17+)
- Patron MVVM (Model / ViewModel / View)
- `URLSession` + `async/await` (sin librerias de networking de terceros)
- Keychain para el JWT (nunca `UserDefaults`)
- `AsyncImage` / `PhotosPicker` nativos de SwiftUI

## Backend consumido

Repo: `inventario-backend`. Base URL local: `http://localhost:8080`. Base URL produccion: `https://ferreteria-zamora-api.onrender.com`.

Login: `POST /api/auth/login` -> `{ token, tokenType, username, roles }`. Header en el resto de los endpoints: `Authorization: Bearer <token>`.

## Estructura de carpetas objetivo

```
InventarioApp/
├── App/                    InventarioAppApp.swift (@main)
├── Core/
│   ├── Networking/         APIClient, Endpoint, APIError
│   └── Auth/                KeychainService, SessionManager
├── Models/                 Producto, Categoria, Proveedor, ProductoImagen, Auth/*
├── Services/                AuthService, ProductoService, CategoriaService, ProveedorService
├── Features/
│   ├── Auth/                LoginView + LoginViewModel
│   ├── Productos/           List, Detail, Form (+ ViewModels)
│   ├── Categorias/
│   └── Proveedores/
├── Shared/Components/       LoadingView, ErrorBanner
└── Resources/                Assets.xcassets
```

## Convencion de checklist

Cada fase tiene tareas tecnicas + un criterio "Funcional" (demoable en el simulador) + un check de "Probado" (corrido de verdad en Xcode, no solo escrito). Una fase no se marca `[x]` completa hasta que el criterio Funcional fue verificado a mano.

---

## Fase 0 — Setup del proyecto

- [ ] Crear el proyecto en Xcode: File > New Project > iOS > App > SwiftUI, product name `InventarioApp`, interface SwiftUI, min iOS 17
- [ ] Armar la estructura de carpetas objetivo (grupos/carpetas reales, no solo grupos virtuales)
- [ ] Repo `inventario-ios` en GitHub, primer commit con el proyecto vacio
- [ ] **Funcional:** la app compila y corre en el simulador mostrando la pantalla default
- [ ] **Probado:** confirmado en Xcode por el usuario

## Fase 1 — Networking + Login funcional

- [ ] `Models/Auth/LoginRequest.swift`, `LoginResponse.swift`
- [ ] `Core/Networking/APIClient.swift` (URLSession generico, agrega header Authorization, decodifica JSON, maneja errores HTTP)
- [ ] `Core/Networking/Endpoint.swift`, `APIError.swift`
- [ ] `Core/Auth/KeychainService.swift` (guardar/leer/borrar el JWT)
- [ ] `Core/Auth/SessionManager.swift` (estado de sesion observable, rol actual, logout)
- [ ] `Services/AuthService.swift` (login)
- [ ] `Features/Auth/LoginView.swift` + `LoginViewModel.swift`
- [ ] **Funcional:** loguearse contra el backend real (local o Render) con admin/operador/lector, token guardado en Keychain, error visible con credenciales invalidas
- [ ] **Probado:** login exitoso + login fallido verificados en el simulador

## Fase 2 — Listado de productos (solo lectura)

- [ ] `Models/Producto.swift`, `Categoria.swift`, `Proveedor.swift`, `ProductoImagen.swift`
- [ ] `Services/ProductoService.swift` (GET /api/productos)
- [ ] `Features/Productos/ProductoListView.swift` + `ProductoListViewModel.swift`
- [ ] Logout desde esta pantalla
- [ ] **Funcional:** ver la lista real de productos de la API, pull-to-refresh, logout vuelve a Login
- [ ] **Probado:** verificado contra datos reales del backend

## Fase 3 — Detalle de producto + galeria de imagenes

- [ ] `Features/Productos/ProductoDetailView.swift`
- [ ] Carrusel de imagenes con `AsyncImage` (usa `producto.imagenes`, ya embebidas en el JSON)
- [ ] Estado vacio prolijo cuando el producto no tiene imagenes
- [ ] **Funcional:** tocar un producto de la lista abre el detalle con sus fotos (o el estado vacio)
- [ ] **Probado:** probado con un producto con imagenes y uno sin imagenes

## Fase 4 — Crear / editar producto (CRUD completo + subida de imagenes)

- [ ] `Features/Productos/ProductoFormView.swift` + `ProductoFormViewModel.swift` (alta y edicion)
- [ ] Selectors de categoria/proveedor (`Picker`)
- [ ] `PhotosPicker` multi-seleccion (hasta 5), sube cada imagen a `POST /api/productos/{id}/imagenes`
- [ ] Manejo del error 400 "limite alcanzado" del backend en la UI
- [ ] Eliminar una imagen puntual (`DELETE /api/productos/{id}/imagenes/{imagenId}`)
- [ ] **Funcional:** dar de alta un producto completo con fotos desde la app, editarlo despues
- [ ] **Probado:** creado un producto real end-to-end, visible en el portal web Thymeleaf tambien

## Fase 5 — Categorias y proveedores (+ logo)

- [ ] `Features/Categorias/CategoriaListView.swift` (+ ViewModel) — CRUD solo ADMIN
- [ ] `Features/Proveedores/ProveedorListView.swift` (+ ViewModel) — CRUD solo ADMIN
- [ ] Subida de logo de proveedor (`POST /api/proveedores/{id}/logo`)
- [ ] **Funcional:** gestion completa de categorias/proveedores desde la app
- [ ] **Probado:** verificado con usuario ADMIN

## Fase 6 — Roles y manejo de errores en toda la app

- [ ] Ocultar/deshabilitar acciones de creacion/edicion/borrado segun `SessionManager.rol` en las 3 listas
- [ ] `Shared/Components/ErrorBanner.swift` reutilizado en todas las vistas
- [ ] Interceptar 401 (token vencido) -> logout automatico y vuelta a Login
- [ ] **Funcional:** loguearse como LECTOR y confirmar que no aparece ningun boton de mutacion; loguearse como OPERADOR y confirmar que faltan las acciones ADMIN-only (categorias/proveedores/borrar producto)
- [ ] **Probado:** probado con los 3 roles

## Fase 7 — Pulido final

- [ ] Loading states consistentes (`LoadingView`) en las 4 listas
- [ ] Revision de Dark Mode
- [ ] README.md del repo `inventario-ios` (setup, capturas, como correrlo)
- [ ] **Funcional:** demo completa de punta a punta contra la API en produccion (Render)
- [ ] **Probado:** demo corrida contra `https://ferreteria-zamora-api.onrender.com`

---

## Estado actual

Backend (`inventario-backend`) ya tiene: JWT + roles, CRUD de Producto/Categoria/Proveedor, imagenes via Cloudinary (hasta 5 por producto + logo de proveedor). Todo verificado en local y en produccion. iOS arranca desde cero en Fase 0.
