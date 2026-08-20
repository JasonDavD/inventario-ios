# Guion de exposicion — Inventario iOS, Ferreteria Zamora

**Duracion objetivo:** 10–12 minutos + preguntas
**Slides:** 14
**Regla de oro:** la slide muestra poco, vos contas el resto. Si una slide tiene mas de 5 lineas, sobra texto.

> **Sobre el caso de negocio:** el escenario "como trabajaban antes" (Slide 2) es un **caso
> supuesto**, armado para el trabajo academico. Es realista y coherente con lo que la app
> resuelve, pero no sale de un relevamiento real. Si te preguntan de donde salio, la respuesta
> honesta es "es el escenario tipico que asumimos para el proyecto" — no lo presentes como
> datos medidos en una ferreteria concreta.

---

## Slide 1 — Portada

**En pantalla:**
- Inventario Ferreteria Zamora
- App iOS de gestion de inventario
- Tu nombre / curso / fecha
- (Si podes, un screenshot del listado de productos de fondo)

**Que decir:**
> "Buenas. Voy a presentar una app iOS de gestion de inventario para una ferreteria.
> Antes de mostrar codigo quiero contarles que problema resuelve, porque casi todas las
> decisiones tecnicas salieron de ahi."

**Tip:** no leas la portada. Arranca hablando.

---

## Slide 2 — El problema

**En pantalla:**
- Una foto o icono de un mostrador / deposito
- 3 bullets cortos, sin parrafos

**Que decir:**
> "Ferreteria Zamora maneja su inventario en una planilla de Excel que vive en la PC del
> mostrador. Cuando hay que contar stock, alguien va al deposito con una hoja impresa, anota a
> mano lo que encuentra, y al final del dia vuelve y lo tipea en la planilla."
>
> "Ese circuito tiene tres agujeros:"
>
> 1. **Se carga todo dos veces.** Una en papel y otra en la computadora. Y entre una y otra
>    se cuelan errores de tipeo, que en stock significa faltantes que no existen o productos
>    que figuran y no estan.
> 2. **El deposito no tiene senal, y el mostrador esta ocupado.** Si un cliente pregunta si
>    hay stock de algo, hay que dejar la caja, ir a la PC y buscarlo en la planilla.
> 3. **Nadie sabe quien toco que.** La planilla la abren varios. Si un precio aparece
>    cambiado o falta un producto, no hay forma de reconstruir que paso ni cuando.

**Tip:** este es el slide mas importante. Si el jurado compra el problema, el resto se
escucha solo.

---

## Slide 3 — La propuesta

**En pantalla:**
- "Un inventario que funciona en el bolsillo, con o sin internet"
- 3 iconos: telefono / nube tachada / candado

**Que decir:**
> "La propuesta es una app de celular con tres condiciones no negociables:
> que funcione sin conexion, que cada persona solo pueda hacer lo que le corresponde,
> y que todo cambio quede registrado."
>
> "Esas tres condiciones son las que van a explicar las decisiones tecnicas de todo lo que sigue."

---

## Slide 4 — Demo (en vivo)

**En pantalla:**
- Solo el titulo: "Veamoslo funcionando"
- (Dejas la slide y pasas al simulador o al telefono)

**Recorrido sugerido — 2 minutos, no mas:**

1. **Login** — entras como `admin`.
2. **Listado de productos** — mostras la lista con las fotos a la izquierda.
3. **Abris un producto** — precio, stock, categoria, proveedor y la galeria de fotos.
4. **Tocas una foto** — se abre a pantalla completa, deslizas entre fotos.
5. **Editas el stock** y guardas — aparece el chip naranja **PENDIENTE**.
6. **Tocas Sincronizar** — el chip desaparece.
7. **Cuenta > Bitacora** — se ve el registro de la edicion que acabas de hacer.

**Que decir mientras lo haces:**
> "Fijense en el chip naranja: eso quiere decir que el cambio ya esta guardado en el telefono
> pero todavia no llego al servidor. La app no espera a la red para dejarte trabajar."

**Tip:** ensayalo dos veces. Si la demo falla en vivo, tene screenshots de respaldo en las
slides siguientes. El backend esta en Render con plan gratuito y **la primera peticion puede
tardar 20–40 segundos** si estuvo dormido: abri la app y hace un login unos minutos antes de
empezar, para despertarlo.

---

## Slide 5 — Como esta armado

**En pantalla:** un diagrama simple, tres cajas y flechas

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   App iOS   │─────▶│  API REST    │─────▶│ PostgreSQL  │
│   (UIKit)   │◀─────│ (Spring Boot)│◀─────│             │
└──────┬──────┘      └──────────────┘      └─────────────┘
       │
       ├──▶ Core Data  (copia local en el telefono)
       ├──▶ Cloudinary (fotos)
       └──▶ Firebase   (bitacora de auditoria)
```

**Que decir:**
> "La app iOS habla con un backend propio en Spring Boot, que es la fuente de verdad del
> negocio. Pero la app **nunca** lee de la red directamente: lee de una base local en el
> telefono. Y hay dos servicios externos: Cloudinary para las fotos y Firebase para el
> historial de cambios."

**Tip:** no te detengas mas de 40 segundos aca. Es un mapa para ubicarse, no el tema.

---

## Slide 6 — La decision central: offline-first

**En pantalla:**
- "La pantalla nunca lee de la red"
- El diagrama del ciclo:

```
  Usuario edita
       │
       ▼
  Core Data  ──── se marca PENDIENTE ────┐
       │                                  │
       ▼                                  ▼
  La pantalla ya muestra el cambio   Sincronizar
                                          │
                                          ▼
                                     Servidor
```

**Que decir:**
> "Esta es la decision que ordena toda la app. Cuando el usuario guarda algo, se escribe en la
> base local del telefono y la pantalla se actualiza al toque. La subida al servidor es un
> segundo momento, independiente."
>
> "El beneficio para el negocio es directo: **la app no se cuelga porque no haya senal**.
> Podes hacer un inventario completo en el deposito sin una barra de senal y despues,
> cuando volves al mostrador, sincronizas."

**Si preguntan por conflictos:**
> "La sincronizacion tiene un orden que no es casual: primero sube lo pendiente, despues
> procesa las bajas, y **recien al final** baja del servidor. Si bajara primero, pisaria los
> cambios locales que todavia no se subieron."

---

## Slide 7 — Roles: quien puede hacer que

**En pantalla:** una tabla de 3 filas

| Rol | Puede |
|---|---|
| **Lector** | Solo mirar |
| **Operador** | Mirar y editar productos, subir fotos |
| **Admin** | Todo, incluido borrar y gestionar usuarios |

**Que decir:**
> "En una ferreteria no todos hacen lo mismo. Un empleado nuevo tiene que poder consultar
> precios y stock, pero no borrar productos ni cambiarle el rol a nadie."
>
> "La app **esconde** lo que no corresponde: si entras como Lector, el boton de agregar no
> existe, y la pantalla te explica por que en vez de dejarte un boton que falla."

**El punto fuerte, decilo:**
> "Ahora, esconder botones no es seguridad: es comodidad. La seguridad real esta en el
> backend, que rechaza la operacion aunque alguien llame a la API por afuera de la app.
> Lo verificamos: entrando como Operador a un endpoint de administracion, el servidor
> responde 403 y la app lo muestra."

**Tip:** este parrafo suele impresionar en la sustentacion, porque muestra que entendiste
la diferencia entre UI y seguridad. No lo saltees.

---

## Slide 8 — Fotos de producto

**En pantalla:** screenshot del listado con miniaturas + el visor a pantalla completa

**Que decir:**
> "En una ferreteria muchos productos se parecen y se llaman casi igual. Una foto resuelve en
> un segundo lo que un nombre no: cada producto acepta hasta 5 fotos, se ven como miniatura en
> el listado y se abren a pantalla completa con zoom."
>
> "Las fotos se guardan en Cloudinary, no en el telefono ni en nuestra base."

**Si preguntan por que las fotos no son offline:**
> "Es una limitacion asumida y esta explicada en pantalla. El servidor necesita el id del
> producto para asociarle la imagen, y un producto creado sin conexion todavia no lo tiene.
> Entonces la app **no ofrece** el boton hasta que el producto sincroniza, y dice por que."

---

## Slide 9 — Firebase: la bitacora

**En pantalla:**
- Screenshot de la pantalla Bitacora
- Al lado, screenshot de la consola de Firebase con el arbol de datos

**Que decir:**
> "Aca esta la parte de Firebase. Cada alta, edicion y baja queda registrada con **que se hizo,
> sobre que, quien y cuando**."
>
> "Lo interesante es que decidimos **no copiar** los productos a Firebase. Si lo hicieramos,
> tendriamos el mismo dato en dos lugares y cuando difieran no hay forma de saber cual tiene
> razon. Entonces la pregunta fue: que informacion no tiene hoy ningun lado. Y la respuesta es
> el historial: el backend sabe que un producto **hoy** cuesta 45 soles, pero no sabe quien le
> puso ese precio ni cuando."

**Cierre del slide:**
> "Para el negocio eso significa poder responder 'quien bajo este precio' o 'quien borro este
> producto', que antes no se podia."

---

## Slide 10 — Como esta hecho por dentro (rapido)

**En pantalla:** 4 bullets, sin explicar

- **UIKit** con Storyboard, `UITableView` y segues
- **Core Data** como fuente de verdad local
- **URLSession** con `dataTask` y completion handlers
- **MVVM**: la pantalla dibuja, el ViewModel decide

**Que decir:**
> "En cuanto al stack: UIKit clasico con Storyboard, Core Data para la persistencia local y
> URLSession con dataTask para la red. El patron es MVVM: el ViewController solo dibuja, y la
> logica vive en el ViewModel."
>
> "Firebase se sumo con su SDK oficial, solo el modulo de base de datos."

**Tip:** 30 segundos. Es la slide que el jurado necesita ver para tildar la rubrica, pero no
es lo que te va a hacer ganar puntos. No te enamores de ella.

---

## Slide 11 — Como lo probamos

**En pantalla:**
- "Nada se dio por hecho sin correrlo"
- 3 bullets

**Que decir:**
> "Todo lo que muestro fue verificado corriendo la app contra el servidor de produccion, no
> solo compilando:"
>
> - "Entramos con usuarios reales de cada rol y confirmamos que el servidor rechaza lo que
>   tiene que rechazar."
> - "Cada foto subida se verifico que llegara a Cloudinary y quedara guardada en la base local."
> - "Los eventos de la bitacora se verificaron en la consola de Firebase."

**Tip:** si te preguntan por tests automatizados, se honesto: la verificacion fue manual y
documentada paso a paso, no hay suite de tests unitarios. Decirlo con claridad vale mas que
inventar.

---

## Slide 12 — Lo que falta

**En pantalla:** 3 bullets, sin dramatismo

- Reglas de Firebase en modo de prueba (abiertas)
- Sin tests automatizados
- Sin reportes ni exportacion de datos

**Que decir:**
> "Para ser honesto con el alcance: la base de Firebase esta con las reglas de prueba abiertas,
> que sirve para el curso pero no para produccion. No hay tests automatizados. Y no hay
> reportes ni exportacion, que es lo primero que pediria el negocio despues de esto."

**Tip:** mostrar los limites da mas credibilidad que ocultarlos, y ademas **te deja elegir
las preguntas**: si vos decis las debilidades, el jurado pregunta sobre esas y ya tenes la
respuesta pensada.

---

## Slide 13 — Proximos pasos

**En pantalla:**
- Cerrar las reglas de Firebase
- Reportes: valorizacion de stock, productos sin movimiento
- Lector de codigo de barras para inventariar mas rapido
- Alertas de stock minimo

**Que decir:**
> "Si esto siguiera, el orden seria: primero cerrar las reglas de Firebase, despues reportes,
> y despues codigo de barras, que es lo que mas tiempo le ahorraria a quien cuenta el stock."

---

## Slide 14 — Cierre

**En pantalla:**
- "Un inventario que funciona donde esta el producto, no donde esta la computadora"
- Link al repositorio

**Que decir:**
> "En resumen: una app que deja trabajar sin conexion, que controla quien puede hacer que, y
> que registra todo cambio. Gracias, quedo atento a las preguntas."

---

# Preguntas probables y como responderlas

**"¿Por que UIKit y no SwiftUI?"**
> Es requisito de la rubrica del curso: UIKit clasico con Storyboard, Core Data y dataTask.
> Ademas es lo que se ve en la materia.

**"¿Por que Firebase si ya tenias un backend?"**
> Justamente por eso no se duplico nada. Firebase guarda la unica informacion que el backend
> no tiene: el historial de cambios. Copiar productos habria creado dos fuentes de verdad.

**"¿Que pasa si dos personas editan lo mismo?"**
> Hoy gana el ultimo que sincroniza. Para el tamano de una ferreteria con dos o tres personas
> operando es aceptable; resolverlo bien requiere versionado en el backend y esta fuera del
> alcance.

**"¿Los datos estan seguros?"**
> El token de sesion se guarda en el Keychain, no en preferencias. Las contrasenas nunca se
> guardan en el telefono. El backend valida los roles en cada peticion. Lo que si esta abierto
> son las reglas de Firebase, y lo mencione como pendiente.

**"¿Cuanto tarda en sincronizar?"**
> Depende del servidor. Esta en Render con plan gratuito, que duerme el servicio tras un rato
> de inactividad, asi que la primera peticion puede tardar hasta 40 segundos. Las siguientes
> son inmediatas.

**"¿Funciona en Android?"**
> Esta app es iOS nativa. Existe un cliente Android separado que consume el mismo backend.

---

# Checklist para el dia

- [ ] Leer la Slide 2 en voz alta hasta que suene tuya (es el escenario que sostiene todo)
- [ ] Despertar el backend de Render **antes** de empezar (abrir la app y loguear)
- [ ] Simulador ya abierto, con sesion de `admin` iniciada
- [ ] Generar 2 o 3 movimientos antes, para que la Bitacora no se vea vacia
- [ ] Screenshots de respaldo por si falla la demo en vivo
- [ ] Ensayar la demo dos veces con cronometro
