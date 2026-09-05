-- Font loading with CJK fallbacks. Fonts are cached per (size, language);
-- setLanguage() must be called whenever the active language changes.
local assets = {fonts = {}, lang = "en"}

assets.fontPaths = {
    "resources/fonts/NotoSansSC-Bold.ttf",
    "resources/fonts/NotoSansTC-Bold.ttf",
    "resources/fonts/NotoSansJP-Bold.ttf",
    "resources/fonts/NotoSansKR-Bold.ttf",
    "resources/fonts/NotoSans-Bold.ttf",
    "resources/fonts/GoNotoCurrent-Bold.ttf",
    "resources/fonts/GoNotoCJKCore.ttf",
    "resources/fonts/m6x11plus.ttf",
    "C:/Windows/Fonts/simhei.ttf", "C:/Windows/Fonts/simsun.ttc", "C:/Windows/Fonts/msyh.ttc", "C:/Windows/Fonts/deng.ttf",
    "/System/Library/Fonts/PingFang.ttc", "/System/Library/Fonts/STHeiti Light.ttc", "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc", "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/system/fonts/NotoSansCJK-Regular.ttc", "/system/fonts/NotoSansSC-Regular.otf", "/system/fonts/DroidSansFallback.ttf", "/system/fonts/Roboto-Regular.ttf",
}

assets.langFontPaths = {
    zh_CN = {"resources/fonts/NotoSansSC-Bold.ttf", "resources/fonts/GoNotoCurrent-Bold.ttf", "resources/fonts/GoNotoCJKCore.ttf", "C:/Windows/Fonts/simhei.ttf", "C:/Windows/Fonts/msyh.ttc", "C:/Windows/Fonts/simsun.ttc", "/system/fonts/NotoSansCJK-Regular.ttc", "/system/fonts/NotoSansSC-Regular.otf"},
    ja = {"resources/fonts/NotoSansJP-Bold.ttf", "resources/fonts/GoNotoCurrent-Bold.ttf", "resources/fonts/GoNotoCJKCore.ttf", "C:/Windows/Fonts/msgothic.ttc", "C:/Windows/Fonts/meiryo.ttc", "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc", "/system/fonts/NotoSansCJK-Regular.ttc"},
}

function assets.setLanguage(lang) assets.lang = lang end

-- Fonts load lazily on first use (see getFont). Preloading every size x
-- language used to pin 300-400MB of CJK font data in RAM at boot, so
-- initialization stays cheap now: a typical screen touches ~6 sizes in
-- one language.
function assets.init() end

function assets.loadFont(size, lang)
    local paths = (lang and assets.langFontPaths[lang]) or assets.fontPaths
    for _, path in ipairs(paths) do
        local ok, font = pcall(love.graphics.newFont, path, size)
        if ok and font then return font end
    end
    local ok, font = pcall(love.graphics.newFont, size)
    if ok and font then return font end
    return love.graphics.getFont()
end

function assets.getFont(size, lang)
    size = math.floor(size)
    lang = lang or assets.lang
    local key = tostring(size) .. ":" .. tostring(lang)
    if not assets.fonts[key] then assets.fonts[key] = assets.loadFont(size, lang) end
    return assets.fonts[key]
end

function assets.setFont(size, lang) love.graphics.setFont(assets.getFont(size, lang)) end

function assets.textWidth(text, size)
    assets.setFont(size)
    return love.graphics.getFont():getWidth(text)
end

function assets.clearCache()
    assets.fonts = {}
    assets.init()
end

return assets
