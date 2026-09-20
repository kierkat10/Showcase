-- showcase; created by glitchkat10

-- apparently having this in a do is good practice
do

    local showcase_config = {
        key_input = "",
        include_info_queue = true,
        include_card_art = true,
        delay = 1
    }

    local showcase_active = false

    local createOptionsRef = create_UIBox_options
    function create_UIBox_options()
        local contents = createOptionsRef()
        if G.STATE == G.STATES.MENU then
            local showcase_button = UIBox_button({
                minw = 5,
                button = "open_showcase_menu",
                label = { "Showcase" },
                colour = G.C.BOOSTER
            })
            table.insert(contents.nodes[1].nodes[1].nodes[1].nodes, showcase_button)
        end
        return contents
    end

    local function showcase_hover(card)
        card.ability_UIBox_table = card:generate_UIBox_ability_table()
        card.config.h_popup = G.UIDEF.card_h_popup(card)
        card.config.h_popup_config = card:align_h_popup()
        Node.hover(card)
    end

    function showcase(key, delay, has_info_queue, has_card_art)
        showcase_active = true
        if G.CONTROLLER then
            G.CONTROLLER.dragging.target = nil
        end
        delay = delay or 1
        has_info_queue = has_info_queue ~= false
        has_card_art = has_card_art ~= false
        for _, type in pairs(G.I) do
            for i = #type, 1, -1 do
                type[i]:remove()
            end
        end
        if G.SPLASH_LOGO then
            G.SPLASH_LOGO:remove()
            G.SPLASH_LOGO = nil
        end
        local area = CardArea(-40, -40, 1, 1, { type = "title", highlighted_limit = 1 })
        local card = create_card(false, area, false, false, true, false, key)
        card.edition = {}
        local x = G.ROOM.T.w / 2 - card.T.w / 2
        local y = G.ROOM.T.h / 4 - card.T.h / 4
        card.T.x = x
        card.T.y = y
        card.VT.x = x
        card.VT.y = y
        -- prevent the user from hovering over the card
        card.states.hover.can = false
        showcase_hover(card)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = delay,
            func = function()
                local scale = (G.TILESCALE or 1) * (G.TILESIZE or 20)
                local screen_w, screen_h = love.graphics.getDimensions()
                local left, right, top, bottom
                if has_card_art then
                    left = card.T.x
                    right = card.T.x + card.T.w
                    top = card.T.y
                    bottom = card.T.y + card.T.h
                else
                    left = math.huge
                    right = -math.huge
                    top = math.huge
                    bottom = -math.huge
                end
                local function include_bounds(node, rect)
                    if not rect then return end
                    left = math.min(left, rect.x)
                    right = math.max(right, rect.x + rect.w)
                    top = math.min(top, rect.y)
                    bottom = math.max(bottom, rect.y + rect.h)
                end
                local popup = card.children.h_popup
                local info = popup and popup.UIRoot and popup.UIRoot.children and popup.UIRoot.children[1] and popup.UIRoot.children[1].children and popup.UIRoot.children[1].children.info
                local function has_ui_content(node)
                    if not node then return false end
                    if node.config and (node.config.text or node.config.scale or node.config.object) then
                        return true
                    end
                    if node.nodes then
                        for _, child in pairs(node.nodes) do
                            if has_ui_content(child) then
                                return true
                            end
                        end
                    end
                    return false
                end
                local effective_has_info = info ~= nil and info.definition and has_ui_content(info.definition) and has_info_queue
                local visited = {}
                local function walk_simple(node)
                    if not node or visited[node] then
                        return
                    end
                    visited[node] = true
                    if node.T then
                        include_bounds(node, node.T)
                    end
                    if node.nodes then
                        for _, child in pairs(node.nodes) do
                            walk_simple(child)
                        end
                    end
                    if node.children then
                        for _, child in pairs(node.children) do
                            walk_simple(child)
                        end
                    end
                end
                local function walk_complex(node)
                    if not node or visited[node] then
                        return
                    end
                    visited[node] = true
                    if node.VT then
                        include_bounds(node, node.VT)
                    elseif node.T then
                        include_bounds(node, node.T)
                    end
                    if node.nodes then
                        for _, child in pairs(node.nodes) do
                            walk_complex(child)
                        end
                    end
                    if node.children then
                        for _, child in pairs(node.children) do
                            walk_complex(child)
                        end
                    end
                    if node.definition and node.definition.nodes then
                        walk_complex(node.definition)
                    end
                    if node.UIRoot then
                        walk_complex(node.UIRoot)
                    end
                end
                if popup then
                    if effective_has_info then
                        walk_complex(popup)
                    else
                        walk_simple(popup)
                    end
                end
                local x, y = math.max(0, math.floor((G.ROOM.T.x + left) * scale)), math.max(0, math.floor((G.ROOM.T.y + top) * scale))
                local w, h = math.min(math.ceil((right - left) * scale), screen_w - x), math.min(math.ceil((bottom - top) * scale), screen_h - y)
                love.graphics.captureScreenshot(
                    function(image)
                        local cropped = love.image.newImageData(w, h)
                        cropped:paste(image, 0, 0, x, y, w, h)
                        love.filesystem.createDirectory("showcase")
                        cropped:encode("png", "showcase/" .. key .. ".png" )
                        print("showcase saved to " .. love.filesystem.getSaveDirectory() .. "/showcase/" .. key .. ".png")
                        card:stop_hover()
                        showcase_config.key_input = ""
                        G.FUNCS.open_showcase_menu()
                    end
                )
                return true
            end
        }))
    end
    -- hook because otherwise the game crashes w/o smods
    local showcase_slider_ref = G.FUNCS.slider
    G.FUNCS.slider = function(e)
        if not e or not e.children or not e.children[1] then
            return
        end
        local c = e.children[1]
        if not c.config or not c.config.ref_table then
            return
        end
        return showcase_slider_ref(e)
    end

    function G.FUNCS.open_showcase_menu(e)
        G.FUNCS.overlay_menu{
            definition = G.UIDEF.showcase_menu(),
            config = { offset = { x = 0, y = 10 }, showcase_menu = true }
        }
    end

    function G.UIDEF.showcase_menu()
        local scale = 0.8
        return create_UIBox_generic_options({
            back_func = "showcase_back_to_main",
            contents = {
                {
                    n = G.UIT.C,
                    config = { align = "cm", padding = 0.2 },
                    nodes = {
                        {
                            n = G.UIT.R,
                            config = { align = "cm" },
                            nodes = {
                                create_text_input({
                                    id = "showcase_key_input",
                                    w = 4,
                                    h = 0.6,
                                    ref_table = showcase_config,
                                    ref_value = "key_input",
                                    prompt_text = "Key (e.g., j_joker)",
                                    extended_corpus = true,
                                    max_length = 100
                                })
                            }
                        },
                        {
                            n = G.UIT.R,
                            config = { align = "cm", padding = 0.1 },
                            nodes = {
                                {
                                    n = G.UIT.T,
                                    config = {
                                        text = "Delay",
                                        scale = scale * 0.6,
                                        colour = G.C.UI.TEXT_LIGHT
                                    }
                                },
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", padding = 0.1 },
                                    nodes = {
                                        create_slider({
                                            ref_table = showcase_config,
                                            ref_value = "delay",
                                            min = 0.3,
                                            max = 5,
                                            step = 0.1,
                                            decimal_places = 1,
                                            w = 4,
                                            h = 0.4,
                                            label_scale = 0.5,
                                            text_scale = 0.3,
                                            colour = G.C.RED
                                        })
                                    }
                                }
                            }
                        },
                        {
                            n = G.UIT.R,
                            config = { align = "cm", padding = 0.2 },
                            nodes = {
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", minw = 2.5, minh = 0.6, r = 0.1, colour = showcase_config.include_info_queue and G.C.ORANGE or G.C.GREY, padding = 0.1, button = "showcase_toggle_info_queue", hover = true, shadow = true },
                                    nodes = {
                                        {
                                            n = G.UIT.T,
                                            config = { text = "Include Info Queues", scale = scale * 0.7, colour = G.C.UI.TEXT_LIGHT }
                                        }
                                    }
                                },
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", minw = 2.5, minh = 0.6, r = 0.1, colour = showcase_config.include_card_art and G.C.ORANGE or G.C.GREY, padding = 0.1, button = "showcase_toggle_card_art", hover = true, shadow = true },
                                    nodes = {
                                        {
                                            n = G.UIT.T,
                                            config = { text = "Include Card Art", scale = scale * 0.7, colour = G.C.UI.TEXT_LIGHT }
                                        }
                                    }
                                }
                            }
                        },
                        {
                            n = G.UIT.R,
                            config = { align = "cm", padding = 0.4 },
                            nodes = {
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", minw = 5, minh = 1.5, r = 0.1, colour = G.C.BOOSTER, padding = 0.1, button = "showcase_trigger", hover = true, shadow = true },
                                    nodes = {
                                        {
                                            n = G.UIT.T,
                                            config = { text = "Showcase", scale = scale * 1.2, colour = G.C.UI.TEXT_LIGHT }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    end

    G.FUNCS.showcase_toggle_info_queue = function(e)
        showcase_config.include_info_queue = not showcase_config.include_info_queue
        e.config.colour = showcase_config.include_info_queue and G.C.ORANGE or G.C.GREY
    end

    G.FUNCS.showcase_toggle_card_art = function(e)
        showcase_config.include_card_art = not showcase_config.include_card_art
        e.config.colour = showcase_config.include_card_art and G.C.ORANGE or G.C.GREY
    end

    G.FUNCS.showcase_back_to_main = function(e)
        G.FUNCS.exit_overlay_menu()
        if showcase_active then
            showcase_active = false
            for _, type in pairs(G.I) do
                for i = #type, 1, -1 do
                    type[i]:remove()
                end
            end
            G:main_menu()
        end
    end

    G.FUNCS.showcase_trigger = function(e)
        local key_input = showcase_config.key_input or ""
        -- check for errors like using quotation marks or random spaces
        local cleaned_key = key_input:gsub('"', ""):gsub("'", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if cleaned_key == "" then
            return
        end
        local test_area = CardArea(-40, -40, 1, 1, {
            type = "title",
            highlighted_limit = 1
        })
        local success, test_card = pcall(create_card, false, test_area, false, false, true, false, cleaned_key)
        if not success or not test_card or not test_card.config or not test_card.config.center then
            print("\"" .. cleaned_key .. "\" is not a valid key.")
            -- dummy
            return
        end
        test_card:remove()
        G.FUNCS.exit_overlay_menu()
        showcase(
            cleaned_key,
            showcase_config.delay,
            showcase_config.include_info_queue,
            showcase_config.include_card_art
        )
    end

end
