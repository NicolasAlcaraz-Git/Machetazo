extends Node2D
class_name Companero

## Version 0.3 - Companeros
## Representa a un companero de clase, ubicado en una de las 8 direcciones
## alrededor del jugador (grilla 3x3, ver documento de diseno).
##
## Ciclo automatico: DISTRAIDO -> PREPARADO -> ADVERTENCIA -> (repetir).
## A diferencia de la profesora, el documento no pide que este ciclo sea
## predecible, asi que cada companero tiene una pequenia variacion aleatoria
## en sus tiempos y (por defecto) arranca en una fase al azar, para que los
## 8 no cambien de estado todos juntos.

enum Direccion {
	ARRIBA,
	ABAJO,
	IZQUIERDA,
	DERECHA,
	ARRIBA_IZQUIERDA,
	ARRIBA_DERECHA,
	ABAJO_IZQUIERDA,
	ABAJO_DERECHA,
}

enum Estado {
	PREPARADO,   ## Verde: listo para recibir el machete.
	ADVERTENCIA, ## Amarillo: a punto de distraerse (todavia valido, ver doc).
	DISTRAIDO,   ## Gris/default: no se le puede pasar el machete.
}

const COLOR_PREPARADO := Color(0.25, 0.8, 0.35)
const COLOR_ADVERTENCIA := Color(0.95, 0.85, 0.2)
const COLOR_DISTRAIDO := Color(0.55, 0.55, 0.55)

@export var direccion: Direccion = Direccion.ARRIBA

## Duraciones base del ciclo, en segundos. Se les suma/resta
## "variacion_aleatoria" para que no todos los companeros vayan sincronizados.
@export var duracion_distraido: float = 6.0
@export var duracion_preparado: float = 4.0
@export var duracion_advertencia: float = 1.5

## Variacion aleatoria (+/- segundos) aplicada a cada duracion.
@export var variacion_aleatoria: float = 1.0

## Si esta activo, el companero arranca en un estado/momento al azar del
## ciclo (recomendado dejarlo prendido para que los 8 se vean desincronizados
## desde el primer frame). Desactivalo si necesitas un companero
## predecible para debug.
@export var iniciar_en_fase_aleatoria: bool = true

## Permite pausar el ciclo automatico (util para debug).
@export var ciclo_activo: bool = true

@export var estado: Estado = Estado.DISTRAIDO:
	set(value):
		estado = value
		_actualizar_color()

@onready var visual: AnimatedSprite2D = $Visual

var _secuencia: Array[Estado] = [
	Estado.DISTRAIDO,
	Estado.PREPARADO,
	Estado.ADVERTENCIA,
]
var _indice_secuencia: int = 0
var _tiempo_restante: float = 0.0


func _ready() -> void:
	if iniciar_en_fase_aleatoria:
		_indice_secuencia = randi() % _secuencia.size()
		estado = _secuencia[_indice_secuencia]
	else:
		_indice_secuencia = _secuencia.find(estado)
		if _indice_secuencia == -1:
			_indice_secuencia = 0

	_actualizar_color()
	_tiempo_restante = _duracion_con_variacion(estado)


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
	var base := _duracion_base(valor)
	if variacion_aleatoria <= 0.0:
		return base
	return max(0.1, base + randf_range(-variacion_aleatoria, variacion_aleatoria))


func _duracion_base(valor: Estado) -> float:
	match valor:
		Estado.PREPARADO:
			return duracion_preparado
		Estado.ADVERTENCIA:
			return duracion_advertencia
		Estado.DISTRAIDO:
			return duracion_distraido
	return 1.0


func _actualizar_color() -> void:
	if not is_instance_valid(visual):
		return
	match estado:
		Estado.PREPARADO:
			visual.modulate = COLOR_PREPARADO
		Estado.ADVERTENCIA:
			visual.modulate = COLOR_ADVERTENCIA
		Estado.DISTRAIDO:
			visual.modulate = COLOR_DISTRAIDO


## Segun el documento: en el primer prototipo, "amarillo" (advertencia)
## todavia se considera un lanzamiento valido.
func esta_disponible() -> bool:
	return estado == Estado.PREPARADO or estado == Estado.ADVERTENCIA
