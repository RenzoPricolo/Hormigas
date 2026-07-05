extends StaticBody2D

enum TipoComida { MANZANA, HOJA, PAN }
export(TipoComida) var tipo_actual = TipoComida.MANZANA
#Este podriamos hacelo variar con la comida elegidas
export var cantidad_recursos = 5

#Para darle diferentes ascpectos a la comida, se repetira el codigo con otras ima
const SPRITE_MANZANA = preload("res://Imagenes/manzana.png")


onready var sprite_nodo = $Sprite
onready var rango_olfato = $RangoOlfato

func _ready():
	actualizar_aspecto_visual()
	
	rango_olfato.connect("body_entered", self, "_on_RangoOlfato_body_entered")

func actualizar_aspecto_visual():
	match tipo_actual:
		TipoComida.MANZANA:
			sprite_nodo.texture = SPRITE_MANZANA


func restar_recurso():
	cantidad_recursos -= 1
	if cantidad_recursos <= 0:
		queue_free() 

func _on_RangoOlfato_body_entered(body):
	
	if body.has_method("detectar_comida"):
		body.detectar_comida(self)
