extends Node2D
class_name Profesora

## Version 0.2 - Profesora
## Ciclo automatico (ver punto 8 del documento de diseno):
## NO_MIRA -> ADVERTENCIA -> MIRA -> NO_MIRA -> (repetir)
##
## NO_MIRA y MIRA tienen variacion aleatoria (para que el patron no sea
## contable/monotono). ADVERTENCIA a proposito NO varia: el aviso amarillo
## siempre dura lo mismo, y es justamente eso lo que mantiene el nivel
## "facil" pese a que el resto del ciclo ya no es predecible.

enum Estado {
	NO_MIRA,     ## Verde: el jugador puede crear el machete con tranquilidad.
	ADVERTENCIA, ## Amarillo: esta por darse vuelta (duracion fija, confiable).
	MIRA,        ## Rojo: esta mirando a los alumnos.
}

const COLOR_NO_MIRA := Color(0.25, 0.8, 0.35)
const COLOR_ADVERTENCIA := Color(0.95, 0.85, 0.2)
const COLOR_MIRA := Color(0.85, 0.2, 0.2)

## Duraciones base del ciclo, en segundos.
@export var duracion_no_mira: float = 5.0
@export var duracion_advertencia: float = 2.0
@export var duracion_mira: float = 4.0

## Variacion aleatoria (+/- segundos). Notar que ADVERTENCIA no tiene
## variacion propia (ver nota arriba): esa duracion siempre es fija.
@export var variacion_no_mira: float = 3.0
@export var variacion_mira: float = 3.0

## Tiempo (segundos) que la profesora pasa quieta en NO_MIRA al arrancar el
## nivel, antes de que el ciclo automatico empiece a correr. Le da al
## jugador una primera mirada tranquila al aula.
@export var tiempo_inicial_quieto: float = 5.0

## Permite pausar el ciclo automatico (util para debug).
@export var ciclo_activo: bool = true

@export var estado: Estado = Estado.NO_MIRA:
	set(value):
		estado = value
		_actualizar_color()

@onready var visual: AnimatedSprite2D = $Visual

## La secuencia es NO_MIRA -> ADVERTENCIA -> MIRA -> ADVERTENCIA -> (repetir).
## Hay dos ADVERTENCIA: la de "entrada" (va a mirar) y la de "salida" (va a
## dejar de mirar). Asi, despues de MIRA (rojo) siempre viene un amarillo
## antes de volver a NO_MIRA (verde): el ciclo nunca salta directo de rojo
## a verde.
var _secuencia: Array[Estado] = [
	Estado.NO_MIRA,
	Estado.ADVERTENCIA,
	Estado.MIRA,
	Estado.ADVERTENCIA,
]
var _indice_secuencia: int = 0
var _tiempo_restante: float = 0.0


func _ready() -> void:
	_indice_secuencia = 0
	estado = Estado.NO_MIRA
	_actualizar_color()
	_tiempo_restante = max(0.5, tiempo_inicial_quieto)


func _process(delta: float) -> void:
	if not ciclo_activo:
		return

	_tiempo_restante -= delta
	if _tiempo_restante <= 0.0:
		_avanzar_estado()


func _avanzar_estado() -> void:
	_indice_secuencia = (_indice_secuencia + 1) % _secuencia.size()
	estado = _secuencia[_indice_secuencia]
	_tiempo_restante += _duracion_con_variacion(estado)


func _duracion_con_variacion(valor: Estado) -> float:
	match valor:
		Estado.NO_MIRA:
			return max(1.0, duracion_no_mira + randf_range(-variacion_no_mira, variacion_no_mira))
		Estado.MIRA:
			return max(0.5, duracion_mira + randf_range(-variacion_mira, variacion_mira))
		Estado.ADVERTENCIA:
			return duracion_advertencia
	return 1.0


func _actualizar_color() -> void:
	if not is_instance_valid(visual):
		return
	var color: Color
	match estado:
		Estado.NO_MIRA:
			color = COLOR_NO_MIRA
		Estado.ADVERTENCIA:
			color = COLOR_ADVERTENCIA
		Estado.MIRA:
			color = COLOR_MIRA
	Fx.color(visual, color)


func esta_mirando() -> bool:
	return estado == Estado.MIRA


## Interrumpe el ciclo normal y hace que la profesora empiece a "mirar"
## AHORA MISMO (por ejemplo: el machete le pego a un companero distraido,
## sonido de "auch", ella se da vuelta a ver que paso). No causa una
## derrota inmediata por si sola; eso lo decide Jugador.gd si el jugador
## vuelve a arriesgarse mientras ella esta en este estado. Al terminar
## MIRA, retoma la secuencia normal (pasa por ADVERTENCIA como siempre).
func forzar_mira() -> void:
	if estado == Estado.MIRA:
		return # ya esta mirando, no hay nada que forzar
	_indice_secuencia = _secuencia.find(Estado.MIRA)
	estado = Estado.MIRA
	_tiempo_restante = _duracion_con_variacion(Estado.MIRA)
