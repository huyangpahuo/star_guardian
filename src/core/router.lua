-- Stack-based scene router.
--   gotoScene(name) replace the whole stack (hard transitions)
--   push(name)      open an overlay on top of the current scene
--   pop()           close the top overlay, revealing what was beneath
-- Draw walks the whole stack bottom-up so overlays render over their
-- parent; update and input events go to the top frame only, which freezes
-- gameplay while an overlay is open.
local router = {}

function router.new(scenes, ctx)
    return setmetatable({scenes = scenes, ctx = ctx, stack = {}}, {__index = router})
end

function router:frame() return self.stack[#self.stack] end
function router:currentName() local f = self:frame(); return f and f.name end

local function closeFrame(self, i)
    local f = table.remove(self.stack, i)
    if f and f.scene.exit then f.scene.exit(self.ctx, f) end
    return f
end

function router:push(name, params)
    local scene = self.scenes[name]
    assert(scene, "unknown scene: " .. tostring(name))
    local frame = {name = name, scene = scene, layout = {}}
    self.stack[#self.stack + 1] = frame
    if scene.enter then scene.enter(self.ctx, frame, params) end
    return frame
end

function router:pop()
    if #self.stack <= 1 then return nil end
    return closeFrame(self, #self.stack)
end

function router:gotoScene(name, params)
    while #self.stack > 0 do closeFrame(self, #self.stack) end
    return self:push(name, params)
end

function router:update(dt)
    local f = self:frame()
    if f and f.scene.update then f.scene.update(self.ctx, f, dt) end
end

function router:draw()
    for i = 1, #self.stack do
        local f = self.stack[i]
        f.layout = f.layout or {}
        f.scene.draw(self.ctx, f)
    end
end

function router:keypressed(key)
    local f = self:frame()
    if f and f.scene.keypressed then return f.scene.keypressed(self.ctx, f, key) end
end

function router:pointerpressed(x, y)
    local f = self:frame()
    if f and f.scene.pointerpressed then return f.scene.pointerpressed(self.ctx, f, x, y) end
end

function router:pointerreleased(x, y)
    local f = self:frame()
    if f and f.scene.pointerreleased then return f.scene.pointerreleased(self.ctx, f, x, y) end
end

function router:pointermoved(x, y)
    local f = self:frame()
    if f and f.scene.pointermoved then return f.scene.pointermoved(self.ctx, f, x, y) end
end

return router
