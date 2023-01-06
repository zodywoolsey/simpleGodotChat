extends Control

const PORT = 3000
const MAX_USERS = 4 #not including host

@onready var host = $VBoxContainer3/VBoxContainer/HBoxContainer2/host
@onready var leave = $VBoxContainer3/VBoxContainer/HBoxContainer2/leave
@onready var connect = $VBoxContainer3/VBoxContainer/HBoxContainer/connect
@onready var ipa = $VBoxContainer3/VBoxContainer/HBoxContainer/ip
@onready var chat_display = $VBoxContainer3/VBoxContainer2/chatDisplay
@onready var message :LineEdit = $VBoxContainer3/VBoxContainer2/message
@onready var send = $VBoxContainer3/VBoxContainer2/message/send
@onready var current_ip = $VBoxContainer3/VBoxContainer/HBoxContainer/currentIp

func _ready():
#	OS.shell_open(ProjectSettings.globalize_path("user://"))
	var out = []
	print(OS.execute("python",[ProjectSettings.globalize_path("res://hostname.py")],out))
	var hostname = out[0].replace("\n",'')
	if !hostname:
		if OS.has_feature("windows"):
			if OS.has_environment("COMPUTERNAME"):
				current_ip.text = "your ip: " + IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
		elif OS.has_feature("x11"):
			if OS.has_environment("HOSTNAME"):
				current_ip.text = "your ip: " + IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
		elif OS.has_feature("OSX"):
			if OS.has_environment("HOSTNAME"):
				current_ip.text = "your ip: " + IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
	current_ip.text = "your ip: " + IP.resolve_hostname(hostname, IP.TYPE_IPV4)
	multiplayer.connected_to_server.connect(enter_room)
	multiplayer.peer_connected.connect(user_entered)
	multiplayer.peer_disconnected.connect(user_exited)
	host.pressed.connect(host_room)
	connect.pressed.connect(join_room)
	message.text_submitted.connect(sendMessage)
	send.pressed.connect(sendMessage)
	leave.pressed.connect(leave_room)

func user_entered(id):
	chat_display.add_item(str(id) + " joined the room")

func user_exited(id):
	chat_display.add_item(str(id) + " left the room")

func host_room():
	var host = ENetMultiplayerPeer.new()
	host.create_server(PORT, MAX_USERS)
	multiplayer.multiplayer_peer = host
	enter_room()
	chat_display.add_item("Room Created")

func join_room():
	var ip = ipa.text
	var host = ENetMultiplayerPeer.new()
	host.create_client(ip, PORT)
	multiplayer.multiplayer_peer = host

func enter_room():
	chat_display.add_item("Successfully joined room")
	leave.show()
	connect.hide()
	host.hide()
	ipa.hide()

func leave_room():
	multiplayer.multiplayer_peer = null
	chat_display.add_item("Left Room")
	leave.hide()
	connect.show()
	host.show()
	ipa.show()

@rpc("call_remote","any_peer","reliable")
func displayMessage(msg):
	chat_display.add_item("them: "+msg)

func sendMessage(msg=''):
	if msg == '':
		msg = message.text
	rpc("displayMessage",msg)
	chat_display.add_item("you: "+msg)
	message.clear()
