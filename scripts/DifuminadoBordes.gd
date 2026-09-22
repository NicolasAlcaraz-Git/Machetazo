extends CanvasLayer

## Autoload: degradé suave en los bordes de la pantalla del juego (1024x768)
## donde chocan con las barras negras que pone el motor cuando la ventana es
## mas ancha o mas alta que la resolucion base. El degradé va del azul del
## juego a un azul cada vez mas oscuro, sin llegar nunca al negro: el negro
## puro es exclusivo de las barras del motor. Al ser autoload cubre TODAS las
## escenas (menu, niveles, fin de partida) sin tocar cada una.
##
## Capas: fondo -10, mundo 0, este difuminado 1, HUD 2. Asi el degradé se
## ve sobre el fondo y el mundo, pero la interfaz (labels, barras, botones)
## siempre queda encima y legible.
##
## Cada borde tiene su propia textura de degradé (sin flips, que se veian
## desparejos izquierda/derecha), todas con el mismo ancho y la misma curva
## para que ambos lados luzcan identicos.

## Ancho del difuminado en pixeles de juego. Mientras mas ancho, mas suave.
const ANCHO: float = 250.0

## Azul de llegada del degradé: mas profundo que el fondo del juego pero
## claramente azul, nunca negro.
const COLOR_BORDE := Color(0.033, 0.049, 0.123, 1.0)

## Relacion de aspecto del juego (1024x768 = 4:3).
const ASPECTO_JUEGO: float = 1024.0 / 768.0

## Tolerancia para no dibujar degradés por redondeos de un pixel.
const EPSILON_ASPECTO: float = 0.005

var _borde_izq: TextureRect
var _borde_der: TextureRect
var _borde_arr: TextureRect
var _borde_aba: TextureRect


func _ready() -> void:
	layer = 1

	# Izquierda: el azul oscuro pegado al borde izquierdo de la pantalla.
	_borde_izq = _crear_borde(_crear_textura_h(true))
	_configurar(_borde_izq, Control.PRESET_LEFT_WIDE)
	_borde_izq.offset_right = ANCHO

	# Derecha: el azul oscuro pegado al borde derecho (textura espejada por
	# color, no por flip, para que sea identica al lado izquierdo).
	_borde_der = _crear_borde(_crear_textura_h(false))
	_configurar(_borde_der, Control.PRESET_RIGHT_WIDE)
	_borde_der.offset_left = -ANCHO

	# Arriba: azul oscuro pegado al borde superior.
	_borde_arr = _crear_borde(_crear_textura_v(true))
	_configurar(_borde_arr, Control.PRESET_TOP_WIDE)
	_borde_arr.offset_bottom = ANCHO

	# Abajo: azul oscuro pegado al borde inferior.
	_borde_aba = _crear_borde(_crear_textura_v(false))
	_configurar(_borde_aba, Control.PRESET_BOTTOM_WIDE)
	_borde_aba.offset_top = -ANCHO

	add_child(_borde_izq)
	add_child(_borde_der)
	add_child(_borde_arr)
	add_child(_borde_aba)

	get_window().size_changed.connect(_actualizar_bordes)
	_actualizar_bordes()


## Degradé horizontal (izquierda -> derecha). oscuro_primero = true deja el
## azul oscuro en el lado izquierdo de la textura; false, en el derecho.
func _crear_textura_h(oscuro_primero: bool) -> GradientTexture2D:
	var tex := GradientTexture2D.new()
	tex.gradient = _crear_gradiente(oscuro_primero)
	tex.width = 128
	tex.height = 8
	tex.fill_from = Vector2(0, 0.5)
	tex.fill_to = Vector2(1, 0.5)
	return tex


## Degradé vertical (arriba -> abajo). oscuro_primero = true deja el azul
## oscuro arriba; false, abajo.
func _crear_textura_v(oscuro_primero: bool) -> GradientTexture2D:
	var tex := GradientTexture2D.new()
	tex.gradient = _crear_gradiente(oscuro_primero)
	tex.width = 8
	tex.height = 128
	tex.fill_from = Vector2(0.5, 0)
	tex.fill_to = Vector2(0.5, 1)
	return tex


## Gradiente lineal: COLOR_BORDE opaco a COLOR_BORDE transparente (o al
## reves), interpolando solo el alpha para que el tono azul se mantenga.
func _crear_gradiente(oscuro_primero: bool) -> Gradient:
	var transparente := Color(COLOR_BORDE.r, COLOR_BORDE.g, COLOR_BORDE.b, 0.0)
	var grad := Gradient.new()
	if oscuro_primero:
		grad.set_color(0, COLOR_BORDE)
		grad.set_color(1, transparente)
	else:
		grad.set_color(0, transparente)
		grad.set_color(1, COLOR_BORDE)
	return grad


func _crear_borde(textura: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = textura
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _configurar(rect: TextureRect, preset: Control.LayoutPreset) -> void:
	rect.set_anchors_preset(preset)
	rect.offset_top = 0
	rect.offset_bottom = 0
	rect.offset_left = 0
	rect.offset_right = 0


## Muestra solo los bordes que realmente tienen barra negra detras: laterales
## si la ventana es mas ancha que 4:3, superior/inferior si es mas alta.
## Se recalcula cada vez que cambia el tamano de la ventana.
func _actualizar_bordes() -> void:
	var ventana := get_window()
	if ventana == null:
		return
	var v := Vector2(ventana.size)
	if v.x <= 0.0 or v.y <= 0.0:
		return

	var ratio := v.x / v.y
	var hay_laterales := ratio > ASPECTO_JUEGO + EPSILON_ASPECTO
	var hay_verticales := ratio < ASPECTO_JUEGO - EPSILON_ASPECTO

	_borde_izq.visible = hay_laterales
	_borde_der.visible = hay_laterales
	_borde_arr.visible = hay_verticales
	_borde_aba.visible = hay_verticales
