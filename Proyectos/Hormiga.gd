extends KinematicBody2D
class_name HormigaBase

var puede_atacar = true

export (String, "COMUN", "ROJA") var faccion = "COMUN"
export (String, "RECOLECTORA", "GUERRERA") var clase = "RECOLECTORA"

enum Estado { DEAMBULAR, IDLE, IR_A_COMIDA, REGRESAR_AL_HORMIGUERO, COMBATIR, HUIR, EN_REFUGIO }
var estado_actual = Estado.DEAMBULAR

export var velocidad = 120
var direccion = Vector2.ZERO
var camino : PoolVector2Array = PoolVector2Array() 
var nodo_navigation : Navigation2D = null

var posicion_comida = Vector2.ZERO
var nodo_comida_actual = null
var posicion_hormiguero = Vector2.ZERO
var objetivo_enemigo: KinematicBody2D = null

onready var timer = $Dembulamiento
onready var visual_carga = $Fragmento 
onready var radar = $VisionHormigas

func _ready():
	randomize()
	timer.connect("timeout", self, "_on_Dembulamiento_timeout")
	radar.connect("body_entered", self, "_on_VisionHormigas_body_entered")
	if visual_carga: visual_carga.visible = false 
	
	nodo_navigation = get_tree().get_root().find_node("Navigation2D", true, false) as Navigation2D
	buscar_hormiguero_propio()
	elegir_nueva_direccion()

func buscar_hormiguero_propio():
	var nombre_hormiguero = "Hormiguero" if faccion == "COMUN" else "HormigueroRojo"
	var hormiguero = get_tree().get_root().find_node(nombre_hormiguero, true, false)
	if hormiguero: 
		posicion_hormiguero = hormiguero.global_position

func _physics_process(delta):
	match estado_actual:
		Estado.DEAMBULAR:
			moverse_por_camino()
			
		Estado.IDLE:
			direccion = Vector2.ZERO
			
		Estado.IR_A_COMIDA:
			if not is_instance_valid(nodo_comida_actual):
				recalcular_a_deambular()
				return
			if camino.size() == 0:
				calcular_camino_hacia(posicion_comida)
			moverse_por_camino()
			if global_position.distance_to(posicion_comida) < 200: 
				recolectar_comida()

		Estado.REGRESAR_AL_HORMIGUERO:
			if camino.size() == 0:
				calcular_camino_hacia(posicion_hormiguero)
			moverse_por_camino()
			if global_position.distance_to(posicion_hormiguero) < 200:
				entregar_comida()
			
		Estado.COMBATIR:
			if not is_instance_valid(objetivo_enemigo) or "estado_actual" in objetivo_enemigo and objetivo_enemigo.estado_actual == Estado.EN_REFUGIO:
				recalcular_a_deambular()
				return
			calcular_camino_hacia(objetivo_enemigo.global_position)
			moverse_por_camino()
			if global_position.distance_to(objetivo_enemigo.global_position) < 80:
				atacar_enemigo()

		Estado.HUIR:
			if camino.size() == 0:
				calcular_camino_hacia(posicion_hormiguero)
			moverse_por_camino()
			if global_position.distance_to(posicion_hormiguero) < 55:
				entrar_al_refugio()

		Estado.EN_REFUGIO:
			direccion = Vector2.ZERO
			visible = false

func calcular_camino_hacia(destino: Vector2):
	if nodo_navigation:
		camino = nodo_navigation.get_simple_path(global_position, destino)

func moverse_por_camino():
	if camino.size() == 0:
		return
	var punto_objetivo = camino[0]
	if global_position.distance_to(punto_objetivo) < 15:
		camino.remove(0)
		if camino.size() == 0:
			return
		punto_objetivo = camino[0] 
	direccion = (punto_objetivo - global_position).normalized()
	move_and_slide(direccion * velocidad)
	if direccion != Vector2.ZERO:
		rotation = direccion.angle()

func elegir_nueva_direccion():
	if randf() < 0.15:
		estado_actual = Estado.IDLE
		camino = PoolVector2Array() 
		timer.start(rand_range(0.5, 1.5))
	else:
		estado_actual = Estado.DEAMBULAR
		var rango_exploracion = 450
		var destino_al_azar = global_position + Vector2(
			rand_range(-rango_exploracion, rango_exploracion), 
			rand_range(-rango_exploracion, rango_exploracion)
		)
		calcular_camino_hacia(destino_al_azar)
		timer.start(rand_range(3.5, 6.0))

func detectar_comida(nodo_comida):
	if estado_actual == Estado.DEAMBULAR or estado_actual == Estado.IDLE:
		nodo_comida_actual = nodo_comida
		posicion_comida = nodo_comida.global_position
		estado_actual = Estado.IR_A_COMIDA
		camino = PoolVector2Array()
		timer.stop()

func recolectar_comida():
	if is_instance_valid(nodo_comida_actual):
		nodo_comida_actual.restar_recurso()
		if visual_carga: visual_carga.visible = true       
		estado_actual = Estado.REGRESAR_AL_HORMIGUERO
		camino = PoolVector2Array() 

func entregar_comida():
	if visual_carga: visual_carga.visible = false         
	camino = PoolVector2Array() 
	if is_instance_valid(nodo_comida_actual):
		estado_actual = Estado.IR_A_COMIDA
	else:
		recalcular_a_deambular()

func _on_VisionHormigas_body_entered(body):
	if "faccion" in body and body.faccion != self.faccion:
		if estado_actual == Estado.COMBATIR or estado_actual == Estado.HUIR or estado_actual == Estado.EN_REFUGIO:
			return
		reaccionar_ante_enemigo(body)

func reaccionar_ante_enemigo(enemigo):
	if clase == "GUERRERA":
		estado_actual = Estado.COMBATIR
		objetivo_enemigo = enemigo
		camino = PoolVector2Array()
		timer.stop()
		print(faccion, " GUERRERA: ¡Al ataque!")
	else:
		estado_actual = Estado.HUIR
		camino = PoolVector2Array()
		timer.stop()
		if visual_carga: visual_carga.visible = false
		print(faccion, " ", clase, ": ¡Huyendo al hormiguero!")

func atacar_enemigo():
	
	if is_queued_for_deletion() or not is_instance_valid(objetivo_enemigo) or objetivo_enemigo.is_queued_for_deletion():
		recalcular_a_deambular()
		return

	
	if "clase" in objetivo_enemigo and objetivo_enemigo.clase == "GUERRERA":
		print("¡Duelo de guerreras! Ambas caen en combate.")
		objetivo_enemigo.queue_free() 
		self.queue_free()             
		return                        

	
	else:
		print("Guerrera elimina a indefensa.")
		objetivo_enemigo.queue_free() # Elimina a la recolectora
		recalcular_a_deambular()
		return

func entrar_al_refugio():
	estado_actual = Estado.EN_REFUGIO
	timer.start(rand_range(3.0, 5.0)) 

func _on_Dembulamiento_timeout():
	if estado_actual == Estado.EN_REFUGIO:
		visible = true
		global_position = posicion_hormiguero
		recalcular_a_deambular()
	elif estado_actual == Estado.DEAMBULAR or estado_actual == Estado.IDLE:
		elegir_nueva_direccion()

func recalcular_a_deambular():
	estado_actual = Estado.DEAMBULAR
	camino = PoolVector2Array()
	elegir_nueva_direccion()
