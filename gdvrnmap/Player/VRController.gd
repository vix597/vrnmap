extends ARVRController
class_name VRController

var controller_velocity := Vector3.ZERO
var prior_controller_position := Vector3.ZERO
var prior_controller_velocities := []
var teleport_pos = null
var teleport_mesh : MeshInstance = null
var teleport_button_down := false
var vr_camera : ARVRCamera = null

onready var teleportRayCast = $TeleportRayCast
onready var input = $VRInputParser
onready var rumbleTimer = $RumbleTimer
onready var controllerMesh = $ControllerMesh


func _ready():
    teleport_mesh = get_tree().root.find_node("*TeleportMesh*", true, false)
    vr_camera = get_parent().find_node("*Camera")

    # Crash if we don't have the required nodes
    assert(teleport_mesh != null)
    assert(vr_camera != null)


func _physics_process(delta):
    if not input.initialized:
        return

    if teleport_button_down:
        update_teleport_raycast()

    update_velocity(delta)


func rumble_for(time : float, intensity : float = 0.5):
    rumble = clamp(rumble + intensity, 0.0, 1.0)
    rumbleTimer.start(time)


func update_teleport_raycast():
    teleportRayCast.force_raycast_update()
    if teleportRayCast.is_colliding():
        # Make sure the normal is approx. straight up and down
        if teleportRayCast.get_collision_normal().y >= 0.85:
            # Set teleport_pos to the raycast point and move the teleport mesh.
            teleport_pos = teleportRayCast.get_collision_point()
            teleport_mesh.global_transform.origin = teleport_pos


func update_velocity(delta):
    # Reset the controller velocity
    controller_velocity = Vector3.ZERO

    if prior_controller_velocities.size() > 0:
        for vel in prior_controller_velocities:
            controller_velocity += vel

        # Get the average velocity, instead of just adding them together.
        controller_velocity = controller_velocity / prior_controller_velocities.size()

    # Add the most recent controller velocity to the list of proper controller velocities
    prior_controller_velocities.append((global_transform.origin - prior_controller_position) / delta)

    # Calculate the velocity using the controller's prior position.
    controller_velocity += (global_transform.origin - prior_controller_position) / delta
    prior_controller_position = global_transform.origin

    # If we have more than a third of a seconds worth of velocities, then we
    # should remove the oldest
    if prior_controller_velocities.size() > 30:
        prior_controller_velocities.remove(0)


func _on_VRInputParser_teleport_pressed():
    teleport_button_down = true
    teleport_mesh.visible = true
    teleportRayCast.visible = true


func _on_VRInputParser_teleport_released():
    # If we have a teleport position, and the teleport mesh is visible, then teleport the player.
    if teleport_pos != null and teleport_mesh.visible:
        # Because of how ARVR origin works, we need to figure out where the player is in relation to the ARVR origin.
        # This is so we can teleport the player at their current position in VR to the teleport position
        var camera_offset = vr_camera.global_transform.origin - get_parent().global_transform.origin
        # We do not want to account for offsets in the player's height.
        camera_offset.y = 0

        # Teleport the ARVR origin to the teleport position, applying the camera offset.
        get_parent().global_transform.origin = teleport_pos - camera_offset

    # Reset the teleport related variables.
    teleport_button_down = false
    teleport_mesh.visible = false
    teleportRayCast.visible = false
    teleport_pos = null


func _on_RumbleTimer_timeout():
    rumble = 0.0


func _on_VRInputParser_controller_initialized():
    controllerMesh.mesh = input.load_controller_mesh()
