local assets = {
    fonts = {},
    fontPaths = {
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
    },
    langFontPaths = {
        zh_CN = {"resources/fonts/NotoSansSC-Bold.ttf", "resources/fonts/GoNotoCurrent-Bold.ttf", "resources/fonts/GoNotoCJKCore.ttf", "C:/Windows/Fonts/simhei.ttf", "C:/Windows/Fonts/msyh.ttc", "C:/Windows/Fonts/simsun.ttc", "/system/fonts/NotoSansCJK-Regular.ttc", "/system/fonts/NotoSansSC-Regular.otf"},
        ja = {"resources/fonts/NotoSansJP-Bold.ttf", "resources/fonts/GoNotoCurrent-Bold.ttf", "resources/fonts/GoNotoCJKCore.ttf", "C:/Windows/Fonts/msgothic.ttc", "C:/Windows/Fonts/meiryo.ttc", "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc", "/system/fonts/NotoSansCJK-Regular.ttc"},
    }
}
function assets.init() for _, size in ipairs({12,14,16,18,20,22,24,28,32,36,48,64}) do assets.getFont(size, "en"); assets.getFont(size, "zh_CN"); assets.getFont(size, "ja") end end
function assets.loadFont(size, lang)
    local paths = (lang and assets.langFontPaths[lang]) or assets.fontPaths
    for _, path in ipairs(paths) do
        local info = love.filesystem.getInfo(path)
        local ok, font
        if info then
            ok, font = pcall(love.graphics.newFont, path, size)
        else
            ok, font = pcall(love.graphics.newFont, path, size)
        end
        if ok and font then return font end
    end
    local ok, font = pcall(love.graphics.newFont, size)
    if ok and font then return font end
    return love.graphics.getFont()
end
function assets.getFont(size, lang) size = math.floor(size); local key = tostring(size) .. ":" .. tostring(lang or "default"); if not assets.fonts[key] then assets.fonts[key] = assets.loadFont(size, lang) end; return assets.fonts[key] end
function assets.setFont(size, lang) love.graphics.setFont(assets.getFont(size, lang)) end
function assets.clearCache() assets.fonts = {}; assets.init() end
return assets
