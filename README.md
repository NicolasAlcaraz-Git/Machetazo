# Machetazo

RESUMEN
"Machetazo" es un videojuego 2D de observación y reacción para PC, pensado para jugarse con una réplica de mando arcade compuesta por 1 palanca de 8 direcciones y 1 único botón de acción. Nuestro primer prototipo utiliza formas geométricas simples de colores diferenciados y una vista cenital picada.

El jugador controla a un estudiante ubicado en el banco central de un aula distribuida en forma de cuadrícula. Lo rodean 8 bancos que corresponden exactamente a las 8 direcciones de la palanca, y frente a todos ellos se encuentra la profesora, inicialmente de espaldas al pizarrón. El objetivo del jugador es fabricar "machetes" (apuntes para copiarse en un examen) y hacérselos llegar a los compañeros que estén atentos y preparados para recibirlos, sin ser descubierto por la profesora, antes de que se agote el tiempo.

Desarrollamos el proyecto como prueba de concepto dentro de la materia "Taller de Diseño de Videojuegos 3" para el "Trabajo Práctico 3: Preproducción de Videojuego 2D". Para esta primera etapa de desarrollo creamos 3 niveles/aulas con el objetivo de validar el loop principal de jugabilidad y presentarlo en instancias de búsqueda de financiamiento e inversión.

Link de descarga al ejecutable: https://drive.google.com/file/d/1ycGYD8WsErSfMeLg9Cqiyz0MLY6vL0jd/view?usp=sharing 

---

## Cambios y agregados (v0.7)

Esta versión agrega un **tutorial guiado** que enseña la mecánica antes de
jugar los niveles reales, y corrige dos errores que dejaban el juego congelado
o sin ayudas visibles.

### Tutorial (`scenes/TutorialAula.tscn` + `scripts/TutorialAula.gd`)

Un nivel aparte, con los **8 compañeros** (uno por cada dirección de la
palanca) pidiendo **1 machete** cada uno, para que completar las tres fases
alcance justo a los 8 machetes de la meta. Se divide en tres etapas:

1. **`MASH` — masheo.** Solo el jugador y la profesora están habilitados.
   Aparecen el botón arcade animado y una flecha indicando que hay que
   spamear la acción. Los compañeros están apagados: todavía no se puede tirar.
2. **`AIM_DELIVER` — apuntado y entrega.** Se encienden los 8 compañeros. Se
   muestra la palanca recorriendo las 8 direcciones y el botón de acción, para
   explicar cómo apuntar y lanzar. Aparecen las **flechas sobre cada compañero
   disponible** (ver más abajo).
3. **`NORMALIZE` — nivel completo.** Al entregar el primer machete de cada
   compañero, la profesora se activa y arranca el nivel normal. Durante esta
   etapa un signo `!` sigue siempre a la profesora: **amarillo** cuando está
   en advertencia y **rojo** cuando está mirando. Las flechas de los compañeros
   siguen apareciendo.

Al ganar, el tutorial pasa al nivel 1. Perder recarga el tutorial.

### Flechas sobre los compañeros

Cada compañero que puede recibir un machete en este momento tiene **una flecha
encima**, y pueden verse varias a la vez. La flecha aparece en los estados
`PREPARADO` (verde) y `ADVERTENCIA` (amarillo), que son los dos válidos para
tirar, y desaparece cuando el compañero pasa a `OCUPADO` (verde oscuro, está
copiando) o `DISTRAIDO` (gris).

Esto funciona **siempre, en todas las partidas**: el tutorial es un nivel más,
no guarda nada en disco y corre exactamente igual cada vez que se entra.

### Correcciones de esta versión

- **El juego ya no se congela al terminar.** El tutorial pausaba el árbol
  (`get_tree().paused`) al mostrar el fin de partida y nunca lo despausaba, así
  que la pantalla de derrota quedaba muda y sin reactions. Ahora todos los
  caminos de salida (volver al menú, reiniciar, pasar de nivel) descartan el
  resultado, restauran `get_tree().paused = false` y limpian los estados de la
  UI antes de cambiar de escena.
- **Las flechas y los signos ya se ven.** Los indicadores se dibujaban en un
  `CanvasLayer` usando coordenadas del mundo, así que caían fuera de la
  pantalla. Ahora las posiciones pasan por
  `get_viewport().get_canvas_transform()` antes de usarse.
- **Las flechas son un pool reutilizable** en vez de una sola instancia que se
  turnaba entre compañeros: así puede haber varias visibles al mismo tiempo.
- **Los compañeros solo se activan si tenés machetes en mano.** Ahora es una
  regla de **todos** los niveles, no solo del tutorial: mientras estás masheando
  el set (`ESPERANDO` / `CREANDO`) los 8 compañeros están en gris y no hay a
  quién apuntarle. En cuanto completás la barra de creación y tenés machetes en
  mano, arranca la pausa normal de activaciones del nivel y se abren ventanas
  verdes como siempre. Al entregar el último machete del set, los que estaban
  verdes **se apagan al instante**.
  - Es el export `companeros_solo_con_machetes_en_mano` de `scripts/Aula.gd`,
    que está en `true` por defecto. Los tres niveles usan `Aula.gd`, así que
    el cambio se aplicó una sola vez. El tutorial lo hereda sin tocar nada (su
    fase 1 es el caso extremo: todavía no tenés machetes).
  - Efecto en la dificultad: el masheo deja de ser un tramo donde hay presión
    de timing, pero con el set lleno vas a ver entre uno y dos segundos de
    pausa antes de que alguien se ponga verde (en los niveles 1 y 2).
  - El buchón del nivel 2 y las extensiones del nivel 3 no cambian: siguen
    mirando y siguen azules respectivamente.
- **Las flechas ya no desaparecen para siempre.** Antes el tutorial guardaba en
  `user://tutorial_progress.cfg` que las ayudas ya se habían visto, y a partir de
  la segunda partida la bandera `arrow_ready_shown` apagaba las flechas para
  siempre (el signo de la profesora no dependía de esa bandera, por eso seguía
  funcionando). Ahora no hay ningún archivo de progreso: el tutorial siempre
  muestra los mismos indicadores.
- Se reemplazó `Image.create()` (deprecado en Godot 4.3+) por
  `Image.create_empty()`.
- `scenes/TutorialAula.tscn`: `siguiente_escena` apunta a `scenes/Aula.tscn`
  y el HUD arranca con la meta correcta (`0 / 8`).
- `scenes/MenuNiveles.tscn`: se corrigió el `uid` del script, que no coincidía
  con `scripts/MenuNiveles.gd.uid`.
- Se eliminó el `.uid` inventado de `scripts/Buchon.gd` para que Godot lo
  regenere correctamente.

Sin tocar: la lógica de juego de los niveles 1, 2 y 3.

---

## Cambios y agregados (v0.6)

Esta versión agrega una **pantalla inicial de selección de nivel** y deja al
juego funcionando igual que siempre desde cualquier nivel.

### Menu de seleccion de nivel (nuevo)

- Nueva escena `scenes/MenuNiveles.tscn` + script `scripts/MenuNiveles.gd`.
- Pantalla simple con título, subtítulo y **botones por nivel**:
  - `TUTORIAL` -> `scenes/TutorialAula.tscn` (agregado en v0.7)
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
los niveles y el temporizador.

---

## Estado actual del juego

- Arranca en el menú de selección de nivel.
- Hay un **tutorial** jugable (`TutorialAula.tscn`): los 8 compañeros piden
  1 machete cada uno y el nivel se divide en tres etapas (masheo, apuntado y
  entrega, y juego completo con la profesora activa). Es siempre igual: no
  guarda progreso ni esconde los indicadores entre partidas.
- Hay **3 niveles jugables**, todos con la misma mecánica base (masheo +
  apuntado 8 direcciones + entrega de machetes), y cada uno agrega algo:
  - **Nivel 1** (`Aula.tscn`): aula clásica, 8 compañeros en grilla 3x3.
	Introducción a la mecánica, sin buchón ni extensiones.
  - **Nivel 2** (`Aula2.tscn`): igual que el nivel 1 pero entra el
	**buchón**, que vigila desde el banco de abajo y bloquea a compañeros de la
	fila inferior mientras mira.
  - **Nivel 3** (`Aula3.tscn`): aula grande, 15 bancos, activaciones más
	frecuentes (más simultáneos y menos pausa) y los bancos laterales
	"de extensión" que permiten repartir machetes a los bancos extra.
- **Meta del nivel**: entregar los machetes que necesita cada compañero
  (2 o 3 por defecto). Cuando todos quedan agotados, se gana. Si el tiempo llega
  a 0 antes, se pierde.
- **Ritmo del set**: los compañeros solo se activan cuando tenés machetes en
  mano. Masheás con todos en gris, y al terminar el set arrancan a abrirse las
  ventanas verdes. Si entregás todo, los verdes se apagan y vuelta a mashear.
- Ganas -> siguiente nivel (o menú en el caso del nivel 3). Perdés -> se
  reinicia el nivel actual.
- Interfaz: HUD con tiempo, machetes entregados, machetes en mano y
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
  TutorialAula.tscn            Tutorial guiado de 3 etapas (nuevo, v0.7)
  Aula.tscn                    Nivel 1
  Aula2.tscn                   Nivel 2
  Aula3.tscn                   Nivel 3
  Jugador.tscn / Profesora.tscn / Companero.tscn / Buchon.tscn
scripts/
  MenuNiveles.gd               Script del menú de niveles (nuevo, v0.6)
  TutorialAula.gd              Tutorial: fases, pausa, flechas y signos (nuevo, v0.7)
  Aula.gd                      Director de escena + temporizador + fin de partida
  Jugador.gd                   Estados (ESPERANDO/CREANDO/APUNTANDO/EXTENSION)
  Companero.gd                 Estados de atención, agotamiento, extensiones
  Profesora.gd / Buchon.gd     Ciclos de mira/no-mira, bloqueo de compañeros
  MacheteTrazo.gd, BarraProgreso.gd, Cursor.gd, Fondo.gd, Fx.gd
assets/placeholders/           Texturas placeholder (cuadrado / rectángulo)
```

---

## Cómo correr

1. Abrir el proyecto con **Godot 4.7** (GL Compatibility).
2. Presionar **F5** (o Play). Arranca en el menú de selección de nivel, donde
   `TUTORIAL` es el primer botón.

> **No pasarle una escena a `--check-only`.** Ese flag solo funciona junto a
> `--script`; si se le da una escena, Godot abre el juego en headless y se
> queda corriendo para siempre. Para validar sintaxis:
>
> ```
> godot --headless --path . --check-only --script res://scripts/TutorialAula.gd
> ```
>
> Para probar una escena sin dejar procesos colgados, sumar `--quit-after N`
> (frames), que cierra el juego solo al pasar por el frame N.

---

## Notas

- El HUD, los overlays de fin de partida y el menú están generados 100% por
  código (sin escenas extra ni assets), siguiendo el estilo del resto del
  juego.
- Los errores (tirar afuera o golpear a un compañero distraído) restan 5
  segundos al temporizador; golpear a un distraído además hace que la
  profesora mire de inmediato.
- Con la regla de "solo se activan con machetes en mano", durante el masheo no
  hay compañeros a los que pegarle ni a los que entregar: la activación se
  pausa hasta que el set esté listo.
