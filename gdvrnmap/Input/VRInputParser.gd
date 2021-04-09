extends Node
"""
# Controller input map

## HTC Vive 'wand'

### Buttons

* trigger == 15 (JOY_VR_TRIGGER)
* touch_pad == 14 (JOY_VR_PAD)
* menu == 1 (JOY_OPENVR_MENU)
* grip == 2 (JOY_VR_GRIP)

### Axis

* trigger axis == get_joystick_axis(2) (JOY_VR_ANALOG_TRIGGER)
* up/down on track pad == get_joystick_axis(1) (JOY_ANALOG_LY)
* left/right on track pad == get_joystick_axis(0) (JOY_ANALOG_LX)
    * Example: var trackpad_vector = Vector2(-controller.get_joystick_axis(1), controller.get_joystick_axis(0))

## Oculus quest

### Buttons

* trigger == 15 (JOY_VR_TRIGGER)
* thumb-stick press == 14 (JOY_VR_PAD)
* A/X button == 7 (JOY_OCULUS_AX)
* B/Y button == 1 (JOY_OCULUS_BY)
* grip == 2 (JOY_VR_GRIP)
* menu == 3 (JOY_OCULUS_MENU)

### Axis

* trigger axis == get_joystick_axis(2) (JOY_VR_ANALOG_TRIGGER)
* grip axis == get_joystick_axis(4) (JOY_VR_ANALOG_GRIP)
* up/down on thumb-stick == get_joystick_axis(1) (JOY_ANALOG_LY)
* left/rigth on thumb-stick == get_joystick_axis(0) (JOY_ANALOG_LX)
    * Example: var joystick_vector = Vector2(-controller.get_joystick_axis(1), controller.get_joystick_axis(0))
"""

signal controller_initialized()
signal teleport_pressed()
signal teleport_released()
signal trigger_pressed()
signal trigger_released()
signal grip_pressed()
signal grip_released()
signal pause_pressed()
signal pause_released()

enum ControllerType {
    NONE,
    HTC_VIVE,
    OCULUS,
    VALVE_INDEX
}

var type = ControllerType.NONE
var controller : ARVRController = null
var initialized := false
var controller_name : String = ""


func _ready():
    controller = get_parent()


func _process(_delta):
    # Once the controller is active we don't need to
    # bother with the _process callback anymore. We
    # just need to wait until it's active so we know
    # certain attributes (like name) are populated
    if controller.get_is_active() and not initialized:
        controller_name = controller.get_controller_name()
        set_controller_type(controller_name)
        initialized = true
        emit_signal("controller_initialized")

    if not initialized:
        return


func load_controller_mesh() -> Mesh:
    var ovr_render_model := preload("res://addons/godot-openvr/OpenVRRenderModel.gdns").new()
    if ovr_render_model.load_model(controller_name.substr(0, controller_name.length()-2)):
        return ovr_render_model

    if ovr_render_model.load_model("generic_controller"):
        return ovr_render_model

    return Mesh.new()


func set_controller_type(name : String):
    print("DEBUG: Controller ", name, " became active.")
    if "vive" in name.to_lower():
        print("DEBUG: ControllerType.HTC_VIVE")
        type = ControllerType.HTC_VIVE
    elif "oculus" in name.to_lower():
        print("DEBUG: ControllerType.OCULUS")
        type = ControllerType.OCULUS
    else:
        print("DEBUG: TODO - Support this controller: ", name)


func _on_VRController_button_pressed(button):
    match type:
        ControllerType.HTC_VIVE:
            if button == JOY_VR_TRIGGER:
                emit_signal("trigger_pressed")
            elif button == JOY_VR_GRIP:
                emit_signal("grip_pressed")
            elif button == JOY_OPENVR_MENU:
                emit_signal("pause_pressed")
            elif button == JOY_VR_PAD:
                emit_signal("teleport_pressed")
        ControllerType.OCULUS:
            if button == JOY_VR_TRIGGER:
                emit_signal("trigger_pressed")
            elif button == JOY_VR_GRIP:
                emit_signal("grip_pressed")
            elif button == JOY_OCULUS_MENU:
                emit_signal("pause_pressed")
            elif button == JOY_OCULUS_AX or button == JOY_OCULUS_BY or button == JOY_VR_PAD:
                emit_signal("teleport_pressed")


func _on_VRController_button_release(button):
    match type:
        ControllerType.HTC_VIVE:
            if button == JOY_VR_TRIGGER:
                emit_signal("trigger_released")
            elif button == JOY_VR_GRIP:
                emit_signal("grip_released")
            elif button == JOY_OPENVR_MENU:
                emit_signal("pause_released")
            elif button == JOY_VR_PAD:
                emit_signal("teleport_released")
        ControllerType.OCULUS:
            if button == JOY_VR_TRIGGER:
                emit_signal("trigger_released")
            elif button == JOY_VR_GRIP:
                emit_signal("grip_released")
            elif button == JOY_OCULUS_MENU:
                emit_signal("pause_released")
            elif button == JOY_OCULUS_AX or button == JOY_OCULUS_BY or button == JOY_VR_PAD:
                emit_signal("teleport_released")










