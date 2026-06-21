Db = {}

---@param plate string
---@return string plate trimmed of trailing spaces and upper-cased
function Db.NormalizePlate(plate)
    return (plate or ''):gsub('%s+$', ''):upper()
end

---@param plate string
---@return string? owner identifier, or nil if the vehicle does not exist
function Db.GetVehicleOwner(plate)
    return MySQL.scalar.await(
        'SELECT `owner` FROM `owned_vehicles` WHERE `plate` = ?',
        { plate }
    )
end

---@param plate string
---@return number? model hash registered for the plate (from saved props)
function Db.GetVehicleModel(plate)
    local raw = MySQL.scalar.await('SELECT `vehicle` FROM `owned_vehicles` WHERE `plate` = ?', { plate })
    if not raw then return nil end
    local ok, props = pcall(json.decode, raw)
    if ok and props then return props.model end
    return nil
end

---@param identifier string
---@param job string?
---@param stored boolean true = in garage, false = currently out
---@return table[] rows owned by the player or their job, with category info
function Db.GetVehicles(identifier, job, stored)
    return MySQL.query.await([[
        SELECT ov.plate, ov.vehicle, ov.type, ov.owner, c.id AS category_id, c.name AS category_name
        FROM owned_vehicles ov
        LEFT JOIN garage_vehicle_category vc ON vc.plate = ov.plate
        LEFT JOIN garage_categories c ON c.id = vc.category_id AND c.owner = ?
        WHERE ov.owner IN (?, ?) AND ov.stored = ?
    ]], { identifier, identifier, job or identifier, stored and 1 or 0 }) or {}
end

---@param identifier string
---@return table[] rows stored vehicles other players shared with this identifier
function Db.GetSharedVehicles(identifier)
    return MySQL.query.await([[
        SELECT ov.plate, ov.vehicle, ov.type, ov.owner
        FROM garage_shared s
        INNER JOIN owned_vehicles ov ON ov.plate = s.plate
        WHERE s.shared_with = ? AND ov.stored = 1
    ]], { identifier }) or {}
end

---@param identifier string
---@param plate string
---@param job string?
---@return boolean true if the player owns the plate, has the owning job, or it's shared
function Db.CanAccessVehicle(identifier, plate, job)
    local count = MySQL.scalar.await([[
        SELECT 1 FROM owned_vehicles WHERE plate = ? AND owner IN (?, ?)
        UNION
        SELECT 1 FROM garage_shared WHERE plate = ? AND shared_with = ?
        LIMIT 1
    ]], { plate, identifier, job or identifier, plate, identifier })
    return count ~= nil
end

---@param plate string
---@return boolean stored handles oxmysql returning TINYINT(1) as boolean or number
function Db.IsStored(plate)
    local stored = MySQL.scalar.await(
        'SELECT `stored` FROM `owned_vehicles` WHERE `plate` = ?',
        { plate }
    )
    return stored == true or tonumber(stored) == 1
end

---@param plate string
---@param stored boolean
---@param props string? encoded vehicle properties (sets the column, nil clears it)
function Db.SetStored(plate, stored, props)
    return MySQL.update.await(
        'UPDATE `owned_vehicles` SET `stored` = ?, `vehicle` = ? WHERE `plate` = ?',
        { stored and 1 or 0, props, plate }
    )
end

---@param plate string
---@param stored boolean
function Db.SetStoredFlag(plate, stored)
    return MySQL.update.await(
        'UPDATE `owned_vehicles` SET `stored` = ? WHERE `plate` = ?',
        { stored and 1 or 0, plate }
    )
end

---@param plate string
---@param newOwner string identifier, or job name for a faction vehicle
---@param newJob string? job name for a faction vehicle, nil for a personal owner
function Db.TransferVehicle(plate, newOwner, newJob)
    MySQL.update.await('DELETE FROM `garage_shared` WHERE `plate` = ?', { plate })
    MySQL.update.await('DELETE FROM `garage_vehicle_category` WHERE `plate` = ?', { plate })
    return MySQL.update.await(
        'UPDATE `owned_vehicles` SET `owner` = ?, `job` = ? WHERE `plate` = ?',
        { newOwner, newJob, plate }
    )
end

---@param identifier string
---@return table[] rows { id, name }
function Db.GetCategories(identifier)
    return MySQL.query.await(
        'SELECT `id`, `name` FROM `garage_categories` WHERE `owner` = ? ORDER BY `name`',
        { identifier }
    ) or {}
end

---@param identifier string
---@return number count
function Db.CountCategories(identifier)
    return MySQL.scalar.await(
        'SELECT COUNT(*) FROM `garage_categories` WHERE `owner` = ?',
        { identifier }
    ) or 0
end

---@param identifier string
---@param name string
---@return number insertId
function Db.CreateCategory(identifier, name)
    return MySQL.insert.await(
        'INSERT INTO `garage_categories` (`owner`, `name`) VALUES (?, ?)',
        { identifier, name }
    )
end

---@param identifier string
---@param categoryId number
---@param name string
---@return boolean renamed only if the category belonged to the identifier
function Db.RenameCategory(identifier, categoryId, name)
    local affected = MySQL.update.await(
        'UPDATE `garage_categories` SET `name` = ? WHERE `id` = ? AND `owner` = ?',
        { name, categoryId, identifier }
    )
    return affected and affected > 0
end

---@param identifier string
---@param categoryId number
---@return boolean deleted only if the category belonged to the identifier
function Db.DeleteCategory(identifier, categoryId)
    local affected = MySQL.update.await(
        'DELETE FROM `garage_categories` WHERE `id` = ? AND `owner` = ?',
        { categoryId, identifier }
    )
    if affected and affected > 0 then
        MySQL.update.await('DELETE FROM `garage_vehicle_category` WHERE `category_id` = ?', { categoryId })
    end
    return affected and affected > 0
end

---@param identifier string
---@param categoryId number
---@return boolean
function Db.CategoryBelongsTo(identifier, categoryId)
    return MySQL.scalar.await(
        'SELECT 1 FROM `garage_categories` WHERE `id` = ? AND `owner` = ?',
        { categoryId, identifier }
    ) ~= nil
end

---@param plate string
---@param categoryId number? nil clears the vehicle's category
function Db.SetVehicleCategory(plate, categoryId)
    if categoryId then
        return MySQL.update.await([[
            INSERT INTO garage_vehicle_category (plate, category_id) VALUES (?, ?)
            ON DUPLICATE KEY UPDATE category_id = VALUES(category_id)
        ]], { plate, categoryId })
    end
    return MySQL.update.await('DELETE FROM `garage_vehicle_category` WHERE `plate` = ?', { plate })
end

---@param plate string
---@return table[] rows { shared_with }
function Db.GetShares(plate)
    return MySQL.query.await(
        'SELECT `shared_with` FROM `garage_shared` WHERE `plate` = ?',
        { plate }
    ) or {}
end

---@param plate string
---@param identifier string
---@return boolean
function Db.IsShared(plate, identifier)
    return MySQL.scalar.await(
        'SELECT 1 FROM `garage_shared` WHERE `plate` = ? AND `shared_with` = ?',
        { plate, identifier }
    ) ~= nil
end

---@param plate string
---@param identifier string
function Db.AddShare(plate, identifier)
    return MySQL.insert.await(
        'INSERT IGNORE INTO `garage_shared` (`plate`, `shared_with`) VALUES (?, ?)',
        { plate, identifier }
    )
end

---@param plate string
---@param identifier string
function Db.RemoveShare(plate, identifier)
    return MySQL.update.await(
        'DELETE FROM `garage_shared` WHERE `plate` = ? AND `shared_with` = ?',
        { plate, identifier }
    )
end
