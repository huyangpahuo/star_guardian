-- Localization lookup. Language packs live in localization/<code>.lua.
local i18n = {lang = "en", data = {}, listeners = {}}

for _, lang in ipairs({"en", "zh_CN", "ja"}) do
    i18n.data[lang] = require("localization." .. lang)
end
-- Short alias: the quick-switch buttons and old saves may use "zh".
i18n.data.zh = i18n.data.zh_CN

for _, lang in ipairs({"en", "zh_CN", "ja"}) do
    i18n.data[lang].name = i18n.data[lang].name or lang
end

function i18n.setLang(lang)
    if not i18n.data[lang] then return end
    i18n.lang = lang
    for _, fn in ipairs(i18n.listeners) do fn(lang) end
end

function i18n.onLangChange(fn) table.insert(i18n.listeners, fn) end
function i18n.t(key) return i18n.data[i18n.lang][key] or i18n.data.en[key] or key end
function i18n.getLangs() return {"en", "zh_CN", "ja"} end
function i18n.getName(code) return (i18n.data[code] and i18n.data[code].name) or code end

-- Best-effort locale guess from the environment; the save file wins later.
function i18n.autoDetect()
    local env = os.getenv("LANG") or os.getenv("LANGUAGE") or ""
    if env:find("zh") then i18n.setLang("zh_CN")
    elseif env:find("ja") or env:find("jp") then i18n.setLang("ja")
    else i18n.setLang("en") end
end

return i18n
