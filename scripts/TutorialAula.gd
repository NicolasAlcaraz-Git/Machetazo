extends Aula
class_name TutorialAula

## Tutorial guiado en 3 fases + el juego normal del nivel.
##
## El objetivo es que el jugador no se vea abrumado con todas las mecanicas de
## golpe: primero aprende a spamear, despues a apuntar y entregar, y recien
## ahi se activa la profesora.
##
##   Fase 1 (MASH):         la profesora y los 8 companeros estan
##                          DESACTIVADOS. Solo hay que spamear el boton para
##                          preparar el set. Errar no puede pasar: no hay a
##                          quien fallarle. Se muestra un sprite animado del
##                          boton siendo spameado + un texto.
##                          (La compulsa de entrega de Aula.gd, activa en
##                          todos los niveles desde v0.7, ya mantiene a los
##                          companeros en gris mientras no haya machetes en
##                          mano: esta fase es el caso extremo de esa regla.)
##
##   Fase 2 (AIM_DELIVER):  la profesora SIGUE desactivada (tirar a un
##                          companero distraido no penaliza ni la delata) y
##                          los 8 companeros ya se activan (verde/amarillo/
##                          gris). Se muestra un sprite animado de la palanca
##                          recorriendo las 8 direcciones mas el boton de
##                          accion + un texto, y una flecha chica encima de
##                          CADA companero que puede recibir un machete.
##
##   Fase 3 (NORMALIZE):    al entregar el PRIMER set completo (8 machetes)
##                          la profesora se activa y el juego sigue normal:
##                          hay que seguir preparando y entregando hasta
##                          agotar a los 8 companeros. Un signo de
##                          exclamacion acompana a la profesora mientras esta
##                          en amarillo (aviso) o en rojo (peligro). Las
##                          flechas de los companeros siguen apareciendo.
##
## Las flechas se muestran SIEMPRE que un companero pueda recibir un machete,
## tanto en la fase 2 como en la 3. El tutorial es un nivel mas: corre igual
## en todas las partidas, sin guardados ni "solo la primera vez".
##
## IMPORTANTE: este proyecto no tiene ningun sprite ni animacion en disco.
## Todo lo que se ve en el tutorial (flechas, signos, boton, palanca) se
## DIBUJA pixel a pixel aca abajo y se convierte en texturas en memoria.

enum Step {
	MASH,          ## Fase 1: solo spamear el boton para crear el set.
	AIM_DELIVER,   ## Fase 2: apuntar y entregar (sin profesora).
	NORMALIZE,     ## Fase 3: juego normal hasta agotar a los 8 companeros.
}

## Colores de los indicadores.
const COLOR_FLECHA := Color(0.35, 0.95, 0.45, 0.95)
const COLOR_EXCL_AMARILLA := Color(0.95, 0.85, 0.2)
const COLOR_EXCL_ROJA := Color(0.95, 0.25, 0.25)

## Separacion (en pixeles de pantalla) entre el companero y su flecha, y
## entre la profesora y su signo de exclamacion.
const OFFSET_FLECHA_Y := -68.0
const OFFSET_EXCL_Y := -96.0

## Donde se ubica el panel de instruccion (pixeles de pantalla). Esquina
## superior derecha: el HUD solo ocupa la izquierda y ningun companero del
## tutorial llega tan arriba a la derecha, asi que nunca se superpone.
const PANEL_POS := Vector2(890, 92)
const PANEL_LABEL_POS := Vector2(756, 160)
const PANEL_LABEL_SIZE := Vector2(266, 134)

## Texto de ayuda de cada fase.
const TEXTO_MASH := "SPAMEA EL BOTÓN\npara preparar los machetes"
const TEXTO_APUNTAR := "MOVÉ LA PALANCA y TIRÁ\nal alumno con flecha"
const TEXTO_CUIDADO := "¡NO TE DEJES VER!\nprepará y entregá hasta el final"


var step := Step.MASH

# --- UI (todo generado por codigo, ver _dibujar_* mas abajo) ---

var layer_ui: CanvasLayer
var sprite_button_spam: AnimatedSprite2D
var sprite_stick_btn: AnimatedSprite2D
var label_instruccion: Label
var excl_advert: Sprite2D
var excl_mira: Sprite2D

## Una flecha por companero que puede recibir machetes (o sea, por cada uno
## que NO es extension). Se muestran y ocultan siguiendo el estado de su
## companero en las fases 2 y 3.
var _flechas: Array[Sprite2D] = []


func _ready() -> void:
	var db = get_node_or_null("DifuminadoBordes")
	if db != null:
		db.queue_free()
	is_tutorial = true
	penalties_enabled = false
	super._ready()
	if is_instance_valid(barra_machete):
		barra_machete.visible = true
	if is_instance_valid(label_en_mano):
		label_en_mano.visible = true
	_setup_companeros_tutorial()
	_setup_enemigos_tutorial()
	_create_ui()
	_set_step(Step.MASH)


## Los 8 companeros arrancan apagados: en la fase 1 todavia no se puede tirar
## nada. Ojo que la compulsa de entrega de Aula.gd (v0.7) ya lo garantiza por
## su cuenta, porque en esta fase el jugador no tiene machetes en mano; esto se
## mantiene para que la fase 1 sea explicita y no dependa de ese estado.
func _setup_companeros_tutorial() -> void:
	for c in companeros:
		c.active = false
		c.set_active(false)
		if is_instance_valid(c.visual):
			c.visual.modulate = Color(0.5, 0.5, 0.5, 0.8)


## La profesora y el buchon arrancan apagados: hasta la fase 3 no pueden
## delatar al jugador.
func _setup_enemigos_tutorial() -> void:
	if is_instance_valid(profesora):
		profesora.enabled = false
	if buchon != null and is_instance_valid(buchon):
		buchon.enabled = false


func _create_ui() -> void:
	layer_ui = CanvasLayer.new()
	layer_ui.name = "CapaTutorialUI"
	layer_ui.layer = 3
	add_child(layer_ui)

	_crear_label_instruccion()
	_crear_flechas()
	_crear_signos_profesora()
	_crear_anim_boton_spam()
	_crear_anim_palanca()


# --- Posicionamiento: mundo -> pantalla ---
#
# Los sprites de este tutorial viven en un CanvasLayer (capas de pantalla,
# SIN camara). Los companeros y la profesora viven en el mundo (CON camara).
# Por eso las posiciones del mundo hay que pasarlas por el canvas transform
# del viewport antes de usarlas como posicion de pantalla; si se usan tal
# cual, los indicadores quedan dibujados en coordenadas de mundo y caen
# fuera de la pantalla.


## Convierte una posicion del mundo a pixeles de pantalla (el mismo espacio
## en el que se posicionan el HUD y los sprites de este CanvasLayer).
func _a_pantalla(pos_mundo: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * pos_mundo


# --- Creacion de la UI ---


func _crear_label_instruccion() -> void:
	label_instruccion = Label.new()
	label_instruccion.name = "LabelInstruccion"
	label_instruccion.add_theme_font_size_override("font_size", 19)
	label_instruccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_instruccion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_instruccion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_instruccion.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	label_instruccion.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label_instruccion.add_theme_constant_override("shadow_offset_x", 2)
	label_instruccion.add_theme_constant_override("shadow_offset_y", 2)
	label_instruccion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_instruccion.position = PANEL_LABEL_POS
	label_instruccion.size = PANEL_LABEL_SIZE
	layer_ui.add_child(label_instruccion)


## Una flecha por companero (menos las extensiones, que son puentes). Se
## visibilidad las maneja _actualizar_flechas().
func _crear_flechas() -> void:
	var textura := _textura_flecha()
	for c in companeros:
		if c.es_extension:
			continue
		var flecha := Sprite2D.new()
		flecha.name = "Flecha"
		flecha.texture = textura
		flecha.visible = false
		layer_ui.add_child(flecha)
		_flechas.append(flecha)


## Los dos signos de exclamacion de la profesora (uno para el estado
## amarillo y otro para el rojo). Se muestran siguiendo su estado real.
func _crear_signos_profesora() -> void:
	excl_advert = _crear_signo("ExclamacionAmarilla", COLOR_EXCL_AMARILLA)
	excl_mira = _crear_signo("ExclamacionRoja", COLOR_EXCL_ROJA)


func _crear_signo(nombre: String, color: Color) -> Sprite2D:
	var signo := Sprite2D.new()
	signo.name = nombre
	signo.texture = _textura_exclamacion(color)
	signo.visible = false
	layer_ui.add_child(signo)
	return signo


# --- Updates por frame ---


func _process(delta: float) -> void:
	super._process(delta)
	_actualizar_flechas()
	_actualizar_signos_profesora()
	_process_pasos()


## Muestra una flecha encima de CADA companero que puede recibir un machete
## ahora mismo, y la saca en cuanto deja de poder. Activo en las fases 2 y 3
## (en la fase 1 los companeros estan apagados y no hay a quien apuntarle).
func _actualizar_flechas() -> void:
	var mostrar := step == Step.AIM_DELIVER or step == Step.NORMALIZE
	var i := 0
	for c in companeros:
		if c.es_extension:
			continue
		if i >= _flechas.size():
			break
		var flecha := _flechas[i]
		i += 1
		if not mostrar or not is_instance_valid(c):
			flecha.visible = false
			continue
		# PREPARADO (verde) y ADVERTENCIA (amarillo) siguen siendo tiros
		# validos, asi que la flecha aparece en los dos. En OCUPADO
		# (verde oscuro, esta copiando) y en DISTRAIDO (gris) no: ahi no
		# se puede tirar.
		var disponible := c.estado == Companero.Estado.PREPARADO \
			or c.estado == Companero.Estado.ADVERTENCIA
		flecha.visible = disponible
		if disponible:
			flecha.position = _a_pantalla(c.global_position) \
				+ Vector2(0, OFFSET_FLECHA_Y)


## El signo de exclamacion sigue a la profesora mientras esta activa
## (fase 3): amarillo mientras esta en ADVERTENCIA, rojo mientras esta en
## MIRA (incluida la gracia de entrada, que ya es roja para el jugador).
func _actualizar_signos_profesora() -> void:
	var activa: bool = step == Step.NORMALIZE and is_instance_valid(profesora)
	var amarilla := false
	var roja := false
	if activa:
		match profesora.estado:
			Profesora.Estado.ADVERTENCIA:
				amarilla = true
			Profesora.Estado.MIRA:
				roja = true

	excl_advert.visible = amarilla
	excl_mira.visible = roja
	if is_instance_valid(profesora):
		var base := _a_pantalla(profesora.global_position) \
			+ Vector2(0, OFFSET_EXCL_Y)
		if amarilla:
			excl_advert.position = base
		if roja:
			excl_mira.position = base


# --- Cambios de fase ---


func _set_step(s: Step) -> void:
	step = s
	match step:
		Step.MASH:
			# Fase 1: sin profesora, sin companeros, sin penalizacion.
			penalties_enabled = false
			_ocultar_indicadores()
			label_instruccion.text = TEXTO_MASH
			sprite_button_spam.visible = true
			for c in companeros:
				c.active = false
				c.set_active(false)
			if is_instance_valid(profesora):
				profesora.enabled = false
			if buchon != null and is_instance_valid(buchon):
				buchon.enabled = false

		Step.AIM_DELIVER:
			# Fase 2: los companeros se activan, la profesora sigue apagada
			# (fallar no cuesta tiempo ni la delata).
			penalties_enabled = false
			_ocultar_indicadores()
			label_instruccion.text = TEXTO_APUNTAR
			sprite_stick_btn.visible = true
			for c in companeros:
				if not c.es_extension:
					c.active = true
					c.set_active(true)
			if is_instance_valid(profesora):
				profesora.enabled = false
			if buchon != null and is_instance_valid(buchon):
				buchon.enabled = false

		Step.NORMALIZE:
			# Fase 3: la profesora entra y el juego corre normal hasta
			# agotar a los 8 companeros. Las flechas de los companeros siguen
			# visibles (las vuelve a prender _actualizar_flechas al frame
			# siguiente); solo se apagan los signos y los sprites de teaching.
			penalties_enabled = true
			_ocultar_indicadores()
			label_instruccion.text = TEXTO_CUIDADO
			if is_instance_valid(profesora):
				profesora.enabled = true
			if buchon != null and is_instance_valid(buchon):
				buchon.enabled = true


## Apaga los indicadores de enseña (sprites del boton y de la palanca, y
## signos de la profesora). Los textos NO se apagan: el de instruccion siempre
## esta. Las flechas de los companeros NO se tocan aqui: las maneja
## _actualizar_flechas() cada frame, asi que en la fase 3 vuelven a prenderse
## solas apenas cambia el estado de cada companero.
func _ocultar_indicadores() -> void:
	if is_instance_valid(sprite_button_spam):
		sprite_button_spam.visible = false
	if is_instance_valid(sprite_stick_btn):
		sprite_stick_btn.visible = false
	if is_instance_valid(excl_advert):
		excl_advert.visible = false
	if is_instance_valid(excl_mira):
		excl_mira.visible = false


func _process_pasos() -> void:
	match step:
		Step.MASH:
			# El set se completo: el jugador ya sabe spamear, pasar a la
			# fase de apuntar.
			if jugador.machetes_en_mano >= 1:
				_set_step(Step.AIM_DELIVER)
		Step.AIM_DELIVER:
			# Se entrego el primer set completo (o se desperdicio todo, lo
			# cual tampoco penaliza): entra la profesora.
			if jugador.machetes_en_mano <= 0:
				_set_step(Step.NORMALIZE)
		Step.NORMALIZE:
			pass


# --- Fin de partida ---
#
# OJO: Aula.mostrar_fin_partida() congela el juego con
# get_tree().paused = true. Los handlers de abajo TIENEN que sacar la pausa
# antes de cambiar de escena: si no, la escena nueva arranca congelada y el
# juego queda trabado para siempre (no hay nada mas que se pueda tocar).


func _volver_al_menu() -> void:
	if _fin_resuelto:
		return
	_fin_resuelto = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MenuNiveles.tscn")


## "SEGUIR JUGANDO": si GANASTE el tutorial, pasa al nivel 1; si perdiste,
## reinicia el tutorial.
func _reiniciar_nivel() -> void:
	if _fin_resuelto:
		return
	_fin_resuelto = true
	get_tree().paused = false
	if _es_victoria and not siguiente_escena.is_empty():
		get_tree().change_scene_to_file(siguiente_escena)
	else:
		get_tree().reload_current_scene()


# ============================================================
#  DIBUJO DE SPRITES POR CODIGO (el proyecto no tiene assets)
#  Cada _textura_* crea una Image vacia y la pinta pixel a pixel.
# ============================================================


func _crear_anim_boton_spam() -> void:
	sprite_button_spam = AnimatedSprite2D.new()
	sprite_button_spam.name = "BotonSpam"
	sprite_button_spam.position = PANEL_POS
	# play()/autoplay solo surten efecto si el nodo todavia no esta en el
	# arbol, por eso se arma la animacion antes de agregarlo.
	_build_anim_button_spam(sprite_button_spam)
	layer_ui.add_child(sprite_button_spam)


## Animacion del boton siendo spameado: la cupula baja y sube (el "click").
func _build_anim_button_spam(a: AnimatedSprite2D) -> void:
	a.sprite_frames = SpriteFrames.new()
	a.sprite_frames.remove_animation("default")
	a.sprite_frames.add_animation("press")
	# 4 frames: arriba, abajo, arriba, abajo -> el spameo ritmico.
	var hundido := [false, true, false, true]
	for i in range(hundido.size()):
		a.sprite_frames.add_frame("press", _textura(_frame_boton_spam(hundido[i])), 0.09)
	a.animation = "press"
	a.autoplay = "press"
	a.play()
	a.visible = false


## Animacion de la palanca + boton de accion: la palanca recorre las 8
## direcciones mientras el boton se pulsa.
func _crear_anim_palanca() -> void:
	sprite_stick_btn = AnimatedSprite2D.new()
	sprite_stick_btn.name = "PalancaBoton"
	sprite_stick_btn.position = PANEL_POS
	_build_anim_stick_btn(sprite_stick_btn)
	layer_ui.add_child(sprite_stick_btn)


func _build_anim_stick_btn(a: AnimatedSprite2D) -> void:
	a.sprite_frames = SpriteFrames.new()
	a.sprite_frames.remove_animation("default")
	a.sprite_frames.add_animation("cycle")
	# 16 frames = 8 direcciones x 2 estados del boton (normal / hundido).
	for dir in range(8):
		for hundido in [false, true]:
			a.sprite_frames.add_frame(
				"cycle", _textura(_frame_palanca(dir, hundido)), 0.12
			)
	a.animation = "cycle"
	a.autoplay = "cycle"
	a.play()
	a.visible = false


# --- Texturas de los indicadores ---


## Flechita verde que se dibuja ARRIBA de cada companero que puede
## recibir un machete (apunta hacia abajo, hacia el).
func _textura_flecha() -> ImageTexture:
	var w := 26
	var h := 40
	var img := _img(w, h)
	# Asta (rectangulo vertical centrado).
	_dibujar_rect(img, Rect2(10, 0, 6, 24), COLOR_FLECHA)
	# Punta (triangulo que se cierra hacia abajo).
	_dibujar_triangulo(img, 13.0, 22.0, 40.0, 11.0, 0.0, COLOR_FLECHA)
	return ImageTexture.create_from_image(img)


## Signo de exclamacion "!" (barra + punto) del color pedido.
func _textura_exclamacion(color: Color) -> ImageTexture:
	var img := _img(24, 62)
	# Barra vertical.
	_dibujar_rect_redondeado(img, Rect2(9, 0, 6, 40), 3, color)
	# Punto.
	_dibujar_rect_redondeado(img, Rect2(7, 48, 10, 10), 5, color)
	return ImageTexture.create_from_image(img)


# --- Frames de las animaciones ---


## Un frame del boton siendo spameado. Es un boton arcade visto de lado:
## una placa fija y una cupula que baja cuando se lo hunde.
func _frame_boton_spam(hundido: bool) -> Image:
	var img := _img(120, 110)
	var base_y := 84.0
	var bajada := 11.0 if hundido else 0.0

	# Placa base (fija).
	_dibujar_rect_redondeado(img, Rect2(12, base_y - 4, 96, 24), 6,
		Color(0.18, 0.19, 0.25, 0.95))
	# Aro donde se encaja la cupula.
	_dibujar_aro(img, Vector2(60, base_y - 8.0), 27.0, 5,
		Color(0.45, 0.47, 0.56, 0.95))
	# Cupula (baja al hundirse).
	var centro := Vector2(60, base_y - 12.0 + bajada)
	var col := Color(0.95, 0.52, 0.18) if not hundido else Color(0.80, 0.40, 0.12)
	_dibujar_circulo(img, centro, 22.0, col)
	# Brillo.
	_dibujar_circulo(img, centro + Vector2(-6, -7), 8.0,
		Color(1, 0.88, 0.65, 0.55 if not hundido else 0.35))
	return img


## Un frame de la palanca + boton: a la izquierda la palanca de 8
## direcciones (con el pomo girando) y a la derecha el boton de accion
## (que se hunde).
func _frame_palanca(dir_index: int, boton_hundido: bool) -> Image:
	var img := _img(160, 112)

	# --- Palanca ---
	var base := Vector2(46, 56)
	# Aro exterior.
	_dibujar_aro(img, base, 36.0, 4, Color(0.50, 0.53, 0.62, 0.95))
	# Marcas de las 8 direcciones.
	for i in range(8):
		var ang_marca := -PI / 2.0 + float(i) * (TAU / 8.0)
		var p := base + Vector2.from_angle(ang_marca) * 30.0
		_dibujar_circulo(img, p, 2.5, Color(0.62, 0.66, 0.76, 0.9))
	# Pomo de la palanca en la direccion dir_index (0=arriba, sentido reloj).
	var ang := -PI / 2.0 + float(dir_index) * (TAU / 8.0)
	var pomo := base + Vector2.from_angle(ang) * 18.0
	_dibujar_linea(img, base, pomo, 5, Color(0.62, 0.66, 0.76))
	_dibujar_circulo(img, pomo, 11.0, Color(0.78, 0.81, 0.88))
	_dibujar_circulo(img, pomo + Vector2(-3, -3), 5.0, Color(0.93, 0.95, 0.98))

	# --- Boton de accion ---
	var cy := 56.0 + (8.0 if boton_hundido else 0.0)
	var cb := Vector2(112, cy)
	# Aro / sombra del boton.
	_dibujar_aro(img, cb + Vector2(0, 3), 24.0, 5, Color(0.35, 0.36, 0.42, 0.95))
	var col := Color(0.95, 0.52, 0.18) if not boton_hundido else Color(0.80, 0.40, 0.12)
	_dibujar_circulo(img, cb, 21.0, col)
	_dibujar_circulo(img, cb + Vector2(-5, -6), 8.0,
		Color(1, 0.88, 0.65, 0.55 if not boton_hundido else 0.35))
	return img


# ============================================================
#  Primitivas de dibujo (pixel a pixel sobre una Image)
# ============================================================


func _img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


## Envuelve una Image dibujada a mano en una textura usable por los sprites.
func _textura(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


func _img_pintar(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, c)


## Rectangulo lleno (con origen arriba a la izquierda).
func _dibujar_rect(img: Image, r: Rect2, c: Color) -> void:
	var x0 := int(r.position.x)
	var y0 := int(r.position.y)
	var x1 := int(r.position.x + r.size.x)
	var y1 := int(r.position.y + r.size.y)
	for y in range(y0, y1):
		for x in range(x0, x1):
			_img_pintar(img, x, y, c)


## Rectangulo con esquinas redondeadas.
func _dibujar_rect_redondeado(img: Image, r: Rect2, radio: float, c: Color) -> void:
	var radio_ef := minf(radio, minf(r.size.x, r.size.y) * 0.5)
	var x0 := int(floor(r.position.x))
	var y0 := int(floor(r.position.y))
	var x1 := int(ceil(r.position.x + r.size.x))
	var y1 := int(ceil(r.position.y + r.size.y))
	for y in range(y0, y1):
		for x in range(x0, x1):
			# Proyecta (x,y) al rectangulo interno (inset por el radio); si
			# esta fuera, mira la distancia a ese rectangulo interno.
			var cx := clampf(float(x), r.position.x + radio_ef,
				r.position.x + r.size.x - radio_ef)
			var cy := clampf(float(y), r.position.y + radio_ef,
				r.position.y + r.size.y - radio_ef)
			var dx := float(x) + 0.5 - cx
			var dy := float(y) + 0.5 - cy
			if dx * dx + dy * dy <= radio_ef * radio_ef:
				_img_pintar(img, x, y, c)


## Triangulo con base horizontal arriba y punta abajo (para la flecha).
func _dibujar_triangulo(img: Image, cx: float, y_top: float, y_bot: float,
		half_top: float, half_bot: float, c: Color) -> void:
	var y0 := int(floor(y_top))
	var y1 := int(ceil(y_bot))
	for y in range(y0, y1):
		var t := float(y - y_top) / maxf(1.0, y_bot - y_top)
		var half := lerpf(half_top, half_bot, clampf(t, 0.0, 1.0))
		var xa := int(floor(cx - half))
		var xb := int(ceil(cx + half))
		for x in range(xa, xb + 1):
			_img_pintar(img, x, y, c)


## Disco lleno.
func _dibujar_circulo(img: Image, c: Vector2, rad: float, col: Color) -> void:
	var r2 := rad * rad
	var x0 := int(floor(c.x - rad - 1))
	var x1 := int(ceil(c.x + rad + 1))
	var y0 := int(floor(c.y - rad - 1))
	var y1 := int(ceil(c.y + rad + 1))
	for y in range(y0, y1):
		for x in range(x0, x1):
			var dx := float(x) + 0.5 - c.x
			var dy := float(y) + 0.5 - c.y
			if dx * dx + dy * dy <= r2:
				_img_pintar(img, x, y, col)


## Anillo (aro) de grosor "grosor".
func _dibujar_aro(img: Image, c: Vector2, rad: float, grosor: float,
		col: Color) -> void:
	var r_in := maxf(0.0, rad - grosor)
	var r_out := rad
	var x0 := int(floor(c.x - r_out - 1))
	var x1 := int(ceil(c.x + r_out + 1))
	var y0 := int(floor(c.y - r_out - 1))
	var y1 := int(ceil(c.y + r_out + 1))
	for y in range(y0, y1):
		for x in range(x0, x1):
			var dx := float(x) + 0.5 - c.x
			var dy := float(y) + 0.5 - c.y
			var d := sqrt(dx * dx + dy * dy)
			if d <= r_out and d >= r_in:
				_img_pintar(img, x, y, col)


## Linea gruesa entre dos puntos (usada para el asta de la palanca).
func _dibujar_linea(img: Image, a: Vector2, b: Vector2, grosor: float,
		col: Color) -> void:
	var pasos := int(ceil(maxf(absf(b.x - a.x), absf(b.y - a.y))))
	for i in range(pasos + 1):
		var t := float(i) / float(maxi(1, pasos))
		_dibujar_circulo(img, a.lerp(b, t), grosor * 0.5, col)
