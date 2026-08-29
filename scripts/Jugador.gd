extends Node2D
class_name Jugador

## Estados del jugador (ver punto 4 del documento de diseno).
## En la Version 0.1 el jugador solo existe visualmente en el centro del aula;
## la logica de cada estado se ira agregando en las versiones 0.4 y 0.5.

enum Estado {
	ESPERANDO,  ## Estado inicial: observa, puede empezar a crear un machete.
	CREANDO,    ## Contador 0/10, vulnerable si la profesora mira.
	APUNTANDO,  ## Cursor activo, se elige una de las 8 direcciones.
	LANZANDO,   ## Se confirma el lanzamiento y se resuelve exito/error.
}

@export var estado: Estado = Estado.ESPERANDO

@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	pass # La maquina de estados se implementa a partir de la Version 0.4.
