extends Node
class_name EverglenNavalSystem

## Everglen naval layer.
## Attach as a child of the world controller and feed it settlement positions.
## Vessel textures are expected at res://assets/everglen/vessels/.

const VESSEL_PATHS := {
    "boat": "res://assets/everglen/vessels/boat.png",
    "sailboat": "res://assets/everglen/vessels/sailboat.png",
    "sailship": "res://assets/everglen/vessels/sailship.png"
}

const TYPE_CIVILIAN := "civilian"
const TYPE_MILITARY := "military"

var routes: Array = []
var vessels: Array = []
var vessel_textures: Dictionary = {}
var rng := RandomNumberGenerator.new()
var elapsed := 0.0

func _ready() -> void:
    rng.randomize()
    _load_vessel_textures()

func _load_vessel_textures() -> void:
    for vessel_type in VESSEL_PATHS:
        var texture = load(VESSEL_PATHS[vessel_type])
        if texture:
            vessel_textures[vessel_type] = texture

func configure_sea_routes(sea_routes: Array) -> void:
    routes = sea_routes.duplicate(true)
    vessels.clear()
    for route in routes:
        if route.get("type", "sea") != "sea":
            continue
        var distance: float = float(route.get("distance", 1.0))
        var count := clampi(int(distance / 260.0), 1, 3)
        for i in range(count):
            var military := rng.randf() < 0.18
            vessels.append({
                "route": route,
                "progress": rng.randf(),
                "speed": rng.randf_range(0.018, 0.035),
                "kind": _pick_vessel_kind(military),
                "military": military,
                "heading": 0.0
            })

func _pick_vessel_kind(military: bool) -> String:
    if military:
        # The supplied pack is civilian, so military vessels currently use
        # the sailship silhouette as a temporary fallback until dedicated
        # warship art is imported.
        return "sailship"
    var roll := rng.randf()
    if roll < 0.35:
        return "boat"
    if roll < 0.72:
        return "sailboat"
    return "sailship"

func _process(delta: float) -> void:
    elapsed += delta
    for vessel in vessels:
        vessel.progress = fmod(float(vessel.progress) + float(vessel.speed) * delta, 1.0)
        var route: Dictionary = vessel.route
        var a: Vector2 = route.get("from", Vector2.ZERO)
        var b: Vector2 = route.get("to", Vector2.ZERO)
        var p: Vector2 = a.lerp(b, float(vessel.progress))
        var look_ahead := a.lerp(b, fmod(float(vessel.progress) + 0.01, 1.0))
        vessel.heading = p.angle_to_point(look_ahead)

func draw_vessels(target: CanvasItem, scale: float = 1.0) -> void:
    for vessel in vessels:
        var route: Dictionary = vessel.route
        var a: Vector2 = route.get("from", Vector2.ZERO)
        var b: Vector2 = route.get("to", Vector2.ZERO)
        var p: Vector2 = a.lerp(b, float(vessel.progress))
        var texture = vessel_textures.get(vessel.kind)
        if texture:
            var size := texture.get_size() * (scale * 0.18)
            var rect := Rect2(p - size * 0.5, size)
            target.draw_texture_rect(texture, rect, false)
        else:
            _draw_fallback_vessel(target, p, vessel.heading, scale, vessel.military)

func _draw_fallback_vessel(target: CanvasItem, p: Vector2, heading: float, scale: float, military: bool) -> void:
    var length := 13.0 * scale
    var width := 5.0 * scale
    var forward := Vector2.from_angle(heading)
    var side := Vector2(-forward.y, forward.x)
    var hull := PackedVector2Array([
        p + forward * length,
        p + side * width - forward * length * 0.55,
        p - forward * length,
        p - side * width - forward * length * 0.55
    ])
    target.draw_colored_polygon(hull, Color("#7b4f32"))
    target.draw_line(p - forward * 2.0, p + forward * 2.0, Color("#d4b06a"), maxf(1.0, scale))
    if military:
        target.draw_line(p - side * width, p + side * width, Color("#9d3f3f"), maxf(1.0, scale))
