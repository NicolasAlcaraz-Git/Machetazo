extends Node2D

## Version 0.3.2 - Aula (director de companeros)
## El jugador, la profesora y los 8 companeros son nodos hijos reales
## dentro de Aula.tscn (podes arrastrarlos en el editor para reacomodarlos).
##
## Ademas de recolectar referencias, este script actua como "director de
## escena" para los companeros: en vez de que cada uno decida por su cuenta
## cuando activarse (lo que generaba coincidencias por simple azar al ser
## 8 procesos en paralelo), Aula.gd decide de a uno (rara vez dos) cuando
## le toca a cada companero abrir su ventana de disponibilidad, respetando
## un maximo simultaneo y una pausa minima entre activaciones.

@onready var label_tiempo: Label = $HUD/LabelTiempo
@onready var label_machetes: Label = $HUD/LabelMachetes

@onready var jugador: Jugador = $Jugador
@onready var profesora: Profesora = $Profesora

var companeros: Array[Companero] = []

## --- Director de companeros ---

## Nunca hay mas de esta cantidad de companeros en PREPARADO/ADVERTENCIA
## al mismo tiempo. Con 2 pueden coincidir ocasionalmente dos, pero nunca
## tres o mas (a proposito, segun lo charlado: 2 esta bien, 3+ ya no).
@export var maximo_simultaneos: int = 3

## Tiempo (segundos) que TODOS los companeros pasan quietos/distraidos al
## arrancar el nivel, antes del primer intento de activacion.
@export var tiempo_inicial_quieto: float = 5.0

## Pausa (segundos, rango min-max) entre el INICIO de una activacion y el
## siguiente intento. Esta es la palanca principal del ritmo del "sigilo"
## de los companeros: valores altos = mas espera entre oportunidades (y
## practicamente nunca se solapan 2); valores bajos = mas oportunidades,
## pero mas chance de que se solapen 2 al mismo tiempo.
@export var pausa_entre_activaciones_min: float = 5.0
@export var pausa_entre_activaciones_max: float = 10.0

var _companeros_activos: Array[Companero] = []
var _tiempo_para_proxima_activacion: float = 0.0


func _ready() -> void:
	for hijo in $Companeros.get_children():
		if hijo is Companero:
			hijo.desactivar()
			companeros.append(hijo)

	_actualizar_ui_placeholder()
	_tiempo_para_proxima_activacion = tiempo_inicial_quieto


func _process(delta: float) -> void:
	_avanzar_companeros_activos(delta)

	_tiempo_para_proxima_activacion -= delta
	if _tiempo_para_proxima_activacion <= 0.0:
		_intentar_activar_uno()


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
## al azar entre los que estan distraidos y no estan ya activos.
func _intentar_activar_uno() -> void:
	_tiempo_para_proxima_activacion = randf_range(
		pausa_entre_activaciones_min, pausa_entre_activaciones_max
	)

	if _companeros_activos.size() >= maximo_simultaneos:
		return # ya hay el maximo permitido, esperamos al proximo intento

	var candidatos: Array[Companero] = []
	for companero in companeros:
		if companero.estado == Companero.Estado.DISTRAIDO:
			candidatos.append(companero)

	if candidatos.is_empty():
		return

	var elegido: Companero = candidatos[randi() % candidatos.size()]
	elegido.activar()
	_companeros_activos.append(elegido)


func _actualizar_ui_placeholder() -> void:
	label_tiempo.text = "TIEMPO: 60"
	label_machetes.text = "MACHETES ENTREGADOS: 0 / 5"


## Utilidad para versiones futuras: devuelve el companero que esta
## en una direccion dada (o null si no existe).
func obtener_companero_en(direccion: Companero.Direccion) -> Companero:
	for companero in companeros:
		if companero.direccion == direccion:
			return companero
	return null
