extends Control
class_name MenuNiveles

## Version 0.6 - Menu de seleccion de nivel
## Pantalla inicial simple con tres botones (NIVEL 1, 2 y 3). Al elegir un
## nivel se carga su escena directamente (Aula.tscn, Aula2.tscn o Aula3.tscn)
## y el juego corre exactamente igual que siempre: mismo Aula.gd, mismos
## companeros, misma logica de temporizador y de fin de partida.
##
## Ademas de soportar mouse, los botones se manejan con las flechas del
## teclado (ui_left/ui_right/ui_up/ui_down) y se confirman con ENTER o el
## boton de accion (ui_accept), tal como se usan en el resto del juego.

const NIVELES = [
	{
		"nombre": "NIVEL 1",
		"detalle": "Aula clasica: 8 compañeros.",
		"escena": "res://scenes/Aula.tscn",
	},
	{
		"nombre": "NIVEL 2",
		"detalle": "Entra el buchón vigilante.",
		"escena": "res://scenes/Aula2.tscn",
	},
	{
		"nombre": "NIVEL 3",
		"detalle": "Aula grande: 14 compañeros",
		"escena": "res://scenes/Aula3.tscn",
	},
]

var _botones: Array[Button] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.10, 0.13, 0.22))
	_crear_fondo()
	_crear_titulo()
	_crear_botones()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not _botones.is_empty():
		_botones[0].grab_focus()


## Fondo degradado (reutiliza Fondo.gd, igual que las aulas) detras del menu.
func _crear_fondo() -> void:
	var capa := CanvasLayer.new()
	capa.name = "CapaFondo"
	capa.layer = -10
	add_child(capa)
	var fondo := Fondo.new()
	fondo.name = "Fondo"
	fondo.configurar(get_viewport().get_visible_rect().size)
	capa.add_child(fondo)


func _crear_titulo() -> void:
	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.text = "MACHETAZO"
	titulo.add_theme_font_size_override("font_size", 72)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	titulo.offset_left = -400
	titulo.offset_right = 400
	titulo.offset_top = 110
	titulo.offset_bottom = 205
	_aplicar_sombra(titulo)
	add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.name = "Subtitulo"
	subtitulo.text = "ELEGI UN NIVEL"
	subtitulo.add_theme_font_size_override("font_size", 26)
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitulo.offset_left = -400
	subtitulo.offset_right = 400
	subtitulo.offset_top = 210
	subtitulo.offset_bottom = 246
	_aplicar_sombra(subtitulo)
	add_child(subtitulo)


func _crear_botones() -> void:
	const ANCHO := 420.0
	const ALTO := 62.0
	const TOP := 300.0
	const PASO := 132.0

	for i in NIVELES.size():
		var nivel: Dictionary = NIVELES[i]

		var boton := Button.new()
		boton.name = "BotonNivel%d" % (i + 1)
		boton.text = nivel["nombre"]
		boton.add_theme_font_size_override("font_size", 30)
		boton.set_anchors_preset(Control.PRESET_CENTER_TOP)
		boton.offset_left = -ANCHO / 2.0
		boton.offset_right = ANCHO / 2.0
		boton.offset_top = TOP + PASO * i
		boton.offset_bottom = TOP + PASO * i + ALTO
		boton.pressed.connect(_cargar_nivel.bind(nivel["escena"]))
		add_child(boton)
		_botones.append(boton)

		var detalle := Label.new()
		detalle.name = "DetalleNivel%d" % (i + 1)
		detalle.text = nivel["detalle"]
		detalle.add_theme_font_size_override("font_size", 18)
		detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detalle.add_theme_color_override("font_color", Color(0.78, 0.83, 0.95))
		detalle.set_anchors_preset(Control.PRESET_CENTER_TOP)
		detalle.offset_left = -400
		detalle.offset_right = 400
		detalle.offset_top = TOP + PASO * i + ALTO + 4
		detalle.offset_bottom = TOP + PASO * i + ALTO + 28
		_aplicar_sombra(detalle)
		add_child(detalle)


func _cargar_nivel(escena: String) -> void:
	get_tree().change_scene_to_file(escena)


func _aplicar_sombra(label: Label) -> void:
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
