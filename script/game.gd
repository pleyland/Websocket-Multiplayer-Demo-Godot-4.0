extends Control


const _crown = preload("res://img/crown.png")

var _players = []
var _turn = -1

@onready var _list = $HBoxContainer/VBoxContainer/ItemList
@onready var _action = $HBoxContainer/VBoxContainer/Action


#The master and mastersync rpc behavior is not officially supported anymore. Try using another keyword or making custom logic using get_multiplayer().get_remote_sender_id()
@rpc("any_peer", "call_local")
func set_player_name(_name):
	var sender = multiplayer.get_remote_sender_id()
	rpc("update_player_name", sender, _name)


@rpc("any_peer", "call_local") func update_player_name(player, _name):
	var pos = _players.find(player)
	if pos != -1:
		_list.set_item_text(pos, _name)


#The master and mastersync rpc behavior is not officially supported anymore. Try using another keyword or making custom logic using get_multiplayer().get_remote_sender_id()
@rpc ("any_peer","call_local")
func request_action(action):
	var sender = multiplayer.get_remote_sender_id()
	if _players[_turn] != multiplayer.get_remote_sender_id():
		rpc("_log", "Someone is trying to cheat! %s" % str(sender))
		return
	do_action(action)
	next_turn()


@rpc("any_peer", "call_local") func do_action(action):
	var _name = _list.get_item_text(_turn)
	var val = randi() % 100
	rpc("_log", "%s: %ss %d" % [_name, action, val])


@rpc("any_peer", "call_local") func set_turn(turn):
	_turn = turn
	if turn >= _players.size():
		return
	for i in range(0, _players.size()):
		if i == turn:
			_list.set_item_icon(i, _crown)
		else:
			_list.set_item_icon(i, null)
	_action.disabled = _players[turn] != multiplayer.get_unique_id()


@rpc("any_peer", "call_local") func del_player(id):
	var pos = _players.find(id)
	if pos == -1:
		return
	_players.remove_at(pos)
	_list.remove_item(pos)
	if _turn > pos:
		_turn -= 1
	if multiplayer.is_server():
		rpc("set_turn", _turn)


@rpc("any_peer", "call_local") func add_player(id, _name=""):
	_players.append(id)
	if _name == "":
		_list.add_item("... connecting ...", null, false)
	else:
		_list.add_item(_name, null, false)


func get_player_name(pos):
	if pos < _list.get_item_count():
		return _list.get_item_text(pos)
	else:
		return "Error!"


func next_turn():
	_turn += 1
	if _turn >= _players.size():
		_turn = 0
	rpc("set_turn", _turn)


func start():
	set_turn(0)


func stop():
	_players.clear()
	_list.clear()
	_turn = 0
	_action.disabled = true


func on_peer_add(id):
	if not multiplayer.is_server():
		return
	for i in range(0, _players.size()):
		rpc_id(id, "add_player", _players[i], get_player_name(i))
	rpc("add_player", id)
	rpc_id(id, "set_turn", _turn)


func on_peer_del(id):
	if not multiplayer.is_server():
		return
	rpc("del_player", id)


@rpc("any_peer", "call_local") func _log(what):
	$HBoxContainer/RichTextLabel.add_text(what + "\n")


func _on_Action_pressed():
	if multiplayer.is_server():
		do_action("roll")
		next_turn()
	else:
		rpc_id(1, "request_action", "roll")
