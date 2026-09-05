-- Minimal JSON encoder/decoder (used by the MCP bridge only).
local json = {}

local function encodeValue(v)
    local t = type(v)
    if t == "table" then
        local parts = {}
        local isArray = true
        local n = 0
        for k in pairs(v) do
            if type(k) ~= "number" then isArray = false break end
            n = n + 1
        end
        if isArray and n > 0 then
            for _, val in ipairs(v) do
                parts[#parts + 1] = encodeValue(val)
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        for k, val in pairs(v) do
            local key = type(k) == "string" and encodeValue(k) or tostring(k)
            parts[#parts + 1] = key .. ":" .. encodeValue(val)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif t == "string" then
        return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "nil" then
        return "null"
    else
        return '"' .. tostring(v) .. '"'
    end
end

function json.encode(obj) return encodeValue(obj) end

function json.decode(str)
    local pos = 1

    local function skipWhitespace()
        while pos <= #str and str:sub(pos, pos):match("%s") do pos = pos + 1 end
    end

    local function decodeString()
        local result = {}
        pos = pos + 1 -- opening quote
        while pos <= #str do
            local char = str:sub(pos, pos)
            if char == '"' then
                pos = pos + 1
                return table.concat(result)
            elseif char == "\\" then
                pos = pos + 1
                local escape = str:sub(pos, pos)
                local map = {n = "\n", t = "\t", r = "\r", ["\\"] = "\\", ['"'] = '"'}
                result[#result + 1] = map[escape] or escape
                pos = pos + 1
            else
                result[#result + 1] = char
                pos = pos + 1
            end
        end
        error("Unterminated string")
    end

    local function decodeValue()
        skipWhitespace()
        local char = str:sub(pos, pos)
        if char == '"' then
            return decodeString()
        elseif char == "{" then
            local obj = {}
            pos = pos + 1
            skipWhitespace()
            if str:sub(pos, pos) == "}" then pos = pos + 1 return obj end
            while true do
                skipWhitespace()
                local key = decodeString()
                skipWhitespace()
                if str:sub(pos, pos) ~= ":" then error("Expected :") end
                pos = pos + 1
                obj[key] = decodeValue()
                skipWhitespace()
                char = str:sub(pos, pos)
                if char == "}" then pos = pos + 1 return obj
                elseif char == "," then pos = pos + 1
                else error("Expected , or }") end
            end
        elseif char == "[" then
            local arr = {}
            pos = pos + 1
            skipWhitespace()
            if str:sub(pos, pos) == "]" then pos = pos + 1 return arr end
            while true do
                arr[#arr + 1] = decodeValue()
                skipWhitespace()
                char = str:sub(pos, pos)
                if char == "]" then pos = pos + 1 return arr
                elseif char == "," then pos = pos + 1
                else error("Expected , or ]") end
            end
        elseif str:sub(pos, pos + 3) == "true" then
            pos = pos + 4 return true
        elseif str:sub(pos, pos + 4) == "false" then
            pos = pos + 5 return false
        elseif str:sub(pos, pos + 3) == "null" then
            pos = pos + 4 return nil
        else
            local numStr = str:match("^%-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
            if numStr then
                pos = pos + #numStr
                return tonumber(numStr)
            end
            error("Invalid JSON value at position " .. pos)
        end
    end

    local value = decodeValue()
    return value
end

return json
