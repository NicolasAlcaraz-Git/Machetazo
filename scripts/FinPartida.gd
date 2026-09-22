extends Control
class_name FinPartida

## Manejador de input del cartel de fin de partida. Los nodos visuales (cartel,
## botones y fondo oscuro) los crea Aula.gd como hijos DIRECTOS del HUD (ahí se
## posicionan con coordenadas de pantalla y se ven bien). Este script vive en un
## nodo aparte del HUD que, con PROCESS_MODE_ALWAYS, sigue procesando input con
## el juego PAUSADO: se navega con palanca/flechas (el foco arranca en "SEGUIR
## JUGANDO") y se confirma con el boton de accion (accion) o ui_accept, ademas
## del mouse.
##
## Aula.gd llama a inicializar() una vez en _ready con los nodos ya creados y
## luego a mostrar() al ganar o perder.

var on_seguir: Callable = Callable()
var on_menu: Callable = Callable()

var label_fin: Label
var btn_seguir: Button
var btn_menu: Button
var _fade: ColorRect

## False durante el juego normal: el manejador ignora el input para no
## interferir con la accion del jugador. Se activa en mostrar() (fin de
## partida) y vuelve a false al confirmar.
var _activo: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Asigna los nodos (creados por Aula.gd como hijos directos del HUD) y los
## callbacks de cada opcion. Llamar una sola vez en _ready.
func inicializar(carton: Label, seguir: Button, menu: Button, fondo: ColorRect,
		on_seguir_cb: Callable, on_menu_cb: Callable) -> void:
	label_fin = carton
	btn_seguir = seguir
	btn_menu = menu
	_fade = fondo
	on_seguir = on_seguir_cb
	on_menu = on_menu_cb
	_conectar_foco()


## Conecta los dos botones entre si en todas las direcciones: con las flechas o
## la palanca (ui_left/right/up/down) se alterna entre "SEGUIR JUGANDO" y
## "VOLVER AL MENU" sin importar como haya quedado acomodado el foco. Sin estos
## vecinos explicitos, el autodeteccion de Godot a veces no conecta botones que
## se muestran/ocultan sin haber acomodado el layout.
func _conectar_foco() -> void:
	btn_seguir.focus_neighbor_left = btn_menu.get_path()
	btn_seguir.focus_neighbor_right = btn_menu.get_path()
	btn_seguir.focus_neighbor_top = btn_menu.get_path()
	btn_seguir.focus_neighbor_bottom = btn_menu.get_path()
	btn_menu.focus_neighbor_left = btn_seguir.get_path()
	btn_menu.focus_neighbor_right = btn_seguir.get_path()
	btn_menu.focus_neighbor_top = btn_seguir.get_path()
	btn_menu.focus_neighbor_bottom = btn_seguir.get_path()


## Muestra el cartel (con pop) y las dos opciones, dejando el foco en
## "SEGUIR JUGANDO". Aula.gd pausa el juego justo despues de llamar esto.
func mostrar(texto: String) -> void:
	_activo = true
	label_fin.text = texto
	label_fin.visible = true
	label_fin.scale = Vector2(0.6, 0.6)
	var tween := label_fin.create_tween()
	tween.tween_property(label_fin, "scale", Vector2(1.0, 1.0), 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_fade.visible = true
	_fade.color = Color(0, 0, 0, 0.45)

	btn_seguir.visible = true
	btn_menu.visible = true
	btn_seguir.grab_focus()


## Confirma el boton enfocado al pulsar el boton de accion del juego (accion)
## o ui_accept (ENTER/Espacio).
func _input(event: InputEvent) -> void:
	if not _activo:
		return
	if event.is_action_pressed("accion") or event.is_action_pressed("ui_accept"):
		_confirmar()


## Le pega al boton que tenga el foco (o a "SEGUIR JUGANDO" si no hay foco).
func _confirmar() -> void:
	if btn_menu == null or not _activo:
		return
	_activo = false
	var foco := get_viewport().gui_get_focus_owner()
	if foco == btn_menu:
		btn_menu.pressed.emit()
	else:
		btn_seguir.pressed.emit()