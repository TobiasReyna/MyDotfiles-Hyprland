-- =============================================================================
-- Entrada: teclado (LATAM), mouse y touchpad de laptop
-- =============================================================================

hl.config({
	input = {
		kb_layout = "latam",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,
		numlock_by_default = true,
		accel_profile = "flat",
		sensitivity = 0, -- -1.0 a 1.0 (0 = sin modificación)

		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
		},
	},
})

-- Gesto de 3 dedos horizontal en touchpad para cambiar de workspace
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
