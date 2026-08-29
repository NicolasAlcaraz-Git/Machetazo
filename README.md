# Machetazo — Prototipo de primer nivel

Prototipo de preproduccion (Godot 4.8) del juego 2D "Machetazo": un
estudiante debe crear y pasar "machetes" (chuletas de examen) a sus
companeros sin que la profesora lo descubra.

## Como abrir el proyecto

1. Abrir Godot 4.8.
2. "Import" -> seleccionar la carpeta `Machetazo/` (donde esta `project.godot`).
3. La escena principal (`scenes/Aula.tscn`) corre automaticamente al presentar Play.

## Estado actual: Version 0.1 — Aula

Segun el orden recomendado en el documento de diseno, esta primera entrega
cubre unicamente:

- [x] Crear la escena (`Aula.tscn`).
- [x] Crear jugador (cuadrado central, azul).
- [x] Crear 8 companeros (cuadrados grises alrededor, uno por cada una de
      las 8 direcciones de la palanca).
- [x] Crear profesora (rectangulo verde, arriba).
- [x] Colocarlos correctamente (grilla 3x3).
- [ ] Sin gameplay todavia (a proposito, segun el documento).

Los colores de companeros/profesora ya reaccionan a su `estado` (export var
en el Inspector), aunque todavia nada los cambia automaticamente: eso es
la Version 0.2 (profesora) y 0.3 (companeros).

### Sprites placeholder (en vez de formas vectoriales)

`Jugador`, `Companero` y `Profesora` usan un nodo `Sprite2D` llamado
`Visual`, con una textura placeholder blanca lisa
(`assets/placeholders/square_placeholder.png` para jugador/companeros,
`rect_placeholder.png` para la profesora) y el color real puesto por
`modulate`. Cuando tengas el arte definitivo, el cambio es: seleccionar el
nodo `Visual` en el Inspector y arrastrar el `.png`/`.aseprite` final al
campo `Texture` (o hacerlo por codigo con `visual.texture = ...`). No hace
falta tocar ningun script ni la logica de estados.

### Posiciones editables a mano

`Jugador`, `Profesora` y los 8 `Companero_*` ya son nodos reales dentro de
`Aula.tscn` (antes se generaban por codigo). Podes abrir la escena en el
editor, seleccionarlos en el panel de escena o hacer click en el viewport
2D, y moverlos con el mouse o cambiando su `Position` en el Inspector — el
cambio queda guardado en la escena.

Ojo con los `Companero_*`: cada uno tiene una propiedad exportada
`Direccion` (Inspector) que indica a que direccion de la palanca
corresponde. Si movés un compañero a otro lugar de la grilla, actualizale
tambien la `Direccion` para que siga siendo coherente con el gameplay que
viene en las proximas versiones.

## Controles (pensados para programarse en las proximas versiones)

Vas a testear con un **joystick comun** (un stick + un solo boton), y el
target final es una **palanca arcade** con un boton. Para que el cambio de
un dispositivo a otro sea trivial, la idea es NO usar el Input Map de
Godot (los archivos de mapeo por eje/boton son fragiles y dependen del
dispositivo) sino leer el joystick directo por codigo:

```gdscript
# Direccion de la palanca (eje analogico -> Vector2)
var eje_x := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
var eje_y := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)

# Boton principal (crear machete / lanzar), con deteccion de flanco
# para contar pulsaciones y no "mantener apretado":
var apretado := Input.is_joy_button_pressed(0, JOY_BUTTON_A)
```

Con un joystick generico, `JOY_BUTTON_A` puede no ser el boton fisico que
esperas: conviene armar una escena de calibracion chiquita que imprima en
pantalla el indice de cada boton/eje al tocarlos, para despues cablear el
indice correcto. Esto lo podemos armar como parte de la Version 0.4/0.5
(cuando entra el boton) — avisame y lo hacemos.

## Roadmap (segun el documento de diseno)

- [x] v0.1 — Aula (esta entrega)
- [ ] v0.2 — Profesora: ciclo automatico NO_MIRA -> ADVERTENCIA -> MIRA -> ADVERTENCIA -> NO_MIRA
- [ ] v0.3 — Companeros: ciclo automatico PREPARADO -> ADVERTENCIA -> DISTRAIDO
- [ ] v0.4 — Creacion: boton, contador 0/10, deteccion de "profesora mirando"
- [ ] v0.5 — Apuntado: cursor, 8 direcciones, control por palanca
- [ ] v0.6 — Lanzamiento: comprobacion de objetivo, contador de entregas
- [ ] v0.7 — Condiciones: temporizador general, derrota, victoria, penalizaciones

## Estructura

```
Machetazo/
├── project.godot
├── assets/
│   └── placeholders/
│       ├── square_placeholder.png   # jugador y companeros
│       └── rect_placeholder.png     # profesora
├── scenes/
│   ├── Aula.tscn        # escena principal, con todos los nodos ya colocados
│   ├── Jugador.tscn
│   ├── Companero.tscn
│   └── Profesora.tscn
└── scripts/
    ├── Aula.gd          # solo recolecta referencias, no crea nada
    ├── Jugador.gd
    ├── Companero.gd
    └── Profesora.gd
```

## Subir a GitHub

Este proyecto ya viene con un repo git local inicializado (con el primer
commit hecho). Para subirlo:

```bash
cd Machetazo
git remote add origin https://github.com/TU_USUARIO/machetazo.git
git branch -M main
git push -u origin main
```
