extends Node2D
class_name MacheteTrazo

## Efecto decorativo del lanzamiento: un destello/trazo que viaja de un
## punto a otro (jugador -> companero). NO bloquea el gameplay: la entrega
## del machete ya ocurrio cuando se instancia esto.

const COLOR_TRAZO := Color(0.95, 0.9, 0.5, 1.0)
const COLOR_DESTELLO := Color(1, 1, 1, 1.0)

@export var vel_diametro: float = 160.0

var _origen: Vector2 = Vector2.ZERO
var _destino: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _duracion: float = 0.18
var _radio: float = 10.0
var _done: bool = false


static func crear(padre: Node2D, origen: Vector2, destino: Vector2) -> void:
	var trazo := MacheteTrazo.new()
	trazo._origen = origen
	trazo._destino = destino
	padre.add_child(trazo)


func _ready() -> void:
	position = _origen
	_done = false


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta / _duracion
	if _t >= 1.0:
		_done = true
		_esperar_y_liberar()
		return
	position = _origen.lerp(_destino, _t)
	_radio += vel_diametro * delta * 0.5
	queue_redraw()


func _esperar_y_liberar() -> void:
	await get_tree().create_timer(0.08).timeout
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _radio, COLOR_TRAZO)
	draw_circle(Vector2.ZERO, _radio * 0.5, COLOR_DESTELLO)
