extends Node2D
class_name Companero

## Version 0.4 - Companeros
## Representa a un companero de clase, ubicado en una de las 8 direcciones
## alrededor del jugador (grilla 3x3, ver documento de diseno), o en las
## 6 posiciones laterales extra (grilla 3x5, "bancos adicionales").
##
## A partir de esta version, el companero YA NO decide por si mismo cuando
## pasar a PREPARADO: eso lo controla el "director" en Aula.gd, para poder
## garantizar un maximo de companeros activos a la vez y evitar que, por
## simple azar, varios coincidan en verde/amarillo al mismo tiempo.
## Este script solo sabe: (a) que color mostrar segun su estado, y (b) una
## vez activado, cuanto dura cada fase de SU propia ventana.
##
## Ademas, los dos bancos laterales del jugador (IZQUIERDA y DERECHA) pueden
## funcionar como "extensiones": ademas de su ciclo normal verde/amarillo,
## pasan brevemente a azul (EXTENSION_LISTO). Si el jugador les da un machete
## en azul, pasa a CONTROLAR ese banco (estado del Jugador) y reparte machetes
## a los 3 bancos extra de su lado. Ese machete de control NO cuenta como
## machete entregado a este companero.

enum Direccion {
	ARRIBA,          ## 0
	ABAJO,           ## 1
	IZQUIERDA,       ## 2
	DERECHA,         ## 3
	ARRIBA_IZQUIERDA,## 4
	ARRIBA_DERECHA,  ## 5
	ABAJO_IZQUIERDA, ## 6
	ABAJO_DERECHA,   ## 7
	## Bancos laterales extra (grilla 3x5)
	EXT_IZQ_ARR,     ## 8  x = -360
	EXT_IZQ_CEN,     ## 9  x = -360
	EXT_IZQ_ABA,     ## 10 x = -360
	EXT_DER_ARR,     ## 11 x = +360
	EXT_DER_CEN,     ## 12 x = +360
	EXT_DER_ABA,     ## 13 x = +360
}

enum Estado {
	PREPARADO,     ## Verde: listo para recibir el machete.
	ADVERTENCIA,   ## Amarillo: a punto de distraerse (todavia valido).
	EXTENSION,     ## Azul: listo para ser usado como puente (extension).
	OCUPADO,       ## Verde oscuro + anillo: copiando el machete (cooldown).
	DISTRAIDO,     ## Gris/default: no se le puede pasar el machete.
}

const COLOR_PREPARADO := Color(0.25, 0.8, 0.35)
const COLOR_ADVERTENCIA := Color(0.95, 0.85, 0.2)
const COLOR_EXTENSION := Color(0.2, 0.5, 0.9)   ## azul, igual al jugador.
const COLOR_DISTRAIDO := Color(0.55, 0.55, 0.55)
const COLOR_AGOTADO := Color(1, 1, 1)

@export var direccion: Direccion = Direccion.ARRIBA

## Marca a este companero como uno de los DOS bancos laterales que sirven de
## "extension" del jugador (ver cabecera). Estos, ademas de su ciclo normal,
## pasan a azul (EXTENSION) para poder ser controlados como puente.
@export var es_extension: bool = false

## Duracion de CADA fase de la ventana de este companero en particular
## (una vez que Aula.gd decide activarlo). No es "cada cuanto se activa"
## (eso lo maneja Aula.gd) sino "cuanto dura, una vez que le toca".
@export var duracion_preparado: float = 2.5
@export var duracion_advertencia: float = 1.5

## Variacion aleatoria (+/- segundos) sobre la duracion del PREPARADO
## (verde). El ADVERTENCIA (amarillo) NO varia: siempre dura lo mismo.
@export var variacion_aleatoria: float = 2.5

## Duracion fija (segundos) del estado EXTENSION (azul) para los bancos
## laterales. Es FIJA a proposito: el azul, igual que el amarillo, siempre
## dura lo mismo para que el jugador sepa exactamente cuanto le queda antes
## de que el puente vuelva a gris.
@export var duracion_extension: float = 2.5

## Cuantos machetes necesita este companero antes de quedar "agotado"
## (ya no vuelve a estar disponible para el resto del nivel). Los machetes
## de "control" usados para pasear la palanca hacia los bancos extra NO
## cuentan para este total (ver Jugador.gd).
@export var machetes_necesarios: int = 3

## Duracion (segundos) del estado OCUPADO: el companero esta "copiando" el
## machete recien recibido y no puede recibir otro hasta que pase ese tiempo.
@export var cooldown_ocupado: float = 1.2

## Color del estado OCUPADO (configurable).
@export var color_ocupado: Color = Color(0.1, 0.45, 0.25)

## Radio del anillo de cooldown dibujado alrededor del companero ocupado.
@export var radio_anillo: float = 55.0

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
## Si no, pasa a OCUPADO (copiando) por cooldown_ocupado segundos.
func recibir_machete() -> void:
	machetes_recibidos += 1
	Fx.pop(visual, 0.35, 0.2)
	if esta_agotado():
		desactivar()
	else:
		estado = Estado.OCUPADO
		_tiempo_restante = cooldown_ocupado


## Una vez agotado, nunca mas vuelve a estar disponible en este nivel.
func esta_agotado() -> bool:
	return machetes_recibidos >= machetes_necesarios


## Llamado por Aula.gd (el "director") cuando decide que le toca a este
## companero abrir su ventana de disponibilidad normal (verde -> amarillo).
func activar() -> void:
	estado = Estado.PREPARADO
	_tiempo_restante = _con_variacion(duracion_preparado)


## Llamado por Aula.gd cuando este companero (banco lateral de extension)
## entra en modo puente (azul). Si estaba en medio de su ventana normal,
## se cancela para pasar a azul.
func activar_extension() -> void:
	estado = Estado.EXTENSION
	_tiempo_restante = duracion_extension


## Llamado por Aula.gd en cada frame, pero SOLO mientras este companero
## esta activo. Avanza su propia mini-secuencia interna:
##   normal:    PREPARADO -> ADVERTENCIA -> DISTRAIDO
##   extension: EXTENSION -> DISTRAIDO
## y el cooldown de OCUPADO -> DISTRAIDO.
func avanzar(delta: float) -> void:
	if estado == Estado.DISTRAIDO:
		return

	_tiempo_restante -= delta
	if _tiempo_restante > 0.0:
		if estado == Estado.OCUPADO:
			queue_redraw()
		return

	match estado:
		Estado.PREPARADO:
			estado = Estado.ADVERTENCIA
			# El amarillo dura SIEMPRE lo mismo (sin variacion), para que el
			# jugador sepa exactamente cuanto tiene antes de que se distraiga.
			_tiempo_restante = duracion_advertencia
		Estado.ADVERTENCIA, Estado.EXTENSION:
			desactivar()
		Estado.OCUPADO:
			desactivar()


func desactivar() -> void:
	_tiempo_restante = 0.0
	estado = Estado.DISTRAIDO
	queue_redraw() # limpia el anillo de cooldown


func _con_variacion(base: float) -> float:
	if variacion_aleatoria <= 0.0:
		return base
	return max(0.1, base + randf_range(-variacion_aleatoria, variacion_aleatoria))


func _actualizar_color() -> void:
	if not is_instance_valid(visual):
		return
	if esta_agotado():
		Fx.color(visual, COLOR_AGOTADO)
		return
	var color: Color
	match estado:
		Estado.PREPARADO:
			color = COLOR_PREPARADO
		Estado.ADVERTENCIA:
			color = COLOR_ADVERTENCIA
		Estado.EXTENSION:
			color = COLOR_EXTENSION
		Estado.OCUPADO:
			color = color_ocupado
		Estado.DISTRAIDO:
			color = COLOR_DISTRAIDO
	Fx.color(visual, color)


## Anillo de cooldown: se dibuja unicamente mientras el companero esta
## OCUPADO (copiando el machete). Es un arco (solo contorno) que va de lleno
## a vacio mostrando el tiempo restante del cooldown.
func _draw() -> void:
	if estado != Estado.OCUPADO:
		return
	if cooldown_ocupado <= 0.0:
		return
	var restante: float = clamp(_tiempo_restante / cooldown_ocupado, 0.0, 1.0)
	var inicio: float = -PI / 2.0
	var barrido: float = TAU * restante
	draw_arc(Vector2.ZERO, radio_anillo, inicio, inicio + barrido, 40,
		Color(1, 1, 1, 0.9), 4.0)


## Segun el documento: en el primer prototipo, tanto "amarillo" (advertencia)
## como el banco lateral en azul (extension) se consideran lanzamientos
## validos. Un companero agotado nunca es valido. Un companero OCUPADO
## (copiando) tampoco puede recibir otro machete todavia.
func esta_disponible() -> bool:
	if esta_agotado():
		return false
	if estado == Estado.OCUPADO:
		return false
	return estado == Estado.PREPARADO \
		or estado == Estado.ADVERTENCIA \
		or estado == Estado.EXTENSION
