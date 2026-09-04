extends Node2D
class_name Buchon

## Version 0.2 - Buchon
## Segundo enemigo: mismos estados que la profesora.
## NO_MIRA -> ADVERTENCIA -> MIRA -> NO_MIRA (sin amarillo en la vuelta).
## ADVERTENCIA parpadea entre amarillo y verde, NO detecta.
## MIRA bloquea companeros de un lado y si le dan machete a uno bloqueado = perdida.

enum Estado {
	NO_MIRA,     ## Verde: no bloquea a nadie.
	ADVERTENCIA, ## Amarillo parpadeante: solo advertencia, NO bloquea.
	MIRA,        ## Rojo: bloquea companeros de un lado.
}

const COLOR_NO_MIRA := Color(0.25, 0.8, 0.35)
const COLOR_ADVERTENCIA := Color(0.95, 0.85, 0.2)
const COLOR_MIRA := Color(0.85, 0.2, 0.2)
const COLOR_VERDE := Color(0.25, 0.8, 0.35)
const COLOR_BLOQUEADO := Color(0.85, 0.3, 0.3, 0.7)

@export var duracion_no_mira: float = 5.0
@export var duracion_advertencia: float = 1.5
@export var duracion_mira: float = 4.0
@export var variacion_no_mira: float = 3.0
@export var variacion_mira: float = 3.0
@export var ciclo_activo: bool = true
## Tiempo (segundos) que la profesora pasa quieta en NO_MIRA al arrancar.
@export var tiempo_inicial_quieto: float = 10.0

@export var estado: Estado = Estado.NO_MIRA:
	set(value):
		estado = value
		_actualizar_color()

## Gracia al entrar en MIRA: tiempo (s) en que el cono rojo aparece pero todavia
## no bloquea. Evita muertes "frame perfect" justo en la transicion amarillo->rojo.
@export var gracia_mira: float = 0.3

@onready var visual: AnimatedSprite2D = $Visual

var _tiempo_restante: float = 0.0
var _parpadeo_timer: float = 0.0
var _parpadeo_omega: float = 12.6
var mira_izquierda: bool = true
var _gracia_mira: float = 0.0


func _ready() -> void:
	mira_izquierda = randf() < 0.5
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
			mira_izquierda = randf() < 0.5
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
	return estado == Estado.MIRA


func esta_bloqueando_companero(companero: Companero) -> bool:
	if estado != Estado.MIRA:
		return false
	if _gracia_mira > 0.0:
		return false
	var izq_dirs := [
		Companero.Direccion.IZQUIERDA,
		Companero.Direccion.ABAJO_IZQUIERDA,
	]
	var der_dirs := [
		Companero.Direccion.DERECHA,
		Companero.Direccion.ABAJO_DERECHA,
	]
	if mira_izquierda:
		return companero.direccion in izq_dirs
	else:
		return companero.direccion in der_dirs


func _draw() -> void:
	if estado != Estado.MIRA:
		return

	var largo := 210.0
	var alto := 210.0
	var alpha := 0.5
	# Durante la gracia inicial el triangulo crece desde el buchon (punta fija)
	# y se expande en diagonal, para que el jugador vea la "mira" antes de que
	# empiece a bloquear de verdad.
	var t_gracia := 0.0
	if gracia_mira > 0.0:
		t_gracia = clampf(1.0 - _gracia_mira / gracia_mira, 0.0, 1.0)
	var escala := lerpf(0.0, 1.0, t_gracia)
	var color_cono := Color(0.85, 0.2, 0.2, alpha * lerpf(0.0, 1.0, t_gracia))

	# Triangulo rectangulo que NAC E desde el buchon (punta) y se abre en diagonal
	# hacia los DOS companeros que vigila: el de la fila media (arriba) y el de la
	# fila de abajo. El angulo recto NO esta en el buchon: queda en el companero
	# de abajo (IZQ/DER), para que el cono no invada la zona del jugador.
	var lado := -1.0 if mira_izquierda else 1.0
	var punta := Vector2(0, 0)
	var abajo := Vector2(lado * largo * escala, 0)          # angulo recto (companero de abajo)
	var arriba := Vector2(lado * largo * escala, -alto * escala) # companero de arriba

	var puntos := PackedVector2Array([punta, abajo, arriba])
	draw_colored_polygon(puntos, color_cono)
	draw_line(punta, abajo, Color(0.85, 0.2, 0.2, alpha * 0.8 * t_gracia), 2.0)
	draw_line(punta, arriba, Color(0.85, 0.2, 0.2, alpha * 0.8 * t_gracia), 2.0)
