--[[
    ins-garages — configuration

    Hey! Thanks for downloading. Everything you can tweak lives in this file.
    Change the values, save, then restart the resource (txAdmin or `restart
    ins-garages` in the server console). You don't need to touch any other file.

    If something breaks, double-check you didn't remove a comma or a bracket. :)
]]

Config = {}

-- Which framework are you on? Leave this on 'auto' and the script figures it out
-- by itself (ESX or QBCore). If auto-detect ever gives you trouble, you can force
-- it by setting this to 'esx' or 'qb'.
Config.Framework = 'auto'

-- This loads the translations from the locales/ folder. Don't remove this line.
-- Want another language? Copy locales/en.json to e.g. locales/de.json, translate
-- the values, and set the convar `setr ox:locale "de"` in your server.cfg.
lib.locale()

-- The key players press to OPEN the garage menu (on foot).
-- Full list of key ids: https://docs.fivem.net/docs/game-references/controls/
Config.OpenKey = 38 -- E

-- The key players press to STORE the car they're sitting in.
Config.StoreKey = 47 -- G

-- How close (in meters) the player has to be on foot to open the garage.
Config.InteractDistance = 2.0

-- How close the car has to be to the garage to park it with the store key.
-- A bit bigger than the one above so you can park without sitting on top of it.
Config.StoreDistance = 8.0

-- How many categories (folders) a single player is allowed to create, and how
-- long a category name can be. Raise or lower these to taste.
Config.MaxCategories = 10
Config.MaxCategoryNameLength = 24

-- The glowing marker shown at every garage. `type` is the marker shape, `size`
-- how big it is, and `color` its RGBA. Marker shapes: https://docs.fivem.net/docs/game-references/markers/
Config.Marker = {
    type = 36,
    size = vec3(1.0, 1.0, 1.0),
    color = { r = 65, g = 130, b = 255, a = 150 },
}

-- Cars that can NEVER be shared with other players (use the spawn name, lowercase).
-- Handy for keeping rare/donator vehicles from being passed around. Add as many
-- as you like.
Config.ShareBlacklist = {
    'adder',
    'zentorno',
    't20',
}

-- Jobs a vehicle can NEVER be transferred to (job name, lowercase). 'unemployed'
-- is here so people can't dump cars onto the "no job" society by accident.
Config.JobTransferBlacklist = {
    'unemployed',
}

-- Charge players cash to recover a vehicle they lost outside the garage (blew it
-- up, crashed, relogged, etc.). Set to 0 if you want recovery to be free.
Config.RecoverFee = 0

--[[
    Your garages. Add as many as you want — just copy one block and tweak it.

    label  : the name shown on the blip and at the top of the menu.
    coords  : where the marker sits and where players interact. vec3(x, y, z).
    spawn   : where cars come out. vec4(x, y, z, heading) — heading = which way
              the car faces. Pick a clear spot so cars don't spawn inside a wall.
    blip    : the map icon. Set it to false if you don't want a blip at all.
    types   : (optional) which vehicle types this garage handles, e.g. { 'car' }
              for a normal garage, { 'boat' } for a marina, { 'air' } for a
              hangar. Remove the line entirely to allow every type.
    job     : (optional) lock the garage to one job, e.g. 'police'. Only players
              with that job will see the prompt and can open it. Remove the line
              for a normal public garage.
]]
Config.Garages = {
    {
        label = 'Legion Square Garage',
        coords = vec3(214.4611, -794.1823, 30.8446),
        spawn = vec4(228.5, -801.0, 30.5, 158.0),
        blip = { sprite = 357, color = 3, scale = 0.8 },
        types = { 'car' },
    },
    {
        label = 'Sandy Shores Garage',
        coords = vec3(1736.0, 3710.0, 34.15),
        spawn = vec4(1729.0, 3712.0, 34.0, 22.0),
        blip = { sprite = 357, color = 3, scale = 0.8 },
        types = { 'car' },
    },
    -- Here's an example of a job-locked garage. Remove the dashes to enable it,
    -- or use it as a template for your own faction garages.
    -- {
    --     label = 'Police Garage',
    --     coords = vec3(454.6, -1017.4, 28.4),
    --     spawn = vec4(438.5, -1018.3, 27.7, 90.0),
    --     blip = { sprite = 357, color = 3, scale = 0.8 },
    --     types = { 'car' },
    --     job = 'police',
    -- },
}
