extends Node2D

## Version 0.1 - Aula
## El jugador, la profesora y los 8 companeros ahora son nodos hijos reales
## dentro de Aula.tscn (podes arrastrarlos en el editor para reacomodarlos).
## Este script solo junta las referencias y arma el estado inicial de la UI.

@onready var label_tiempo: Label = $HUD/LabelTiempo
@onready var label_machetes: Label = $HUD/LabelMachetes

@onready var jugador: Jugador = $Jugador
@onready var profesora: Profesora = $Profesora

var companeros: Array[Companero] = []


func _ready() -> void:
	for hijo in $Companeros.get_children():
		if hijo is Companero:
			companeros.append(hijo)

	_actualizar_ui_placeholder()


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
