extends Node2D
class_name Aula

## Version 0.5.2 - Aula (director de companeros + temporizador + fin de partida)
## El jugador, la profesora y los 8 companeros son nodos hijos reales
## dentro de Aula.tscn (podes arrastrarlos en el editor para reacomodarlos).
##
## Ademas de recolectar referencias, este script actua como "director de
## escena" para los companeros: en vez de que cada uno decida por su cuenta
## cuando activarse (lo que generaba coincidencias por simple azar al ser
## 8 procesos en paralelo), Aula.gd decide de a uno cuando le toca a cada
## companero abrir su ventana de disponibilidad, respetando un maximo
## simultaneo y una pausa minima entre activaciones.
##
## Meta del nivel: cada companero necesita "machetes_necesarios" machetes
## (2 por defecto, ver Companero.gd) antes de quedar agotado. Cuando los 8
## quedan agotados, se gana el nivel. Si se acaba el tiempo antes de eso,
## se pierde.

@onready var label_tiempo: Label = $HUD/LabelTiempo
@onready var label_machetes: Label = $HUD/LabelMachetes

@onready var jugador: Jugador = $Jugador
@onready var profesora: Profesora = $Profesora

var companeros: Array[Companero] = []
var buchon: Buchon = null
var label_en_mano: Label
var label_racha: Label
var barra_machete: BarraProgreso

## Fin de partida: cartel, botones y fondo son hijos DIRECTOS del HUD (con
## coordenadas de pantalla fijas, como el resto de labels del HUD, para que se
## vean bien en los 3 niveles). overlay_fin es el manejador de FinPartida.gd,
## un nodo mas del HUD que sigue en pie con el juego PAUSADO: se navega con
## palanca/flechas y se confirma con el boton de accion (accion) o ui_accept.
const FinPartidaScript := preload("res://scripts/FinPartida.gd")
var overlay_fin
var label_fin: Label
var btn_seguir: Button
var btn_menu: Button
var _fade_fin: ColorRect

## True si se GANO el nivel. Define que hace "SEGUIR JUGANDO": si se gano,
## avanza al siguiente nivel; si se perdio, reinicia el actual.
var _es_victoria: bool = false

## True desde que el jugador elige una opcion. Evita dobles disparos (el boton
## reacciona a ui_accept y ademas los confirmamos por _input).
var _fin_resuelto: bool = false

## --- Director de companeros ---

## Nunca hay mas de esta cantidad de companeros en PREPARADO/ADVERTENCIA
## al mismo tiempo. Mas simultaneos = mas objetivos activos (whack-a-mole).
@export var maximo_simultaneos: int = 4

## Tiempo (segundos) que TODOS los companeros pasan quietos/distraidos al
## arrancar el nivel, antes del primer intento de activacion.
@export var tiempo_inicial_quieto: float = 2.0

## Pausa (segundos, rango min-max) entre el INICIO de una activacion y el
## siguiente intento. Esta es la palanca principal del ritmo del "sigilo"
## de los companeros: valores altos = mas espera entre oportunidades (y
## practicamente nunca se solapan 2); valores bajos = mas oportunidades,
## pero mas chance de que se solapen 2 al mismo tiempo.
@export var pausa_entre_activaciones_min: float = 1.5
@export var pausa_entre_activaciones_max: float = 3.5

var _companeros_activos: Array[Companero] = []
var _tiempo_para_proxima_activacion: float = 0.0

## --- Temporizador general del nivel ---

## Tiempo total del nivel, en segundos. 6 minutos por defecto.
@export var tiempo_total: float = 360.0

## Cuanto tiempo se resta por cada error (lanzar afuera o golpear a un
## companero distraido). Ver registrar_error() / registrar_golpe().
@export var penalizacion_tiempo: float = 5.0

## Ruta de la escena del nivel siguiente. Se usa al GANAR y elegir
## "SEGUIR JUGANDO": avanza a este nivel. Si esta vacio (nivel 3, el ultimo),
## ganar y seguir jugando vuelve al nivel 1. Perder siempre reinicia el nivel
## actual, con o sin esta ruta.
@export var siguiente_escena: String = ""

var _tiempo_restante: float = 0.0

## --- Meta del nivel ---

var _entregas_exitosas: int = 0


func _ready() -> void:
	for hijo in $Companeros.get_children():
		if hijo is Buchon:
			buchon = hijo
		elif hijo is Companero:
			hijo.desactivar()
			companeros.append(hijo)

	_fade_fin = _crear_fade_fin()
	$HUD.add_child(_fade_fin)

	label_fin = _crear_label_fin()
	_aplicar_sombra(label_fin)
	$HUD.add_child(label_fin)

	btn_seguir = _crear_boton_fin("SEGUIR JUGANDO", Vector2(332, 604))
	btn_menu = _crear_boton_fin("VOLVER AL MENU", Vector2(692, 604))
	$HUD.add_child(btn_seguir)
	$HUD.add_child(btn_menu)
	btn_seguir.pressed.connect(_reiniciar_nivel)
	btn_menu.pressed.connect(_volver_al_menu)

	overlay_fin = FinPartidaScript.new()
	overlay_fin.name = "OverlayFin"
	overlay_fin.inicializar(label_fin, btn_seguir, btn_menu, _fade_fin,
		_reiniciar_nivel, _volver_al_menu)
	$HUD.add_child(overlay_fin)

	label_en_mano = _crear_label_en_mano()
	$HUD.add_child(label_en_mano)

	label_racha = _crear_label_racha()
	$HUD.add_child(label_racha)
	label_racha.text = "RACHA: 0"

	barra_machete = _crear_barra_machete()
	$HUD.add_child(barra_machete)

	_tiempo_restante = tiempo_total
	_actualizar_label_tiempo()
	label_machetes.text = "MACHETES ENTREGADOS: 0 / %d" % _meta_machetes()
	actualizar_en_mano(0, jugador.machetes_por_set)

	label_tiempo.add_theme_font_size_override("font_size", 30)
	label_machetes.add_theme_font_size_override("font_size", 22)
	_aplicar_sombra(label_tiempo)
	_aplicar_sombra(label_machetes)
	_aplicar_sombra(label_en_mano)
	_aplicar_sombra(label_racha)

	_tiempo_para_proxima_activacion = tiempo_inicial_quieto

	_crear_fondo()
	Fx.respirar(jugador, 0.03, 1.4)
	for companero in companeros:
		Fx.respirar(companero, 0.03, 1.4)


func _process(delta: float) -> void:
	_avanzar_companeros_activos(delta)

	_tiempo_para_proxima_activacion -= delta
	if _tiempo_para_proxima_activacion <= 0.0:
		_intentar_activar_uno()

	_avanzar_temporizador(delta)


## --- Director de companeros ---

## Les avisa a los companeros activos que paso el tiempo (para que avancen
## su propia mini-secuencia PREPARADO -> ADVERTENCIA -> DISTRAIDO) y los
## saca de la lista de "activos" en cuanto vuelven a estar distraidos.
func _avanzar_companeros_activos(delta: float) -> void:
	var siguen_activos: Array[Companero] = []
	for companero in _companeros_activos:
		companero.avanzar(delta)
		if companero.estado != Companero.Estado.DISTRAIDO:
			siguen_activos.append(companero)
	_companeros_activos = siguen_activos


## Se llama cada vez que se cumple la pausa. Programa el proximo intento
## SIEMPRE (haya exito o no), y si hay lugar libre, activa a un companero
## al azar entre los que estan distraidos, no estan ya activos y no estan
## agotados (ya recibieron todos sus machetes).
func _intentar_activar_uno() -> void:
	_tiempo_para_proxima_activacion = randf_range(
		pausa_entre_activaciones_min, pausa_entre_activaciones_max
	)

	if _companeros_activos.size() >= maximo_simultaneos:
		return # ya hay el maximo permitido, esperamos al proximo intento

	var candidatos: Array[Companero] = []
	for companero in companeros:
		if companero.estado == Companero.Estado.DISTRAIDO and not companero.esta_agotado():
			candidatos.append(companero)

	if candidatos.is_empty():
		return

	var elegido: Companero = candidatos[randi() % candidatos.size()]
	elegido.activar()
	_companeros_activos.append(elegido)


## --- Temporizador general ---

func _avanzar_temporizador(delta: float) -> void:
	if _tiempo_restante <= 0.0:
		return

	_tiempo_restante = max(0.0, _tiempo_restante - delta)
	_actualizar_label_tiempo()

	if _tiempo_restante <= 0.0:
		jugador.perder_por_tiempo()


func _actualizar_label_tiempo() -> void:
	var segundos_totales := int(ceil(_tiempo_restante))
	var minutos := segundos_totales / 60
	var segundos := segundos_totales % 60
	label_tiempo.text = "TIEMPO: %d:%02d" % [minutos, segundos]


## Resta tiempo por un error (lanzar sin objetivo valido). No tiene
## reaccion de la profesora: no habia nadie a quien pegarle.
func registrar_error() -> void:
	_restar_tiempo(penalizacion_tiempo)


## Resta tiempo Y ademas hace que la profesora mire de inmediato: el
## machete golpeo a un companero distraido (grito de "auch", ella se da
## vuelta). No es derrota inmediata por si sola.
func registrar_golpe(_companero: Companero) -> void:
	profesora.forzar_mira()
	_restar_tiempo(penalizacion_tiempo)


func _restar_tiempo(segundos: float) -> void:
	_tiempo_restante = max(0.0, _tiempo_restante - segundos)
	_actualizar_label_tiempo()
	if _tiempo_restante <= 0.0:
		jugador.perder_por_tiempo()


## --- Meta del nivel / HUD ---

func _meta_machetes() -> int:
	var total := 0
	for companero in companeros:
		# Los bancos de extension no reciben machetes para ellos mismos:
		# son puentes, no objetivos, y no cuentan para la meta del nivel.
		if companero.es_extension:
			continue
		total += companero.machetes_necesarios
	return total


func registrar_entrega_exitosa() -> void:
	_entregas_exitosas += 1
	label_machetes.text = "MACHETES ENTREGADOS: %d / %d" % [_entregas_exitosas, _meta_machetes()]


## El jugador devolvio el machete al nene del medio desde un banco lateral
## de extension. No premia ni penaliza; solo se registra para coherencia.
func registrar_devolucion() -> void:
	pass


func todos_los_companeros_agotados() -> bool:
	for companero in companeros:
		if companero.es_extension:
			continue
		if not companero.esta_agotado():
			return false
	return true


## -- Fin de partida (cartel + opciones) --

## Muestra el cartel de fin de partida (GANASTE/PERDISTE) y las dos opciones
## del jugador, y CONGELA el juego hasta que elija una. Llamado por Jugador.gd
## tanto al ganar (victoria=true) como al perder (victoria=false).
func mostrar_fin_partida(texto: String, victoria: bool) -> void:
	_es_victoria = victoria
	_fin_resuelto = false
	overlay_fin.mostrar(texto)
	# El juego queda congelado al instante: el jugador elige, no hay avance
	# automatico. Solo los nodos PROCESS_MODE_ALWAYS (overlay, cartel, botones,
	# fondo) siguen vivos.
	get_tree().paused = true


## "SEGUIR JUGANDO". Si se PERDIO, reinicia el nivel actual desde cero.
## Si se GANO, avanza al siguiente nivel; como no hay mas niveles despues del
## 3, ganas en el 3 y eliges seguir -> se vuelve al nivel 1.
func _reiniciar_nivel() -> void:
	if _fin_resuelto:
		return
	_fin_resuelto = true
	get_tree().paused = false
	if _es_victoria:
		if siguiente_escena.is_empty():
			get_tree().change_scene_to_file("res://scenes/Aula.tscn")
		else:
			get_tree().change_scene_to_file(siguiente_escena)
	else:
		get_tree().reload_current_scene()


## "VOLVER AL MENU": vuelve a la pantalla de seleccion de nivel.
func _volver_al_menu() -> void:
	if _fin_resuelto:
		return
	_fin_resuelto = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MenuNiveles.tscn")


## Cartel central, entre el jugador (abajo) y el companero de arriba. Hijo
## DIRECTO del HUD para posicionarse con coordenadas de pantalla fijas.
func _crear_label_fin() -> Label:
	var label := Label.new()
	label.name = "LabelFin"
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	label.add_theme_font_size_override("font_size", 56)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_CENTER)
	_posicionar_centro(label, Vector2(512, 444), Vector2(600, 80))
	label.visible = false
	return label


func _crear_boton_fin(texto: String, centro: Vector2) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.process_mode = Node.PROCESS_MODE_ALWAYS
	boton.add_theme_font_size_override("font_size", 22)
	boton.set_anchors_preset(Control.PRESET_CENTER)
	_posicionar_centro(boton, centro, Vector2(280, 48))
	boton.visible = false
	return boton


## Fondo oscurecido del cartel, a pantalla completa.
func _crear_fade_fin() -> ColorRect:
	var fade := ColorRect.new()
	fade.name = "FadeFin"
	fade.process_mode = Node.PROCESS_MODE_ALWAYS
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.visible = false
	return fade


## Centra un Control hijo DIRECTO del HUD en pantalla: PRESET_CENTER ancla al
## centro del viewport (512, 384) y los offsets se calculan respecto a ese
## punto, sin depender del tamano del nodo padre.
func _posicionar_centro(control: Control, centro: Vector2, tam: Vector2) -> void:
	control.offset_left = centro.x - tam.x / 2.0 - 512.0
	control.offset_top = centro.y - tam.y / 2.0 - 384.0
	control.offset_right = control.offset_left + tam.x
	control.offset_bottom = control.offset_top + tam.y


## Label chico que muestra cuantos machetes quedan en el set actual.
func _crear_label_en_mano() -> Label:
	var label := Label.new()
	label.name = "LabelEnMano"
	label.add_theme_font_size_override("font_size", 22)
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.offset_left = 20
	label.offset_top = 100
	return label


## Llamado por Jugador.gd cada vez que cambia la cantidad de machetes en
## mano (set en curso).
func actualizar_en_mano(actual: int, total: int) -> void:
	label_en_mano.text = "EN MANO: %d / %d" % [actual, total]


## Label chico que muestra la racha vigente y los clicks que pide el proximo
## set. Se actualiza con cada entrega (verde suma/amarillo-azul congela) y se
## resetea con cada fallo.
func _crear_label_racha() -> Label:
	var label := Label.new()
	label.name = "LabelRacha"
	label.add_theme_font_size_override("font_size", 22)
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.offset_left = 20
	label.offset_top = 138
	return label


## Llamado por Jugador.gd cada vez que cambia la racha o las pulsaciones
## requeridas para crear el proximo set.
func actualizar_racha(racha: int, requeridas: int) -> void:
	label_racha.text = "RACHA: %d   |   CLICKS/SET: %d" % [racha, requeridas]


## Barra vertical a la izquierda de la pantalla (no tapa a los companeros
## de abajo, a diferencia de la version horizontal anterior).
func _crear_barra_machete() -> BarraProgreso:
	var barra := BarraProgreso.new()
	barra.name = "BarraMachete"
	barra.vertical = true
	barra.num_segmentos = jugador.machetes_por_set
	barra.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	barra.offset_left = 24
	barra.offset_right = 60
	barra.offset_top = -150
	barra.offset_bottom = 150
	return barra


## Llamado por Jugador.gd cada vez que cambia el contador 0/10 de creacion.
func actualizar_barra_machete(actual: int, total: int) -> void:
	barra_machete.progreso = float(actual) / float(total) if total > 0 else 0.0


## Utilidad: devuelve el companero que esta en una direccion dada (o null).
func obtener_companero_en(direccion: Companero.Direccion) -> Companero:
	for companero in companeros:
		if companero.direccion == direccion:
			return companero
	return null


## Utilidad: devuelve el companero cuyo NODO esta en la posicion dada, con
## cierta tolerancia (o null). Se usa para apuntar desde los bancos laterales
## de extension, donde el destino se calcula por coordenadas de grilla.
func obtener_companero_en_posicion(pos: Vector2) -> Companero:
	var tolerancia: float = 90.0
	for companero in companeros:
		if companero.position.distance_to(pos) <= tolerancia:
			return companero
	return null


## True si el companero esta bloqueado por el buchon (si hay un buchon activo
## y mirando hacia el lado del companero).
func companero_bloqueado_por_buchon(companero: Companero) -> bool:
	if buchon == null:
		return false
	return buchon.esta_bloqueando_companero(companero)


## Sombra suave en un label para mejorar la legibilidad sobre el fondo.
func _aplicar_sombra(label: Label) -> void:
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


## Crea el fondo degradado del aula, en un CanvasLayer detras del mundo
## para que no se vea afectado por la camara y quede detras de todo.
func _crear_fondo() -> void:
	var tam := get_viewport().get_visible_rect().size
	var capa := CanvasLayer.new()
	capa.name = "CapaFondo"
	capa.layer = -10
	add_child(capa)
	var fondo := Fondo.new()
	fondo.name = "Fondo"
	fondo.configurar(tam)
	capa.add_child(fondo)
	RenderingServer.set_default_clear_color(Color(0.10, 0.13, 0.22))
