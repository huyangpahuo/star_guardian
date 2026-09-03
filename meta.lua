local profile = require("profile")

local meta = {filename = "savegame.lua"}

function meta.path()
    return love.filesystem.getSaveDirectory() .. "\\" .. meta.filename
end

local function serialize(v)
    local t = type(v)
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "string" then return string.format("%q", v) end
    if t ~= "table" then return "nil" end
    local out = {"{"}
    for k, val in pairs(v) do
        local key = type(k) == "string" and k:match("^[%a_][%w_]*$") and (k .. " = ") or ("[" .. serialize(k) .. "] = ")
        table.insert(out, "  " .. key .. serialize(val) .. ",")
    end
    table.insert(out, "}")
    return table.concat(out, "\n")
end

function meta.load()
    if not love.filesystem.getInfo(meta.filename) then return nil end
    local chunk = love.filesystem.load(meta.filename)
    if not chunk then return nil end
    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

function meta.write(data)
    profile.merge(data)
    return love.filesystem.write(meta.filename, "return " .. serialize(profile.get()))
end

return meta
