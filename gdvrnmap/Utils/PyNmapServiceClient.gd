extends Node

signal host_discovered(host)

var connected := false
var ws_client := WebSocketClient.new()
var available_ifaces := []


func _ready():
    # warning-ignore:return_value_discarded
    ws_client.connect("connection_closed", self, "_on_WebSocketClient_closed")
    # warning-ignore:return_value_discarded
    ws_client.connect("connection_error", self, "_on_WebSocketClient_closed")
    # warning-ignore:return_value_discarded
    ws_client.connect("data_received", self, "_on_WebSocketClient_data_received")


func _process(_delta):
    # Call this in _process or _physics_process. Data transfer, and signals
    # emission will only happen when calling this function.
    ws_client.poll()


func connect_websocket(url : String):
    var err := ws_client.connect_to_url(url)
    if err != OK:
        print("ERROR: Unable to connect to websocket at: ", url)
        set_process(false)


func start_host_discovery(cidr : String):
    print("DEBUG: Start host discovery")
    var msg := _get_message(cidr, "discover")
    _send_data(msg)


func _send_data(data : String):
    # warning-ignore:return_value_discarded
    ws_client.get_peer(1).put_packet(data.to_utf8())


func _get_message(contents, mtype : String) -> String:
    var obj = {
        "contents": contents,
        "type": mtype
    }
    return to_json(obj)


func _parse_message(raw_data : String) -> Dictionary:
    var error := validate_json(raw_data)
    if error:
        return {
            "type": "error",
            "contents": "Invalid JSON from server: " + error
        }
    return parse_json(raw_data)


func _populate_ifaces(data : Array):
    for iface in data:
        var name : String = iface.name
        if name.to_lower().find("loopback") != -1:
            continue  # Skip loopback adapters
        if name.to_lower().find("vethernet") != -1:
            continue  # Skip virtual machine adapters
        if name.to_lower().find("hyper-v") != -1:
            continue  # Skip Hyper-V adapters
        if name.to_lower().find("virtualbox") != -1:
            continue  # Skip virtual box adapters
        if name.to_lower().find("bluetooth") != -1:
            continue  # Skip bluetooth adapters

        var skip := false
        for ip in iface.ips:
            if ip.begins_with("169.254"):
                skip = true
                break

        if skip:
            continue  # Skip automatic private IP (no network access)

        # If we haven't skipped yet, add it to the list
        available_ifaces.push_back(iface)

    print("Available interfaces:")
    for iface in available_ifaces:
        print("\tName: ", iface.name)
        print("\tDescription: ", iface.description)
        print("\tIPs: ", iface.ips)


func _on_WebSocketClient_closed(was_clean : bool = false):
    if was_clean:
        print("WebSocket disconnect")
    else:
        print("ERROR: WebSocket disconnected due to error")
    set_process(false)


func _on_WebSocketClient_data_received():
    # Print the received packet, you MUST always use get_peer(1).get_packet
    # to receive data from server, and not get_packet directly when not
    # using the MultiplayerAPI.
    var raw_data := ws_client.get_peer(1).get_packet().get_string_from_utf8()
    var data := _parse_message(raw_data)

    if data.type == "ifaces":
        print("Got ifaces!")
        _populate_ifaces(data.contents)
        connected = true
    elif data.type == "ping":
        print("Got ping!")
    elif data.type == "discover":
        print("Discovered host information!")
        print(data.contents)
        emit_signal("host_discovered", data.contents)
    elif data.type == "error":
        print("ERROR: ", data.contents)
    else:
        print("Unknown message type: ", data.type)
        print("Contents: ", data.contents)
