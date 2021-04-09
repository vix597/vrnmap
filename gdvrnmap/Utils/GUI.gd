tool
extends MeshInstance

var PlayerStats = Utils.get_player_stats()
var viewport : Viewport = null


func _ready():
	# Get the viewport and wait two frames
	viewport = get_node("GUI")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	# Get the texture
	var gui_img = viewport.get_texture()
	
	# Make a new material and set the viewport texture as the texture, then set
	# the material for this MeshInstance to the newly created material.
	var material = SpatialMaterial.new()
	material.flags_unshaded = true
	material.albedo_texture = gui_img
	set_surface_material(0, material)
	
	# Connect to score changed
	PlayerStats.connect("score_changed", self, "_on_PlayerStats_score_changed")


func _on_PlayerStats_score_changed(_amount : int, _result : int):
	# Any time the score changes, switch the viewport's clear mode
	# to clear on next frame to update the score. This will clear
	# once then switch back to clear mode of never.
	viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
