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
  property bool isLocked: true
  property bool lockBackground: true
  property bool lockLayout: true
  property bool showNotifications: true
  property bool popupOpen: false

  // Paths
  readonly property string homeDir: Quickshell.env("HOME")
  readonly property string stateFilePath: homeDir + "/.local/state/omarchy/lock-topbar.json"
  readonly property string pluginBinDir: homeDir + "/.config/omarchy/plugins/io.github.culcat.lock-topbar/bin"

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

  // Visual geometry
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
          color: root.isLocked ? Commons.Color.accent : Commons.Color.muted
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
            color: root.isLocked ? Commons.Color.accent : Commons.Color.muted
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
          root.broadcastState()
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
          root.broadcastState()
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
          root.broadcastState()
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

  // Synchronization between multi-monitor bar instances
  function syncFromPeer(val, bg, layout, notify) {
    isLocked = val
    lockBackground = bg
    lockLayout = layout
    showNotifications = notify
  }

  function broadcastState() {
    var items = bar && typeof bar.moduleWidgets === "function"
      ? bar.moduleWidgets(moduleName) : [root]
    for (var i = 0; i < items.length; i++) {
      if (items[i] && items[i] !== root && typeof items[i].syncFromPeer === "function") {
        items[i].syncFromPeer(isLocked, lockBackground, lockLayout, showNotifications)
      }
    }
  }

  // Toggle & Mutator functions
  function toggleLock() {
    setLocked(!isLocked)
  }

  function setLocked(val) {
    isLocked = val
    saveState()
    broadcastState()
  }

  // Persistence via FileView
  FileView {
    id: stateFile
    path: root.stateFilePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadState(text())
  }

  function loadState(raw) {
    var content = raw !== undefined ? raw : stateFile.text()
    if (!content) return
    try {
      var data = JSON.parse(content)
      if (data && typeof data === "object") {
        if (typeof data.locked === "boolean") isLocked = data.locked
        if (typeof data.lockBackground === "boolean") lockBackground = data.lockBackground
        if (typeof data.lockLayout === "boolean") lockLayout = data.lockLayout
        if (typeof data.showNotifications === "boolean") showNotifications = data.showNotifications
      }
    } catch (e) {
      // ignore parse errors
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

  // Automatic wrapper installation to ~/.local/bin
  Process {
    id: installerProc
    command: [
      "/bin/bash", "-c",
      "mkdir -p \"$HOME/.local/bin\" \"$HOME/.local/state/omarchy\" && " +
      "if [ -d \"" + root.pluginBinDir + "\" ]; then " +
      "  cp -f \"" + root.pluginBinDir + "/omarchy-bar\" \"$HOME/.local/bin/omarchy-bar\" 2>/dev/null; " +
      "  cp -f \"" + root.pluginBinDir + "/omarchy-hyprland-workspace-layout-toggle\" \"$HOME/.local/bin/omarchy-hyprland-workspace-layout-toggle\" 2>/dev/null; " +
      "  chmod +x \"$HOME/.local/bin/omarchy-bar\" \"$HOME/.local/bin/omarchy-hyprland-workspace-layout-toggle\" 2>/dev/null; " +
      "fi"
    ]
  }

  Component.onCompleted: {
    isLocked = setting("locked", isLocked)
    lockBackground = setting("lockBackground", lockBackground)
    lockLayout = setting("lockLayout", lockLayout)
    showNotifications = setting("showNotifications", showNotifications)
    loadState()
    installerProc.running = true
  }
}
