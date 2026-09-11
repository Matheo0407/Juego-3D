extends CharacterBody3D

# --- Stats ---
var SaludAhora  : int = 100
var SaludMax : int = 100
var ammo : int = 15
var MaxAmmo : int = 15 
var score : int = 0

# --- REFERENCIAS UI ---
var barra_vida: Node = null
var barra_municion: Node = null

# --- REFERENCIAS PARA CONTROLES MÓVILES ---
@onready var touchpad_camara: Control = get_node_or_null("/root/World/CanvasLayer2/TouchpadCamara")

# --- VARIABLES DE MOVIMIENTO Y CAMARA ---
var sens_X = 0.08
var sens_Y = 0.08
const SPEED = 10.0
const JUMP_VELOCITY = 6.0
@onready var camara: Camera3D = $CameraOrbit/Camera3D
@onready var pivote = get_node("CameraOrbit/Camera3D/Gun/Node3D")
@onready var bulletScene = preload("res://bullet.tscn")

# Controles de Rango de Cámara y Sensibilidad Táctil
var rango_vertical_min: float = -70.0
var rango_vertical_max: float = 70.0 
var sens_touch_X: float = 0.15       
var sens_touch_Y: float = 0.15       

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

# Variables lógicas de plataforma
var es_mobile: bool = false
var touchpad_finger_index: int = -1 

func _ready():
	# 1. Detección nativa rigurosa por OS (Evita falsos positivos de pantallas táctiles en PC)
	var os_actual = OS.get_name()
	if os_actual == "Android" or os_actual == "iOS" or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		es_mobile = true

	# 2. Captura del Mouse garantizada para computadoras
	if not es_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# 3. Bandera de Debug avanzada con OS, Arquitectura y Estado de compilación solicitado
	if OS.is_debug_build():
		var tipo_compilacion = "DEBUG"
		var arquitectura = "32-bit"
		if OS.has_feature("64-bit") or OS.has_feature("x86_64") or OS.has_feature("arm64"):
			arquitectura = "64-bit"
			
		if OS.has_feature("arm64") or OS.has_feature("armhf") or OS.has_feature("arm32"): 
			arquitectura += " (ARM)"
		elif OS.has_feature("x86_64") or OS.has_feature("x86"):
			arquitectura += " (Intel/AMD)"
		
		print("--- INFO SISTEMA DEPURACIÓN ---")
		print("OS: %s | Arch de la App: %s | Compilación: %s" % [os_actual, arquitectura, tipo_compilacion])
		print("energia: %s vida: %s ammo: %s score: %s wallkicks: %s VENTANA_MAX: %s restante: %s RECARGA: %s" % [energia, SaludAhora, ammo, score, wallkicks_realizados, VENTANA_COMBO_MAX, ventana_combo_restante, RECARGA_WK_CASTIGO])
		print("---------------------------------")
	
	# 4. Inicialización de componentes gráficos
	add_to_group("player")
	
	barra_vida = get_node_or_null("/root/World/CanvasLayer2/ProgressBar")
	barra_municion = get_node_or_null("/root/World/CanvasLayer2/ProgressBar2")
	
	if barra_vida:
		barra_vida.min_value = 0
		barra_vida.max_value = SaludMax
		barra_vida.value = SaludAhora
		
	if barra_municion:
		barra_municion.min_value = 0
		barra_municion.max_value = MaxAmmo
		barra_municion.value = ammo
		
	# 5. Mapeos de emergencia para teclado en PC
	_configurar_tecla_si_no_existe("ui_left", KEY_A)
	_configurar_tecla_si_no_existe("ui_right", KEY_D)
	_configurar_tecla_si_no_existe("ui_up", KEY_W)
	_configurar_tecla_si_no_existe("ui_down", KEY_S)
	_configurar_tecla_si_no_existe("dash", KEY_SHIFT)

func _configurar_tecla_si_no_existe(accion: String, tecla_codigo: int):
	if not InputMap.has_action(accion):
		InputMap.add_action(accion)
	var ya_mapeada = false
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventKey and evento.physical_keycode == tecla_codigo:
			ya_mapeada = true
	if not ya_mapeada:
		var event = InputEventKey.new()
		event.physical_keycode = tecla_codigo
		InputMap.action_add_event(accion, event)

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
	if Input.is_action_just_pressed("ui_cancel") and not es_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Temporizadores de mecánicas de combo
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

	# --- MOVIMIENTO ADAPTATIVO UNIFICADO (PC Y CELULAR) ---
	# Como el plugin VirtualJoystickDX ya simula presionar ui_left, ui_right, etc.,
	# el código lee el vector directamente de la misma manera para ambos dispositivos.
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

	# --- Salto / Wallkick ---
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
	
	# Disparos separados por plataformas
	if es_mobile:
		if Input.is_action_just_pressed("shoot_mobile"):
			disparar()
	else:
		if Input.is_action_just_pressed("shoot"):
			disparar()

func disparar():
	if ammo > 0: 
		var bullet = bulletScene.instantiate()
		get_tree().get_root().add_child(bullet)
		bullet.global_transform = pivote.global_transform
		bullet.scale = Vector3.ONE
		ammo -= 1
		if barra_municion:
			barra_municion.value = ammo

func add_score(puntosQueDa): score += puntosQueDa
func take_damage(damage):
	SaludAhora -= damage
	if barra_vida: barra_vida.value = SaludAhora
	if SaludAhora <= 0: morirse()
func morirse(): get_tree().reload_current_scene()

func add_healt(vida):
	SaludAhora = clamp(SaludAhora + vida, 0, SaludMax)
	if barra_vida: barra_vida.value = SaludAhora

func add_ammo(municion):
	ammo = clamp(ammo + municion, 0, MaxAmmo)
	if barra_municion: barra_municion.value = ammo

# --- ENTRADAS INTERNA DE ACCIONES SIMULTÁNEAS (Cámara y tacto) ---
func _input(event: InputEvent) -> void:
	# 1. Movimiento de cámara por Mouse (PC)
	if event is InputEventMouseMotion and not es_mobile:
		if camara and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(deg_to_rad(-event.relative.x * sens_X))
			camara.rotate_x(deg_to_rad(-event.relative.y * sens_Y))
			camara.rotation_degrees.x = clamp(camara.rotation_degrees.x, rango_vertical_min, rango_vertical_max)

	# 2. Movimiento de cámara por Touchpad (Celular)
	elif es_mobile:
		if event is InputEventScreenTouch:
			if event.pressed:
				if touchpad_camara and touchpad_camara.get_global_rect().has_point(event.position):
					touchpad_finger_index = event.index
				else:
					var mitad_pantalla = get_viewport().get_visible_rect().size.x / 2.0
					if event.position.x > mitad_pantalla:
						touchpad_finger_index = event.index
			else:
				if event.index == touchpad_finger_index:
					touchpad_finger_index = -1

		elif event is InputEventScreenDrag:
			if event.index == touchpad_finger_index and camara:
				rotate_y(deg_to_rad(-event.relative.x * sens_touch_X))
				camara.rotate_x(deg_to_rad(-event.relative.y * sens_touch_Y))
				camara.rotation_degrees.x = clamp(camara.rotation_degrees.x, rango_vertical_min, rango_vertical_max)
