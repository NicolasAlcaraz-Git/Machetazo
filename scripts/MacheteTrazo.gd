extends Node2D
class_name MacheteTrazo

## Efecto decorativo del lanzamiento: la bolita de papel viaja de un punto a
## otro (jugador -> companero). NO bloquea el gameplay: la entrega del machete
## ya ocurrio cuando se instancia esto.

## Bolita de papel arrugado que viaja hasta el companero.
const TEX_PAPEL = preload("res://assets/sprites/papel.png")

## La bola de papel no llena todo el cuadrado de la textura (tiene un poco de
## margen transparente alrededor), asi que se la dibuja un poco mas grande que
## el diametro del circulo que reemplaza para que se vea del mismo tamano.
const ESCALA_PAPEL := 2.3

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
	# La bola de papel viaja centrada en el nodo y crece igual que el circulo
	# viejo (ver _radio y vel_diametro en _process).
	var lado := _radio * ESCALA_PAPEL
	var tam := Vector2(lado, lado)
	draw_texture_rect(TEX_PAPEL, Rect2(-tam * 0.5, tam), false)
