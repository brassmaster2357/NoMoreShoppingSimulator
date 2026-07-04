local AutoShop = {
    active = false,
    targets = {},
	target_count = 0,
    found = false,
    rerolls = 0,
    max_rerolls = 1000,
    selection_mode = false,
    start_rolls = false
}

local function start_shop_search()
    attention_text({
        text = "Starting Rerolls",
        scale = 1,
        hold = 3,
        major = G.jokers or G.play,
        backdrop_colour = G.C.GREEN
    })

    AutoShop.active = true
    AutoShop.found = false
    AutoShop.rerolls = 0
end

local old_create_card = create_card

create_card = function(...)
    local card = old_create_card(...)

    -- print(card.config.center.key or "unknown")

    local key = card.config.center.key

    if AutoShop.active and AutoShop.targets[key] then
        attention_text({
            text = "Item found",
            scale = 1,
            hold = 3,
            major = G.jokers or G.play,
            backdrop_colour = G.C.GREEN
        })
        AutoShop.found = true
        AutoShop.active = false
        AutoShop.targets[key] = false
    end

    return card
end

local old_draw = Card.draw
function Card:draw(...)
    local card = self
    local key = card.config.center.key

    if AutoShop.targets[key] then
        card:add_sticker('nmSS_selected', true)
    else
        card:remove_sticker('nmSS_selected', true)
    end
    old_draw(self, ...)
end

local function queue_reroll()
    if not AutoShop.active or AutoShop.found or AutoShop.rerolls >= AutoShop.max_rerolls then
        return
    end
	
	if Talisman and type(G.GAME.dollars) == "table" then
		if to_big(G.GAME.dollars) <= to_big(G.GAME.current_round.reroll_cost) then
			return
		end
	else
		if G.GAME.dollars <= G.GAME.current_round.reroll_cost then
			return
		end
	end

    G.E_MANAGER:add_event(Event({
        trigger = "immediate",
        func = function()
            if not AutoShop.active or AutoShop.found or AutoShop.rerolls >= AutoShop.max_rerolls then
                return true
            end

			if Talisman and type(G.GAME.dollars) == "table" then
				if to_big(G.GAME.dollars) <= to_big(G.GAME.current_round.reroll_cost) then
					return
				end
			else
				if G.GAME.dollars <= G.GAME.current_round.reroll_cost then
					return
				end
			end

            AutoShop.rerolls = AutoShop.rerolls + 1

            G.FUNCS.reroll_shop()

            queue_reroll()

            return true
        end
    }))
end


local old_reroll_shop = G.FUNCS.reroll_shop

G.FUNCS.reroll_shop = function(...)
    if AutoShop.start_rolls then
        AutoShop.start_rolls = false
        start_shop_search()
        queue_reroll()
    else
        old_reroll_shop(...)
    end
end

local function get_hovered_card()
    local hover = G.CONTROLLER and G.CONTROLLER.hovering and G.CONTROLLER.hovering.target
    if hover and hover.config and hover.config.center then
        return hover
    end
    return nil
end


SMODS.Keybind {
    key = 'toggleSelectionMode',
    key_pressed = 'f',
    held_keys = { 'lctrl' },

    action = function(self)
        if AutoShop.active then
            attention_text({
                text = "Cancelling Rerolls",
                scale = 1,
                hold = 3,
                major = G.jokers or G.play,
                backdrop_colour = G.C.GREEN
            })
            AutoShop.active = false
            AutoShop.start_rolls = false
        else
            if AutoShop.selection_mode then
                AutoShop.selection_mode = false
				if AutoShop.target_count == 0 then
					attention_text({
						text = "No cards selected",
						scale = 1,
						hold = 3,
						major = G.jokers or G.play,
						backdrop_colour = G.C.GREEN
					})
					AutoShop.start_rolls = false
				else
					attention_text({
						text = string.format("Stopping selection mode, %d total", AutoShop.target_count),
						scale = 1,
						hold = 3,
						major = G.jokers or G.play,
						backdrop_colour = G.C.GREEN
					})
					AutoShop.start_rolls = true
				end
            else
                attention_text({
                    text = "Starting selection mode",
                    scale = 1,
                    hold = 3,
                    major = G.jokers or G.play,
                    backdrop_colour = G.C.GREEN
                })
                AutoShop.selection_mode = true
                AutoShop.start_rolls = false
            end
        end
    end,
}



SMODS.Keybind {
    key = 'selectTarget',
    key_pressed = 'space',

    action = function(self)
        local card = get_hovered_card()

        if not card then
            return
        end
        if not AutoShop.selection_mode then
            return
        end

        local key = card.config.center.key

        AutoShop.targets[key] = not AutoShop.targets[key]
		
		if (AutoShop.targets[key]) then
			AutoShop.target_count = AutoShop.target_count + 1
		else
			AutoShop.target_count = AutoShop.target_count - 1
		end
    end,
}
