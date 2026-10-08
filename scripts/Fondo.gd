extends Node2D
class_name Fondo

## Fondo del aula: un degradado vertical dibujado por codigo (sin texturas ni
## shaders). Se ubica al fondo de la escena, detras de todos los personajes.

@export var color_superior := Color(0.17, 0.21, 0.33, 1.0)
@export var color_inferior := Color(0.10, 0.13, 0.22, 1.0)
@export var textura: Texture2D

const _TEX_AULA = preload("res://assets/sprites machetazo 1/Aula_1.png")

var _tam: Vector2 = Vector2.ZERO


## Ajusta el tamano del rectangulo que llena el degradado.
func configurar(tam: Vector2) -> void:
	_tam = tam
	queue_redraw()


func _ready() -> void:
	var nombre := ""
	if get_tree() != null and get_tree().current_scene != null:
		nombre = get_tree().current_scene.name
	if nombre == "Aula" or nombre == "Aula2" or nombre == "Aula3" or nombre == "TutorialAula":
		textura = _TEX_AULA


func _draw() -> void:
	if _tam.x <= 0.0 or _tam.y <= 0.0:
		return
	if textura != null:
		draw_texture_rect(textura, Rect2(0, 0, _tam.x, _tam.y), false)
		return
	var bandas := 40
	for i in range(bandas):
		var t: float = float(i) / float(bandas - 1)
		var color: Color = color_superior.lerp(color_inferior, t)
		var y: float = _tam.y * float(i) / float(bandas)
		var alto: float = _tam.y / float(bandas) + 1.0
		draw_rect(Rect2(0, y, _tam.x, alto), color)
