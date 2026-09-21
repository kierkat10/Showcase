-- showcase; created by glitchkat10

-- apparently having this in a do is good practice
do

    local showcase_config = {
        full_input = "",
        set_input = "",
        mod_input = "",
        key_input = "",
        include_info_queue = true,
        include_card_art = true,
        delay = 1,
        save_as = "key"
    }

    local showcase_active = false
    local showcase_all_active = false
    local escape_pressed = false
    local use_full_input = false

    local function clean_input(str)
        return (str or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("^_+", ""):gsub("_+$", "")
    end

    local function update_full_input()
        local set_input = clean_input(showcase_config.set_input)
        local mod_input = clean_input(showcase_config.mod_input)
        local key_input = showcase_config.key_input or ""
        if mod_input == "" then
            if set_input ~= "" and key_input ~= "" then
                showcase_config.full_input = set_input .. "_" .. key_input
            elseif set_input ~= "" then
                showcase_config.full_input = set_input
            elseif key_input ~= "" then
                showcase_config.full_input = key_input
            else
                showcase_config.full_input = ""
            end
        else
            showcase_config.full_input = set_input .. "_" .. mod_input .. "_" .. key_input
        end
    end

    local function update_split_input()
        local input = showcase_config.full_input or ""
        input = input:gsub("^%s+", ""):gsub("%s+$", "")
        local set_input, rest = input:match("^([^_]+)_(.*)$")
        if not set_input then
            showcase_config.set_input = clean_input(input)
            showcase_config.mod_input = ""
            showcase_config.key_input = ""
            return
        end
        local mod_input, key_input = rest:match("^([^_]+)_(.*)$")
        if mod_input then
            showcase_config.set_input = clean_input(set_input)
            showcase_config.mod_input = clean_input(mod_input)
            showcase_config.key_input = key_input or ""
        else
            showcase_config.set_input = clean_input(set_input)
            showcase_config.mod_input = ""
            showcase_config.key_input = rest
        end
    end

    local function sync_full_input()
        if use_full_input then
            update_full_input()
        else
            showcase_config.full_input = ""
        end
    end

    local function get_name_from_table(tbl)
        if not tbl then
            return ""
        end
        local name = ""
        for _, v in ipairs(tbl) do
            if v.config and v.config.object and v.config.object.strings then
                for _, string_data in ipairs(v.config.object.strings) do
                    name = name .. tostring(string_data.string or "")
                end
            elseif v.config and v.config.text then
                name = name .. tostring(v.config.text)
            end
        end
        return name
    end

    local function get_card_filename(card, key)
        if showcase_config.save_as == "key" then
            return key
        end
        local center = card.config and card.config.center
        local name = ""
        if center and center.name then
            name = center.name
        else
            name = get_name_from_table(card.ability_UIBox_table and card.ability_UIBox_table.name)
        end
        if name == "" then
            return key
        end
        local mod_name = "Balatro"
        if center and center.mod then
            mod_name = center.mod.display_name or center.mod.name or center.mod.id or mod_name
        end
        name = name .. " (" .. tostring(mod_name) .. ")"
        name = name:gsub('[\\/:*?"<>|]', "_")
        return name
    end

    local keypressed_ref = love.keypressed
    love.keypressed = function(key, scancode, isrepeat)
        if showcase_all_active and key == "escape" then
            escape_pressed = true
            showcase_all_active = false
            return
        end
        if showcase_active and key == "escape" then
            G.FUNCS.showcase_back_to_main()
            return
        end
        if keypressed_ref then
            return keypressed_ref(key, scancode, isrepeat)
        end
    end

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

    function showcase(key, delay, has_info_queue, has_card_art, return_to_menu)
        showcase_active = true
        if G.CONTROLLER then
            G.CONTROLLER.dragging.target = nil
        end
        delay = delay or 1
        has_info_queue = has_info_queue ~= false
        has_card_art = has_card_art ~= false
        return_to_menu = return_to_menu ~= false
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
        if SMODS then
            card:set_edition(nil, true, true)
        else
            card.edition = {}
        end
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

                local popup = card.children.h_popup
                local info = popup and popup.UIRoot and popup.UIRoot.children and popup.UIRoot.children[1] and popup.UIRoot.children[1].children and popup.UIRoot.children[1].children.info
                local effective_has_info = info ~= nil and info.definition and has_ui_content(info.definition) and has_info_queue
                local visited = {}

                local function walk(node)
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
                            walk(child)
                        end
                    end
                    if node.children then
                        for _, child in pairs(node.children) do
                            walk(child)
                        end
                    end
                    if effective_has_info then
                        if node.definition and node.definition.nodes then
                            walk(node.definition)
                        end
                        if node.UIRoot then
                            walk(node.UIRoot)
                        end
                    end
                end

                if popup then
                    walk(popup)
                end
                local x, y = math.max(0, math.floor((G.ROOM.T.x + left) * scale)), math.max(0, math.floor((G.ROOM.T.y + top) * scale))
                local w, h = math.min(math.ceil((right - left) * scale), screen_w - x), math.min(math.ceil((bottom - top) * scale), screen_h - y)
                love.graphics.captureScreenshot(
                    function(image)
                        local cropped = love.image.newImageData(w, h)
                        cropped:paste(image, 0, 0, x, y, w, h)
                        love.filesystem.createDirectory("Showcase")
                        local filename = get_card_filename(card, key)
                        cropped:encode("png", "Showcase/" .. filename .. ".png" )
                        print("Showcase saved to " .. love.filesystem.getSaveDirectory() .. "/Showcase/" .. filename .. ".png")
                        card:stop_hover()
                        card:remove()
                        if return_to_menu then
                            if use_full_input then
                                update_full_input()
                                local set_input = clean_input(showcase_config.set_input)
                                local mod_input = clean_input(showcase_config.mod_input)
                                if mod_input == "" then
                                    showcase_config.full_input = set_input .. "_"
                                else
                                    showcase_config.full_input = set_input .. "_" .. mod_input .. "_"
                                end
                            else
                                showcase_config.key_input = ""
                            end
                            G.FUNCS.open_showcase_menu()
                        end
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
                            config = { align = "cm", padding = 0.1 },
                            nodes = use_full_input and {
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm" },
                                    nodes = {
                                        UIBox_button({
                                            label = { "<<" },
                                            button = "toggle_showcase_input",
                                            colour = G.C.BLUE,
                                            minw = 0.8,
                                            minh = 0.6
                                        })
                                    }
                                },
                                create_text_input({
                                    id = "showcase_full_input",
                                    w = 3.5,
                                    h = 0.6,
                                    ref_table = showcase_config,
                                    ref_value = "full_input",
                                    prompt_text = "Full Key (e.g. j_joker)",
                                    extended_corpus = true,
                                    max_length = 100
                                })
                            } or {
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm" },
                                    nodes = {
                                        UIBox_button({
                                            label = { ">>" },
                                            button = "toggle_showcase_input",
                                            colour = G.C.BLUE,
                                            minw = 0.8,
                                            minh = 0.6
                                        })
                                    }
                                },
                                create_text_input({
                                    id = "showcase_set_input",
                                    w = 2,
                                    h = 0.6,
                                    ref_table = showcase_config,
                                    ref_value = "set_input",
                                    prompt_text = "Set (e.g. j)",
                                    extended_corpus = true,
                                    max_length = 100
                                }),
                                create_text_input({
                                    id = "showcase_mod_input",
                                    w = 2,
                                    h = 0.6,
                                    ref_table = showcase_config,
                                    ref_value = "mod_input",
                                    prompt_text = "Mod Prefix",
                                    extended_corpus = true,
                                    max_length = 100
                                }),
                                create_text_input({
                                    id = "showcase_key_input",
                                    w = 2.5,
                                    h = 0.6,
                                    ref_table = showcase_config,
                                    ref_value = "key_input",
                                    prompt_text = "Key (e.g. joker)",
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
                            config = { align = "cm" },
                            nodes = {
                                create_option_cycle({
                                    label = "Save As",
                                    scale = 0.8,
                                    options = { "Key", "Name (Mod)" },
                                    opt_callback = "showcase_save_as",
                                    current_option = showcase_config.save_as == "key" and 1 or 2,
                                    w = 4,
                                    h = 0.6
                                })
                            }
                        },
                        {
                            n = G.UIT.R,
                            config = { align = "cm", padding = 0.2 },
                            nodes = { }
                        },
                        {
                            n = G.UIT.R,
                            config = { align = "cm" },
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
                            },
                        },
                        {
                            n = G.UIT.R,
                            config = { align = "cm" },
                            nodes = {
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", minw = 1, minh = 0.4, r = 0.1, colour = G.C.DARK_EDITION, padding = 0.1, button = "showcase_all_trigger", hover = true, shadow = true },
                                    nodes = {
                                        {
                                            n = G.UIT.T,
                                            config = { text = "Showcase All Matching Set & Prefix", scale = scale * 0.5, colour = G.C.UI.TEXT_LIGHT }
                                        }
                                    }
                                }
                            },
                        },
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

    G.FUNCS.toggle_showcase_input = function(e)
        if use_full_input then
            update_split_input()
            use_full_input = false
        else
            use_full_input = true
        end
        sync_full_input()
        G.FUNCS.open_showcase_menu()
    end

    G.FUNCS.showcase_save_as = function(e)
        if e and e.cycle_config then
            showcase_config.save_as = e.cycle_config.current_option == 1 and "key" or "name"
        end
    end

    G.FUNCS.showcase_back_to_main = function(e)
        G.FUNCS.exit_overlay_menu()
        showcase_all_active = false
        escape_pressed = false
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
        if showcase_all_active then
            return
        end
        local set_input
        local mod_input
        local key_input

        if use_full_input then
            update_split_input()
            set_input = clean_input(showcase_config.set_input)
            mod_input = clean_input(showcase_config.mod_input)
            key_input = showcase_config.key_input or ""
        else
            set_input = clean_input(showcase_config.set_input)
            mod_input = clean_input(showcase_config.mod_input)
            key_input = showcase_config.key_input or ""
        end

        local cleaned_key = ""
        if set_input ~= "" then
            cleaned_key = set_input
        end
        if mod_input ~= "" then
            cleaned_key = cleaned_key ~= "" and cleaned_key .. "_" .. mod_input or mod_input
        end
        if key_input ~= "" then
            cleaned_key = cleaned_key ~= "" and cleaned_key .. "_" .. key_input or key_input
        end
        cleaned_key = cleaned_key:gsub('"', ""):gsub("'", "")
        if cleaned_key == "" then return end
        local test_area = CardArea(-40, -40, 1, 1, {
            type = "title",
            highlighted_limit = 1
        })
        local success, test_card = pcall(create_card, false, test_area, false, false, true, false, cleaned_key)
        if not success or not test_card or not test_card.config or not test_card.config.center then
            print("\"" .. cleaned_key .. "\" is not a valid key.")
            return
        end
        test_card:remove()
        G.FUNCS.exit_overlay_menu()
        showcase(
            cleaned_key,
            showcase_config.delay,
            showcase_config.include_info_queue,
            showcase_config.include_card_art,
            true
        )
    end

    G.FUNCS.showcase_all_trigger = function(e)
        local set_input
        local mod_input
        if use_full_input then
            update_split_input()
            set_input = clean_input(showcase_config.set_input)
            mod_input = clean_input(showcase_config.mod_input)
        else
            set_input = clean_input(showcase_config.set_input)
            mod_input = clean_input(showcase_config.mod_input)
        end
        if set_input == "" then return end
        local prefix
        if mod_input == "" then
            prefix = set_input .. "_"
        else
            prefix = set_input .. "_" .. mod_input .. "_"
        end
        local matching_keys = {}
        if G.P_CENTER_POOLS then
            for pool_name, pool in pairs(G.P_CENTER_POOLS) do
                if type(pool) == "table" then
                    for _, center in pairs(pool) do
                        if center and center.key and type(center.key) == "string" and center.key:sub(1, #prefix) == prefix then
                            table.insert(matching_keys, center.key)
                        end
                    end
                end
            end
        end
        if #matching_keys == 0 then
            print("Mod Prefix \"" .. prefix .. "\" yielded no results.")
            return
        end
        table.sort(matching_keys)
        G.FUNCS.exit_overlay_menu()
        showcase_all_active = true
        escape_pressed = false
        local function showcase_next(index)
            if escape_pressed or not showcase_all_active then
                showcase_all_active = false
                escape_pressed = false
                for _, type in pairs(G.I) do
                    for i = #type, 1, -1 do
                        type[i]:remove()
                    end
                end
                G.FUNCS.open_showcase_menu()
                return
            end
            if index > #matching_keys then
                if use_full_input then
                    update_full_input()
                    local set_input = clean_input(showcase_config.set_input)
                    local mod_input = clean_input(showcase_config.mod_input)
                    if mod_input == "" then
                        showcase_config.full_input = set_input .. "_"
                    else
                        showcase_config.full_input = set_input .. "_" .. mod_input .. "_"
                    end
                else
                    showcase_config.key_input = ""
                end
                showcase_all_active = false
                escape_pressed = false
                G.FUNCS.open_showcase_menu()
                return
            end
            local key = matching_keys[index]
            showcase(
                key,
                showcase_config.delay,
                showcase_config.include_info_queue,
                showcase_config.include_card_art,
                false
            )
            G.E_MANAGER:add_event(Event({
                trigger = "immediate",
                func = function()
                    if not showcase_all_active then
                        for _, type in pairs(G.I) do
                            for i = #type, 1, -1 do
                                type[i]:remove()
                            end
                        end
                        escape_pressed = false
                        G.FUNCS.open_showcase_menu()
                        return true
                    end
                    showcase_next(index + 1)
                    return true
                end
            }))
        end
        showcase_next(1)
    end

end