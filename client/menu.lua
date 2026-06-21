---@param v table vehicle entry
---@return string label readable vehicle name (falls back to spawn name)
local function vehicleLabel(v)
    if v.model then
        local name = GetDisplayNameFromVehicleModel(v.model)
        if name and name ~= '' then
            local label = GetLabelText(name)
            if label and label ~= 'NULL' then return label end
            return name
        end
    end
    return 'Vehicle'
end

---@return table? data garage data for the current garage
local function fetchGarage()
    return lib.callback.await('ins-garages:getGarage', false, CurrentGarage and CurrentGarage.index)
end

---@param v table vehicle entry
---@return table? metadata ox_lib metadata of fuel/engine/body, nil when unknown
local function vehicleMetadata(v)
    local meta = {}
    if v.fuel then meta[#meta + 1] = { label = locale('state_fuel'), value = ('%d%%'):format(math.floor(v.fuel + 0.5)) } end
    if v.engine then meta[#meta + 1] = { label = locale('state_engine'), value = ('%d%%'):format(math.floor(v.engine / 10 + 0.5)) } end
    if v.body then meta[#meta + 1] = { label = locale('state_body'), value = ('%d%%'):format(math.floor(v.body / 10 + 0.5)) } end
    return meta[1] and meta or nil
end

local openVehicleList, openSharedList, openOutList, openVehicleDetail, openCategoryList
local openCategoriesMenu, openManageCategory, openSetCategory, openSharingMenu, openTransferMenu

---@param v table vehicle entry
---@param data table garage data
---@param backId string menu id to return to from the vehicle's detail view
---@return table option ox_lib option that opens the vehicle detail menu
local function vehicleOption(v, data, backId)
    return {
        title = vehicleLabel(v),
        description = v.personal
            and locale('plate_category', v.plate, v.category_name or locale('category_none'))
            or locale('plate_faction', v.plate, v.owner or '?'),
        icon = 'car-side',
        metadata = vehicleMetadata(v),
        arrow = true,
        onSelect = function() openVehicleDetail(v, data.categories, backId) end,
    }
end

function OpenGarageMenu()
    local data = fetchGarage()
    if not data then return end
    if data.denied then
        return lib.notify({ type = 'error', description = locale('no_garage_access') })
    end

    local options = {
        {
            title = locale('my_vehicles', #data.owned),
            description = locale('my_vehicles_desc'),
            icon = 'car',
            onSelect = function() openVehicleList(data) end,
        },
        {
            title = locale('shared_with_me', #data.shared),
            description = locale('shared_with_me_desc'),
            icon = 'users',
            onSelect = function() openSharedList(data) end,
        },
        {
            title = locale('manage_categories'),
            description = locale('manage_categories_desc'),
            icon = 'folder',
            onSelect = function() openCategoriesMenu() end,
        },
    }

    if #data.out > 0 then
        table.insert(options, 2, {
            title = locale('out_vehicles', #data.out),
            description = locale('out_vehicles_desc'),
            icon = 'car-burst',
            onSelect = function() openOutList(data) end,
        })
    end

    lib.registerContext({
        id = 'ins_garage_main',
        title = CurrentGarage and CurrentGarage.label or locale('menu_garage'),
        options = options,
    })
    lib.showContext('ins_garage_main')
end

---@param data table garage data
openVehicleList = function(data)
    local byCat, uncategorized = {}, {}
    for _, v in ipairs(data.owned) do
        if v.category_id then
            byCat[v.category_id] = byCat[v.category_id] or {}
            local list = byCat[v.category_id]
            list[#list + 1] = v
        else
            uncategorized[#uncategorized + 1] = v
        end
    end

    local options = {}

    for _, cat in ipairs(data.categories) do
        local list = byCat[cat.id] or {}
        options[#options + 1] = {
            title = cat.name,
            description = locale('category_count', #list),
            icon = 'folder',
            arrow = true,
            onSelect = function() openCategoryList(cat, list, data) end,
        }
    end

    if #uncategorized > 0 and #data.categories > 0 then
        options[#options + 1] = { title = locale('uncategorized_header'), disabled = true }
    end

    for _, v in ipairs(uncategorized) do
        options[#options + 1] = vehicleOption(v, data, 'ins_garage_owned')
    end

    if #options == 0 then
        options[1] = { title = locale('no_vehicles'), disabled = true }
    end

    lib.registerContext({
        id = 'ins_garage_owned',
        title = locale('my_vehicles_title'),
        menu = 'ins_garage_main',
        options = options,
    })
    lib.showContext('ins_garage_owned')
end

---@param cat table { id, name }
---@param list table[] vehicles inside the category
---@param data table garage data
openCategoryList = function(cat, list, data)
    local options = {}
    for _, v in ipairs(list) do
        options[#options + 1] = vehicleOption(v, data, 'ins_garage_category')
    end
    if #options == 0 then
        options[1] = { title = locale('no_vehicles'), disabled = true }
    end

    lib.registerContext({
        id = 'ins_garage_category',
        title = cat.name,
        menu = 'ins_garage_owned',
        options = options,
    })
    lib.showContext('ins_garage_category')
end

---@param data table garage data
openOutList = function(data)
    local options = {}
    for _, v in ipairs(data.out) do
        options[#options + 1] = {
            title = vehicleLabel(v),
            description = locale('recover_desc', v.plate),
            icon = 'car-burst',
            metadata = vehicleMetadata(v),
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = locale('recover'),
                    content = Config.RecoverFee > 0
                        and locale('recover_confirm_fee', v.plate, Config.RecoverFee)
                        or locale('recover_confirm', v.plate),
                    centered = true,
                    cancel = true,
                })
                if confirm ~= 'confirm' then return openOutList(data) end
                local ok, msg = lib.callback.await('ins-garages:recover', false, v.plate)
                lib.notify({ type = ok and 'success' or 'error', description = msg })
                OpenGarageMenu()
            end,
        }
    end
    if #options == 0 then
        options[1] = { title = locale('no_out_vehicles'), disabled = true }
    end

    lib.registerContext({
        id = 'ins_garage_out',
        title = locale('out_vehicles_title'),
        menu = 'ins_garage_main',
        options = options,
    })
    lib.showContext('ins_garage_out')
end

---@param v table vehicle entry
---@param categories table[] the player's categories
---@param backId string? menu id the back button returns to
openVehicleDetail = function(v, categories, backId)
    local options = {
        {
            title = locale('take_out'),
            icon = 'right-from-bracket',
            onSelect = function() TakeOutVehicle(v.plate) end,
        },
        {
            title = locale('set_category'),
            description = v.category_name and locale('category_current', v.category_name) or locale('uncategorized'),
            icon = 'folder-tree',
            arrow = true,
            onSelect = function() openSetCategory(v, categories) end,
        },
    }

    if v.personal then
        options[#options + 1] = {
            title = locale('manage_sharing'),
            description = locale('manage_sharing_desc'),
            icon = 'share-nodes',
            arrow = true,
            onSelect = function() openSharingMenu(v) end,
        }
        options[#options + 1] = {
            title = locale('transfer'),
            description = locale('transfer_desc'),
            icon = 'right-left',
            arrow = true,
            onSelect = function() openTransferMenu(v) end,
        }
    end

    lib.registerContext({
        id = 'ins_garage_detail',
        title = vehicleLabel(v),
        menu = backId or 'ins_garage_owned',
        options = options,
    })
    lib.showContext('ins_garage_detail')
end

---@param v table vehicle entry
openTransferMenu = function(v)
    local myJobLabel = Framework.GetJobLabel() or locale('job_none')

    lib.registerContext({
        id = 'ins_garage_transfer',
        title = locale('transfer_title'),
        menu = 'ins_garage_detail',
        options = {
            {
                title = locale('transfer_player'),
                description = locale('transfer_player_desc'),
                icon = 'user',
                onSelect = function()
                    local input = lib.inputDialog(locale('transfer_player_dialog'), {
                        { type = 'number', label = locale('server_id'), required = true, min = 1 },
                    })
                    if not input then return end
                    local ok, msg = lib.callback.await('ins-garages:transferToPlayer', false, v.plate, input[1])
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                    if ok then OpenGarageMenu() else openTransferMenu(v) end
                end,
            },
            {
                title = locale('transfer_faction'),
                description = locale('transfer_faction_desc', myJobLabel),
                icon = 'building-shield',
                onSelect = function()
                    local ok, msg = lib.callback.await('ins-garages:transferToJob', false, v.plate)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                    if ok then OpenGarageMenu() else openTransferMenu(v) end
                end,
            },
        },
    })
    lib.showContext('ins_garage_transfer')
end

---@param data table garage data
openSharedList = function(data)
    local options = {}
    for _, v in ipairs(data.shared) do
        options[#options + 1] = {
            title = vehicleLabel(v),
            description = locale('plate_only', v.plate),
            icon = 'car-side',
            metadata = vehicleMetadata(v),
            onSelect = function() TakeOutVehicle(v.plate) end,
        }
    end
    if #options == 0 then
        options[1] = { title = locale('nothing_shared'), disabled = true }
    end

    lib.registerContext({
        id = 'ins_garage_shared',
        title = locale('shared_with_me_desc'),
        menu = 'ins_garage_main',
        options = options,
    })
    lib.showContext('ins_garage_shared')
end

openCategoriesMenu = function()
    local data = fetchGarage()
    if not data then return end

    local options = {
        {
            title = locale('create_category'),
            icon = 'plus',
            onSelect = function()
                local input = lib.inputDialog(locale('new_category'), {
                    { type = 'input', label = locale('category_name'), required = true, max = Config.MaxCategoryNameLength },
                })
                if not input then return end
                local ok, msg = lib.callback.await('ins-garages:createCategory', false, input[1])
                lib.notify({ type = ok and 'success' or 'error', description = msg })
                openCategoriesMenu()
            end,
        },
    }

    for _, cat in ipairs(data.categories) do
        options[#options + 1] = {
            title = cat.name,
            description = locale('manage_category'),
            icon = 'folder',
            arrow = true,
            onSelect = function() openManageCategory(cat) end,
        }
    end

    lib.registerContext({
        id = 'ins_garage_categories',
        title = locale('manage_categories'),
        menu = 'ins_garage_main',
        options = options,
    })
    lib.showContext('ins_garage_categories')
end

---@param cat table { id, name }
openManageCategory = function(cat)
    lib.registerContext({
        id = 'ins_garage_managecat',
        title = cat.name,
        menu = 'ins_garage_categories',
        options = {
            {
                title = locale('rename_category'),
                icon = 'pen',
                onSelect = function()
                    local input = lib.inputDialog(locale('rename_category'), {
                        { type = 'input', label = locale('category_name'), default = cat.name,
                          required = true, max = Config.MaxCategoryNameLength },
                    })
                    if not input then return openManageCategory(cat) end
                    local ok, msg = lib.callback.await('ins-garages:renameCategory', false, cat.id, input[1])
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                    openCategoriesMenu()
                end,
            },
            {
                title = locale('delete_category'),
                icon = 'trash',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = locale('delete_category'),
                        content = locale('delete_category_confirm', cat.name),
                        centered = true,
                        cancel = true,
                    })
                    if confirm ~= 'confirm' then return openManageCategory(cat) end
                    local ok, msg = lib.callback.await('ins-garages:deleteCategory', false, cat.id)
                    lib.notify({ type = ok and 'success' or 'error', description = msg })
                    openCategoriesMenu()
                end,
            },
        },
    })
    lib.showContext('ins_garage_managecat')
end

---Re-open the My Vehicles list with fresh data after a change.
local function reopenVehicleList()
    local data = fetchGarage()
    if data and not data.denied then
        openVehicleList(data)
    else
        OpenGarageMenu()
    end
end

---@param v table vehicle entry
---@param categories table[] the player's categories
openSetCategory = function(v, categories)
    local options = {
        {
            title = locale('remove_from_category'),
            icon = 'xmark',
            onSelect = function()
                local ok, msg = lib.callback.await('ins-garages:setVehicleCategory', false, v.plate, nil)
                lib.notify({ type = ok and 'success' or 'error', description = msg })
                reopenVehicleList()
            end,
        },
    }

    for _, cat in ipairs(categories) do
        options[#options + 1] = {
            title = cat.name,
            icon = 'folder',
            onSelect = function()
                local ok, msg = lib.callback.await('ins-garages:setVehicleCategory', false, v.plate, cat.id)
                lib.notify({ type = ok and 'success' or 'error', description = msg })
                reopenVehicleList()
            end,
        }
    end

    if #categories == 0 then
        options[#options + 1] = { title = locale('no_categories'), disabled = true }
    end

    lib.registerContext({
        id = 'ins_garage_setcat',
        title = locale('set_category'),
        menu = 'ins_garage_detail',
        options = options,
    })
    lib.showContext('ins_garage_setcat')
end

---@param v table vehicle entry
openSharingMenu = function(v)
    local shares = lib.callback.await('ins-garages:getShares', false, v.plate)

    local options = {
        {
            title = locale('share_with_player'),
            description = locale('transfer_player_desc'),
            icon = 'user-plus',
            onSelect = function()
                local input = lib.inputDialog(locale('share_dialog'), {
                    { type = 'number', label = locale('server_id'), required = true, min = 1 },
                })
                if not input then return end
                local ok, msg = lib.callback.await('ins-garages:share', false, v.plate, input[1])
                lib.notify({ type = ok and 'success' or 'error', description = msg })
                openSharingMenu(v)
            end,
        },
    }

    for _, s in ipairs(shares) do
        options[#options + 1] = {
            title = s.name,
            description = locale('click_revoke', s.online and locale('online') or locale('offline')),
            icon = 'user-minus',
            onSelect = function()
                local ok, msg = lib.callback.await('ins-garages:unshare', false, v.plate, s.identifier)
                lib.notify({ type = ok and 'success' or 'error', description = msg })
                openSharingMenu(v)
            end,
        }
    end

    if #shares == 0 then
        options[#options + 1] = { title = locale('not_shared'), disabled = true }
    end

    lib.registerContext({
        id = 'ins_garage_sharing',
        title = locale('manage_sharing'),
        menu = 'ins_garage_detail',
        options = options,
    })
    lib.showContext('ins_garage_sharing')
end
