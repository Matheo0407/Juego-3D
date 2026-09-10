extends CharacterBody3D

# --- Stats ---
var SaludAhora  : int = 10
var SaludMax : int = 10
var ammo : int = 15
var score : int = 0
# --- VARIABLES DE MOVIMIENTO Y DASH ---
var sens_X = 0.08
var sens_Y = 0.08
const SPEED = 10.0
const JUMP_VELOCITY = 6.0
@onready var camara: Camera3D = $CameraOrbit/Camera3D
@onready var pivote = get_node("CameraOrbit/Camera3D/Gun/Node3D")
@onready var bulletScene = preload("res://bullet.tscn")
 
const DISTANCIA_DASH = 10.0
const TIEMPO_DASH = 0.2  
var tiempo_dash_restante = 0.0  

var energia: float = 3.0        
const MAX_ENERGIA: float = 3.0 
const TIEMPO_POR_CARGA = 3.0   

const TIEMPO_COOLDOWN = 0.4    
var cooldown_restante = 0.0

# CONFIGURACIÓN DEL WALLKICK
const FUERZA_WALLKICK_UP = 6.5     
const FUERZA_WALLKICK_OUT = 8.5    
const DURACION_IMPULSO_WK = 0.25   
var tiempo_impulso_wk_restante = 0.0

var wallkicks_realizados: int = 0       
const VENTANA_COMBO_MAX = 2.0           
var ventana_combo_restante = 0.0        

const RECARGA_WK_CASTIGO = 2.0          
var bloqueo_recarga_wk = 0.0            

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
		var event = InputEventKey.new()
		event.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("dash", event)


func dash():
	if energia >= 1.0 and cooldown_restante <= 0.0 and camara:
		var dir_dash = -camara.global_transform.basis.z
		dir_dash.y = 0
		dir_dash = dir_dash.normalized()
		
		if dir_dash.length() > 0:
			energia -= 1.0              
			cooldown_restante = TIEMPO_COOLDOWN  
			tiempo_dash_restante = TIEMPO_DASH   
			
			velocity.x = dir_dash.x * (DISTANCIA_DASH * 4.0)
			velocity.z = dir_dash.z * (DISTANCIA_DASH * 4.0)
			
			Global.reproducir("res://dash.mp3") 

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if bloqueo_recarga_wk > 0.0:
		bloqueo_recarga_wk = maxf(0.0, bloqueo_recarga_wk - delta)

	if wallkicks_realizados > 0 and bloqueo_recarga_wk <= 0.0:
		ventana_combo_restante = maxf(0.0, ventana_combo_restante - delta)
		if ventana_combo_restante == 0.0:
			wallkicks_realizados = 0

	if cooldown_restante > 0.0:
		cooldown_restante = maxf(0.0, cooldown_restante - delta)

	if energia < MAX_ENERGIA:
		energia = minf(MAX_ENERGIA, energia + (1.0 / TIEMPO_POR_CARGA) * delta)

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if tiempo_dash_restante > 0.0:
		tiempo_dash_restante -= delta
	elif tiempo_impulso_wk_restante > 0.0:
		tiempo_impulso_wk_restante -= delta
	else:
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall() and not is_on_floor():
			if bloqueo_recarga_wk <= 0.0:
				wallkicks_realizados += 1
				ventana_combo_restante = VENTANA_COMBO_MAX
				
				if wallkicks_realizados >= 3:
					bloqueo_recarga_wk = RECARGA_WK_CASTIGO
					wallkicks_realizados = 0 
				
				var dir_repulsion = get_wall_normal()
				dir_repulsion.y = 0 
				dir_repulsion = dir_repulsion.normalized()
				
				velocity.y = FUERZA_WALLKICK_UP
				velocity.x = dir_repulsion.x * FUERZA_WALLKICK_OUT
				velocity.z = dir_repulsion.z * FUERZA_WALLKICK_OUT
				
				tiempo_impulso_wk_restante = DURACION_IMPULSO_WK
		
	if Input.is_action_just_pressed("dash"):
		dash()
	
	move_and_slide()
	if Input.is_action_just_pressed("shoot"):
		disparar()
func disparar():
	var bullet = bulletScene.instantiate()
	get_tree().get_root().add_child(bullet)
	bullet.global_transform = pivote.global_transform
	# bullet.scale = Vector3.ONE
	ammo -= 1
func _input(event):
	if event is InputEventMouseMotion:
		if camara:
			rotate_y(deg_to_rad(-event.relative.x * sens_X))
			camara.rotate_x(deg_to_rad(-event.relative.y * sens_Y))
