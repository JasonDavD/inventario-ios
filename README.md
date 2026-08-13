# Inventario iOS - Ferreteria Zamora

App iOS en UIKit (Storyboard + Core Data + `URLSession.dataTask`) para el sistema de inventario de Ferreteria Zamora. Consume la API REST de [`inventario-backend`](../inventario-backend) (Spring Boot + JWT + roles ADMIN/OPERADOR/LECTOR).

Ver [`PLAN.md`](PLAN.md) para el detalle completo de arquitectura, estructura de carpetas y el plan de desarrollo por fases (con checklist de progreso).

## Estado

En desarrollo, Fase 0 cerrada: el proyecto compila y corre en el simulador. Ver la seccion "Convencion de checklist" en `PLAN.md` para el significado de cada estado (`[ ]` / `[~]` / `[x]`).

## Como correrlo

Requiere Xcode 26.3 o superior. Abrir `InventarioApp.xcodeproj` y correr con Cmd+R, o desde la terminal:

```
xcodebuild -project InventarioApp.xcodeproj -scheme InventarioApp \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

## Curso

Desarrollo de Aplicaciones Moviles I - CIBERTEC (Ciclo V)
