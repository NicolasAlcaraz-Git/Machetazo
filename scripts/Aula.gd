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
var label_fin: Label
var label_en_mano: Label
var label_racha: Label
var barra_machete: BarraProgreso

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

## --- Extension (bancos laterales como puente) ---

## Cada cuanto (rango min-max en segundos) se intenta poner un banco lateral
## en azul (modo puente, ver Companero.activar_extension). El azul que acompaña
## el ritmo general, ademas del ciclo verde/amarillo normal.
@export var pausa_extension_min: float = 5.0
@export var pausa_extension_max: float = 9.0

var _tiempo_para_extension: float = 0.0

var _companeros_activos: Array[Companero] = []
var _tiempo_para_proxima_activacion: float = 0.0

## --- Temporizador general del nivel ---

## Tiempo total del nivel, en segundos. 6 minutos por defecto.
@export var tiempo_total: float = 360.0

## Cuanto tiempo se resta por cada error (lanzar afuera o golpear a un
## companero distraido). Ver registrar_error() / registrar_golpe().
@export var penalizacion_tiempo: float = 5.0

## Ruta de la escena del nivel siguiente ("" = este es el ultimo nivel y se
## recarga al ganarlo). Al ganar el nivel, el juego carga esta escena.
@export var siguiente_escena: String = ""

var _tiempo_restante: float = 0.0

## --- Meta del nivel ---

var _entregas_exitosas: int = 0


func _ready() -> void:
	for hijo in $Companeros.get_children():
		if hijo is Companero:
			hijo.desactivar()
			companeros.append(hijo)

	label_fin = _crear_label_fin()
	$HUD.add_child(label_fin)

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

	_aplicar_sombra(label_tiempo)
	_aplicar_sombra(label_machetes)
	_aplicar_sombra(label_en_mano)
	_aplicar_sombra(label_racha)
	_aplicar_sombra(label_fin)

	_tiempo_para_proxima_activacion = tiempo_inicial_quieto
	_tiempo_para_extension = tiempo_inicial_quieto + 2.0

	_crear_fondo()
	Fx.respirar(jugador, 0.03, 1.4)
	for companero in companeros:
		Fx.respirar(companero, 0.03, 1.4)


func _process(delta: float) -> void:
	_avanzar_companeros_activos(delta)

	_tiempo_para_proxima_activacion -= delta
	if _tiempo_para_proxima_activacion <= 0.0:
		_intentar_activar_uno()

	_tiempo_para_extension -= delta
	if _tiempo_para_extension <= 0.0:
		_intentar_activar_extension()

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


## Cada tanto pone en azul (modo puente) a uno de los dos bancos laterales de
## extension que este distraido y no agotado. Se programa SIEMPRE la proxima
## pasada, haya o no activado a alguien.
func _intentar_activar_extension() -> void:
	_tiempo_para_extension = randf_range(pausa_extension_min, pausa_extension_max)

	var candidatos: Array[Companero] = []
	for companero in companeros:
		if companero.es_extension \
			and companero.estado == Companero.Estado.DISTRAIDO:
			candidatos.append(companero)

	if candidatos.is_empty():
		return

	var elegido: Companero = candidatos[randi() % candidatos.size()]
	elegido.activar_extension()
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
		if not companero.esta_agotado():
			return false
	return true


## -- Transicion entre niveles --

## True si este nivel tiene una escena siguiente configurada (no es el ultimo).
func tiene_siguiente_escena() -> bool:
	return not siguiente_escena.is_empty()


## Fade a negro y carga la escena siguiente. Llamado por Jugador.gd cuando se
## gana el nivel y existe un siguiente.
func transicionar_nivel() -> void:
	get_tree().paused = true

	var overlay := ColorRect.new()
	overlay.name = "FadeReinicio"
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(overlay)
	var tween := overlay.create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)

	await get_tree().create_timer(jugador.tiempo_reinicio).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file(siguiente_escena)


func _crear_label_fin() -> Label:
	var label := Label.new()
	label.name = "LabelFin"
	label.add_theme_font_size_override("font_size", 56)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -300
	label.offset_right = 300
	label.offset_top = -40
	label.offset_bottom = 40
	label.visible = false
	return label


## Llamado por Jugador.gd al ganar o perder.
func mostrar_mensaje_fin(texto: String) -> void:
	label_fin.text = texto
	label_fin.visible = true
	label_fin.scale = Vector2(0.6, 0.6)
	var tween := label_fin.create_tween()
	tween.tween_property(label_fin, "scale", Vector2(1.0, 1.0), 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Label chico que muestra cuantos machetes quedan en el set actual.
func _crear_label_en_mano() -> Label:
	var label := Label.new()
	label.name = "LabelEnMano"
	label.add_theme_font_size_override("font_size", 22)
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.offset_left = 20
	label.offset_top = 80
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
	label.offset_top = 108
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
