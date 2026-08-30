extends Control
class_name BarraProgreso

## Barra de progreso simple (Control + _draw(), sin texturas) para mostrar
## visualmente el contador 0/10 de creacion del machete. Se crea por
## codigo desde Aula.gd y se actualiza llamando a "progreso = 0.0..1.0".

@export var color_fondo: Color = Color(0.15, 0.15, 0.15, 0.85)
@export var color_relleno: Color = Color(0.85, 0.2, 0.2, 1.0)
@export var color_borde: Color = Color(1, 1, 1, 0.6)

## Si esta en true, se llena de abajo hacia arriba (para ponerla parada,
## a un costado de la pantalla). Si esta en false, se llena de izquierda
## a derecha (para ponerla horizontal, arriba o abajo de la pantalla).
@export var vertical: bool = false

var progreso: float = 0.0:
	set(value):
		progreso = clamp(value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, color_fondo)

	if progreso > 0.0:
		if vertical:
			var alto_relleno := size.y * progreso
			var origen := Vector2(0, size.y - alto_relleno)
			draw_rect(Rect2(origen, Vector2(size.x, alto_relleno)), color_relleno)
		else:
			var ancho_relleno := size.x * progreso
			draw_rect(Rect2(Vector2.ZERO, Vector2(ancho_relleno, size.y)), color_relleno)

	draw_rect(rect, color_borde, false, 2.0)
