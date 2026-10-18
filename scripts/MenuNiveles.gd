extends Control
class_name MenuNiveles

## Version 0.8 - Pantalla de inicio
## Menu principal con cuatro opciones: JUGAR (nivel 1), TUTORIAL, OPCIONES
## (todavia sin efecto) y SALIR (cierra el juego). La progresion entre niveles
## no vive aqui: cada aula define su "siguiente_escena" y al ganar se avanza
## al siguiente nivel hasta volver a este menu.
##
## Ademas de soportar mouse, los botones se manejan con las flechas del
## teclado (ui_up/ui_down) y se confirman con el boton de accion del juego
## (accion), el mismo que se usa para mashear y lanzar. Tambien responde a
## ui_accept (ENTER/Espacio) si se juega con teclado.
##
## La UI se crea 100% por codigo (mismo estilo que el resto del proyecto):
## fondo degradado, titulo con latido, botones con StyleBoxFlat y una
## descripcion dinamica que cambia segun el boton con foco.

const OPCIONES = [
	{
		"nombre": "JUGAR",
		"detalle": "Entra directo al nivel 1.",
		"accion": "jugar",
	},
	{
		"nombre": "TUTORIAL",
		"detalle": "Aprende a crear y entregar machetes.",
		"accion": "tutorial",
	},
	{
		"nombre": "OPCIONES",
		"detalle": "Proximamente.",
		"accion": "opciones",
	},
	{
		"nombre": "SALIR",
		"detalle": "Cierra el juego.",
		"accion": "salir",
	},
]

const COLOR_ACENTE := Color(0.25, 0.8, 0.35)

var _botones: Array[Button] = []

var _descripcion: Label

## Evita que una misma pulsacion dispare la accion dos veces (por ejemplo si
## el boton reacciona a ui_accept y ademas entra por _input).
var _activando: bool = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.10, 0.13, 0.22))
	_crear_fondo()
	_crear_titulo()
	_crear_botones()
	_crear_descripcion()
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
	titulo.add_theme_font_size_override("font_size", 96)
	titulo.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	titulo.offset_left = -500
	titulo.offset_right = 500
	titulo.offset_top = 70
	titulo.offset_bottom = 200
	_aplicar_sombra(titulo)
	add_child(titulo)
	# El titulo "late" igual que los companeros y el jugador. El pivot en el
	# centro (calculado ya con el tamano real) hace que el latido sea simetrico.
	titulo.pivot_offset = titulo.size / 2.0
	Fx.respirar_control(titulo, 0.03, 1.4)


func _crear_botones() -> void:
	const ANCHO := 480.0
	const ALTO := 70.0
	const TOP := 280.0
	const PASO := 100.0

	for i in OPCIONES.size():
		var opcion: Dictionary = OPCIONES[i]

		var boton := Button.new()
		boton.name = "Boton%s" % String(opcion["accion"]).capitalize()
		boton.text = opcion["nombre"]
		boton.add_theme_font_size_override("font_size", 34)
		boton.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
		boton.set_anchors_preset(Control.PRESET_CENTER_TOP)
		boton.offset_left = -ANCHO / 2.0
		boton.offset_right = ANCHO / 2.0
		boton.offset_top = TOP + PASO * i
		boton.offset_bottom = TOP + PASO * i + ALTO
		_aplicar_estilo_boton(boton)
		boton.pressed.connect(_activar_opcion.bind(i))
		boton.focus_entered.connect(_actualizar_descripcion.bind(i))
		boton.mouse_entered.connect(_actualizar_descripcion.bind(i))
		add_child(boton)
		_botones.append(boton)


## Estilo moderno por codigo: fondo semitransparente, esquinas redondeadas y
## acento verde al enfocar/pasar el mouse (sin depender de assets).
func _aplicar_estilo_boton(boton: Button) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(1.0, 1.0, 1.0, 0.07)
	sb_normal.set_corner_radius_all(14)
	sb_normal.content_margin_left = 24.0
	sb_normal.content_margin_right = 24.0
	sb_normal.content_margin_top = 10.0
	sb_normal.content_margin_bottom = 10.0
	boton.add_theme_stylebox_override("normal", sb_normal)

	var sb_hover: StyleBoxFlat = sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(1.0, 1.0, 1.0, 0.14)
	boton.add_theme_stylebox_override("hover", sb_hover)

	var sb_foco: StyleBoxFlat = sb_normal.duplicate() as StyleBoxFlat
	sb_foco.bg_color = Color(COLOR_ACENTE.r, COLOR_ACENTE.g, COLOR_ACENTE.b, 0.18)
	sb_foco.border_color = Color(COLOR_ACENTE.r, COLOR_ACENTE.g, COLOR_ACENTE.b, 0.9)
	sb_foco.set_border_width_all(2)
	boton.add_theme_stylebox_override("focus", sb_foco)

	var sb_presionado: StyleBoxFlat = sb_normal.duplicate() as StyleBoxFlat
	sb_presionado.bg_color = Color(COLOR_ACENTE.r, COLOR_ACENTE.g, COLOR_ACENTE.b, 0.35)
	boton.add_theme_stylebox_override("pressed", sb_presionado)


## Un solo label de descripcion que cambia segun el boton con foco (o al
## pasar el mouse), en vez de una etiqueta fija por boton.
func _crear_descripcion() -> void:
	_descripcion = Label.new()
	_descripcion.name = "Descripcion"
	_descripcion.text = OPCIONES[0]["detalle"]
	_descripcion.add_theme_font_size_override("font_size", 20)
	_descripcion.add_theme_color_override("font_color", Color(0.78, 0.83, 0.95))
	_descripcion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_descripcion.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_descripcion.offset_left = -500
	_descripcion.offset_right = 500
	_descripcion.offset_top = 680
	_descripcion.offset_bottom = 710
	_aplicar_sombra(_descripcion)
	add_child(_descripcion)


func _actualizar_descripcion(indice: int) -> void:
	if _descripcion == null or not is_instance_valid(_descripcion):
		return
	_descripcion.text = OPCIONES[indice]["detalle"]


func _activar_opcion(indice: int) -> void:
	if _activando:
		return
	match OPCIONES[indice]["accion"]:
		"jugar":
			_activando = true
			get_tree().change_scene_to_file("res://scenes/Aula.tscn")
		"tutorial":
			_activando = true
			get_tree().change_scene_to_file("res://scenes/TutorialAula.tscn")
		"opciones":
			pass
		"salir":
			_activando = true
			get_tree().quit()


## El menu se confirma con el BOTON DE ACCION del juego (accion), el mismo que
## se usa para mashear/lanzar en las aulas. El input map solo define "accion"
## (botones 0 a 3 del pad), asi que el confirm de los botones del menu no podia
## depender de ui_accept. Tambien se acepta ui_accept (ENTER/Espacio).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("accion") or event.is_action_pressed("ui_accept"):
		_confirmar_seleccion()


## Confirma el boton que tenga el foco; si no hay ninguno con foco, activa la
## primera opcion (JUGAR). _activar_opcion() se encarga de no repetir.
func _confirmar_seleccion() -> void:
	var foco := get_viewport().gui_get_focus_owner()
	for i in _botones.size():
		if _botones[i] == foco:
			_activar_opcion(i)
			return
	_activar_opcion(0)


func _aplicar_sombra(label: Label) -> void:
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
