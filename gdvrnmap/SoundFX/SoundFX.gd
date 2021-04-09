extends Node

# Auto-load singleton to play sound effects

var sounds_path = "res://SoundFX/"
var impact_sounds_path = sounds_path + "ImpactSounds/"

var sounds := {
    "BallHitBlock": load(impact_sounds_path + "BallHitBlock.ogg"),
    "BallHitPaddle": load(impact_sounds_path + "BallHitPaddle.ogg"),
    "BallHitWall": load(impact_sounds_path + "BallHitWall.ogg")
}

onready var sound_players := $StreamPlayers.get_children()
onready var sound_players_3d := $StreamPlayers3D.get_children()


func play(sound_string : String, pitch_scale : float = 1, volume_db : float = 0):
    for player in sound_players:
        if not player.playing:
            player.pitch_scale = pitch_scale
            player.volume_db = volume_db
            player.stream = sounds[sound_string]
            player.play()
            return
    print("WARNING: Too many sounds playing at once!")


func play_3d(sound_string : String, origin : Vector3, pitch_scale : float = 1.0, volume_db : float = 0.0, max_distance : float = 0.0):
    for player in sound_players_3d:
        if not player.playing:
            player.pitch_scale = pitch_scale
            player.unit_db = volume_db
            player.stream = sounds[sound_string]
            player.global_transform.origin = origin
            player.max_distance = max_distance
            player.play()
            return
    print("WARNING: Too many sounds playing at once!")
