extends Node2D
class_name Companero

## Representa a un companero de clase, ubicado en una de las 8 direcciones
## alrededor del jugador (grilla 3x3, ver documento de diseno).

enum Direccion {
	ARRIBA,
	ABAJO,
	IZQUIERDA,
	DERECHA,
	ARRIBA_IZQUIERDA,
	ARRIBA_DERECHA,
	ABAJO_IZQUIERDA,
	ABAJO_DERECHA,
}

enum Estado {
	PREPARADO,   ## Verde: listo para recibir el machete.
	ADVERTENCIA, ## Amarillo: a punto de distraerse (todavia valido, ver doc).
	DISTRAIDO,   ## Gris/default: no se le puede pasar el machete.
}

const COLOR_PREPARADO := Color(0.25, 0.8, 0.35)
const COLOR_ADVERTENCIA := Color(0.95, 0.85, 0.2)
const COLOR_DISTRAIDO := Color(0.55, 0.55, 0.55)

@export var direccion: Direccion = Direccion.ARRIBA

@export var estado: Estado = Estado.DISTRAIDO:
	set(value):
		estado = value
		_actualizar_color()

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	_actualizar_color()


func _actualizar_color() -> void:
	if not is_instance_valid(visual):
		return
	match estado:
		Estado.PREPARADO:
			visual.color = COLOR_PREPARADO
		Estado.ADVERTENCIA:
			visual.color = COLOR_ADVERTENCIA
		Estado.DISTRAIDO:
			visual.color = COLOR_DISTRAIDO


## Segun el documento: en el primer prototipo, "amarillo" (advertencia)
## todavia se considera un lanzamiento valido.
func esta_disponible() -> bool:
	return estado == Estado.PREPARADO or estado == Estado.ADVERTENCIA
