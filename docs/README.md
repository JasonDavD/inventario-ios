# docs

Material de entrega del proyecto.

| Archivo | Que es |
|---|---|
| `Arquitectura-App.pdf` | Como funciona la app por dentro, recorrida por procesos: arrancar, entrar, leer, guardar, sincronizar |
| `Firebase-Implementacion.pdf` | La integracion de Firebase en detalle, archivo por archivo |
| `GUION-EXPOSICION.md` | Guion de 14 slides para la sustentacion |

## Regenerar los PDF

Los dos PDF **se generan por codigo**, no se editan a mano. Si hay que cambiarles algo, se
toca el script y se vuelve a correr:

```
pip3 install reportlab
python3 docs/generar-arquitectura.py
python3 docs/generar-firebase.py
```

Cada script escribe su PDF al lado suyo, sin importar desde que carpeta se lo invoque.

> El escenario de negocio del guion (como trabajaban antes) es un **caso supuesto** armado
> para el trabajo academico, no un relevamiento real. Esta aclarado dentro del propio archivo.
