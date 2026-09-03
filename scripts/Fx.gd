extends Node
class_name Fx

## Utilidades visuales reutilizables (tweens), hechas por codigo sin assets.
## Todos los efectos son decorativos y NO bloquean el gameplay.

## Interpola el "modulate" de un nodo hacia un color de forma suave.
static func color(nodo: CanvasItem, color: Color, duracion: float = 0.25) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	var tween := nodo.create_tween()
	tween.tween_property(nodo, "modulate", color, duracion)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## "Pop": un rebote de escala (1 -> 1 + pico -> 1). Ideal al recibir algo.
static func pop(nodo: Node2D, pico: float = 0.25, duracion: float = 0.16) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	var base := nodo.scale
	var tween := nodo.create_tween()
	tween.tween_property(nodo, "scale", base * (1.0 + pico), duracion * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(nodo, "scale", base, duracion * 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Sacudida rapida de posicion (shake). Ideal al golpear/fallar.
static func shake(nodo: Node2D, intensidad: float = 6.0, duracion: float = 0.15) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	var origen := nodo.position
	var tween := nodo.create_tween()
	for i in range(6):
		var offset := Vector2(
			randf_range(-intensidad, intensidad),
			randf_range(-intensidad, intensidad)
		)
		tween.tween_property(nodo, "position", origen + offset, duracion / 6.0)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(nodo, "position", origen, duracion / 6.0)


## Escala oscilante infinita (idle "respiracion"). Devuelve el tween por si
## se quiere cancelar.
static func respirar(nodo: Node2D, amplitud: float = 0.04, duracion: float = 1.3) -> Tween:
	if nodo == null or not is_instance_valid(nodo):
		return null
	var base := nodo.scale
	var tween := nodo.create_tween().set_loops()
	tween.tween_property(nodo, "scale", base * (1.0 - amplitud), duracion)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(nodo, "scale", base * (1.0 + amplitud), duracion)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween
