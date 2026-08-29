extends Node2D
class_name Profesora

## Version 0.2 - Profesora
## Ciclo automatico (ver punto 8 del documento de diseno):
## NO_MIRA -> ADVERTENCIA -> MIRA -> ADVERTENCIA -> NO_MIRA -> (repetir)
## El documento pide un comportamiento "sencillo y predecible", por eso NO
## hay variacion aleatoria aca (a diferencia de los companeros en v0.3).

enum Estado {
	NO_MIRA,     ## Verde: el jugador puede crear el machete con tranquilidad.
	ADVERTENCIA, ## Amarillo: esta por darse vuelta.
	MIRA,        ## Rojo: esta mirando a los alumnos.
}

const COLOR_NO_MIRA := Color(0.25, 0.8, 0.35)
const COLOR_ADVERTENCIA := Color(0.95, 0.85, 0.2)
const COLOR_MIRA := Color(0.85, 0.2, 0.2)

## Duraciones del ciclo, en segundos. Valores iniciales segun el documento
## (punto 8); ajustalos en el Inspector durante las pruebas.
@export var duracion_no_mira: float = 6.0
@export var duracion_advertencia: float = 2.0
@export var duracion_mira: float = 3.0

## Permite pausar el ciclo automatico (util para debug).
@export var ciclo_activo: bool = true

@export var estado: Estado = Estado.NO_MIRA:
	set(value):
		estado = value
		_actualizar_color()

@onready var visual: AnimatedSprite2D = $Visual

## La secuencia repite ADVERTENCIA dos veces (entrando y saliendo de MIRA),
## tal como lo describe el documento.
var _secuencia: Array[Estado] = [
	Estado.NO_MIRA,
	Estado.ADVERTENCIA,
	Estado.MIRA,
	Estado.ADVERTENCIA,
]
var _indice_secuencia: int = 0
var _tiempo_restante: float = 0.0


func _ready() -> void:
	_actualizar_color()
	_tiempo_restante = _duracion_de(estado)


func _process(delta: float) -> void:
	if not ciclo_activo:
		return

	_tiempo_restante -= delta
	if _tiempo_restante <= 0.0:
		_avanzar_estado()


func _avanzar_estado() -> void:
	_indice_secuencia = (_indice_secuencia + 1) % _secuencia.size()
	estado = _secuencia[_indice_secuencia]
	_tiempo_restante += _duracion_de(estado)


func _duracion_de(valor: Estado) -> float:
	match valor:
		Estado.NO_MIRA:
			return duracion_no_mira
		Estado.ADVERTENCIA:
			return duracion_advertencia
		Estado.MIRA:
			return duracion_mira
	return 1.0


func _actualizar_color() -> void:
	if not is_instance_valid(visual):
		return
	match estado:
		Estado.NO_MIRA:
			visual.modulate = COLOR_NO_MIRA
		Estado.ADVERTENCIA:
			visual.modulate = COLOR_ADVERTENCIA
		Estado.MIRA:
			visual.modulate = COLOR_MIRA


func esta_mirando() -> bool:
	return estado == Estado.MIRA
