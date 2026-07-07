extends Node2D
const ROCAS_SCENE = preload("res://Roca.tscn")

onready var contenedor_rocas = $Rocas
#Genera cada la hormiga


const HORMIGA_SCENE = preload("res://Hormiga.tscn")
const ROCA_SCENE = preload("res://Roca.tscn") # Tu constante de las rocas

onready var contenedor_hormigas = $Hormigas
onready var nav_mesh = $Navigation2D/NavigationPolygonInstance


onready var nodo_hormiguero_comun = $Hormiguero
onready var nodo_hormiguero_rojo = $HormigueroRojo

func _ready():
	randomize() 

#Generacion Hormigas

func _on_TextureButtonComun_pressed():
	var nueva_hormiga = HORMIGA_SCENE.instance()
	nueva_hormiga.faccion = "COMUN"
	
	#Posibilidad de Clases 0.50=50%
	if randf() < 0.50:
		nueva_hormiga.clase = "GUERRERA"
	else:
		nueva_hormiga.clase = "RECOLECTORA"
	
	if nodo_hormiguero_comun:
		nueva_hormiga.global_position = nodo_hormiguero_comun.global_position
	else:
		nueva_hormiga.global_position = Vector2(220, 1120)
		
	contenedor_hormigas.add_child(nueva_hormiga)
	print("Hormiga Común nacida. Clase: ", nueva_hormiga.clase)


func _on_TextureButtonRojo_pressed():
	var nueva_hormiga = HORMIGA_SCENE.instance()
	nueva_hormiga.faccion = "ROJA"
	
	
	if randf() < 0.50:
		nueva_hormiga.clase = "GUERRERA"
	else:
		nueva_hormiga.clase = "RECOLECTORA"
	
	if nodo_hormiguero_rojo:
		nueva_hormiga.global_position = nodo_hormiguero_rojo.global_position
		
	contenedor_hormigas.add_child(nueva_hormiga)
	print("Hormiga Roja nacida. Clase: ", nueva_hormiga.clase)


#Rocas


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_SPACE:
	
	   var nueva_roca = ROCAS_SCENE.instance()
	
	   var pos_x = get_global_mouse_position().x
	   var pos_y = get_global_mouse_position().y
	   nueva_roca.global_position = Vector2(pos_x, pos_y)
	
	   contenedor_rocas.add_child(nueva_roca)
	   print("Roca nacida en: ", nueva_roca.global_position)
	   actualizar_obstaculos_en_mapa()


func actualizar_obstaculos_en_mapa():
	
	nav_mesh.navpoly.make_polygons_from_outlines()
