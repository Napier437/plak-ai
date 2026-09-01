import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: anaPencere
    visible: true
    width: 1280
    height: 780
    title: "Windows Media Player 11 - Aero AI Suite"
    color: "transparent"

    // --- SPACE İLE BAS-KONUŞ KISAYOLLARI ---
    Shortcut {
        sequence: "Space"
        autoRepeat: false
        onActivated: {
            lcdDurumMetni.text = "DİNLENİYOR..."
            anaPencere.konusuyorMu = false
            asistan.basKonusBasla()
        }
    }

    property int temaModu: 0
    property real ozelOpaklik: 0.45
    property bool konusuyorMu: false
    property string aktifSekme: "Giriş"
    property int ttsModu: 0
    property string aktifSohbetBaslik: "Sohbet 1"
    property int aktifSohbetIndex: 0
    // HER SOHBETİN MESAJLARINI AYRI SAKLAYAN HAFIZA
    property var tumSohbetlerHafizasi: ({
        "Sohbet 1": [
            { "gonderen": "asistan", "mesaj": "Merhaba! Size nasıl yardımcı olabilirim?" }
        ]
    })

    function sohbetYukle(baslik) {
        chatModeli.clear()
        if (!tumSohbetlerHafizasi[baslik]) {
            tumSohbetlerHafizasi[baslik] = [
                { "gonderen": "asistan", "mesaj": "Yeni oturum hazır. Dinliyorum!" }
            ]
        }
        var liste = tumSohbetlerHafizasi[baslik]
        for (var i = 0; i < liste.length; i++) {
            chatModeli.append(liste[i])
        }
    }

    function sohbeteMesajKaydet(baslik, gonderen, mesaj) {
        if (!tumSohbetlerHafizasi[baslik]) {
            tumSohbetlerHafizasi[baslik] = []
        }
        tumSohbetlerHafizasi[baslik].push({ "gonderen": gonderen, "mesaj": mesaj })
    }
    ListModel {
        id: sohbetGecmisModeli
        ListElement { baslik: "Sohbet 1" }
    }

    ListModel {
        id: hatirlaticiModeli
        ListElement { baslik: "Asistan Ses Testi"; tarih: "01.09.2026"; saat: "17:00" }
        ListElement { baslik: "Modülleri Derle"; tarih: "02.09.2026"; saat: "15:30" }
    }

    Timer {
        id: aiCevapZamanlayici
        interval: 7000
        repeat: false
        onTriggered: {
            anaPencere.konusuyorMu = false
        }
    }

    // ==========================================================
    // 1. DİNAMİK AERO CAM & SİNEMATİK SLAYT GÖSTERİSİ KATMANI
    // ==========================================================
    Rectangle {
        id: aeroArkaPlan
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { 
                position: 0.00
                color: temaModu === 1 ? "#edf5fc" : (temaModu === 2 ? "#141518" : "#0f2035") 
            }
            GradientStop { 
                position: 0.45
                color: temaModu === 1 ? "#dbe7f3" : (temaModu === 2 ? "#090a0c" : "#070e17") 
            }
            GradientStop { 
                position: 1.00
                color: temaModu === 1 ? "#c2d4e7" : (temaModu === 2 ? "#030304" : "#020407") 
            }
        }

        Timer {
            id: slaytZamanlayici
            interval: 12000
            running: anaPencere.aktifSekme === "Giriş" && asistan.duvarKagidiVarMi
            repeat: true
            onTriggered: asistan.sonrakiDuvarKagidi()
        }

        Item {
            anchors.fill: parent
            clip: true
            visible: asistan.duvarKagidiVarMi

            Image {
                id: duvarKagidi
                anchors.centerIn: parent
                width: parent.width * 1.15
                height: parent.height * 1.15
                source: asistan.aktifDuvarKagidi
                fillMode: Image.PreserveAspectCrop
                opacity: anaPencere.ozelOpaklik
                asynchronous: true
                cache: true

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: anaPencere.aktifSekme === "Giriş"
                    NumberAnimation { from: 1.0; to: 1.08; duration: 12000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.08; to: 1.0; duration: 12000; easing.type: Easing.InOutQuad }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: anaPencere.aktifSekme === "Giriş"
                    NumberAnimation { from: -20; to: 20; duration: 12000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 20; to: -20; duration: 12000; easing.type: Easing.InOutSine }
                }

                Behavior on opacity { NumberAnimation { duration: 800 } }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: asistan.duvarKagidiVarMi
            gradient: Gradient {
                GradientStop { 
                    position: 0.00
                    color: temaModu === 1 ? Qt.rgba(0.9, 0.95, 1.0, 0.70) : (temaModu === 2 ? Qt.rgba(0.05, 0.05, 0.06, 0.80) : Qt.rgba(0.04, 0.08, 0.14, 0.72))
                }
                GradientStop { 
                    position: 1.00
                    color: temaModu === 1 ? Qt.rgba(0.7, 0.80, 0.90, 0.82) : (temaModu === 2 ? Qt.rgba(0.01, 0.01, 0.02, 0.90) : Qt.rgba(0.01, 0.02, 0.04, 0.88))
                }
            }
        }

        Rectangle {
            width: parent.width * 0.8
            height: parent.height * 0.65
            anchors.centerIn: parent
            radius: width / 2
            visible: anaPencere.aktifSekme !== "Giriş"
            opacity: temaModu === 1 ? 0.35 : (temaModu === 2 ? 0.08 : 0.25)
            gradient: Gradient {
                GradientStop { position: 0.0; color: temaModu === 1 ? "#ffffff" : (temaModu === 2 ? "#94a3b8" : "#00f2fe") }
                GradientStop { position: 0.5; color: temaModu === 1 ? "#60a5fa" : (temaModu === 2 ? "#334155" : "#1e40af") }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // ==========================================================
    // 2. ÜST SEKME ÇUBUĞU
    // ==========================================================
    Rectangle {
        id: sekmeCubugu
        width: parent.width
        height: 44
        anchors.top: parent.top
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.18, 0.22, 0.28, 0.95) }
            GradientStop { position: 0.45; color: Qt.rgba(0.08, 0.10, 0.14, 0.98) }
            GradientStop { position: 0.50; color: Qt.rgba(0.04, 0.05, 0.07, 1.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0.01, 0.02, 0.03, 1.0) }
        }
        border.color: Qt.rgba(1, 1, 1, 0.25)
        border.width: 1

        // SOL ÜST: STT VE 3 KADEMELİ TTS BUTONLARI
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

// 1. STT BUTONU (ONLINE / OFFLINE)
            Rectangle {
                width: 90
                height: 24
                radius: 12
                color: asistan.onlineMod ? "#10b981" : "#334155"
                border.color: asistan.onlineMod ? "#34d399" : "#64748b"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: asistan.onlineMod ? "⚡" : "🔒"; font.pixelSize: 10 }
                    Text {
                        text: asistan.onlineMod ? "ONLINE" : "OFFLINE"
                        color: "#ffffff"
                        font.pixelSize: 9
                        font.bold: true
                        font.family: "Segoe UI"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        asistan.onlineMod = !asistan.onlineMod
                    }
                }
            }
            // 2. 3 KADEMELİ TTS BUTONU (PIPER -> META -> SESSİZ)
            Rectangle {
                width: 85
                height: 24
                radius: 12
                color: anaPencere.ttsModu === 0 ? "#0284c7" : (anaPencere.ttsModu === 1 ? "#7c3aed" : "#334155")
                border.color: anaPencere.ttsModu === 0 ? "#38bdf8" : (anaPencere.ttsModu === 1 ? "#a78bfa" : "#64748b")
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: anaPencere.ttsModu === 0 ? "🚀" : (anaPencere.ttsModu === 1 ? "🎙️" : "🔇"); font.pixelSize: 10 }
                    Text {
                        text: anaPencere.ttsModu === 0 ? "PIPER" : (anaPencere.ttsModu === 1 ? "META" : "SESSİZ")
                        color: "#ffffff"
                        font.pixelSize: 9
                        font.bold: true
                        font.family: "Segoe UI"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        anaPencere.ttsModu = (anaPencere.ttsModu + 1) % 3
                        if (asistan.ttsMod !== undefined) {
                            asistan.ttsMod = anaPencere.ttsModu
                        }
                    }
                }
            }
        }

        // ORTA: SEKMELER VE GİRİŞ'İN SOLUNDAKİ FRENCH HORN
        Row {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 32
                height: 28
                radius: 4
                color: hornHov.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.08)
                border.color: hornHov.containsMouse ? "#38bdf8" : Qt.rgba(1, 1, 1, 0.3)
                border.width: 1

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: "french_horn.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: "📯"
                    font.pixelSize: 13
                    visible: parent.children[0].status !== Image.Ready
                }

                MouseArea {
                    id: hornHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ayarlarMenusu.popup()
                }
            }

            Repeater {
                model: [ "Giriş", "Terminal", "AI Assistant", "Sohbet" ]
                Rectangle {
                    width: modelData === "Terminal" ? 115 : 105
                    height: 28
                    radius: 4
                    property bool secili: anaPencere.aktifSekme === modelData
                    gradient: Gradient {
                        GradientStop { 
                            position: 0.0
                            color: secili ? (temaModu === 0 ? "#00c6ff" : (temaModu === 1 ? "#38bdf8" : "#64748b")) : (tabHov.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent") 
                        }
                        GradientStop { 
                            position: 1.0
                            color: secili ? (temaModu === 0 ? "#0072ff" : (temaModu === 1 ? "#0284c7" : "#1e293b")) : "transparent" 
                        }
                    }
                    border.color: secili ? "#ffffff" : (tabHov.containsMouse ? Qt.rgba(1, 1, 1, 0.3) : "transparent")
                    border.width: 1

                    Text {
                        text: modelData === "Terminal" ? "Terminal (Alpha)" : modelData
                        color: parent.secili ? "#ffffff" : "#94a3b8"
                        font.bold: parent.secili
                        font.pixelSize: 10
                        font.family: "Segoe UI"
                        anchors.centerIn: parent
                    }
                    MouseArea { 
                        id: tabHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: anaPencere.aktifSekme = modelData
                    }
                }
            }
        }

        // SAĞ ÜST KONTROL SETİ
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Row {
                visible: asistan.duvarKagidiVarMi
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    text: "Opaklık"
                    color: "#94a3b8"
                    font.pixelSize: 10
                    font.family: "Segoe UI"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 55
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: parent.width
                        height: 3
                        radius: 1.5
                        anchors.centerIn: parent
                        color: "#0f172a"
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                    }

                    Rectangle {
                        id: sliderTutamaç
                        width: 7
                        height: 13
                        radius: 2
                        x: (anaPencere.ozelOpaklik - 0.1) / 0.9 * (parent.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#cbd5e1"
                        border.color: "#38bdf8"
                        border.width: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        onPositionChanged: (mouse) => {
                            anaPencere.ozelOpaklik = 0.1 + (Math.max(0, Math.min(1, mouse.x / parent.width)) * 0.9)
                        }
                        onPressed: (mouse) => {
                            anaPencere.ozelOpaklik = 0.1 + (Math.max(0, Math.min(1, mouse.x / parent.width)) * 0.9)
                        }
                    }
                }
            }

            Rectangle {
                width: 105
                height: 26
                radius: 13
                gradient: Gradient {
                    GradientStop { position: 0.0; color: bgHov.containsMouse ? "#334155" : "#1e293b" }
                    GradientStop { position: 1.0; color: "#090d16" }
                }
                border.color: Qt.rgba(1, 1, 1, 0.35)

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "◀"
                        color: "#94a3b8"
                        font.pixelSize: 9
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: asistan.oncekiDuvarKagidi()
                        }
                    }
                    Text {
                        text: asistan.duvarKagidiVarMi ? "🖼️ Duvar K." : "🚫 Saf Mod"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 10
                        font.family: "Segoe UI"
                    }
                    Text {
                        text: "▶"
                        color: "#94a3b8"
                        font.pixelSize: 9
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: asistan.sonrakiDuvarKagidi()
                        }
                    }
                }
                MouseArea {
                    id: bgHov
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: asistan.sonrakiDuvarKagidi()
                }
            }

            Rectangle {
                width: 105
                height: 26
                radius: 13
                gradient: Gradient {
                    GradientStop { position: 0.0; color: temaHov.containsMouse ? "#475569" : "#1e293b" }
                    GradientStop { position: 1.0; color: "#090d16" }
                }
                border.color: Qt.rgba(1, 1, 1, 0.4)

                Text {
                    text: temaModu === 0 ? "🌊 Aqua Aero" : (temaModu === 1 ? "☀️ Işık Modu" : "🎹 Piano Black")
                    color: "#f8fafc"
                    font.bold: true
                    font.pixelSize: 10
                    font.family: "Segoe UI"
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: temaHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: anaPencere.temaModu = (anaPencere.temaModu + 1) % 3
                }
            }

            Rectangle {
                width: 85
                height: 26
                radius: 13
                gradient: Gradient {
                    GradientStop { position: 0.0; color: miniHov.containsMouse ? "#38bdf8" : "#1e293b" }
                    GradientStop { position: 1.0; color: "#090d16" }
                }
                border.color: Qt.rgba(1, 1, 1, 0.4)

                Text {
                    text: "🗖 Mini Mod"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 10
                    font.family: "Segoe UI"
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: miniHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        anaPencere.hide()
                        var comp = Qt.createComponent("mini_player.qml")
                        if (comp.status === Component.Ready) {
                            comp.createObject(null)
                        }
                    }
                }
            }
        }
    }

    // ==========================================================
    // 3. GÖRÜNÜM: "GİRİŞ" (SLAYT, BÜYÜK SAAT, ŞİİR & WIDGETLAR)
    // ==========================================================
    Item {
        id: girisGörünüm
        visible: anaPencere.aktifSekme === "Giriş"
        anchors.top: sekmeCubugu.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 28

        property var suAn: new Date()
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: girisGörünüm.suAn = new Date()
        }

        // 1. SOL ALT: BÜYÜK TARİH VE SAAT
        Column {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            spacing: 2

            Text {
                text: Qt.formatDate(girisGörünüm.suAn, "dddd, d MMMM yyyy")
                color: "#e2e8f0"
                font.pixelSize: 18
                font.bold: true
                font.family: "Segoe UI"
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.6)
            }

            Text {
                text: Qt.formatTime(girisGörünüm.suAn, "hh:mm")
                color: "#ffffff"
                font.pixelSize: 72
                font.bold: true
                font.family: "Segoe UI, Consolas"
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.7)
            }
        }

        // 2. ORTA ALAN: KUTUSUZ ZARİF ŞİİR & GÜNÜN SÖZÜ
        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            width: parent.width * 0.42
            spacing: 12

            Text {
                text: "“Ne içindeyim zamanın,\nNe de büsbütün dışında;\nYekpâre, geniş bir ânın\nParçalanmaz akışında.”"
                color: "#ffffff"
                font.pixelSize: 16
                font.italic: true
                font.family: "Georgia, Segoe UI"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width
                lineHeight: 1.5
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.75)
            }

            Text {
                text: "— Ahmet Hamdi Tanpınar"
                color: "#38bdf8"
                font.pixelSize: 12
                font.bold: true
                font.family: "Segoe UI"
                anchors.horizontalCenter: parent.horizontalCenter
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.6)
            }
        }

        // 3. SAĞ SÜTUN: ETKİNLİKLER (ÜST) & CURRENCYLER (ALT)
        Column {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 290
            spacing: 16

            // SAĞ ÜST: ETKİNLİKLER VE MİNİ TAKVİM
            Rectangle {
                width: parent.width
                height: parent.height * 0.52
                radius: 14
                color: Qt.rgba(0.04, 0.06, 0.09, 0.75)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                border.width: 1.2
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // BAŞLIK VE ETKİNLİK OLUŞTUR BUTONU
                    Row {
                        width: parent.width
                        height: 24

                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "📅"; font.pixelSize: 12 }
                            Text {
                                text: "ETKİNLİKLER"
                                color: "#38bdf8"
                                font.bold: true
                                font.pixelSize: 11
                                font.family: "Segoe UI"
                            }
                        }

                        Item { width: parent.width - 170; height: 1 }

                        Rectangle {
                            width: 78
                            height: 22
                            radius: 4
                            color: newEtkHov.containsMouse ? "#0284c7" : Qt.rgba(0.02, 0.52, 0.78, 0.3)
                            border.color: "#38bdf8"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "+ Etkinlik"
                                color: "#ffffff"
                                font.pixelSize: 9
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: newEtkHov
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hatirlaticiEkleModal.open()
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.15) }

                    // GERÇEK EKLENEN ETKİNLİKLER LİSTESİ
                    ScrollView {
                        width: parent.width
                        height: 75
                        clip: true

                        ListView {
                            width: parent.width
                            spacing: 4
                            model: hatirlaticiModeli
                            delegate: Rectangle {
                                width: parent.width - 4
                                height: 24
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.06)

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 6
                                    Text { text: "📌"; font.pixelSize: 8; anchors.verticalCenter: parent.verticalCenter }
                                    Text { 
                                        text: model.baslik
                                        color: "#ffffff"
                                        font.pixelSize: 9
                                        font.family: "Segoe UI"
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        width: 140
                                    }
                                    Text {
                                        text: model.saat ? model.saat : model.tarih
                                        color: "#38bdf8"
                                        font.pixelSize: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                        anchors.rightMargin: 4
                                    }
                                }
                            }
                        }
                    }

                    // CANLI MİNİ TAKVİM
                    Rectangle {
                        width: parent.width
                        height: parent.height - 125
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.45)
                        border.color: Qt.rgba(1, 1, 1, 0.15)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            Text {
                                text: Qt.formatDate(girisGörünüm.suAn, "MMMM yyyy").toUpperCase()
                                color: "#38bdf8"
                                font.bold: true
                                font.pixelSize: 10
                                font.family: "Segoe UI"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 14
                                Repeater {
                                    model: ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]
                                    Text { text: modelData; color: "#94a3b8"; font.pixelSize: 9; font.bold: true }
                                }
                            }

                            Grid {
                                anchors.horizontalCenter: parent.horizontalCenter
                                columns: 7
                                spacing: 12

                                Repeater {
                                    model: 31
                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 3
                                        property bool bugunMu: (index + 1) === girisGörünüm.suAn.getDate()
                                        color: bugunMu ? "#0284c7" : "transparent"
                                        border.color: bugunMu ? "#38bdf8" : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: index + 1
                                            color: parent.bugunMu ? "#ffffff" : "#cbd5e1"
                                            font.pixelSize: 8
                                            font.bold: parent.bugunMu
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // SAĞ ALT: CURRENCYLER (PİYASA & DÖVİZ KURLARI)
            Rectangle {
                width: parent.width
                height: parent.height * 0.44
                radius: 14
                color: Qt.rgba(0.04, 0.06, 0.09, 0.75)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                border.width: 1.2
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Row {
                        spacing: 8
                        Text { text: "📈"; font.pixelSize: 12 }
                        Text {
                            text: "CURRENCIES & PİYASALAR"
                            color: "#22c55e"
                            font.bold: true
                            font.pixelSize: 11
                            font.family: "Segoe UI"
                            font.letterSpacing: 1.0
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.15) }

                    Column {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: [
                                { birim: "USD / TRY", deger: "36.85 ₺", fark: "+%0.15", yukselis: true },
                                { birim: "EUR / TRY", deger: "39.40 ₺", fark: "+%0.22", yukselis: true },
                                { birim: "GRAM ALTIN", deger: "3.240 ₺", fark: "+%0.45", yukselis: true },
                                { birim: "BIST 100", deger: "10.150", fark: "-%0.30", yukselis: false }
                            ]

                            Rectangle {
                                width: parent.width
                                height: 26
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.04)

                                Row {
                                    width: parent.width
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: modelData.birim
                                        color: "#e2e8f0"
                                        font.bold: true
                                        font.pixelSize: 10
                                        font.family: "Segoe UI"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Item { width: 10; height: 1 }

                                    Text {
                                        text: modelData.deger
                                        color: "#ffffff"
                                        font.pixelSize: 10
                                        font.family: "Consolas"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.fark
                                        color: modelData.yukselis ? "#22c55e" : "#ef4444"
                                        font.bold: true
                                        font.pixelSize: 10
                                        font.family: "Segoe UI"
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================================
    // 4. GÖRÜNÜM A: KLASİK AI ASSISTANT MERKEZİ
    // ==========================================================
    Row {
        id: anaGörünümA
        visible: anaPencere.aktifSekme === "AI Assistant"
        anchors.top: sekmeCubugu.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 16

        Column {
            width: parent.width * 0.25
            height: parent.height
            spacing: 12

            Rectangle {
                width: parent.width
                height: 180
                radius: 12
                color: Qt.rgba(0.04, 0.06, 0.09, 0.82)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: "SİSTEM METRİKLERİ"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 11
                        font.family: "Segoe UI"
                    }

                    Repeater {
                        model: [
                            { label: "NEURAL ENGINE (LLM)", val: 0.82, col: "#00d2ff" },
                            { label: "GPU VRAM USAGE", val: 0.58, col: "#22c55e" },
                            { label: "AUDIO BUFFER (I/O)", val: 0.40, col: "#eab308" },
                            { label: "SYSTEM THREADS", val: 0.25, col: "#ef4444" }
                        ]

                        Column {
                            spacing: 3
                            Text {
                                text: modelData.label
                                color: "#94a3b8"
                                font.pixelSize: 9
                                font.bold: true
                            }
                            Rectangle {
                                width: 170
                                height: 8
                                radius: 4
                                color: "#030712"
                                Rectangle {
                                    width: parent.width * modelData.val
                                    height: parent.height
                                    radius: 4
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: Qt.darker(modelData.col, 1.3) }
                                        GradientStop { position: 1.0; color: modelData.col }
                                    }
                                }
                            }
                        }
                    }
                }
            }
// SOHBET GEÇMİŞİ (DİNAMİK LİSTE VE + YENİ SOHBET BUTONU)
            Rectangle {
                width: parent.width
                height: Math.max(120, parent.height - 180 - 120 - 48) // 180 (Metrikler) + 120 (Saat) + Spacing/Margin toplamı
                radius: 12
                color: Qt.rgba(0.04, 0.06, 0.09, 0.82)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Başlık ve Buton Satırı
                    Row {
                        width: parent.width
                        height: 24

                        Text {
                            text: "SOHBET GEÇMİŞİ"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 11
                            font.family: "Segoe UI"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Sağa yaslamak için araya esnek boşluk
                        Item {
                            width: parent.width - 95 - 85 // Başlık genişliği ve buton payı
                            height: 1
                        }

                        Rectangle {
                            width: 82
                            height: 22
                            radius: 4
                            color: newChatHov.containsMouse ? "#0284c7" : Qt.rgba(1, 1, 1, 0.15)
                            border.color: "#38bdf8"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "+ Yeni Sohbet"
                                color: "#ffffff"
                                font.pixelSize: 9
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: newChatHov
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var yeniNo = sohbetGecmisModeli.count + 1
                                    var yeniBaslik = "Sohbet " + yeniNo
                                    sohbetGecmisModeli.append({ "baslik": yeniBaslik })
                                    anaPencere.aktifSohbetBaslik = yeniBaslik
                                    anaPencere.aktifSohbetIndex = sohbetGecmisModeli.count - 1
                                    
                                    // Yeni sohbeti bağımsız hafızayla başlat
                                    tumSohbetlerHafizasi[yeniBaslik] = [
                                        { "gonderen": "asistan", "mesaj": "Yeni oturum hazır. Dinliyorum!" }
                                    ]
                                    sohbetYukle(yeniBaslik)
                                    anaPencere.aktifSekme = "Sohbet"
                                }
                            }
                        }
                    }

                    // Liste Alanı
                    ScrollView {
                        width: parent.width
                        height: parent.height - 36
                        clip: true

                        ListView {
                            width: parent.width
                            spacing: 6
                            model: sohbetGecmisModeli
                            delegate: Rectangle {
                                width: parent.width - 6
                                height: 32
                                radius: 5
                                color: (anaPencere.aktifSohbetIndex === index) ? Qt.rgba(0.02, 0.52, 0.78, 0.35) : (chatItemHov.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05))
                                border.color: (anaPencere.aktifSohbetIndex === index) ? "#38bdf8" : "transparent"

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    Text { text: "💬"; font.pixelSize: 10 }
                                    Text { text: model.baslik; color: "#cbd5e1"; font.pixelSize: 10; font.family: "Segoe UI" }
                                }

                                MouseArea {
                                    id: chatItemHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        anaPencere.aktifSohbetBaslik = model.baslik
                                        anaPencere.aktifSohbetIndex = index
                                        sohbetYukle(model.baslik) // Seçilen sohbetin geçmişini yükler
                                        anaPencere.aktifSekme = "Sohbet"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: dijitalSaatPaneli
                width: parent.width
                height: 120
                radius: 12
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1e242d" }
                    GradientStop { position: 1.0; color: "#040507" }
                }
                border.color: Qt.rgba(1, 1, 1, 0.35)
                clip: true

                Column {
                    anchors.centerIn: parent
                    spacing: 3
                    Text {
                        text: Qt.formatDate(girisGörünüm.suAn, "dddd, d MMMM yyyy")
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 11
                        font.family: "Segoe UI"
                        opacity: 0.9
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: Qt.formatTime(girisGörünüm.suAn, "hh:mm:ss")
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 32
                        font.family: "Segoe UI, Consolas"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // ORTA SÜTUN
        Item {
            width: parent.width * 0.46
            height: parent.height

            Rectangle {
                id: lcdEkrani
                width: parent.width * 0.95
                height: 48
                radius: 10
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#222a36" }
                    GradientStop { position: 1.0; color: "#05070a" }
                }
                border.color: "#00d2ff"

                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { text: "▶"; color: "#22c55e"; font.pixelSize: 13 }
                    Text {
                        id: lcdDurumMetni
                        text: "AERO MEDIA CORE • SİNYAL ALINIYOR"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 12
                        font.family: "Segoe UI"
                    }
                }
            }
            Item {
                anchors.fill: parent
                anchors.bottomMargin: 14
                opacity: anaPencere.konusuyorMu ? 1.0 : 0.25
                Behavior on opacity { NumberAnimation { duration: 300 } }

                Timer {
                    interval: 75
                    running: true
                    repeat: true
                    onTriggered: {
                        for (var i = 0; i < sutunModeli.count; ++i) {
                            var carpan = Math.sin((i / 8) * Math.PI) * 1.2
                            var taban = anaPencere.konusuyorMu ? (Math.random() * 65 + 30) * Math.max(0.6, carpan) : (Math.sin((i + Date.now()/250)) * 12 + 20)
                            sutunModeli.setProperty(i, "yukseklik", Math.max(16, Math.min(110, taban)))
                        }
                    }
                }

                ListModel {
                    id: sutunModeli
                    Component.onCompleted: {
                        for (var i = 0; i < 10; ++i) {
                            append({ "yukseklik": 25 })
                        }
                    }
                }

                Row {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14

                    Repeater {
                        model: sutunModeli
                        Rectangle {
                            width: 36
                            height: model.yukseklik
                            radius: 6
                            anchors.bottom: parent.bottom
                            gradient: Gradient {
                                GradientStop { 
                                    position: 0.00
                                    color: anaPencere.temaModu === 1 ? Qt.rgba(0.1, 0.1, 0.15, 0.85) : Qt.rgba(1.0, 1.0, 1.0, 0.85) 
                                }
                                GradientStop { 
                                    position: 0.40
                                    color: anaPencere.temaModu === 1 ? Qt.rgba(0.18, 0.20, 0.25, 0.60) : (anaPencere.temaModu === 0 ? Qt.rgba(0.0, 0.85, 1.0, 0.65) : Qt.rgba(0.9, 0.95, 1.0, 0.55)) 
                                }
                                GradientStop { 
                                    position: 1.00
                                    color: anaPencere.temaModu === 1 ? Qt.rgba(0.05, 0.05, 0.08, 0.35) : Qt.rgba(0.1, 0.25, 0.45, 0.25) 
                                }
                            }
                            border.color: anaPencere.temaModu === 1 ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(1, 1, 1, 0.6)
                            border.width: 1
                            Behavior on height { NumberAnimation { duration: 70 } }
                        }
                    }
                }
            }

            // PLAK GÖVDESİ
            Item {
                id: merkezPlakGrup
                width: 380
                height: 380
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -20

                Item {
                    anchors.fill: parent
                    Rectangle {
                        width: 366
                        height: 146
                        radius: 73
                        anchors.centerIn: parent
                        rotation: 45
                        gradient: Gradient {
                            GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.55) }
                            GradientStop { position: 0.20; color: Qt.rgba(1, 1, 1, 0.15) }
                            GradientStop { position: 0.80; color: Qt.rgba(0, 0, 0, 0.35) }
                            GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.30) }
                        }
                        border.color: Qt.rgba(1, 1, 1, 0.80)
                        border.width: 1.8
                    }

                    Rectangle {
                        width: 366
                        height: 146
                        radius: 73
                        anchors.centerIn: parent
                        rotation: -45
                        gradient: Gradient {
                            GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.55) }
                            GradientStop { position: 0.20; color: Qt.rgba(1, 1, 1, 0.15) }
                            GradientStop { position: 0.80; color: Qt.rgba(0, 0, 0, 0.35) }
                            GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.30) }
                        }
                        border.color: Qt.rgba(1, 1, 1, 0.80)
                        border.width: 1.8
                    }
                }

                Rectangle {
                    id: disKromHalka
                    width: 346
                    height: 346
                    radius: 173
                    anchors.centerIn: parent
                    gradient: Gradient {
                        GradientStop { position: 0.00; color: "#ffffff" }
                        GradientStop { position: 0.20; color: "#64748b" }
                        GradientStop { position: 0.45; color: "#cbd5e1" }
                        GradientStop { position: 0.70; color: "#1e293b" }
                        GradientStop { position: 0.90; color: "#94a3b8" }
                        GradientStop { position: 1.00; color: "#ffffff" }
                    }
                    border.color: Qt.rgba(1, 1, 1, 0.95)
                    border.width: 2.5

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: width / 2
                        color: "transparent"
                        border.color: Qt.rgba(0, 0, 0, 0.75)
                        border.width: 2
                    }
                }

                Rectangle {
                    id: vinilGovde
                    width: 322
                    height: 322
                    radius: 161
                    anchors.centerIn: parent
                    color: "#050608"
                    border.color: "#181a1f"
                    border.width: 1.2

                    Repeater {
                        model: 10
                        Rectangle {
                            width: 312 - (index * 11)
                            height: width
                            radius: width / 2
                            anchors.centerIn: parent
                            color: "transparent"
                            border.color: (index % 2 === 0) ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.95)
                            border.width: 1.2
                        }
                    }

                    Item {
                        id: parlayanVinilEfekti
                        anchors.fill: parent

                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1400
                            running: anaPencere.konusuyorMu
                        }

                        Rectangle {
                            width: parent.width
                            height: 70
                            radius: 35
                            anchors.centerIn: parent
                            rotation: 40
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.00; color: "transparent" }
                                GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.25) }
                                GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.95) }
                                GradientStop { position: 0.65; color: Qt.rgba(1, 1, 1, 0.25) }
                                GradientStop { position: 1.00; color: "transparent" }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 50
                            radius: 25
                            anchors.centerIn: parent
                            rotation: -50
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.00; color: "transparent" }
                                GradientStop { position: 0.40; color: Qt.rgba(0.7, 0.85, 1.0, 0.20) }
                                GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.80) }
                                GradientStop { position: 0.60; color: Qt.rgba(0.7, 0.85, 1.0, 0.20) }
                                GradientStop { position: 1.00; color: "transparent" }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 90
                            radius: 45
                            anchors.centerIn: parent
                            rotation: -10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.00; color: "transparent" }
                                GradientStop { position: 0.50; color: Qt.rgba(0, 0, 0, 0.90) }
                                GradientStop { position: 1.00; color: "transparent" }
                            }
                        }
                    }

                    Item {
                        id: donenCdKatmani
                        width: 206
                        height: 206
                        anchors.centerIn: parent

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0.00; color: "#ff2a2a" }
                                GradientStop { position: 0.18; color: "#ffcc00" }
                                GradientStop { position: 0.38; color: "#00e676" }
                                GradientStop { position: 0.62; color: "#00d4ff" }
                                GradientStop { position: 0.80; color: "#2979ff" }
                                GradientStop { position: 0.92; color: "#e0e7ff" }
                                GradientStop { position: 1.00; color: "#ff2a2a" }
                            }
                            RotationAnimation on rotation {
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 8000
                                running: anaPencere.konusuyorMu
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 14
                            anchors.centerIn: parent
                            rotation: 45
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.90) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 14
                            anchors.centerIn: parent
                            rotation: -45
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.90) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }

                    Rectangle {
                        width: 90
                        height: 90
                        radius: 45
                        anchors.centerIn: parent
                        color: Qt.rgba(0.15, 0.25, 0.35, 0.50)
                        border.color: Qt.rgba(1, 1, 1, 0.85)
                        border.width: 2.2
                    }

                    Rectangle {
                        id: merkezMilButon
                        width: 44
                        height: 44
                        radius: 22
                        anchors.centerIn: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: milHov.containsMouse ? "#ffffff" : "#f1f5f9" }
                            GradientStop { position: 0.5; color: milHov.containsMouse ? "#64748b" : "#334155" }
                            GradientStop { position: 1.0; color: "#090d16" }
                        }
                        border.color: "#ffffff"
                        border.width: 2

                        MouseArea {
                            id: milHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onPressed: {
                                lcdDurumMetni.text = "DİNLENİYOR..."
                                anaPencere.konusuyorMu = false
                                asistan.basKonusBasla()
                            }

                            onReleased: {
                                lcdDurumMetni.text = "DÜŞÜNÜYOR..."
                                asistan.basKonusBitir()
                            }

                            onCanceled: {
                                asistan.basKonusBitir()
                            }
                        }
                    }
                }

                Item {
                    width: 322
                    height: 161
                    anchors.top: vinilGovde.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    Rectangle {
                        width: 322
                        height: 322
                        radius: 161
                        anchors.top: parent.top
                        gradient: Gradient {
                            GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.70) }
                            GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.25) }
                            GradientStop { position: 0.60; color: "transparent" }
                        }
                    }
                }
            }
        }

        // SAĞ SÜTUN: KONSOL & DİNAMİK HATIRLATICILAR
        Column {
            width: parent.width * 0.26
            height: parent.height
            spacing: 12

            Rectangle {
                width: parent.width
                height: parent.height * 0.54
                radius: 12
                color: Qt.rgba(0.04, 0.06, 0.09, 0.82)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "SİSTEM KONSOLU"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 11
                        font.family: "Segoe UI"
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height - 30
                        color: "#030406"
                        radius: 6

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true

                            Text {
                                id: konsolMetni
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: "> Optical disc mounted.\n> Ready for prompt..."
                                color: "#86efac"
                                font.family: "Consolas, Monospace"
                                font.pixelSize: 10
                                lineHeight: 1.4
                            }
                        }
                    }
                }
            }

            // HATIRLATICILAR (DİNAMİK LİSTE VE + EKLE BUTONU)
            Rectangle {
                width: parent.width
                height: parent.height * 0.43
                radius: 12
                color: Qt.rgba(0.04, 0.06, 0.09, 0.82)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Row {
                        width: parent.width
                        Text {
                            text: "HATIRLATICILAR"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 11
                            font.family: "Segoe UI"
                        }

                        Rectangle {
                            width: 55
                            height: 18
                            radius: 4
                            color: "#0284c7"
                            anchors.right: parent.right

                            Text {
                                text: "+ Ekle"
                                color: "#ffffff"
                                font.pixelSize: 9
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hatirlaticiEkleModal.open()
                            }
                        }
                    }

                    ScrollView {
                        width: parent.width
                        height: parent.height - 30
                        clip: true

                        ListView {
                            width: parent.width
                            spacing: 6
                            model: hatirlaticiModeli
                            delegate: Rectangle {
                                width: parent.width - 4
                                height: 32
                                radius: 5
                                color: Qt.rgba(1, 1, 1, 0.06)
                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8
                                    Text { text: "📌"; font.pixelSize: 10 }
                                    Text { text: model.baslik; color: "#cbd5e1"; font.pixelSize: 10; font.family: "Segoe UI" }
                                    Text {
                                        text: model.saat ? model.saat : model.tarih
                                        color: "#94a3b8"
                                        font.pixelSize: 9
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================================
    // 5. GÖRÜNÜM B: SOHBET (CHAT) EKRANI
    // ==========================================================
    Row {
        id: sohbetGörünümB
        visible: anaPencere.aktifSekme === "Sohbet"
        anchors.top: sekmeCubugu.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 16

        Column {
            width: parent.width * 0.70
            height: parent.height
            spacing: 10

            Rectangle {
                width: parent.width
                height: parent.height - girdiKonteyner.height - 10
                radius: 14
                color: Qt.rgba(0.04, 0.06, 0.09, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                border.width: 1.2
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // DÜZENLENEBİLİR SOHBET BAŞLIĞI
                    Row {
                        spacing: 8
                        Text { text: "💬"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }

                        TextInput {
                            id: baslikDuzenleGirdi
                            text: anaPencere.aktifSohbetBaslik
                            color: "#38bdf8"
                            font.bold: true
                            font.pixelSize: 12
                            font.family: "Segoe UI"
                            selectByMouse: true
                            onEditingFinished: {
                                anaPencere.aktifSohbetBaslik = text
                                sohbetGecmisModeli.setProperty(anaPencere.aktifSohbetIndex, "baslik", text)
                            }
                        }

                        Text {
                            text: "✏️ (Başlığı değiştirmek için tıklayın)"
                            color: Qt.rgba(1, 1, 1, 0.3)
                            font.pixelSize: 9
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    ScrollView {
                        id: chatScroll
                        width: parent.width
                        height: parent.height - 35
                        clip: true

                        ListView {
                            id: chatListView
                            width: parent.width
                            spacing: 10
                            model: ListModel {
                                id: chatModeli
                                ListElement { gonderen: "asistan"; mesaj: "Merhaba! Size nasıl yardımcı olabilirim?" }
                            }
                            delegate: Item {
                                width: chatListView.width
                                height: balon.height + 6

                                Rectangle {
                                    id: balon
                                    width: Math.min(mesajMetin.contentWidth + 24, parent.width * 0.75)
                                    height: mesajMetin.contentHeight + 16
                                    radius: 10
                                    anchors.right: model.gonderen === "kullanici" ? parent.right : undefined
                                    anchors.left: model.gonderen === "asistan" ? parent.left : undefined
                                    anchors.rightMargin: 12
                                    anchors.leftMargin: 4

                                    gradient: Gradient {
                                        GradientStop { 
                                            position: 0.0
                                            color: model.gonderen === "kullanici" ? "#0284c7" : Qt.rgba(0.15, 0.20, 0.28, 0.9) 
                                        }
                                        GradientStop { 
                                            position: 1.0
                                            color: model.gonderen === "kullanici" ? "#0369a1" : Qt.rgba(0.07, 0.10, 0.16, 0.95) 
                                        }
                                    }
                                    border.color: Qt.rgba(1, 1, 1, 0.25)

                                    TextEdit {
                                        id: mesajMetin
                                        text: model.mesaj
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        font.family: "Segoe UI"
                                        wrapMode: TextEdit.Wrap
                                        readOnly: true
                                        selectByMouse: true
                                        selectedTextColor: "#ffffff"
                                        selectionColor: "#0284c7"
                                        width: Math.min(implicitWidth, chatListView.width * 0.75 - 24)
                                        anchors.centerIn: parent

                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.RightButton
                                            cursorShape: Qt.IBeamCursor
                                            onClicked: {
                                                if (mesajMetin.selectedText.length > 0) {
                                                    kopyalaMenu.targetEdit = mesajMetin
                                                    kopyalaMenu.popup()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: girdiKonteyner
                width: parent.width
                height: Math.min(Math.max(48, girdiKutusu.contentHeight + 20), 120)
                radius: 10
                color: Qt.rgba(0.03, 0.05, 0.08, 0.92)
                border.color: girdiKutusu.activeFocus ? "#38bdf8" : Qt.rgba(1, 1, 1, 0.25)
                border.width: 1.2
                Behavior on height { NumberAnimation { duration: 80 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    ScrollView {
                        id: girdiKaydirici
                        width: parent.width - 145
                        height: parent.height
                        clip: true

                        TextArea {
                            id: girdiKutusu
                            width: parent.width
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.family: "Segoe UI"
                            wrapMode: TextArea.Wrap
                            verticalAlignment: TextArea.AlignVCenter
                            leftPadding: 8
                            rightPadding: 8
                            topPadding: 6
                            bottomPadding: 6
                            selectByMouse: true
                            focus: anaPencere.aktifSekme === "Sohbet"

                            Keys.onReturnPressed: (event) => {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    event.accepted = false
                                } else {
                                    gonderTetikle()
                                    event.accepted = true
                                }
                            }

                            Text {
                                text: "Aero asistana bir mesaj yazın... (Shift+Enter yeni satır)"
                                color: Qt.rgba(1, 1, 1, 0.4)
                                visible: !girdiKutusu.text && !girdiKutusu.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                            }
                        }
                    }

                    // STT MİKROFON BUTONU
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        anchors.verticalCenter: parent.verticalCenter
                        color: micHov.pressed ? "#ef4444" : (micHov.containsMouse ? "#0284c7" : Qt.rgba(1, 1, 1, 0.1))
                        border.color: "#38bdf8"
                        border.width: 1

                        Text { text: "🎙️"; font.pixelSize: 14; anchors.centerIn: parent }

                        MouseArea {
                            id: micHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: {
                                lcdDurumMetni.text = "DİNLENİYOR..."
                                anaPencere.konusuyorMu = false
                                asistan.basKonusBasla()
                            }
                            onReleased: {
                                lcdDurumMetni.text = "DÜŞÜNÜYOR..."
                                asistan.basKonusBitir()
                            }
                        }
                    }

                    // GÖNDER BUTONU
                    Rectangle {
                        width: 80
                        height: 36
                        radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: sendHov.containsMouse ? "#38bdf8" : "#0284c7" }
                            GradientStop { position: 1.0; color: "#0369a1" }
                        }
                        border.color: "#ffffff"

                        Text {
                            text: "Gönder ⏎"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 11
                            font.family: "Segoe UI"
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: sendHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: gonderTetikle()
                        }
                    }
                }
            }
        }

        // SAĞ: KOMPAKT SKEUMORFİK PLAK
        Column {
            width: parent.width * 0.28
            height: parent.height
            spacing: 12

            Rectangle {
                width: parent.width
                height: parent.height * 0.55
                radius: 14
                color: Qt.rgba(0.04, 0.06, 0.09, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                border.width: 1.2
                clip: true

                Item {
                    width: 380
                    height: 380
                    anchors.centerIn: parent
                    scale: 0.58

                    Item {
                        anchors.fill: parent

                        Rectangle {
                            width: 366
                            height: 146
                            radius: 73
                            anchors.centerIn: parent
                            rotation: 45
                            gradient: Gradient {
                                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.55) }
                                GradientStop { position: 0.20; color: Qt.rgba(1, 1, 1, 0.15) }
                                GradientStop { position: 0.80; color: Qt.rgba(0, 0, 0, 0.35) }
                                GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.30) }
                            }
                            border.color: Qt.rgba(1, 1, 1, 0.80)
                            border.width: 1.8
                        }

                        Rectangle {
                            width: 366
                            height: 146
                            radius: 73
                            anchors.centerIn: parent
                            rotation: -45
                            gradient: Gradient {
                                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.55) }
                                GradientStop { position: 0.20; color: Qt.rgba(1, 1, 1, 0.15) }
                                GradientStop { position: 0.80; color: Qt.rgba(0, 0, 0, 0.35) }
                                GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.30) }
                            }
                            border.color: Qt.rgba(1, 1, 1, 0.80)
                            border.width: 1.8
                        }
                    }

                    Rectangle {
                        width: 346
                        height: 346
                        radius: 173
                        anchors.centerIn: parent
                        gradient: Gradient {
                            GradientStop { position: 0.00; color: "#ffffff" }
                            GradientStop { position: 0.20; color: "#64748b" }
                            GradientStop { position: 0.45; color: "#cbd5e1" }
                            GradientStop { position: 0.70; color: "#1e293b" }
                            GradientStop { position: 0.90; color: "#94a3b8" }
                            GradientStop { position: 1.00; color: "#ffffff" }
                        }
                        border.color: Qt.rgba(1, 1, 1, 0.95)
                        border.width: 2.5

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: width / 2
                            color: "transparent"
                            border.color: Qt.rgba(0, 0, 0, 0.75)
                            border.width: 2
                        }
                    }

                    Rectangle {
                        id: vinilGovdeKucuk
                        width: 322
                        height: 322
                        radius: 161
                        anchors.centerIn: parent
                        color: "#050608"
                        border.color: "#181a1f"
                        border.width: 1.2

                        Repeater {
                            model: 10
                            Rectangle {
                                width: 312 - (index * 11)
                                height: width
                                radius: width / 2
                                anchors.centerIn: parent
                                color: "transparent"
                                border.color: (index % 2 === 0) ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.95)
                                border.width: 1.2
                            }
                        }

                        Item {
                            anchors.fill: parent

                            RotationAnimation on rotation {
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1600
                                running: anaPencere.konusuyorMu
                            }

                            Rectangle {
                                width: parent.width
                                height: parent.height
                                radius: width / 2
                                rotation: 25
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.00; color: Qt.rgba(0.0, 0.0, 0.0, 0.95) }
                                    GradientStop { position: 0.25; color: Qt.rgba(0.2, 0.22, 0.26, 0.40) }
                                    GradientStop { position: 0.42; color: Qt.rgba(0.75, 0.80, 0.88, 0.35) }
                                    GradientStop { position: 0.50; color: Qt.rgba(1.0, 1.0, 1.0, 0.75) }
                                    GradientStop { position: 0.58; color: Qt.rgba(0.75, 0.80, 0.88, 0.35) }
                                    GradientStop { position: 0.75; color: Qt.rgba(0.2, 0.22, 0.26, 0.40) }
                                    GradientStop { position: 1.00; color: Qt.rgba(0.0, 0.0, 0.0, 0.95) }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: parent.height
                                radius: width / 2
                                rotation: -65
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.00; color: Qt.rgba(0.0, 0.0, 0.0, 0.85) }
                                    GradientStop { position: 0.35; color: Qt.rgba(0.15, 0.17, 0.20, 0.25) }
                                    GradientStop { position: 0.50; color: Qt.rgba(0.9, 0.95, 1.0, 0.50) }
                                    GradientStop { position: 0.65; color: Qt.rgba(0.15, 0.17, 0.20, 0.25) }
                                    GradientStop { position: 1.00; color: Qt.rgba(0.0, 0.0, 0.0, 0.85) }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 18
                                radius: 9
                                anchors.centerIn: parent
                                rotation: 25
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.00; color: "transparent" }
                                    GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.85) }
                                    GradientStop { position: 1.00; color: "transparent" }
                                }
                            }
                        }

                        Item {
                            width: 206
                            height: 206
                            anchors.centerIn: parent

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                gradient: Gradient {
                                    GradientStop { position: 0.00; color: "#ff2a2a" }
                                    GradientStop { position: 0.18; color: "#ffcc00" }
                                    GradientStop { position: 0.38; color: "#00e676" }
                                    GradientStop { position: 0.62; color: "#00d4ff" }
                                    GradientStop { position: 0.80; color: "#2979ff" }
                                    GradientStop { position: 0.92; color: "#e0e7ff" }
                                    GradientStop { position: 1.00; color: "#ff2a2a" }
                                }
                                RotationAnimation on rotation {
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: 8000
                                    running: anaPencere.konusuyorMu
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 48
                                radius: 14
                                anchors.centerIn: parent
                                rotation: 45
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.90) }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 48
                                radius: 14
                                anchors.centerIn: parent
                                rotation: -45
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.90) }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }
                        }

                        Rectangle {
                            width: 90
                            height: 90
                            radius: 45
                            anchors.centerIn: parent
                            color: Qt.rgba(0.15, 0.25, 0.35, 0.50)
                            border.color: Qt.rgba(1, 1, 1, 0.85)
                            border.width: 2.2
                        }

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 22
                            anchors.centerIn: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#ffffff" }
                                GradientStop { position: 0.5; color: "#64748b" }
                                GradientStop { position: 1.0; color: "#090d16" }
                            }
                            border.color: "#ffffff"
                            border.width: 2
                        }
                    }

                    Item {
                        width: 322
                        height: 161
                        anchors.top: parent.top
                        anchors.topMargin: 29
                        anchors.horizontalCenter: parent.horizontalCenter
                        clip: true

                        Rectangle {
                            width: 322
                            height: 322
                            radius: 161
                            anchors.top: parent.top
                            gradient: Gradient {
                                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.70) }
                                GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.25) }
                                GradientStop { position: 0.60; color: "transparent" }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height * 0.43
                radius: 14
                color: Qt.rgba(0.04, 0.06, 0.09, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                border.width: 1.2
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "VOICE SPECTRUM"
                        color: "#38bdf8"
                        font.bold: true
                        font.pixelSize: 11
                        font.letterSpacing: 1.2
                    }

                    Item {
                        width: parent.width
                        height: parent.height - 30

                        Row {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            Repeater {
                                model: sutunModeli
                                Rectangle {
                                    width: 16
                                    height: Math.min(model.yukseklik * 0.9, 95)
                                    radius: 3
                                    anchors.bottom: parent.bottom
                                    gradient: Gradient {
                                        GradientStop { 
                                            position: 0.0
                                            color: anaPencere.temaModu === 1 ? Qt.rgba(0.1, 0.1, 0.15, 0.85) : "#ffffff" 
                                        }
                                        GradientStop { 
                                            position: 1.0
                                            color: anaPencere.temaModu === 0 ? "#00c6ff" : Qt.rgba(0.2, 0.4, 0.6, 0.4) 
                                        }
                                    }
                                    border.color: Qt.rgba(1, 1, 1, 0.4)
                                    Behavior on height { NumberAnimation { duration: 70 } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================================
    // 6. GÖRÜNÜM C: "TERMINAL (ALPHA)" EKRANI
    // ==========================================================
    Row {
        id: terminalGörünümC
        visible: anaPencere.aktifSekme === "Terminal"
        anchors.top: sekmeCubugu.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 16

        // SOL ALAN: BÜYÜK ANA TERMİNAL KONSOLU
        Rectangle {
            width: parent.width * 0.68
            height: parent.height
            radius: 14
            color: Qt.rgba(0.02, 0.03, 0.05, 0.92)
            border.color: Qt.rgba(1, 1, 1, 0.25)
            border.width: 1.2
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Row {
                    spacing: 8
                    Text { text: "⬛"; color: "#22c55e"; font.pixelSize: 10 }
                    Text {
                        text: "TERMINAL CONSOLE (ALPHA) • /bin/bash"
                        color: "#22c55e"
                        font.bold: true
                        font.pixelSize: 11
                        font.family: "Consolas, Monospace"
                        font.letterSpacing: 1.2
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.15)
                }

                ScrollView {
                    id: termScroll
                    width: parent.width
                    height: parent.height - 75
                    clip: true

                    TextArea {
                        id: terminalCikti
                        width: parent.width
                        color: "#86efac"
                        font.pixelSize: 11
                        font.family: "Consolas, Monospace"
                        wrapMode: TextArea.Wrap
                        readOnly: true
                        selectByMouse: true
                        text: "Arch Linux Aero Terminal Emülatörü [Alpha Sürüm]\nKomut yazmak için aşağıdaki satırı kullanabilirsiniz.\n\nalp@arch:~$ "
                    }
                }

                // Komut Yazma Satırı
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.6)
                    border.color: termGirdi.activeFocus ? "#22c55e" : Qt.rgba(1, 1, 1, 0.2)

                    Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 6

                        Text {
                            text: "❯"
                            color: "#22c55e"
                            font.bold: true
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: termGirdi
                            width: parent.width - 30
                            height: parent.height
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.family: "Consolas, Monospace"
                            verticalAlignment: TextInput.AlignVCenter
                            focus: anaPencere.aktifSekme === "Terminal"

                            onAccepted: {
                                if (text.trim() !== "") {
                                    terminalCikti.text += "\n" + text + "\n[Komut simüle edildi: " + text + "]\nalp@arch:~$ "
                                    text = ""
                                }
                            }
                        }
                    }
                }
            }
        }

        // SAĞ ALAN: YAPAY ZEKA SOHBET KUTUSU (ÜST) & OTOMASYON LİSTESİ (ALT)
        Column {
            width: parent.width * 0.30
            height: parent.height
            spacing: 12

            // 1. SAĞ ÜST: YAPAY ZEKA SOHBET KUTUSU
            Rectangle {
                width: parent.width
                height: parent.height * 0.48
                radius: 14
                color: Qt.rgba(0.04, 0.06, 0.09, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                border.width: 1.2
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "AI KOD & KOMUT ASİSTANI"
                        color: "#38bdf8"
                        font.bold: true
                        font.pixelSize: 11
                        font.letterSpacing: 1.0
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height - 75
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.4)
                        clip: true

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true

                            Text {
                                id: miniAiLog
                                width: parent.width
                                text: "Asistan: Terminal için komut veya otomasyon betiği yazmamı ister misiniz?"
                                color: "#cbd5e1"
                                font.pixelSize: 11
                                font.family: "Segoe UI"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 6
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.color: miniAiGirdi.activeFocus ? "#38bdf8" : Qt.rgba(1, 1, 1, 0.2)

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4

                            TextInput {
                                id: miniAiGirdi
                                width: parent.width - 50
                                height: parent.height
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.family: "Segoe UI"
                                verticalAlignment: TextInput.AlignVCenter
                                leftPadding: 4

                                onAccepted: {
                                    if (text.trim() !== "") {
                                        miniAiLog.text += "\n\nSiz: " + text + "\nAsistan: Bu komut hazırlandı."
                                        text = ""
                                    }
                                }

                                Text {
                                    text: "Asistana sor..."
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                    visible: !miniAiGirdi.text && !miniAiGirdi.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                }
                            }

                            Rectangle {
                                width: 44
                                height: 24
                                radius: 4
                                color: "#0284c7"
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Sor"; color: "#ffffff"; font.pixelSize: 10; font.bold: true; anchors.centerIn: parent }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (miniAiGirdi.text.trim() !== "") {
                                            miniAiLog.text += "\n\nSiz: " + miniAiGirdi.text + "\nAsistan: Bu komut hazırlandı."
                                            miniAiGirdi.text = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 2. SAĞ ALT: OTOMASYON EKLE BUTONU VE OTOMASYON LİSTESİ
            Rectangle {
                width: parent.width
                height: parent.height * 0.49
                radius: 14
                color: Qt.rgba(0.04, 0.06, 0.09, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.25)
                border.width: 1.2
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 6
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: otoHov.containsMouse ? "#38bdf8" : "#0284c7" }
                            GradientStop { position: 1.0; color: "#0369a1" }
                        }
                        border.color: "#ffffff"

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "➕"; font.pixelSize: 10 }
                            Text {
                                text: "Yeni Otomasyon Oluştur"
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 11
                                font.family: "Segoe UI"
                            }
                        }

                        MouseArea {
                            id: otoHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: console.log("[Aero]: Yeni Otomasyon penceresi açılıyor...")
                        }
                    }

                    Text {
                        text: "KAYITLI OTOMASYONLAR"
                        color: "#94a3b8"
                        font.bold: true
                        font.pixelSize: 10
                        font.letterSpacing: 1.0
                    }

                    ScrollView {
                        width: parent.width
                        height: parent.height - 85
                        clip: true

                        Column {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: [
                                    { baslik: "Reflector Mirror Güncelle", komut: "sudo reflector --latest 15 --sort rate", ikon: "⚡" },
                                    { baslik: "Sistem Paketlerini Yenile", komut: "sudo pacman -Syu", ikon: "🔄" },
                                    { baslik: "Önbellek & Çöp Temizliği", komut: "yay -Sc --noconfirm", ikon: "🧹" }
                                ]

                                Rectangle {
                                    width: parent.width - 6
                                    height: 38
                                    radius: 6
                                    color: otoItemHov.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                                    border.color: Qt.rgba(1, 1, 1, 0.2)

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 8

                                        Text {
                                            text: modelData.ikon
                                            font.pixelSize: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2
                                            Text {
                                                text: modelData.baslik
                                                color: "#ffffff"
                                                font.bold: true
                                                font.pixelSize: 10
                                                font.family: "Segoe UI"
                                            }
                                            Text {
                                                text: modelData.komut
                                                color: "#94a3b8"
                                                font.pixelSize: 9
                                                font.family: "Consolas"
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: otoItemHov
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            terminalCikti.text += "\n" + modelData.komut + "\n[Otomasyon Tetiklendi: " + modelData.baslik + "]\nalp@arch:~$ "
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================================
    // 7. ŞIK VE KOMPAKT SAĞ TIK MENÜLERİ (AERO STİLİ)
    // ==========================================================
    Menu {
        id: kopyalaMenu
        property var targetEdit: null

        background: Rectangle {
            implicitWidth: 120
            implicitHeight: 32
            color: Qt.rgba(0.08, 0.12, 0.18, 0.95)
            border.color: Qt.rgba(1, 1, 1, 0.25)
            radius: 6
        }

        MenuItem {
            text: "📋 Kopyala"
            font.pixelSize: 11
            font.family: "Segoe UI"
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                font: parent.font
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 6
            }
            background: Rectangle {
                color: parent.highlighted ? "#0284c7" : "transparent"
                radius: 4
            }
            onTriggered: {
                if (kopyalaMenu.targetEdit) {
                    kopyalaMenu.targetEdit.copy()
                }
            }
        }
    }

    Menu {
        id: girdiMenu

        background: Rectangle {
            implicitWidth: 130
            implicitHeight: 70
            color: Qt.rgba(0.08, 0.12, 0.18, 0.95)
            border.color: Qt.rgba(1, 1, 1, 0.25)
            radius: 6
        }

        MenuItem {
            text: "📋 Yapıştır"
            font.pixelSize: 11
            font.family: "Segoe UI"
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                font: parent.font
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 6
            }
            background: Rectangle {
                color: parent.highlighted ? "#0284c7" : "transparent"
                radius: 4
            }
            onTriggered: girdiKutusu.paste()
        }

        MenuItem {
            text: "✂️ Hepsini Seç"
            font.pixelSize: 11
            font.family: "Segoe UI"
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                font: parent.font
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 6
            }
            background: Rectangle {
                color: parent.highlighted ? "#0284c7" : "transparent"
                radius: 4
            }
            onTriggered: girdiKutusu.selectAll()
        }
    }

    // ==========================================
    // 8. FONKSİYONLAR VE SİNYAL BAĞLANTILARI
    // ==========================================
    function gonderTetikle() {
        if (girdiKutusu.text.trim() !== "") {
            var metin = girdiKutusu.text.trim()
            girdiKutusu.text = ""
            anaPencere.konusuyorMu = true
            
            chatModeli.append({ "gonderen": "kullanici", "mesaj": metin })
            sohbeteMesajKaydet(anaPencere.aktifSohbetBaslik, "kullanici", metin)
            chatListView.positionViewAtEnd()
            
            asistan.mesajGonder(metin)
        }
    }

    Connections {
        target: asistan

        function onYeniMesajEkle(rol, metin) {
            var gonderenRol = (rol === "user" || rol === "kullanici") ? "kullanici" : "asistan"
            chatModeli.append({ "gonderen": gonderenRol, "mesaj": metin })
            sohbeteMesajKaydet(anaPencere.aktifSohbetBaslik, gonderenRol, metin)
            chatListView.positionViewAtEnd()
        }

        function onMesajGuncelle(metin) {
            if (chatModeli.count > 0) {
                chatModeli.setProperty(chatModeli.count - 1, "mesaj", metin)
                var aktifDizi = tumSohbetlerHafizasi[anaPencere.aktifSohbetBaslik]
                if (aktifDizi && aktifDizi.length > 0) {
                    aktifDizi[aktifDizi.length - 1].mesaj = metin
                }
                chatListView.positionViewAtEnd()
            }
        }


        function onDurumDegisti(durum) {
            if (durum === "dinliyor") {
                lcdDurumMetni.text = "DİNLENİYOR..."
                anaPencere.konusuyorMu = false
            } else if (durum === "dusunuyor") {
                lcdDurumMetni.text = "DÜŞÜNÜYOR..."
                anaPencere.konusuyorMu = true
            } else if (durum === "hazir") {
                lcdDurumMetni.text = "AERO MEDIA CORE • SİNYAL ALINIYOR"
                anaPencere.konusuyorMu = false
            }
        }
    }

    // 1. AYARLAR MENÜSÜ (FRENCH HORN)
    Menu {
        id: ayarlarMenusu

        background: Rectangle {
            implicitWidth: 220
            color: Qt.rgba(0.08, 0.12, 0.18, 0.98)
            border.color: "#38bdf8"
            radius: 8
        }

        MenuItem { text: "🤖 LLM: hizli-asistan (Ollama)"; font.pixelSize: 10; font.family: "Segoe UI" }
        MenuItem { text: "🎙️ STT: Whisper Large v3"; font.pixelSize: 10; font.family: "Segoe UI" }
        MenuItem { text: "🔊 TTS Hızı: 1.05x"; font.pixelSize: 10; font.family: "Segoe UI" }
        MenuSeparator {}
        MenuItem { text: "⚙️ Gelişmiş Parametreler..."; font.pixelSize: 10; font.family: "Segoe UI" }
        MenuItem { text: "ℹ️ Aero AI Suite Hakkında"; font.pixelSize: 10; font.family: "Segoe UI" }
    }

    // 2. HATIRLATICI EKLEME DİYALOĞU
    Dialog {
        id: hatirlaticiEkleModal
        anchors.centerIn: parent
        width: 320
        height: 260
        modal: true
        title: "Yeni Etkinlik / Hatırlatıcı Ekle"

        background: Rectangle {
            color: Qt.rgba(0.06, 0.09, 0.14, 0.95)
            border.color: "#38bdf8"
            border.width: 1.5
            radius: 12
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text { text: "Etkinlik Başlığı:"; color: "#ffffff"; font.pixelSize: 11; font.family: "Segoe UI" }
            Rectangle {
                width: parent.width; height: 30; radius: 4; color: Qt.rgba(0,0,0,0.5); border.color: Qt.rgba(1,1,1,0.3)
                TextInput { id: modalBaslikGirdi; anchors.fill: parent; anchors.margins: 6; color: "#ffffff"; font.pixelSize: 11 }
            }

            Text { text: "Tarih (GG.AA.YYYY):"; color: "#ffffff"; font.pixelSize: 11; font.family: "Segoe UI" }
            Rectangle {
                width: parent.width; height: 30; radius: 4; color: Qt.rgba(0,0,0,0.5); border.color: Qt.rgba(1,1,1,0.3)
                TextInput { id: modalTarihGirdi; text: Qt.formatDate(new Date(), "dd.MM.yyyy"); anchors.fill: parent; anchors.margins: 6; color: "#ffffff"; font.pixelSize: 11 }
            }

            Text { text: "Saat (İsteğe Bağlı):"; color: "#ffffff"; font.pixelSize: 11; font.family: "Segoe UI" }
            Rectangle {
                width: parent.width; height: 30; radius: 4; color: Qt.rgba(0,0,0,0.5); border.color: Qt.rgba(1,1,1,0.3)
                TextInput { id: modalSaatGirdi; text: "12:00"; anchors.fill: parent; anchors.margins: 6; color: "#ffffff"; font.pixelSize: 11 }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                Rectangle {
                    width: 90; height: 28; radius: 4; color: "#0284c7"
                    Text { text: "Kaydet"; color: "#ffffff"; font.bold: true; font.pixelSize: 11; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modalBaslikGirdi.text.trim() !== "") {
                                hatirlaticiModeli.append({
                                    "baslik": modalBaslikGirdi.text.trim(),
                                    "tarih": modalTarihGirdi.text.trim(),
                                    "saat": modalSaatGirdi.text.trim()
                                })
                                modalBaslikGirdi.text = ""
                                hatirlaticiEkleModal.close()
                            }
                        }
                    }
                }

                Rectangle {
                    width: 90; height: 28; radius: 4; color: "#334155"
                    Text { text: "İptal"; color: "#ffffff"; font.pixelSize: 11; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; onClicked: hatirlaticiEkleModal.close() }
                }
            }
        }
    }
}