extends Spatial

const TestBlock = preload("res://TestBlock.tscn")

var discovery_started := false

onready var spawn = $Spawn


func _ready():
    Utils.initialize_vr()

    # warning-ignore:return_value_discarded
    PyNmapServiceClient.connect("host_discovered", self, "_on_PyNmapServiceClient_host_discovered")

    PyNmapServiceClient.connect_websocket("ws://127.0.0.1:42069")


func _process(_delta):
    if not PyNmapServiceClient.connected:
        return
    if not discovery_started:
        PyNmapServiceClient.start_host_discovery("192.168.1.0/24")
        discovery_started = true


func _on_PyNmapServiceClient_host_discovered(_host):
    # warning-ignore:return_value_discarded
    Utils.instance_scene_on_main(TestBlock, spawn.global_transform)
