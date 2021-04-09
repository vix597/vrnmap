extends Node

var vr_initialized := false
var mobile_vr := false
var mobile_vr_runtime_initialized := false


func instance_scene_on_main(packed_scene: PackedScene, position) -> Node:
    var main := get_tree().current_scene
    var instance : Spatial = packed_scene.instance()
    main.add_child(instance)

    if position is Transform:
        instance.global_transform = position
    elif position is Vector3:
        instance.global_transform.origin = position

    return instance


func initialize_vr():
    if mobile_vr and not mobile_vr_runtime_initialized:
        print("DEBUG: Mobile VR runtime initialized")
        var ovr_performance = preload("res://addons/godot_ovrmobile/OvrPerformance.gdns").new()
        ovr_performance.set_clock_levels(1, 1)
        ovr_performance.set_extra_latency_mode(1)
        mobile_vr_runtime_initialized = true
        return

    if vr_initialized:
        return  # Don't initialize VR more than once

    var vr_interface = ARVRServer.find_interface("OVRMobile")
    if vr_interface:
        print("DEBUG: Mobile VR platform detected")
        var ovr_init_config = preload("res://addons/godot_ovrmobile/OvrInitConfig.gdns").new()
        ovr_init_config.set_render_target_size_multiplier(1)

        if vr_interface.initialize():
            get_viewport().arvr = true

        mobile_vr = true
    else:
        print("DEBUG: Desktop VR platform detected")
        vr_interface = ARVRServer.find_interface("OpenVR")
        if vr_interface and vr_interface.initialize():
            get_viewport().arvr = true
            get_viewport().hdr = false
            OS.vsync_enabled = false
            Engine.target_fps = 90
            # Physics FPS set to 90 in project setttings for smooth interactions
            # Tweak this back to the default of 60 if not making a VR game.

    vr_initialized = true
