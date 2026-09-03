extends Control
class_name BarraProgreso

## Barra de progreso (Control + _draw(), sin texturas) para mostrar
## visualmente la preparacion del set de machetes. Se crea por codigo desde
## Aula.gd y se actualiza llamando a "progreso = 0.0..1.0". El relleno se
## interpola suavemente y la barra soporta segmentos (marcas del set).

@export var color_fondo: Color = Color(0.12, 0.12, 0.14, 0.85)
@export var color_relleno: Color = Color(0.85, 0.2, 0.2, 1.0)
@export var color_borde: Color = Color(1, 1, 1, 0.55)
@export var color_segmento: Color = Color(0, 0, 0, 0.4)

## Si esta en true, se llena de abajo hacia arriba (para ponerla parada,
## a un costado de la pantalla). Si esta en false, se llena de izquierda
## a derecha.
@export var vertical: bool = false

## Radio de las esquinas redondeadas.
@export var radio: float = 10.0

## Cantidad de divisiones/segmentos marcados en la barra (0 = ninguno).
## Sirve para visualizar los machetes de cada set.
@export var num_segmentos: int = 0

var progreso: float = 0.0:
	set(value):
		progreso = clamp(value, 0.0, 1.0)

var _progreso_visual: float = 0.0


func _process(delta: float) -> void:
	var velocidad := 6.0
	var nuevo: float = lerpf(_progreso_visual, progreso, min(1.0, velocidad * delta))
	if not is_equal_approx(nuevo, _progreso_visual):
		_progreso_visual = nuevo
		queue_redraw()


func _draw() -> void:
	_dibujar_rect(Rect2(Vector2.ZERO, size), color_fondo, true)

	if _progreso_visual > 0.0:
		var rect: Rect2
		if vertical:
			var alto: float = size.y * _progreso_visual
			rect = Rect2(Vector2(0, size.y - alto), Vector2(size.x, alto))
		else:
			rect = Rect2(Vector2.ZERO, Vector2(size.x * _progreso_visual, size.y))
		_dibujar_rect(rect, color_relleno, true)

	if num_segmentos > 1:
		for i in range(1, num_segmentos):
			var t: float = float(i) / float(num_segmentos)
			if vertical:
				draw_line(Vector2(0, size.y * t), Vector2(size.x, size.y * t),
					color_segmento, 2.0)
			else:
				draw_line(Vector2(size.x * t, 0), Vector2(size.x * t, size.y),
					color_segmento, 2.0)

	_dibujar_rect(Rect2(Vector2.ZERO, size), color_borde, false)


func _dibujar_rect(rect: Rect2, color: Color, relleno: bool) -> void:
	var sb := StyleBoxFlat.new()
	if relleno:
		sb.bg_color = color
	else:
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = color
		sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(radio))
	sb.set_corner_detail(8)
	draw_style_box(sb, rect)
