local utils = {}
function utils.checkCollision(a, b) return math.abs(a.x - b.x) < (a.width/2 + b.width/2) and math.abs(a.y - b.y) < (a.height/2 + b.height/2) end
function utils.clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
function utils.lerp(a, b, t) return a + (b - a) * t end
function utils.dist(x1, y1, x2, y2) return math.sqrt((x2 - x1)^2 + (y2 - y1)^2) end
function utils.pointInRect(px, py, rx, ry, rw, rh) return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh end
function utils.pointInCircle(px, py, cx, cy, r) return utils.dist(px, py, cx, cy) <= r end
return utils
