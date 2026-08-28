extends Node2D

## Version 0.1 - Aula
## Arma la escena: 1 jugador central, 8 companeros alrededor (grilla 3x3)
## y 1 profesora frente a todos. Sin gameplay todavia (eso empieza en v0.2).

const JugadorScene := preload("res://scenes/Jugador.tscn")
const CompaneroScene := preload("res://scenes/Companero.tscn")
const ProfesoraScene := preload("res://scenes/Profesora.tscn")

## Distancia entre el centro de un banco y el siguiente.
const SEPARACION := 220.0

@onready var label_tiempo: Label = $UI/LabelTiempo
@onready var label_machetes: Label = $UI/LabelMachetes

var jugador: Jugador
var profesora: Profesora
var companeros: Array[Companero] = []


func _ready() -> void:
	_crear_profesora()
	_crear_jugador()
	_crear_companeros()
	_actualizar_ui_placeholder()


func _crear_profesora() -> void:
	profesora = ProfesoraScene.instantiate()
	profesora.position = Vector2(0, -SEPARACION * 1.6)
	add_child(profesora)


func _crear_jugador() -> void:
	jugador = JugadorScene.instantiate()
	jugador.position = Vector2.ZERO
	add_child(jugador)


func _crear_companeros() -> void:
	# offset en unidades de grilla (columna, fila) -> direccion correspondiente.
	var mapa := {
		Vector2i(-1, -1): Companero.Direccion.ARRIBA_IZQUIERDA,
		Vector2i(0, -1): Companero.Direccion.ARRIBA,
		Vector2i(1, -1): Companero.Direccion.ARRIBA_DERECHA,
		Vector2i(-1, 0): Companero.Direccion.IZQUIERDA,
		Vector2i(1, 0): Companero.Direccion.DERECHA,
		Vector2i(-1, 1): Companero.Direccion.ABAJO_IZQUIERDA,
		Vector2i(0, 1): Companero.Direccion.ABAJO,
		Vector2i(1, 1): Companero.Direccion.ABAJO_DERECHA,
	}

	for offset in mapa.keys():
		var companero: Companero = CompaneroScene.instantiate()
		companero.position = Vector2(offset) * SEPARACION
		add_child(companero)
		companero.direccion = mapa[offset]
		companeros.append(companero)


func _actualizar_ui_placeholder() -> void:
	label_tiempo.text = "TIEMPO: 60"
	label_machetes.text = "MACHETES ENTREGADOS: 0 / 5"


## Utilidad para versiones futuras: devuelve el companero que esta
## en una direccion dada (o null si no existe).
func obtener_companero_en(direccion: Companero.Direccion) -> Companero:
	for companero in companeros:
		if companero.direccion == direccion:
			return companero
	return null
