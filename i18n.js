.pragma library

var fallback = "en"

var strings = {
  "en": {
    "widget.locked": "Locked",
    "widget.unlocked": "Unlocked",
    "tooltip.locked": "Top bar locked · Accidental transparency & layout changes blocked (click to unlock)",
    "tooltip.unlocked": "Top bar unlocked (click to lock)",
    "panel.title": "Top Bar Lock",
    "panel.subtitle": "Lock protection against accidental clicks",
    "panel.status_locked": "Protection Active",
    "panel.status_unlocked": "Protection Disabled",
    "panel.toggle_btn_lock": "Lock Bar",
    "panel.toggle_btn_unlock": "Unlock Bar",
    "setting.lock_background": "Lock Bar Background",
    "setting.lock_background_desc": "Prevent double-click transparency cycling",
    "setting.lock_layout": "Lock Workspace Layout",
    "setting.lock_layout_desc": "Prevent layout switching when clicking active workspace",
    "setting.notifications": "Desktop Notifications",
    "setting.notifications_desc": "Show toast when an action is blocked",
    "notify.blocked_title": "Top Bar Locked",
    "notify.blocked_background": "Bar transparency change was blocked",
    "notify.blocked_layout": "Workspace layout toggle was blocked"
  },
  "ru": {
    "widget.locked": "Заблокирован",
    "widget.unlocked": "Разблокирован",
    "tooltip.locked": "Топбар заблокирован · Смена прозрачности и режима отключены (клик для разблокировки)",
    "tooltip.unlocked": "Топбар разблокирован (клик для блокировки)",
    "panel.title": "Блокировка топбара",
    "panel.subtitle": "Защита от случайных кликов и изменений",
    "panel.status_locked": "Защита активна",
    "panel.status_unlocked": "Защита отключена",
    "panel.toggle_btn_lock": "Заблокировать",
    "panel.toggle_btn_unlock": "Разблокировать",
    "setting.lock_background": "Блокировать фон бара",
    "setting.lock_background_desc": "Запретить смену прозрачности по двойному клику",
    "setting.lock_layout": "Блокировать режим столов",
    "setting.lock_layout_desc": "Запретить смену раскладки при клике на активный стол",
    "setting.notifications": "Уведомления",
    "setting.notifications_desc": "Показывать оповещение при блокировке действия",
    "notify.blocked_title": "Топбар заблокирован",
    "notify.blocked_background": "Смена прозрачности топбара заблокирована",
    "notify.blocked_layout": "Смена режима рабочего стола заблокирована"
  }
}

function normalizeLocale(value) {
  var code = String(value || "").trim().toLowerCase()
  if (!code) return ""
  var modifier = code.indexOf("@")
  if (modifier > 0) code = code.slice(0, modifier)
  var encoding = code.indexOf(".")
  if (encoding > 0) code = code.slice(0, encoding)
  return code.replace(/_/g, "-")
}

function matchLocale(code) {
  if (!code) return ""
  if (strings[code] !== undefined) return code
  var base = code.split("-")[0]
  if (strings[base] !== undefined) return base
  return ""
}

function resolveLanguage(preference, systemLocale) {
  var pref = normalizeLocale(preference)
  if (pref && pref !== "auto" && pref !== "system") {
    var chosen = matchLocale(pref)
    if (chosen) return chosen
  }
  return matchLocale(normalizeLocale(systemLocale)) || fallback
}

function tr(language, key, a, b, c, d) {
  var table = strings[language] || strings[fallback]
  var value = table[key]
  if (value === undefined) value = strings[fallback][key]
  if (value === undefined) return String(key)

  var args = [a, b, c, d]
  for (var i = 0; i < args.length; i++) {
    if (args[i] === undefined) continue
    value = value.replace("{" + i + "}", String(args[i]))
  }
  return value
}
