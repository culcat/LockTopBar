import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui as Ui
import qs.Commons as Commons
import "i18n.js" as I18n

Ui.BarWidget {
  id: root
  moduleName: "io.github.culcat.lock-topbar"

  // Settings & State
  property bool isLocked: setting("locked", true)
  property bool lockBackground: setting("lockBackground", true)
  property bool lockLayout: setting("lockLayout", true)
  property bool showNotifications: setting("showNotifications", true)
  property bool popupOpen: false

  // State file path for persistence across shell restarts
  readonly property string stateFilePath: Quickshell.env("HOME") + "/.local/state/omarchy/lock-topbar.json"

  // Localization
  readonly property string systemLocale: {
    var candidates = [Quickshell.env("LC_ALL"), Quickshell.env("LC_MESSAGES"), Quickshell.env("LANG")]
    for (var i = 0; i < candidates.length; i++) {
      if (candidates[i] && String(candidates[i]).trim() !== "") return String(candidates[i])
    }
    return String(Qt.locale().name || "")
  }
  readonly property string language: I18n.resolveLanguage("auto", systemLocale)

  function tr(key, a, b, c, d) {
    return I18n.tr(language, key, a, b, c, d)
  }

  // Visual appearance
  implicitWidth: iconButton.width
  implicitHeight: iconButton.height

  // Main Bar Button
  Ui.BarIconButton {
    id: iconButton
    anchors.centerIn: parent

    bar: root.bar
    text: root.isLocked ? "󰌾" : "󰌿"
    active: root.isLocked
    dimmed: !root.isLocked
    useActiveColor: true
    activeColor: Commons.Color.accent

    tooltipText: root.isLocked ? root.tr("tooltip.locked") : root.tr("tooltip.unlocked")

    onPressed: function(mouse) {
      if (mouse.button === Qt.LeftButton) {
        root.toggleLock()
      } else if (mouse.button === Qt.RightButton) {
        root.popupOpen = !root.popupOpen
      }
    }
  }

  // Popup settings card on right click
  Ui.PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Commons.Style.space(320))
    contentHeight: popup.fittedContentHeight(popupColumn.implicitHeight)

    Column {
      id: popupColumn
      anchors.fill: parent
      spacing: Commons.Style.space(12)
      padding: Commons.Style.space(14)

      // Header
      RowLayout {
        width: parent.width
        spacing: Commons.Style.space(10)

        Text {
          text: root.isLocked ? "󰌾" : "󰌿"
          font.family: Commons.Style.font.family
          font.pixelSize: Commons.Style.font.title
          color: root.isLocked ? Commons.Color.accent : Commons.Color.dimmed
          textFormat: Text.PlainText
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Commons.Style.space(2)

          Text {
            text: root.tr("panel.title")
            font.family: Commons.Style.font.family
            font.pixelSize: Commons.Style.font.subtitle
            font.weight: Font.Bold
            color: Commons.Color.popups.text
            textFormat: Text.PlainText
          }

          Text {
            text: root.isLocked ? root.tr("panel.status_locked") : root.tr("panel.status_unlocked")
            font.family: Commons.Style.font.family
            font.pixelSize: Commons.Style.font.caption
            color: root.isLocked ? Commons.Color.accent : Commons.Color.dimmed
            textFormat: Text.PlainText
          }
        }

        Ui.Button {
          text: root.isLocked ? root.tr("panel.toggle_btn_unlock") : root.tr("panel.toggle_btn_lock")
          onClicked: root.toggleLock()
        }
      }

      Ui.PanelSeparator {
        width: parent.width
      }

      // Option 1: Lock Background
      Ui.Toggle {
        width: parent.width
        label: root.tr("setting.lock_background")
        description: root.tr("setting.lock_background_desc")
        checked: root.lockBackground
        onClicked: {
          root.lockBackground = !root.lockBackground
          root.saveState()
        }
      }

      // Option 2: Lock Layout
      Ui.Toggle {
        width: parent.width
        label: root.tr("setting.lock_layout")
        description: root.tr("setting.lock_layout_desc")
        checked: root.lockLayout
        onClicked: {
          root.lockLayout = !root.lockLayout
          root.saveState()
        }
      }

      // Option 3: Notifications
      Ui.Toggle {
        width: parent.width
        label: root.tr("setting.notifications")
        description: root.tr("setting.notifications_desc")
        checked: root.showNotifications
        onClicked: {
          root.showNotifications = !root.showNotifications
          root.saveState()
        }
      }
    }
  }

  // IPC Commands handler (omarchy-shell io.github.culcat.lock-topbar <command>)
  Commons.ShellIpc {
    target: "io.github.culcat.lock-topbar"

    function toggle() {
      root.toggleLock()
      return root.isLocked ? "locked" : "unlocked"
    }

    function lock() {
      root.setLocked(true)
      return "locked"
    }

    function unlock() {
      root.setLocked(false)
      return "unlocked"
    }

    function status() {
      return root.isLocked ? "locked" : "unlocked"
    }
  }

  // Toggle & Mutator functions
  function toggleLock() {
    setLocked(!isLocked)
  }

  function setLocked(val) {
    if (isLocked === val) return
    isLocked = val
    saveState()
  }

  // Send desktop notification when modification is blocked
  function notifyBlocked(actionType) {
    if (!showNotifications) return
    var message = actionType === "background"
      ? root.tr("notify.blocked_background")
      : root.tr("notify.blocked_layout")

    Quickshell.execDetached([
      "omarchy-notification-send",
      "-p",
      "-r", "994821",
      "-g", "󰌾",
      root.tr("notify.blocked_title"),
      message
    ])
  }

  // Interception core: patches Commons.Util.execDetached
  function installHooks() {
    if (Commons.Util && !Commons.Util._lockTopBarIntercepted) {
      Commons.Util._lockTopBarIntercepted = true
      var origExec = Commons.Util.execDetached

      Commons.Util.execDetached = function(command) {
        if (root.isLocked && typeof command === "string") {
          var isBgCycle = command.indexOf("omarchy-bar background cycle") !== -1 ||
                          command.indexOf("omarchy-bar background") !== -1
          var isLayoutToggle = command.indexOf("omarchy-hyprland-workspace-layout-toggle") !== -1

          if (isBgCycle && root.lockBackground) {
            root.notifyBlocked("background")
            return
          }
          if (isLayoutToggle && root.lockLayout) {
            root.notifyBlocked("layout")
            return
          }
        }
        return origExec(command)
      }
    }

    // Also traverse parent tree to protect bar root if available
    patchBarTree(root)
  }

  function patchBarTree(item) {
    var cur = item
    while (cur) {
      if (typeof cur.cycleBackground === "function" && !cur._lockTopBarPatched) {
        cur._lockTopBarPatched = true
        var origCycle = cur.cycleBackground
        cur.cycleBackground = function() {
          if (root.isLocked && root.lockBackground) {
            root.notifyBlocked("background")
            return
          }
          return origCycle.apply(this, arguments)
        }
      }

      if (typeof cur.run === "function" && !cur._lockTopBarRunPatched) {
        cur._lockTopBarRunPatched = true
        var origRun = cur.run
        cur.run = function(cmd) {
          if (root.isLocked && root.lockLayout && typeof cmd === "string" && cmd.indexOf("omarchy-hyprland-workspace-layout-toggle") !== -1) {
            root.notifyBlocked("layout")
            return
          }
          return origRun.apply(this, arguments)
        }
      }

      if (typeof cur.beginBarMove === "function" && !cur._lockTopBarMovePatched) {
        cur._lockTopBarMovePatched = true
        var origMove = cur.beginBarMove
        cur.beginBarMove = function(win) {
          if (root.isLocked) return
          return origMove.apply(this, arguments)
        }
      }

      cur = cur.parent
    }
  }

  // Persistence
  FileView {
    id: stateFile
    path: root.stateFilePath
    watchChanges: true
    printErrors: false
    onFileChanged: root.loadState()
  }

  function loadState() {
    var raw = stateFile.text()
    if (!raw) return
    try {
      var data = JSON.parse(raw)
      if (data && typeof data === "object") {
        if (typeof data.locked === "boolean") isLocked = data.locked
        if (typeof data.lockBackground === "boolean") lockBackground = data.lockBackground
        if (typeof data.lockLayout === "boolean") lockLayout = data.lockLayout
        if (typeof data.showNotifications === "boolean") showNotifications = data.showNotifications
      }
    } catch (e) {
      // ignore JSON parse error
    }
  }

  function saveState() {
    var payload = {
      "locked": isLocked,
      "lockBackground": lockBackground,
      "lockLayout": lockLayout,
      "showNotifications": showNotifications
    }
    stateFile.setText(JSON.stringify(payload, null, 2) + "\n")
  }

  Component.onCompleted: {
    loadState()
    installHooks()
    Qt.callLater(installHooks)
  }
}
