SMODS.Atlas({
    key = "Selected_sticker",
    path = "Selected_sticker.png",
    px = 71,
    py = 95,
})

SMODS.Sticker {
    key = "selected",
    atlas = "Selected_sticker",
	badge_colour = HEX("FD5F56"),
    pos = {x = 0, y = 0},
    default_compat = false,
    needs_enable_flag = true,
    hide_badge = false,
}