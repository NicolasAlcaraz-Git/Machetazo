extends Node2D
class_name Profesora

## Version 0.4 - Profesora
## Ciclo: NO_MIRA -> ADVERTENCIA -> MIRA -> NO_MIRA -> (repetir)
##
## NO_MIRA (verde): seguro, el jugador puede actuar.
## ADVERTENCIA (amarillo parpadea 3 veces): advertencia, NO detecta.
## MIRA (rojo): esta mirando, cualquier accion = derrota.
## La vuelta de MIRA va directo a NO_MIRA (sin pasar por amarillo).

enum Estado {
	NO_MIRA,     ## Verde: seguro.
	ADVERTENCIA, ## Amarillo parpadeante: solo advertencia, NO detecta.
	MIRA,        ## Rojo: esta mirando, detecta acciones.
}

const COLOR_NO_MIRA := Color(0.25, 0.8, 0.35)
const COLOR_ADVERTENCIA := Color(0.95, 0.85, 0.2)
const COLOR_MIRA := Color(0.85, 0.2, 0.2)
const COLOR_VERDE := Color(0.25, 0.8, 0.35)

## Duraciones base del ciclo, en segundos.
@export var duracion_no_mira: float = 5.0
@export var duracion_advertencia: float = 1.5
@export var duracion_mira: float = 4.0

## Variacion aleatoria (+/- segundos). ADVERTENCIA siempre dura lo mismo.
@export var variacion_no_mira: float = 3.0
@export var variacion_mira: float = 3.0

## Tiempo (segundos) que la profesora pasa quieta en NO_MIRA al arrancar.
@export var tiempo_inicial_quieto: float = 5.0

## Permite pausar el ciclo automatico (util para debug).
@export var ciclo_activo: bool = true

@export var estado: Estado = Estado.NO_MIRA:
	set(value):
		estado = value
		_actualizar_color()

## Gracia al entrar en MIRA: tiempo (s) en que la profesora se pone roja pero
## todavia NO detecta acciones. Evita muertes "frame perfect" justo en la
## transicion amarillo->rojo (el jugador la ve roja pero tiene un instante
## para reaccionar). El cono aparece de forma progresiva en este lapso.
@export var gracia_mira: float = 0.35

@onready var visual: AnimatedSprite2D = $Visual

var _tiempo_restante: float = 0.0
var _parpadeo_timer: float = 0.0
var _parpadeo_omega: float = 12.6 ## ~2Hz, 3 ciclos en 1.5s
var _gracia_mira: float = 0.0


func _ready() -> void:
	estado = Estado.NO_MIRA
	_actualizar_color()
	_tiempo_restante = max(0.5, tiempo_inicial_quieto)


func _process(delta: float) -> void:
	if not ciclo_activo:
		return

	if estado == Estado.ADVERTENCIA:
		_parpadeo_timer += delta
		var t := sin(_parpadeo_timer * _parpadeo_omega) * 0.5 + 0.5
		visual.modulate = COLOR_ADVERTENCIA.lerp(COLOR_VERDE, t)

	if estado == Estado.MIRA and _gracia_mira > 0.0:
		_gracia_mira -= delta

	_tiempo_restante -= delta
	if _tiempo_restante <= 0.0:
		_avanzar_estado()
	queue_redraw()


func _avanzar_estado() -> void:
	match estado:
		Estado.NO_MIRA:
			estado = Estado.ADVERTENCIA
			_parpadeo_timer = 0.0
			_tiempo_restante += duracion_advertencia
		Estado.ADVERTENCIA:
			estado = Estado.MIRA
			_gracia_mira = gracia_mira
			_tiempo_restante += _duracion_con_variacion(Estado.MIRA)
		Estado.MIRA:
			estado = Estado.NO_MIRA
			_tiempo_restante += _duracion_con_variacion(Estado.NO_MIRA)


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
	match estado:
		Estado.NO_MIRA:
			Fx.color(visual, COLOR_NO_MIRA)
		Estado.ADVERTENCIA:
			Fx.color(visual, COLOR_ADVERTENCIA)
		Estado.MIRA:
			Fx.color(visual, COLOR_MIRA)


func esta_mirando() -> bool:
	if estado != Estado.MIRA:
		return false
	# Durante la gracia inicial la profesora ya esta roja pero el jugador tiene
	# un breve margen antes de que sus acciones cuenten como detectadas.
	return _gracia_mira <= 0.0


## Forzar la profesora a mirar de inmediato (ej: golpe a companero distraido).
func forzar_mira() -> void:
	if estado == Estado.MIRA:
		return
	estado = Estado.MIRA
	_gracia_mira = 0.0 # el castigo es inmediato, sin margen
	_tiempo_restante = _duracion_con_variacion(Estado.MIRA)
