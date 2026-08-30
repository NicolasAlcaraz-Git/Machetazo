extends Node2D
class_name Cursor

## Cursor de apuntado (Version 0.5). Dibuja 4 corchetes en las esquinas de
## un cuadrado, estilo "mira" de camara/enfoque (ver imagen de referencia).
## Verde cuando el objetivo es valido, rojo cuando no.

const COLOR_VALIDO := Color(0.3, 0.9, 0.3)
const COLOR_INVALIDO := Color(0.9, 0.25, 0.25)

## Tamano total del cuadrado que forman los 4 corchetes.
@export var tamano: float = 170.0
## Largo de cada "brazo" del corchete (las dos lineas que salen de cada esquina).
@export var largo_trazo: float = 34.0
@export var grosor: float = 5.0

var _color_actual: Color = COLOR_INVALIDO


func _draw() -> void:
	var m := tamano / 2.0
	_dibujar_esquina(Vector2(-m, -m), Vector2(1, 0), Vector2(0, 1))
	_dibujar_esquina(Vector2(m, -m), Vector2(-1, 0), Vector2(0, 1))
	_dibujar_esquina(Vector2(-m, m), Vector2(1, 0), Vector2(0, -1))
	_dibujar_esquina(Vector2(m, m), Vector2(-1, 0), Vector2(0, -1))


func _dibujar_esquina(origen: Vector2, dir_x: Vector2, dir_y: Vector2) -> void:
	draw_line(origen, origen + dir_x * largo_trazo, _color_actual, grosor)
	draw_line(origen, origen + dir_y * largo_trazo, _color_actual, grosor)


## Llamar cada vez que cambia si el objetivo actual es valido o no.
func actualizar(valido: bool) -> void:
	var nuevo_color := COLOR_VALIDO if valido else COLOR_INVALIDO
	if nuevo_color != _color_actual:
		_color_actual = nuevo_color
		queue_redraw()
