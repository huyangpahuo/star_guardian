local state = {
    name = "menu",
    stack = {},
}

function state.is(name)
    return state.name == name
end

function state.set(name)
    state.name = name
end

function state.push(name)
    table.insert(state.stack, state.name)
    state.name = name
end

function state.pop()
    local prev = table.remove(state.stack)
    if prev then state.name = prev end
end

return state
