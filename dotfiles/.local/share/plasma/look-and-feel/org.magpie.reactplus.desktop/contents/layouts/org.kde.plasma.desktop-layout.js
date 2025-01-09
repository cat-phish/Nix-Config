var panel = new Panel
var panelScreen = panel.screen

panel.location = "bottom";
panel.height = 34
panel.alignment = "center";
panel.lengthMode = "fillavailable"
panel.floating = false

var kOff = panel.addWidget("org.kde.plasma.kickoff")
// const p = "file://" + userDataPath() + "/.local/share/plasma/look-and-feel/org.magpie.reactplus.desktop/contents/start.svg"
// kOff.writeConfig("icon", p)

panel.addWidget("org.kde.plasma.marginsseparator")

let taskBar = panel.addWidget("org.kde.plasma.taskmanager")
taskBar.currentConfigGroup = ["General"]
taskBar.writeConfig("launchers",["preferred://browser", "preferred://filemanager","applications:org.kde.konsole.desktop"])
taskBar.writeConfig("onlyGroupWhenFull", false)
taskBar.writeConfig("indicateAudioStreams", false)

panel.addWidget("org.kde.plasma.pager")

var langIds = ["as",    // Assamese
               "bn",    // Bengali
               "bo",    // Tibetan
               "brx",   // Bodo
               "doi",   // Dogri
               "gu",    // Gujarati
               "hi",    // Hindi
               "ja",    // Japanese
               "kn",    // Kannada
               "ko",    // Korean
               "kok",   // Konkani
               "ks",    // Kashmiri
               "lep",   // Lepcha
               "mai",   // Maithili
               "ml",    // Malayalam
               "mni",   // Manipuri
               "mr",    // Marathi
               "ne",    // Nepali
               "or",    // Odia
               "pa",    // Punjabi
               "sa",    // Sanskrit
               "sat",   // Santali
               "sd",    // Sindhi
               "si",    // Sinhala
               "ta",    // Tamil
               "te",    // Telugu
               "th",    // Thai
               "ur",    // Urdu
               "vi",    // Vietnamese
               "zh_CN", // Simplified Chinese
               "zh_TW"] // Traditional Chinese

if (langIds.indexOf(languageId) != -1) {
    panel.addWidget("org.kde.plasma.kimpanel");
}

panel.addWidget("org.kde.plasma.systemtray")
var dClock = panel.addWidget("org.kde.plasma.digitalclock");
dClock.writeConfig("showDate", true);
dClock.writeConfig("dateFormat", "custom")
dClock.writeConfig("customDateFormat", "ddd d MMM")
dClock.writeConfig("autoFontAndSize", false)
dClock.writeConfig("fontSize", 11)
var dLogout = panel.addWidget("org.kde.plasma.lock_logout");
dLogout.writeConfig("show_lockScreen", false);
