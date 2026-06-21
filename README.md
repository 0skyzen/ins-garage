# 🚗 ins-garages

A clean, free garage system for **ESX & QBCore** — built entirely on **ox_lib**.

I got tired of garage scripts that ship a heavy NUI, fight with your other resources,
and bury 5 settings under 500 lines of code. So I made this one: no custom UI, no
bloat, everything runs through ox_lib context menus. It's small enough to read in one
sitting and easy to extend if you want to make it your own.

It's free and MIT-licensed — use it on your server, rip it apart, learn from it,
whatever you like. If it helps you, a ⭐ on the repo is appreciated but never required.

---

## ✨ What it does

- **Runs on ESX and QBCore** — it auto-detects your framework, or you can force it.
- **Park & retrieve** your cars at as many garages as you want to place.
- **Realistic parking** — when you park, your character actually steps out of the car
  first (exit animation), then it's stored.
- **Recover lost vehicles** — blew your car up? Crashed and relogged? It won't vanish
  forever. Lost cars show up in an *Out vehicles* list so players can get them back
  (optionally for a small fee you set).
- **Categories with folders** — players make their own folders ("Sports", "Work"…),
  rename or delete them, and their cars show up sorted inside each folder in the menu.
- **Vehicle sharing** — let a friend drive your car. They can take it out and park it
  back, but they can't re-share it or mess with your categories.
- **Transfer** — hand a car to another player, or straight to your faction. Transferring
  to a faction just uses your current job — no typing plate names or job names.
- **Faction garages** — lock a garage to a job (e.g. a police-only garage).
- **Per-garage vehicle types** — make a marina that only handles boats, a hangar for
  aircraft, etc.
- **Vehicle condition at a glance** — fuel, engine and body health show next to each car.
- **Anti plate-spoof protection** — players can't swap a plate onto a better car to
  "upgrade" what's stored; the server checks the real model.
- **Optional Discord logging** — drop in a webhook and share/transfer actions get logged.
- **Fully translatable** — every line of text lives in `locales/`. Add your language,
  done.

No screenshots of a fancy UI here, because there isn't one — it's all native ox_lib
menus, so it matches whatever theme your server already uses. 🙂

---

## 📦 Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- A framework — either [ESX](https://github.com/esx-framework/esx_core) or
  [QBCore](https://github.com/qbcore-framework/qb-core)

---

## 🔧 Installation

1. Drop the `ins-garages` folder into your `resources`.
2. Import `sql/install.sql` into your database. Don't worry — it uses
   `CREATE TABLE IF NOT EXISTS`, so your existing `owned_vehicles` table stays exactly
   as it is.
3. Add `ensure ins-garages` to your `server.cfg`.
4. Open `config.lua` and set your garage locations (and anything else you want). Every
   option in there is commented and explained.

That's it. Restart and you're good.

---

## 🌍 Translations

All text is loaded through ox_lib locales. To add a language, copy `locales/en.json`
to something like `locales/de.json`, translate the values, and set this in your
`server.cfg`:

```cfg
setr ox:locale "de"
```

If you make a translation, feel free to open a PR so others can use it too. ❤️

---

## 🧠 How it works (for the curious)

Cars live in the standard `owned_vehicles` table — `owner` is the ESX identifier or QB
citizenid, and the car's properties are saved in the `vehicle` column as JSON using
ox_lib's `getVehicleProperties` / `setVehicleProperties`. Three tiny extra tables power
the new stuff:

| Table                      | What it's for                              |
| -------------------------- | ------------------------------------------ |
| `garage_categories`        | The folders players create                 |
| `garage_vehicle_category`  | Which folder a plate belongs to            |
| `garage_shared`            | Who a plate is shared with                 |

Everything framework-specific (getting the player, their job, their money) is tucked
away in `server/bridge.lua` and `client/bridge.lua`. So if you ever want to add support
for another framework, those are the only two files you touch.

```
ins-garages/
├── config.lua            -- everything you configure (well commented)
├── fxmanifest.lua
├── sql/install.sql
├── locales/
│   └── en.json           -- all the text (add more languages here)
├── client/
│   ├── bridge.lua        -- framework glue (current job)
│   ├── main.lua          -- garage markers, spawning & parking
│   └── menu.lua          -- all the ox_lib menus
└── server/
    ├── bridge.lua        -- framework glue (player / identifier / job / money)
    ├── logs.lua          -- optional Discord logging
    ├── db.lua            -- all the database queries
    ├── main.lua          -- park / take out / recover
    ├── categories.lua    -- categories
    ├── sharing.lua       -- sharing
    └── transfer.lua      -- transfer to player / faction
```

---

## ❓ FAQ

**Does this replace my framework's default garage?**
No — it uses its own `owned_vehicles` setup and runs alongside whatever you have. On
QBCore it doesn't touch `player_vehicles`.

**A callback "does not exist" error?**
You almost certainly edited a file and didn't restart the resource. Run
`restart ins-garages` (and refresh if you added new files).

**Can players store any random car?**
Only cars they actually own (or that were shared with them), and the anti-spoof check
makes sure the model matches what's registered to the plate.

---

## 📄 License

MIT — do whatever you want with it. No credit required, though it's always appreciated.

Found a bug or have an idea? Open an issue. Pull requests welcome. 🛠️
