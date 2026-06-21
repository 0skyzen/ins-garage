---@param source number
---@param name string
---@return boolean success
---@return string message
lib.callback.register('ins-garages:createCategory', function(source, name)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    name = (name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then
        return false, locale('name_empty')
    end
    if #name > Config.MaxCategoryNameLength then
        return false, locale('name_too_long')
    end
    if Db.CountCategories(identifier) >= Config.MaxCategories then
        return false, locale('category_limit')
    end

    Db.CreateCategory(identifier, name)
    return true, locale('category_created')
end)

---@param source number
---@param categoryId number
---@param name string
---@return boolean success
---@return string message
lib.callback.register('ins-garages:renameCategory', function(source, categoryId, name)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    name = (name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then
        return false, locale('name_empty')
    end
    if #name > Config.MaxCategoryNameLength then
        return false, locale('name_too_long')
    end

    if Db.RenameCategory(identifier, categoryId, name) then
        return true, locale('category_renamed')
    end
    return false, locale('category_not_found')
end)

---@param source number
---@param categoryId number
---@return boolean success
---@return string message
lib.callback.register('ins-garages:deleteCategory', function(source, categoryId)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    if Db.DeleteCategory(identifier, categoryId) then
        return true, locale('category_deleted')
    end
    return false, locale('category_not_found')
end)

---@param source number
---@param plate string
---@param categoryId number? nil clears the vehicle's category
---@return boolean success
---@return string message
lib.callback.register('ins-garages:setVehicleCategory', function(source, plate, categoryId)
    local identifier, job = GetPlayerData(source)
    if not identifier then return false end

    plate = Db.NormalizePlate(plate)
    local owner = Db.GetVehicleOwner(plate)
    if owner ~= identifier and (not job or owner ~= job) then
        return false, locale('not_your_vehicle')
    end

    if categoryId and not Db.CategoryBelongsTo(identifier, categoryId) then
        return false, locale('category_not_found')
    end

    Db.SetVehicleCategory(plate, categoryId)
    return true, locale('vehicle_moved')
end)
