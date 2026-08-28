extends Node2D
class_name Profesora

## La profesora tiene un ciclo de estados (ver punto 8 del documento):
## NO_MIRA -> ADVERTENCIA -> MIRA -> ADVERTENCIA -> NO_MIRA -> (repetir)
## En este prototipo (v0.1) el ciclo automatico todavia no esta implementado
## (eso corresponde a la Version 0.2); por ahora solo existe el estado y su color.

enum Estado {
	NO_MIRA,     ## Verde: el jugador puede crear el machete con tranquilidad.
	ADVERTENCIA, ## Amarillo: esta por darse vuelta.
	MIRA,        ## Rojo: esta mirando a los alumnos.
}

const COLOR_NO_MIRA := Color(0.25, 0.8, 0.35)
const COLOR_ADVERTENCIA := Color(0.95, 0.85, 0.2)
const COLOR_MIRA := Color(0.85, 0.2, 0.2)

@export var estado: Estado = Estado.NO_MIRA:
	set(value):
		estado = value
		_actualizar_color()

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	_actualizar_color()


func _actualizar_color() -> void:
	if not is_instance_valid(visual):
		return
	match estado:
		Estado.NO_MIRA:
			visual.color = COLOR_NO_MIRA
		Estado.ADVERTENCIA:
			visual.color = COLOR_ADVERTENCIA
		Estado.MIRA:
			visual.color = COLOR_MIRA


func esta_mirando() -> bool:
	return estado == Estado.MIRA
