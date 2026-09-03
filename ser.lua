local ser = {}

local function escape(str)
    return string.format("%q", str)
end

local function serializeValue(v, indent)
    indent = indent or ""
    local t = type(v)
    if t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "string" then
        return escape(v)
    elseif t == "table" then
        local parts = {"{"}
        local nextIndent = indent .. "  "
        for k, val in pairs(v) do
            local key
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                key = k .. " = "
            else
                key = "[" .. serializeValue(k, nextIndent) .. "] = "
            end
            table.insert(parts, nextIndent .. key .. serializeValue(val, nextIndent) .. ",")
        end
        if #parts > 1 then table.insert(parts, indent) end
        table.insert(parts, "}")
        return table.concat(parts, "\n")
    else
        return "nil"
    end
end

function ser.serialize(v)
    return serializeValue(v)
end

return ser
