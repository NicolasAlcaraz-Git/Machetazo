extends Node2D
class_name Jugador

## Version 0.4 + 0.5 - Jugador
## Estados del jugador (ver punto 4 del documento de diseno).
##
## Controles esperados:
##   - "ui_left", "ui_right", "ui_up", "ui_down": las acciones nativas de
##     Godot (ya vienen con teclado + D-pad + eje del joystick asignados).
##     Al ser un Input.get_vector(), da lo mismo que la diagonal venga de
##     un stick analogico empujado en diagonal o de dos direcciones
##     presionadas juntas (asi funciona una palanca arcade real: 4
##     microswitches, la diagonal es literalmente los dos de al lado
##     apretados a la vez) — no hace falta nada especial para eso.
##   - "accion": el boton unico. Se usa tanto para crear el machete
##     (mashear) como para lanzarlo (un click). Podes asignarle mas de un
##     boton fisico a esta misma accion en el Input Map, para que cada
##     jugador use el que prefiera.

enum Estado {
	ESPERANDO,  ## Estado inicial: observa, puede empezar a crear un machete.
	CREANDO,    ## Contador 0/10, vulnerable si la profesora mira.
	APUNTANDO,  ## Cursor activo, se elige una de las 8 direcciones.
}

const COLOR_NORMAL := Color(0.2, 0.5, 0.9, 1)
const COLOR_PERDIO := Color(0.85, 0.2, 0.2, 1)
const COLOR_GANO := Color(0.25, 0.8, 0.35, 1)

## Cuantas pulsaciones hacen falta para terminar de crear un machete.
@export var pulsaciones_para_crear: int = 15

## Por debajo de esta magnitud, la palanca se considera "sin direccion"
## (el cursor vuelve al centro).
@export var deadzone_palanca: float = 0.35

## Cuanto tarda en reiniciarse el nivel despues de ganar o perder.
@export var tiempo_reinicio: float = 2.5

@export var estado: Estado = Estado.ESPERANDO

@onready var visual: AnimatedSprite2D = $Visual
@onready var aula: Aula = get_parent()

var contador_machete: int = 0
var direccion_actual: int = -1 # -1 = sin direccion (cursor en el centro)
var cursor: Cursor
var _partida_terminada: bool = false


func _ready() -> void:
	cursor = Cursor.new()
	cursor.visible = false
	add_child(cursor)
	visual.modulate = COLOR_NORMAL


func _process(_delta: float) -> void:
	if _partida_terminada:
		return

	match estado:
		Estado.ESPERANDO, Estado.CREANDO:
			_procesar_creacion()
		Estado.APUNTANDO:
			_procesar_apuntado()


## --- Version 0.4: creacion del machete ---

func _procesar_creacion() -> void:
	if Input.is_action_just_pressed("accion"):
		# El riesgo es del apreton, no de "seguir existiendo en CREANDO":
		# si en ESTE instante la profesora ya esta mirando, pierde. Si
		# todavia esta en amarillo (advertencia), el apreton es valido —
		# es una apuesta del jugador, no una derrota asegurada.
		if aula.profesora.esta_mirando():
			_perder()
			return

		contador_machete += 1
		estado = Estado.CREANDO
		aula.actualizar_barra_machete(contador_machete, pulsaciones_para_crear)
		if contador_machete >= pulsaciones_para_crear:
			_terminar_creacion()


func _terminar_creacion() -> void:
	estado = Estado.APUNTANDO
	direccion_actual = -1
	cursor.position = Vector2.ZERO
	cursor.visible = true
	cursor.actualizar(false) # arranca en el centro = invalido (rojo)


## --- Version 0.5: apuntado y lanzamiento ---

func _procesar_apuntado() -> void:
	var palanca := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if palanca.length() < deadzone_palanca:
		direccion_actual = -1
		cursor.position = Vector2.ZERO
		cursor.actualizar(false)
	else:
		direccion_actual = _direccion_desde_vector(palanca)
		var companero := aula.obtener_companero_en(direccion_actual)
		if companero != null:
			cursor.position = companero.position - position
			cursor.actualizar(companero.esta_disponible())
		else:
			cursor.position = Vector2.ZERO
			cursor.actualizar(false)

	if Input.is_action_just_pressed("accion"):
		_intentar_lanzar()


## Convierte el vector de la palanca en una de las 8 direcciones de
## Companero.Direccion, dividiendo el circulo en 8 octantes de 45 grados.
func _direccion_desde_vector(v: Vector2) -> int:
	var angulo := v.angle()
	var octante := int(round(angulo / (PI / 4.0))) % 8
	if octante < 0:
		octante += 8

	# Empezando en DERECHA (angulo 0) y girando en sentido horario
	# (en Godot, Y crece hacia abajo, asi que angulos crecientes van
	# DERECHA -> ABAJO -> IZQUIERDA -> ARRIBA -> DERECHA otra vez).
	var tabla := [
		Companero.Direccion.DERECHA,
		Companero.Direccion.ABAJO_DERECHA,
		Companero.Direccion.ABAJO,
		Companero.Direccion.ABAJO_IZQUIERDA,
		Companero.Direccion.IZQUIERDA,
		Companero.Direccion.ARRIBA_IZQUIERDA,
		Companero.Direccion.ARRIBA,
		Companero.Direccion.ARRIBA_DERECHA,
	]
	return tabla[octante]


func _intentar_lanzar() -> void:
	# Caso 3 del documento: lanzar justo cuando la profesora mira es
	# derrota inmediata, sin importar si el objetivo era valido o no.
	if aula.profesora.esta_mirando():
		_perder()
		return

	if direccion_actual == -1:
		_error_lanzamiento()
		return

	var companero := aula.obtener_companero_en(direccion_actual)
	if companero == null:
		_error_lanzamiento()
		return

	if not companero.esta_disponible():
		_golpe_a_companero(companero)
		return

	_lanzamiento_exitoso(companero)


func _lanzamiento_exitoso(companero: Companero) -> void:
	companero.recibir_machete()
	aula.registrar_entrega_exitosa()
	_volver_a_esperar()

	if aula.todos_los_companeros_agotados():
		_ganar()


## Tiro afuera: sin direccion o sin companero en esa direccion. No hay
## nadie a quien pegarle, asi que la profesora no reacciona por esto.
func _error_lanzamiento() -> void:
	aula.registrar_error()
	_volver_a_esperar()


## El machete le pega a un companero que no estaba atento (distraido o ya
## agotado): la profesora se da vuelta a mirar de inmediato (ver
## Profesora.forzar_mira()) y se pierde tiempo. No es derrota inmediata.
func _golpe_a_companero(companero: Companero) -> void:
	aula.registrar_golpe(companero)
	_volver_a_esperar()


func _volver_a_esperar() -> void:
	contador_machete = 0
	direccion_actual = -1
	cursor.visible = false
	estado = Estado.ESPERANDO
	aula.actualizar_barra_machete(contador_machete, pulsaciones_para_crear)


## --- Fin de partida ---

## Llamado por Aula.gd cuando el temporizador general llega a 0.
func perder_por_tiempo() -> void:
	_perder()


func _perder() -> void:
	if _partida_terminada:
		return
	_partida_terminada = true
	cursor.visible = false
	visual.modulate = COLOR_PERDIO
	aula.mostrar_mensaje_fin("PERDISTE")
	_reiniciar_tras_pausa()


func _ganar() -> void:
	if _partida_terminada:
		return
	_partida_terminada = true
	cursor.visible = false
	visual.modulate = COLOR_GANO
	aula.mostrar_mensaje_fin("GANASTE")
	_reiniciar_tras_pausa()


## Congela todo el juego (get_tree().paused detiene el _process de todos
## los nodos: companeros, profesora, jugador) y, pasado tiempo_reinicio
## segundos de tiempo REAL (el timer sigue corriendo aunque este pausado),
## recarga la escena entera: reinicia tiempo, machetes, ciclos, todo.
func _reiniciar_tras_pausa() -> void:
	get_tree().paused = true
	await get_tree().create_timer(tiempo_reinicio).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
