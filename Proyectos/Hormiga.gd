extends KinematicBody2D

enum Estado { DEAMBULAR, IDLE, IR_A_COMIDA, REGRESAR_AL_HORMIGUERO }
var estado_actual = Estado.DEAMBULAR

export var velocidad = 120
var direccion = Vector2.ZERO

#Esto controla el movimiento, creo que podria mejorar aun no enitiendo ese Nodo
var camino : PoolVector2Array = PoolVector2Array() 
var nodo_navigation : Navigation2D = null

var posicion_comida = Vector2.ZERO
var nodo_comida_actual = null
var posicion_hormiguero = Vector2.ZERO

onready var timer = $Dembulamiento
onready var visual_carga = $Fragmento 

func _ready():
	randomize()
	timer.connect("timeout", self, "_on_Dembulamiento_timeout")
	if visual_carga: visual_carga.visible = false 
	
	nodo_navigation = get_tree().get_root().find_node("Navigation2D", true, false) as Navigation2D
	
	var hormiguero = get_tree().get_root().find_node("Hormiguero", true, false)
	if hormiguero: posicion_hormiguero = hormiguero.global_position
		
	elegir_nueva_direccion()

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
			
			#Recoleccion de la comida
			if get_slide_count() > 0:
				var choque = get_slide_collision(0)
		
				if choque.collider == nodo_comida_actual:
					recolectar_comida()
					return 
			
			if global_position.distance_to(posicion_comida) < 65: 
				recolectar_comida()
		Estado.REGRESAR_AL_HORMIGUERO:
			if camino.size() == 0:
				calcular_camino_hacia(posicion_hormiguero)
				
			moverse_por_camino()
			
			#Cuando llega al hormiguero
			if get_slide_count() > 0:
				var choque = get_slide_collision(0)
				if choque.collider.name == "Hormiguero":
					entregar_comida()
					return
			
			if global_position.distance_to(posicion_hormiguero) < 60:
				entregar_comida()

#Mas del Nodo de Navegacion

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
	if randf() < 0.2:
		estado_actual = Estado.IDLE
		camino = PoolVector2Array() 
	else:
		estado_actual = Estado.DEAMBULAR
		#Modificando este rango deambulan por mas o menos trechos
		var destino_al_azar = global_position + Vector2(rand_range(-600,600), rand_range(-600, 600))
		calcular_camino_hacia(destino_al_azar)
		
	timer.start(rand_range(1.5, 3.5))

#Cambios de estados

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

func recalcular_a_deambular():
	estado_actual = Estado.DEAMBULAR
	camino = PoolVector2Array()
	elegir_nueva_direccion()

func _on_Dembulamiento_timeout():
	if estado_actual == Estado.DEAMBULAR or estado_actual == Estado.IDLE:
		elegir_nueva_direccion()
