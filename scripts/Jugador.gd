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
	ESPERANDO,  ## Estado inicial: observa, puede empezar a preparar un set.
	CREANDO,    ## Contador 0/30, vulnerable si la profesora mira.
	APUNTANDO,  ## Cursor activo, se pasan los machetes del set en secuencia.
	CONTROLANDO_EXTENSION, ## Apuntando desde un banco lateral (extension) hacia
	                       ## los 3 bancos extra de su lado.
}

const COLOR_NORMAL := Color(0.2, 0.5, 0.9, 1)
const COLOR_PERDIO := Color(0.85, 0.2, 0.2, 1)
const COLOR_GANO := Color(0.25, 0.8, 0.35, 1)

## Cuantas pulsaciones hacen falta para terminar de preparar un set de
## machetes (ver machetes_por_set). Ahora la preparacion lleva mas tiempo.
@export var pulsaciones_para_crear: int = 30

## Cuantos machetes entran en cada set. Se preparan de una vez y luego se
## apuntan y entregan en secuencia (whack-a-mole) hasta agotar el set,
## antes de tener que mashear de nuevo.
@export var machetes_por_set: int = 5

## Por debajo de esta magnitud, la palanca se considera "sin direccion"
## (el cursor vuelve al centro).
@export var deadzone_palanca: float = 0.35

## Cuanto tarda en reiniciarse el nivel despues de ganar o perder.
@export var tiempo_reinicio: float = 2.5

## Cuanto decae el contador por segundo mientras el jugador no esta pulsando
## el boton (en "pulsaciones" por segundo). 0 = sin decaimiento.
@export var decaimiento_por_segundo: float = 8.0

## Tiempo (segundos) que debe pasar sin pulsar el boton antes de que la
## barra empiece a vaciarse. Evita que decaiga entre pulsaciones rapidas.
@export var retraso_decaimiento: float = 1.0

@export var estado: Estado = Estado.ESPERANDO

@onready var visual: AnimatedSprite2D = $Visual
@onready var aula: Aula = get_parent()

var contador_machete: int = 0
var _decaimiento_acumulado: float = 0.0
var _tiempo_sin_pulsar: float = 0.0
var machetes_en_mano: int = 0
var direccion_actual: int = -1 # -1 = sin direccion (cursor en el centro)
var cursor: Cursor
var _partida_terminada: bool = false

## Banco lateral (extension) que el jugador esta controlando actualmente en
## el estado CONTROLANDO_EXTENSION. null en cualquier otro estado.
var _companero_controlado: Companero = null


func _ready() -> void:
	cursor = Cursor.new()
	cursor.visible = false
	add_child(cursor)
	visual.modulate = COLOR_NORMAL


func _process(delta: float) -> void:
	if _partida_terminada:
		return

	match estado:
		Estado.ESPERANDO, Estado.CREANDO:
			_procesar_creacion(delta)
		Estado.APUNTANDO:
			_procesar_apuntado()
		Estado.CONTROLANDO_EXTENSION:
			_procesar_extension()


## --- Version 0.4: creacion del machete ---

func _procesar_creacion(delta: float) -> void:
	if Input.is_action_just_pressed("accion"):
		# El riesgo es del apreton, no de "seguir existiendo en CREANDO":
		# si en ESTE instante la profesora ya esta mirando, pierde. Si
		# todavia esta en amarillo (advertencia), el apreton es valido —
		# es una apuesta del jugador, no una derrota asegurada.
		if aula.profesora.esta_mirando():
			_perder()
			return

		contador_machete += 1
		_decaimiento_acumulado = 0.0 # el pulso frena el decaimiento
		_tiempo_sin_pulsar = 0.0
		estado = Estado.CREANDO
		aula.actualizar_barra_machete(contador_machete, pulsaciones_para_crear)
		if contador_machete >= pulsaciones_para_crear:
			_terminar_creacion()
		return

	# Decaimiento pasivo: la barra baja lentamente, pero solo si ya paso el
	# retraso sin pulsaciones. Se acumula el tiempo inactivo y recien despues
	# de retraso_decaimiento segundos empieza a vaciarse.
	if estado == Estado.CREANDO and decaimiento_por_segundo > 0.0:
		_tiempo_sin_pulsar += delta
		if _tiempo_sin_pulsar > retraso_decaimiento:
			_decaimiento_acumulado += decaimiento_por_segundo * delta
			if _decaimiento_acumulado >= 1.0:
				var bajar := int(_decaimiento_acumulado)
				_decaimiento_acumulado -= float(bajar)
				contador_machete = max(0, contador_machete - bajar)
				aula.actualizar_barra_machete(contador_machete, pulsaciones_para_crear)


func _terminar_creacion() -> void:
	estado = Estado.APUNTANDO
	machetes_en_mano = machetes_por_set
	direccion_actual = -1
	cursor.position = Vector2.ZERO
	cursor.visible = true
	cursor.actualizar(false) # arranca en el centro = invalido (rojo)
	aula.actualizar_en_mano(machetes_en_mano, machetes_por_set)


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
		# Cursor en el centro (sin direccion): no lanzar ni penalizar. El
		# jugador puede seguir masheando sin perder el machete ni la mira.
		return

	var companero := aula.obtener_companero_en(direccion_actual)
	if companero == null:
		_error_lanzamiento()
		return

	# Si el objetivo es un banco lateral en azul (EXTENSION), el jugador NO le
	# entrega el machete: pasa a CONTROLARLO para poder repartir a los bancos
	# extra de ese lado. El machete de "control" no se descuenta del set ni
	# cuenta como entrega para ese companero.
	if companero.es_extension and companero.estado == Companero.Estado.EXTENSION:
		_iniciar_control_extension(companero)
		return

	if not companero.esta_disponible():
		_golpe_a_companero(companero)
		return

	_lanzamiento_exitoso(companero)


func _lanzamiento_exitoso(companero: Companero) -> void:
	companero.recibir_machete()
	aula.registrar_entrega_exitosa()
	MacheteTrazo.crear(aula, position, companero.position)
	_descontar_machete()

	if aula.todos_los_companeros_agotados():
		_ganar()


## Descuenta un machete del set en mano. Si el set se vacia, vuelve a
## esperar (hay que mashear de nuevo para preparar otro set). Si todavia
## quedan machetes, se queda en APUNTANDO para seguir pasando el siguiente.
func _descontar_machete() -> void:
	if machetes_en_mano <= 0:
		return
	machetes_en_mano -= 1
	aula.actualizar_en_mano(machetes_en_mano, machetes_por_set)
	if machetes_en_mano <= 0:
		_volver_a_esperar()


## Tiro afuera: sin direccion o sin companero en esa direccion. No hay
## nadie a quien pegarle, asi que la profesora no reacciona por esto.
## Pero se desperdicia un machete del set.
func _error_lanzamiento() -> void:
	aula.registrar_error()
	_descontar_machete()


## El machete le pega a un companero que no estaba atento (distraido o ya
## agotado): la profesora se da vuelta a mirar de inmediato (ver
## Profesora.forzar_mira()), se pierde tiempo y se desperdicia un machete
## del set. No es derrota inmediata.
func _golpe_a_companero(companero: Companero) -> void:
	aula.registrar_golpe(companero)
	Fx.shake(companero, 7.0, 0.18)
	_descontar_machete()


func _volver_a_esperar() -> void:
	contador_machete = 0
	_decaimiento_acumulado = 0.0
	_tiempo_sin_pulsar = 0.0
	machetes_en_mano = 0
	direccion_actual = -1
	cursor.visible = false
	estado = Estado.ESPERANDO
	aula.actualizar_barra_machete(contador_machete, pulsaciones_para_crear)
	aula.actualizar_en_mano(machetes_en_mano, machetes_por_set)


## --- Extension (bancos laterales como puente) ---

## El jugador le dio un machete (de control) a un banco lateral que estaba en
## azul. Pasa a apuntar DESDE ese banco hacia los bancos extra de su lado.
## El machete de control NO se descuenta del set aqui: se  descuenta cuando
## se reparte a un destino real desde este nuevo origen.
func _iniciar_control_extension(banco: Companero) -> void:
	_companero_controlado = banco
	estado = Estado.CONTROLANDO_EXTENSION
	direccion_actual = -1
	var delta_grilla := _delta_grilla_de_direccion(Companero.Direccion.DERECHA)
	_actualizar_cursor_extension(delta_grilla)


## Procesa el apuntado mientras se controla un banco lateral de extension.
## El origen es la posicion del banco controlado; la palanca apunta a su
## vecino en la grilla (distancia 180), excluyendo siempre al nene del medio
## (posicion original del jugador).
func _procesar_extension() -> void:
	if not is_instance_valid(_companero_controlado):
		_terminar_extension()
		return

	var palanca := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if palanca.length() < deadzone_palanca:
		direccion_actual = -1
		# Cursor centrado sobre el banco controlado (invalido): sin destino.
		cursor.position = _companero_controlado.position - position
		cursor.actualizar(false)
	else:
		direccion_actual = _direccion_desde_vector(palanca)
		var delta := _delta_grilla_de_direccion(direccion_actual)
		_actualizar_cursor_extension(delta)

	if Input.is_action_just_pressed("accion"):
		_intentar_lanzar_extension()


## Calcula y pinta el cursor cuando el origen de apuntado es un banco lateral.
## El destino es una posicion de grilla a 180px del origen; si en esa posicion
## hay un banco valido y distinto del nene original, se apunta a el.
func _actualizar_cursor_extension(delta: Vector2) -> void:
	var origen := _companero_controlado.position
	var destino := origen + delta * 180.0

	# Excluye al nene original (el centro), que nunca es alcanzable desde
	# una extension.
	if destino == position:
		cursor.position = _companero_controlado.position - position
		cursor.actualizar(false)
		return

	var objetivo := aula.obtener_companero_en_posicion(destino)
	if objetivo == null:
		cursor.position = _companero_controlado.position - position
		cursor.actualizar(false)
		return
	cursor.position = objetivo.position - position
	cursor.actualizar(objetivo.esta_disponible())


func _intentar_lanzar_extension() -> void:
	if aula.profesora.esta_mirando():
		_perder()
		return

	if not is_instance_valid(_companero_controlado):
		_terminar_extension()
		return

	if direccion_actual == -1:
		# Palanca en el centro: no hay destino, no se penaliza.
		return

	var delta := _delta_grilla_de_direccion(direccion_actual)
	var destino := _companero_controlado.position + delta * 180.0
	if destino == position:
		_error_lanzamiento()
		_terminar_extension()
		return

	var objetivo := aula.obtener_companero_en_posicion(destino)
	if objetivo == null:
		_error_lanzamiento()
		_terminar_extension()
		return

	if not objetivo.esta_disponible():
		_golpe_a_companero(objetivo)
		_terminar_extension()
		return

	_lanzamiento_exitoso(objetivo)
	_terminar_extension()


## Vuelve a apuntar desde el nene del medio (centro). Se llama al terminar
## un lanzamiento hecho desde una extension, o si el banco controlado deja
## de ser valido. Si el set de machetes ya quedo vacio (el descuento mando al
## jugador de vuelta a ESPERANDO), no se fuerza el APUNTANDO.
func _terminar_extension() -> void:
	_companero_controlado = null
	if machetes_en_mano <= 0:
		cursor.visible = false
		return
	estado = Estado.APUNTANDO
	direccion_actual = -1
	cursor.position = Vector2.ZERO
	cursor.actualizar(false)
	cursor.visible = true


## Convierte una direccion (enum) en un delta de grilla (un paso de 180px,
## en { -1, 0, 1 }). Se usa para el apuntado desde los bancos laterales.
func _delta_grilla_de_direccion(dir: int) -> Vector2:
	match dir:
		Companero.Direccion.ARRIBA:
			return Vector2(0, -1)
		Companero.Direccion.ABAJO:
			return Vector2(0, 1)
		Companero.Direccion.IZQUIERDA:
			return Vector2(-1, 0)
		Companero.Direccion.DERECHA:
			return Vector2(1, 0)
		Companero.Direccion.ARRIBA_IZQUIERDA:
			return Vector2(-1, -1)
		Companero.Direccion.ARRIBA_DERECHA:
			return Vector2(1, -1)
		Companero.Direccion.ABAJO_IZQUIERDA:
			return Vector2(-1, 1)
		Companero.Direccion.ABAJO_DERECHA:
			return Vector2(1, 1)
	return Vector2.ZERO


## --- Fin de partida ---

## Llamado por Aula.gd cuando el temporizador general llega a 0.
func perder_por_tiempo() -> void:
	_perder()


func _perder() -> void:
	if _partida_terminada:
		return
	_partida_terminada = true
	cursor.visible = false
	Fx.color(visual, COLOR_PERDIO, 0.4)
	aula.mostrar_mensaje_fin("PERDISTE")
	_reiniciar_tras_pausa()


func _ganar() -> void:
	if _partida_terminada:
		return
	_partida_terminada = true
	cursor.visible = false
	Fx.color(visual, COLOR_GANO, 0.4)
	aula.mostrar_mensaje_fin("GANASTE")
	_reiniciar_tras_pausa()


## Congela todo el juego (get_tree().paused detiene el _process de todos
## los nodos: companeros, profesora, jugador) y, pasado tiempo_reinicio
## segundos de tiempo REAL (el timer sigue corriendo aunque este pausado),
## recarga la escena entera: reinicia tiempo, machetes, ciclos, todo.
## Antes de recargar, funde la pantalla a negro (fade) para que el reinicio
## no sea brusco.
func _reiniciar_tras_pausa() -> void:
	get_tree().paused = true

	var hud: CanvasLayer = aula.get_node("HUD")
	var overlay := ColorRect.new()
	overlay.name = "FadeReinicio"
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(overlay)
	var tween := overlay.create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)

	await get_tree().create_timer(tiempo_reinicio).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
