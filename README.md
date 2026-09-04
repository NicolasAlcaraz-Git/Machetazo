# Machetazo

Prototipo 2D (Godot 4.8) de preproducción de un videojuego de ritmo/sigilo
ambientado en un aula: hay que mashear un "machete" (contador de pulsaciones)
y pasárselo a los compañeros cuando están atentos (verdes) sin que la
profesora te vea.

---

## Cambios y agregados (v0.6)

Esta versión agrega una **pantalla inicial de selección de nivel** y deja al
juego funcionando igual que siempre desde cualquier nivel.

### Menu de seleccion de nivel (nuevo)

- Nueva escena `scenes/MenuNiveles.tscn` + script `scripts/MenuNiveles.gd`.
- Pantalla simple con título, subtítulo y **tres botones**:
  - `NIVEL 1` -> `scenes/Aula.tscn`
  - `NIVEL 2` -> `scenes/Aula2.tscn`
  - `NIVEL 3` -> `scenes/Aula3.tscn`
- Cada botón muestra un detalle corto de qué tiene ese nivel.
- Al elegir un nivel, se carga esa escena **directamente**. A partir de ahí
  el juego corre exactamente igual que antes: misma lógica (`Aula.gd`),
  mismos compañeros, mismo temporizador y mismo fin de partida.
- Se puede jugar con mouse o con palanca/flechas + ENTER.

### Cambios

- `project.godot`: la **escena principal (`run/main_scene`)** ahora es
  `MenuNiveles.tscn` (antes arrancaba directo en `Aula.tscn`).
- `scenes/Aula3.tscn`: el nivel 3 ahora tiene `siguiente_escena` apuntando
  al menú. Al **ganar** el nivel 3 (el último), el juego vuelve al menú de
  selección en vez de reiniciar el nivel 3 solo. Perder sigue recargando el
  nivel actual.
- Los niveles 1 y 2 mantienen su avance normal: ganar el 1 carga el 2, ganar
  el 2 carga el 3.

Sin tocar: toda la lógica de juego (jugador, compañeros, profesora, buchón),
los niveles y el sistema de rachas/temporizador.

---

## Estado actual del juego

- Arranca en el menú de selección de nivel.
- Hay **3 niveles jugables**, todos con la misma mecánica base (masheo +
  apuntado 8 direcciones + entrega de machetes), y cada uno agrega algo:
  - **Nivel 1** (`Aula.tscn`): aula clásica, 8 compañeros en grilla 3x3.
    Introducción a la mecánica, sin buchón ni extensiones.
  - **Nivel 2** (`Aula2.tscn`): igual que el nivel 1 pero entra el
    **buchón**, que vigila el banco de abajo y bloquea a compañeros de la
    fila inferior mientras mira.
  - **Nivel 3** (`Aula3.tscn`): aula grande, 13 bancos, activaciones más
    frecuentes (más simultáneos y menos pausa) y los bancos laterales
    "de extensión" que permiten repartir machetes a los bancos extra.
- **Meta del nivel**: entregar los machetes que necesita cada compañero
  (2 por defecto). Cuando todos quedan agotados, se gana. Si el tiempo llega
  a 0 antes, se pierde.
- Ganas -> siguiente nivel (o menú en el caso del nivel 3). Perdés -> se
  reinicia el nivel actual.
- Interfaz: HUD con tiempo, machetes entregados, machetes en mano, racha y
  barra vertical de preparación, todo generado por código.

---

## Controles

| Acción                            | Control                                         |
|-----------------------------------|-------------------------------------------------|
| Moverse / apuntar (8 direcciones) | Flechas o palanca analógica                     |
| Acción (mashear / tirar / elegir) | Botón de acción (joystick) — esquema arcade     |
| Navegar el menú                   | Flechas / palanca / mouse + ENTER o click       |

La acción única se usa para todo: mashear el machete, lanzarlo al compañero
apuntado y confirmar en el menú.

---

## Estructura del proyecto

```
project.godot                  Config (escena principal = MenuNiveles.tscn)
scenes/
  MenuNiveles.tscn             Pantalla de selección de nivel (nuevo, v0.6)
  Aula.tscn                    Nivel 1
  Aula2.tscn                   Nivel 2
  Aula3.tscn                   Nivel 3
  Jugador.tscn / Profesora.tscn / Companero.tscn / Buchon.tscn
scripts/
  MenuNiveles.gd               Script del menú de niveles (nuevo, v0.6)
  Aula.gd                      Director de escena + temporizador + fin de partida
  Jugador.gd                   Estados (ESPERANDO/CREANDO/APUNTANDO/EXTENSION), rachas
  Companero.gd                 Estados de atención, agotamiento, extensiones
  Profesora.gd / Buchon.gd     Ciclos de mira/no-mira, bloqueo de compañeros
  MacheteTrazo.gd, BarraProgreso.gd, Cursor.gd, Fondo.gd, Fx.gd
assets/placeholders/           Texturas placeholder (cuadrado / rectángulo)
```

---

## Cómo correr

1. Abrir el proyecto con **Godot 4.8** (GL Compatibility).
2. Presionar **F5** (o Play). Arranca en el menú de selección de nivel.

---

## Notas

- El HUD, los overlays de fin de partida y el menú están generados 100% por
  código (sin escenas extra ni assets), siguiendo el estilo del resto del
  juego.
- Los errores (tirar afuera o golpear a un compañero distraído) restan 5
  segundos al temporizador; golpear a un distraído además hace que la
  profesora mire de inmediato y rompe la racha.