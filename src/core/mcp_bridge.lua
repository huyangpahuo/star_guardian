-- Optional TCP bridge so external MCP tooling can inspect and drive the
-- game (list objects / get object / run Lua / get state / ping).
-- Disabled unless MCP_PORT is set; every failure path is contained so the
-- bridge can never crash the game (busy port, missing luasocket, ...).
local json = require("src.core.json")

local mcp_bridge = {server = nil, clients = {}, objectGetter = nil, enabled = false}

function mcp_bridge.init()
    local port = tonumber(os.getenv("MCP_PORT"))
    if not port then return false end
    local ok, err = pcall(function()
        local socket = require("socket")
        local s = assert(socket.tcp())
        assert(s:bind("*", port))
        assert(s:listen(5))
        s:settimeout(0)
        mcp_bridge.server = s
    end)
    mcp_bridge.enabled = ok
    if ok then
        print("MCP bridge listening on port " .. port)
    else
        print("MCP bridge disabled: " .. tostring(err))
    end
    return ok
end

function mcp_bridge.setObjectGetter(getter) mcp_bridge.objectGetter = getter end

function mcp_bridge.update()
    if not mcp_bridge.server then return end
    local ok, err = pcall(mcp_bridge.pump)
    if not ok then
        print("MCP bridge error: " .. tostring(err))
        mcp_bridge.server = nil
    end
end

function mcp_bridge.pump()
    local client = mcp_bridge.server:accept()
    if client then
        client:settimeout(0)
        mcp_bridge.clients[#mcp_bridge.clients + 1] = client
        print("MCP client connected")
    end

    for i = #mcp_bridge.clients, 1, -1 do
        local client = mcp_bridge.clients[i]
        local line, err = client:receive("*l")
        if line then
            local success, response = pcall(mcp_bridge.handleCommand, line)
            if success then
                client:send(response .. "\n")
            else
                client:send(json.encode({error = tostring(response)}) .. "\n")
            end
        elseif err == "closed" then
            client:close()
            table.remove(mcp_bridge.clients, i)
            print("MCP client disconnected")
        end
    end
end

function mcp_bridge.handleCommand(line)
    local command = json.decode(line)
    if command.command == "ping" then
        return json.encode({pong = true})
    elseif command.command == "list_objects" then
        return mcp_bridge.listObjects()
    elseif command.command == "get_object" then
        return mcp_bridge.getObject(command.id)
    elseif command.command == "get_state" then
        return mcp_bridge.getState()
    elseif command.command == "run_lua" then
        return mcp_bridge.runLua(command.code)
    else
        return json.encode({error = "Unknown command: " .. tostring(command.command)})
    end
end

local function objects()
    if not mcp_bridge.objectGetter then return nil end
    return mcp_bridge.objectGetter()
end

function mcp_bridge.listObjects()
    local objs = objects()
    if not objs then return json.encode({error = "No object getter configured"}) end
    local result = {}
    for id, obj in pairs(objs) do
        if type(obj) == "table" then
            result[#result + 1] = {id = id, type = obj.type, x = obj.x, y = obj.y}
        else
            result[#result + 1] = {id = id, type = type(obj)}
        end
    end
    return json.encode({objects = result})
end

function mcp_bridge.getObject(id)
    local objs = objects()
    if not objs then return json.encode({error = "No object getter configured"}) end
    local obj = objs[id]
    if not obj then return json.encode({error = "Object not found: " .. tostring(id)}) end
    return json.encode({object = obj})
end

-- Flattened snapshot of the interesting game state for quick polling.
function mcp_bridge.getState()
    local objs = objects()
    if not objs then return json.encode({error = "No object getter configured"}) end
    local session = objs.session
    local player = objs.player
    return json.encode({
        score = session and session.score,
        level = session and session.level,
        round = session and session.roundNum,
        highscore = session and session.highscore,
        player = player and {x = player.x, y = player.y, hp = player.hp, maxHp = player.maxHp},
    })
end

-- Run arbitrary Lua with read/write access to the exposed objects.
function mcp_bridge.runLua(code)
    local env = {
        objects = objects() or {},
        love = love,
        print = print,
        pairs = pairs, ipairs = ipairs,
        type = type, tostring = tostring, tonumber = tonumber,
        table = table, math = math, string = string,
    }
    local chunk, err
    if setfenv then
        chunk, err = loadstring(code, "=mcp")
        if chunk then setfenv(chunk, env) end
    else
        chunk, err = load(code, "=mcp", "t", env)
    end
    if not chunk then
        return json.encode({error = "Syntax error: " .. tostring(err)})
    end
    local success, result = pcall(chunk)
    if not success then
        return json.encode({error = "Runtime error: " .. tostring(result)})
    end
    if type(result) == "table" then
        return json.encode({result = result})
    end
    return json.encode({result = tostring(result)})
end

function mcp_bridge.shutdown()
    for _, client in ipairs(mcp_bridge.clients) do
        pcall(function() client:close() end)
    end
    mcp_bridge.clients = {}
    if mcp_bridge.server then
        pcall(function() mcp_bridge.server:close() end)
        mcp_bridge.server = nil
        print("MCP bridge shut down")
    end
    mcp_bridge.enabled = false
end

return mcp_bridge
