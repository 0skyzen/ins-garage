---@param title string embed title
---@param description string embed description
---@param color number? embed color (decimal)
function GarageLog(title, description, color)
    if not Config.Webhook or Config.Webhook == '' then return end

    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
        username = 'ins-garages',
        embeds = { {
            title = title,
            description = description,
            color = color or 3447003,
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') },
        } },
    }), { ['Content-Type'] = 'application/json' })
end

---@param source number
---@return string label "Name (id: src | identifier)"
function LogPlayer(source)
    return ('%s (id: %s | %s)'):format(GetPlayerName(source) or '?', source, GetIdentifier(source) or '?')
end
