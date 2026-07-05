extends Node2D

#Genera cada la hormiga
const HORMIGA_SCENE = preload("res://Hormiga.tscn")

onready var contenedor_hormigas = $Hormigas

func _ready():
	randomize() 

#Texture boton es el boton de madera
func _on_TextureButton_pressed():
	
	var nueva_hormiga = HORMIGA_SCENE.instance()
	
	#Cambiar a que use la posicion del homiguero
	var pos_x = 220
	var pos_y = 1120
	nueva_hormiga.global_position = Vector2(pos_x, pos_y)
	
	contenedor_hormigas.add_child(nueva_hormiga)
	print("Hormiga nacida en: ", nueva_hormiga.global_position)


onready var nav_mesh = $Navigation2D/NavigationPolygonInstance


func actualizar_obstaculos_en_mapa():
	
	nav_mesh.bake_navigation_polygon()
