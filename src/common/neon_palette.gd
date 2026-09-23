class_name NeonPalette
extends RefCounted

## Quiet dark-neon tokens — accents, not floodlights.

const VOID := Color("#05060F")
const ABYSS := Color("#070A14")
const FLOOR := Color("#0C1018")
const FLOOR_EDGE := Color("#2A6A78")
const GRID_LINE := Color("#151C28")

const BARRIER_OK := Color("#2B7A88")
const BARRIER_MID := Color("#A88B3A")
const BARRIER_BAD := Color("#A83A55")

const P1 := Color("#3DB8C8")
const P2 := Color("#C84A6A")
const P1_SOFT := Color(0.24, 0.72, 0.78, 0.55)
const P2_SOFT := Color(0.78, 0.29, 0.42, 0.55)

const SHIELD := Color("#4A6FA8")
const ATTACK := Color("#B85070")
const AIM := Color("#C8B45A")

const UI_BG := Color("#080A12")
const UI_PANEL := Color(0.063, 0.086, 0.157, 0.8)
const UI_TEXT := Color("#C8D4E0")
const UI_MUTED := Color("#6A7888")
const UI_ACCENT := Color("#3DB8C8")
const UI_DANGER := Color("#C84A6A")


static func make_emissive(albedo: Color, emission_energy: float = 0.35, transparent: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.emission_enabled = emission_energy > 0.01
	mat.emission = Color(albedo.r, albedo.g, albedo.b).darkened(0.15)
	mat.emission_energy_multiplier = emission_energy
	mat.roughness = 0.55
	mat.metallic = 0.08
	if transparent or albedo.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = albedo.a
	return mat


static func make_unshaded_glow(color: Color, energy: float = 0.45) -> StandardMaterial3D:
	## Soft accent mesh — keep energy low so bloom stays calm.
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var muted := color.darkened(0.25)
	muted.a = color.a
	mat.albedo_color = muted
	mat.emission_enabled = energy > 0.01
	mat.emission = muted
	mat.emission_energy_multiplier = energy
	if color.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


static func make_flat_panel(bg: Color, border: Color, border_w: float = 2.0, radius: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border.darkened(0.2)
	sb.set_border_width_all(int(border_w))
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func make_round_disk(fill: Color, border: Color, border_w: float = 3.0) -> StyleBoxFlat:
	var sb := make_flat_panel(fill, border, border_w, 999)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb
