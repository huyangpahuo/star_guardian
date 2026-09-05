-- Central visual theme: palette plus screen-adaptive layout metrics.
-- Scenes must derive every coordinate from theme.metrics() instead of
-- hard-coding pixels, so the UI scales with any window size.
local theme = {
    colors = {
        bg        = {0.05, 0.05, 0.10},
        accent    = {0.40, 0.80, 1.00},
        primary   = {0.25, 0.72, 1.00},
        secondary = {0.38, 0.58, 0.95},
        success   = {0.20, 0.70, 0.40},
        danger    = {0.75, 0.30, 0.28},
        neutral   = {0.50, 0.50, 0.60},
        warn      = {1.00, 0.90, 0.30},
        text      = {1, 1, 1},
        dim       = {0.70, 0.80, 0.90},
        hpHigh    = {0.20, 0.90, 0.30},
        hpMid     = {1.00, 0.80, 0.20},
        hpLow     = {1.00, 0.20, 0.20},
    },
}

-- Recomputed every frame from the current window size.
function theme.metrics(w, h)
    local m = math.min(w, h)
    local btnH = math.min(60, h * 0.085)
    return {
        m = m,
        margin = m * 0.03,
        title = m * 0.085,
        heading = m * 0.07,
        body = m * 0.035,
        small = m * 0.028,
        btnW = math.min(340, w * 0.52),
        btnH = btnH,
        btnGap = btnH * 1.55,
        panelW = math.min(760, w * 0.88),
        panelH = math.min(560, h * 0.85),
    }
end

function theme.hpColor(ratio)
    if ratio > 0.5 then return theme.colors.hpHigh
    elseif ratio > 0.25 then return theme.colors.hpMid
    else return theme.colors.hpLow end
end

return theme
