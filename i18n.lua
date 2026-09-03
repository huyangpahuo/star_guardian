local i18n = {lang = "en", data = {}}
for _, lang in ipairs({"en", "zh_CN", "ja"}) do i18n.data[lang] = require("localization." .. lang) end
i18n.data.zh = i18n.data.zh_CN
for _, lang in ipairs({"en", "zh_CN", "ja"}) do
    local t = i18n.data[lang]
    t.name = t.name or lang
end
function i18n.setLang(lang) if i18n.data[lang] then i18n.lang = lang end end
function i18n.t(key) return i18n.data[i18n.lang][key] or i18n.data.en[key] or key end
function i18n.autoDetect() local env = os.getenv("LANG") or os.getenv("LANGUAGE") or ""; if env:find("zh") then i18n.setLang("zh") elseif env:find("ja") or env:find("jp") then i18n.setLang("ja") else i18n.setLang("en") end end
function i18n.getLangs() return {"en", "zh_CN", "ja"} end
function i18n.getName(code) return (i18n.data[code] and i18n.data[code].name) or code end
return i18n
