extends Node2D
class_name Companero

## Version 0.3.2 - Companeros
## Representa a un companero de clase, ubicado en una de las 8 direcciones
## alrededor del jugador (grilla 3x3, ver documento de diseno).
##
## A partir de esta version, el companero YA NO decide por si mismo cuando
## pasar a PREPARADO: eso lo controla el "director" en Aula.gd, para poder
## garantizar un maximo de companeros activos a la vez y evitar que, por
## simple azar, varios de los 8 coincidan en verde/amarillo al mismo tiempo.
## Este script solo sabe: (a) que color mostrar segun su estado, y (b) una
## vez activado, cuanto dura cada fase de SU propia ventana.

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
const COLOR_AGOTADO := Color(1, 1, 1)

@export var direccion: Direccion = Direccion.ARRIBA

## Duracion de CADA fase de la ventana de este companero en particular
## (una vez que Aula.gd decide activarlo). No es "cada cuanto se activa"
## (eso lo maneja Aula.gd) sino "cuanto dura, una vez que le toca".
@export var duracion_preparado: float = 4.0
@export var duracion_advertencia: float = 1.5

## Variacion aleatoria (+/- segundos) sobre esas duraciones, para que la
## ventana de cada companero no dure siempre exactamente lo mismo.
@export var variacion_aleatoria: float = 1.5

## Cuantos machetes necesita este companero antes de quedar "agotado"
## (ya no vuelve a estar disponible para el resto del nivel).
@export var machetes_necesarios: int = 2

var machetes_recibidos: int = 0

@export var estado: Estado = Estado.DISTRAIDO:
	set(value):
		estado = value
		_actualizar_color()

@onready var visual: AnimatedSprite2D = $Visual

var _tiempo_restante: float = 0.0


func _ready() -> void:
	_actualizar_color()


## Llamado por Jugador.gd cuando le entrega un machete exitosamente.
## Si llega al maximo, el companero queda agotado (ver esta_agotado()).
func recibir_machete() -> void:
	machetes_recibidos += 1
	if esta_agotado():
		desactivar()


## Una vez agotado, nunca mas vuelve a estar disponible en este nivel.
func esta_agotado() -> bool:
	return machetes_recibidos >= machetes_necesarios


## Llamado por Aula.gd (el "director") cuando decide que le toca a este
## companero abrir su ventana de disponibilidad.
func activar() -> void:
	estado = Estado.PREPARADO
	_tiempo_restante = _con_variacion(duracion_preparado)


## Llamado por Aula.gd en cada frame, pero SOLO mientras este companero
## esta activo (PREPARADO o ADVERTENCIA). Avanza su propia mini-secuencia
## interna: PREPARADO -> ADVERTENCIA -> DISTRAIDO.
func avanzar(delta: float) -> void:
	if estado == Estado.DISTRAIDO:
		return

	_tiempo_restante -= delta
	if _tiempo_restante > 0.0:
		return

	match estado:
		Estado.PREPARADO:
			estado = Estado.ADVERTENCIA
			_tiempo_restante = _con_variacion(duracion_advertencia)
		Estado.ADVERTENCIA:
			desactivar()


func desactivar() -> void:
	estado = Estado.DISTRAIDO


func _con_variacion(base: float) -> float:
	if variacion_aleatoria <= 0.0:
		return base
	return max(0.1, base + randf_range(-variacion_aleatoria, variacion_aleatoria))


func _actualizar_color() -> void:
	if not is_instance_valid(visual):
		return
	if esta_agotado():
		visual.modulate = COLOR_AGOTADO
		return
	match estado:
		Estado.PREPARADO:
			visual.modulate = COLOR_PREPARADO
		Estado.ADVERTENCIA:
			visual.modulate = COLOR_ADVERTENCIA
		Estado.DISTRAIDO:
			visual.modulate = COLOR_DISTRAIDO


## Segun el documento: en el primer prototipo, "amarillo" (advertencia)
## todavia se considera un lanzamiento valido. Un companero agotado nunca
## es valido, sin importar su color actual.
func esta_disponible() -> bool:
	if esta_agotado():
		return false
	return estado == Estado.PREPARADO or estado == Estado.ADVERTENCIA
