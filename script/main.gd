extends Control


const DEF_PORT = 8080
const PROTO_NAME = "ludus"

var peer = null

@onready var _host_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Host
@onready var _connect_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Connect
@onready var _disconnect_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Disconnect
@onready var _name_edit = $Panel/VBoxContainer/HBoxContainer/NameEdit
@onready var _host_edit = $Panel/VBoxContainer/HBoxContainer2/Hostname
@onready var _game = $Panel/VBoxContainer/Game
@onready var multiplayerPeer = ENetMultiplayerPeer.new()

func _ready():
	#warning-ignore-all:return_value_discarded
	multiplayer.connect("peer_disconnected",Callable(self,"_peer_disconnected"))
	multiplayer.connect("peer_connected",Callable(self,"_peer_connected"))
	multiplayer.connect("connection_failed",Callable(self,"_close_network"))
	multiplayer.connect("connected_to_server",Callable(self,"_connected"))
	$AcceptDialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$AcceptDialog.get_label().vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		_name_edit.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).replace("\\", "/").split("/")
		_name_edit.text = desktop_path[desktop_path.size() - 2]


func start_game():
	_host_btn.disabled = true
	_name_edit.editable = false
	_host_edit.editable = false
	_connect_btn.hide()
	_disconnect_btn.show()
	_game.start()


func stop_game():
	_host_btn.disabled = false
	_name_edit.editable = true
	_host_edit.editable = true
	_disconnect_btn.hide()
	_connect_btn.show()
	_game.stop()


func _close_network():
	"""
	if multiplayer.is_connected("server_disconnected",Callable(self,"_close_network")):
		multiplayer.disconnect("server_disconnected",Callable(self,"_close_network"))
	if multiplayer.is_connected("connection_failed",Callable(self,"_close_network")):
		multiplayer.disconnect("connection_failed",Callable(self,"_close_network"))
	if multiplayer.is_connected("connected_to_server",Callable(self,"_connected")):
		multiplayer.disconnect("connected_to_server",Callable(self,"_connected"))
	"""	
	
	
	
	
	multiplayerPeer.close()
	multiplayerPeer = ENetMultiplayerPeer.new()

	

	stop_game()
	$AcceptDialog.show()
	$AcceptDialog.get_ok_button().grab_focus()
	


func _connected():
	_game.rpc("set_player_name", _name_edit.text)


func _peer_connected(id):
	_game.on_peer_add(id)
	

func _peer_disconnected(id):
	_game.on_peer_del(id)
	if id==1:
		_close_network()

func _on_Host_pressed():
	
	multiplayerPeer.create_server(DEF_PORT)
	
	if multiplayerPeer.get_connection_status()==MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Connection Failed")
		return
	
	multiplayer.connect("server_disconnected",Callable(self,"_close_network"))
	multiplayer.set_multiplayer_peer(multiplayerPeer)
	
	_game.add_player(1, _name_edit.text)
	
	start_game()


func _on_Disconnect_pressed():
	_close_network()


func _on_Connect_pressed():
	var txt=$Panel/VBoxContainer/HBoxContainer2/Hostname.text
	if txt=="":
		OS.alert("Needs host to connect to")
		return
	multiplayerPeer.create_client(txt,DEF_PORT)
	

	multiplayer.set_multiplayer_peer(multiplayerPeer)
	start_game()
