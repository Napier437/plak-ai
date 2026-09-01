import QtQuick 2.15
import QtQuick.Controls 2.15

Window {
    id: miniPencere
    visible: true
    width: 200
    height: 240
    title: "WMP 11 AI Mini Orb"
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.SubWindow

    property bool konusuyorMu: false

    // Masaüstünde Serbestçe Sürükleme
    MouseArea {
        id: suruklemeAlani
        anchors.fill: parent
        property point baslangicNoktasi: Qt.point(0, 0)
        cursorShape: Qt.SizeAllCursor

        onPressed: function(mouse) {
            baslangicNoktasi = Qt.point(mouse.x, mouse.y)
        }
        onPositionChanged: function(mouse) {
            if (pressed) {
                var deltaX = mouse.x - baslangicNoktasi.x
                var deltaY = mouse.y - baslangicNoktasi.y
                miniPencere.x += deltaX
                miniPencere.y += deltaY
            }
        }
    }

    // ==========================================================
    // 1. SAĞ ÜST AERO BÜYÜTME (ANA EKRANA DÖNÜŞ) BUTONU
    // ==========================================================
    Rectangle {
        width: 20
        height: 20
        radius: 10
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        z: 100

        gradient: Gradient {
            GradientStop { position: 0.0; color: btnHov.containsMouse ? "#38bdf8" : Qt.rgba(0.25, 0.3, 0.4, 0.85) }
            GradientStop { position: 1.0; color: Qt.rgba(0.05, 0.08, 0.12, 0.95) }
        }
        border.color: Qt.rgba(1, 1, 1, 0.8)
        border.width: 1

        Text {
            text: "⤢"
            color: "#ffffff"
            font.bold: true
            font.pixelSize: 11
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
        }

        MouseArea {
            id: btnHov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                miniPencere.close()
                if (typeof anaPencere !== "undefined") {
                    anaPencere.show()
                }
            }
        }
    }

    // ==========================================================
    // 2. KOMPAKT SKEUMORFİK CAM PLAK (ÜST / MERKEZ)
    // ==========================================================
    Item {
        id: merkezMiniPlak
        width: 380
        height: 380
        anchors.top: parent.top
        anchors.topMargin: -35
        anchors.horizontalCenter: parent.horizontalCenter
        scale: 0.44
        z: 1

        // Dış Akrilik Cam Kanatlar
        Item {
            anchors.fill: parent

            Rectangle {
                width: 366; height: 146; radius: 73
                anchors.centerIn: parent; rotation: 45
                gradient: Gradient {
                    GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.55) }
                    GradientStop { position: 0.20; color: Qt.rgba(1, 1, 1, 0.15) }
                    GradientStop { position: 0.80; color: Qt.rgba(0, 0, 0, 0.35) }
                    GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.30) }
                }
                border.color: Qt.rgba(1, 1, 1, 0.80); border.width: 1.8
            }

            Rectangle {
                width: 366; height: 146; radius: 73
                anchors.centerIn: parent; rotation: -45
                gradient: Gradient {
                    GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.55) }
                    GradientStop { position: 0.20; color: Qt.rgba(1, 1, 1, 0.15) }
                    GradientStop { position: 0.80; color: Qt.rgba(0, 0, 0, 0.35) }
                    GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.30) }
                }
                border.color: Qt.rgba(1, 1, 1, 0.80); border.width: 1.8
            }
        }

        // Dış Krom Çerçeve
        Rectangle {
            width: 346; height: 346; radius: 173; anchors.centerIn: parent
            gradient: Gradient {
                GradientStop { position: 0.00; color: "#ffffff" }
                GradientStop { position: 0.20; color: "#64748b" }
                GradientStop { position: 0.45; color: "#cbd5e1" }
                GradientStop { position: 0.70; color: "#1e293b" }
                GradientStop { position: 0.90; color: "#94a3b8" }
                GradientStop { position: 1.00; color: "#ffffff" }
            }
            border.color: Qt.rgba(1, 1, 1, 0.95); border.width: 2.5

            Rectangle {
                anchors.fill: parent; anchors.margins: 3; radius: width / 2
                color: "transparent"; border.color: Qt.rgba(0, 0, 0, 0.75); border.width: 2
            }
        }

        // Siyah Vinil Gövde
        Rectangle {
            id: vinilGovde
            width: 322; height: 322; radius: 161; anchors.centerIn: parent
            color: "#050608"; border.color: "#181a1f"; border.width: 1.2

            Repeater {
                model: 10
                Rectangle {
                    width: 312 - (index * 11); height: width; radius: width / 2; anchors.centerIn: parent
                    color: "transparent"
                    border.color: (index % 2 === 0) ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.95)
                    border.width: 1.2
                }
            }

            // Siyah-Beyaz Yelpaze Dönüş Motoru
            Item {
                anchors.fill: parent

                RotationAnimation on rotation {
                    loops: Animation.Infinite; from: 0; to: 360; duration: 1600
                    running: miniPencere.konusuyorMu
                }

                Rectangle {
                    width: parent.width; height: parent.height; radius: width / 2; rotation: 25
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
                    width: parent.width; height: parent.height; radius: width / 2; rotation: -65
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
                    width: parent.width; height: 18; radius: 9; anchors.centerIn: parent; rotation: 25
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: "transparent" }
                        GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.85) }
                        GradientStop { position: 1.00; color: "transparent" }
                    }
                }
            }

            // Dönen CD Katmanı
            Item {
                width: 206; height: 206; anchors.centerIn: parent

                Rectangle {
                    anchors.fill: parent; radius: width / 2
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
                        loops: Animation.Infinite; from: 0; to: 360; duration: 8000
                        running: miniPencere.konusuyorMu
                    }
                }

                Rectangle {
                    width: parent.width; height: 48; radius: 14; anchors.centerIn: parent; rotation: 45
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.90) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Rectangle {
                    width: parent.width; height: 48; radius: 14; anchors.centerIn: parent; rotation: -45
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.90) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }

            // Şeffaf İç Polikarbon Halka
            Rectangle {
                width: 90; height: 90; radius: 45; anchors.centerIn: parent
                color: Qt.rgba(0.15, 0.25, 0.35, 0.50); border.color: Qt.rgba(1, 1, 1, 0.85); border.width: 2.2
            }

            // Merkez Mil Butonu
            Rectangle {
                width: 44; height: 44; radius: 22; anchors.centerIn: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: milHov.containsMouse ? "#ffffff" : "#f1f5f9" }
                    GradientStop { position: 0.5; color: milHov.containsMouse ? "#64748b" : "#334155" }
                    GradientStop { position: 1.0; color: "#090d16" }
                }
                border.color: "#ffffff"; border.width: 2

                MouseArea {
                    id: milHov
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: asistan.asistanlaEtkilesim()
                }
            }
        }

        // Vista Cam Kubbe Parlaması
        Item {
            width: 322; height: 161; anchors.top: parent.top; anchors.topMargin: 29; anchors.horizontalCenter: parent.horizontalCenter
            clip: true

            Rectangle {
                width: 322; height: 322; radius: 161; anchors.top: parent.top
                gradient: Gradient {
                    GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.70) }
                    GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.25) }
                    GradientStop { position: 0.60; color: "transparent" }
                }
            }
        }
    }

    // ==========================================================
    // 3. RETRO ŞASİ & GERÇEK 2000'LER DOT-MATRIX LCD EKRAN
    // ==========================================================
    Item {
        width: 170
        height: 90
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        z: 10

        // Plağın Alt Yarısına Binen Şeffaf Akrilik Koruma Kapağı
        Rectangle {
            width: parent.width - 12
            height: 42
            radius: 8
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.35) }
                GradientStop { position: 0.40; color: Qt.rgba(1, 1, 1, 0.08) }
                GradientStop { position: 1.00; color: Qt.rgba(0, 0, 0, 0.20) }
            }
            border.color: Qt.rgba(1, 1, 1, 0.6)
            border.width: 1.2
        }

        // Fırçalanmış Gri Alt Şasi Gövdesi
        Rectangle {
            width: parent.width
            height: 52
            radius: 6
            anchors.bottom: parent.bottom
            gradient: Gradient {
                GradientStop { position: 0.00; color: "#cbd5e1" }
                GradientStop { position: 0.15; color: "#64748b" }
                GradientStop { position: 0.65; color: "#334155" }
                GradientStop { position: 1.00; color: "#0f172a" }
            }
            border.color: Qt.rgba(1, 1, 1, 0.75)
            border.width: 1.5

            // Vida Detayları
            Rectangle { width: 4; height: 4; radius: 2; color: "#090d16"; border.color: "#94a3b8"; anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 3 }
            Rectangle { width: 4; height: 4; radius: 2; color: "#090d16"; border.color: "#94a3b8"; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 3 }

            // ==========================================================
            // OTOMAT & 2000'LER MP3 ÇALAR ZEYTİN YEŞİLİ DOT-MATRIX LCD
            // ==========================================================
            Rectangle {
                width: parent.width - 16
                height: 32
                radius: 3
                anchors.centerIn: parent
                color: "#1a2e05" // Koyu zeytin yeşili pasif LCD kristal tabanı
                border.color: Qt.rgba(0, 0, 0, 0.9)
                border.width: 1.5
                clip: true

                // Yeşil Arka Aydınlatma Işığı (Backlight Glow)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0.65, 0.95, 0.15, 0.35) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.40, 0.70, 0.05, 0.20) }
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 6

                    // SOL: 5 KANAL SEGMENTLİ PİKSEL SPEKTRUMU
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Repeater {
                            model: 5
                            Column {
                                spacing: 1
                                anchors.bottom: parent.bottom
                                
                                property int seviye: miniPencere.konusuyorMu ? Math.floor(Math.random() * 6) + 1 : (index % 2 === 0 ? 2 : 1)

                                Repeater {
                                    model: 6
                                    Rectangle {
                                        width: 6
                                        height: 3
                                        radius: 0.5
                                        color: (5 - index) < parent.parent.seviye ? "#0d1a02" : Qt.rgba(0.2, 0.35, 0.05, 0.25)
                                    }
                                }
                            }
                        }
                    }

                    // ORTA: İNCE PİKSEL AYIRICI ÇİZGİ
                    Rectangle {
                        width: 1
                        height: parent.height - 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(0.2, 0.35, 0.05, 0.4)
                    }

                    // SAĞ: MONOKROM BİLGİ & DURUM METNİ (KBPS / STAT)
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Row {
                            spacing: 4
                            Text {
                                text: "128k"
                                color: "#0d1a02"
                                font.family: "Consolas, Monospace"
                                font.pixelSize: 8
                                font.bold: true
                            }
                            Text {
                                text: "MP3"
                                color: "#0d1a02"
                                font.family: "Consolas, Monospace"
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }

                        Text {
                            text: miniPencere.konusuyorMu ? "PLAY ▶ 44k" : "READY ■ 00"
                            color: "#0d1a02"
                            font.family: "Consolas, Monospace"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                // LCD Camı Üzeri Polarize Parlama Çizgisi
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.25) }
                        GradientStop { position: 0.4; color: "transparent" }
                    }
                }
            }
        }
    }

    // ==========================================
    // 4. PYTHON SİNYAL BAĞLANTILARI
    // ==========================================
    Connections {
        target: asistan
        function onCevapGeldi(cevap) {
            miniPencere.konusuyorMu = true
            aiMiniTimer.restart()
        }
        function onDurumDegisti(durum) {
            if (durum === "dinliyor") {
                miniPencere.konusuyorMu = false
            }
        }
    }

    Timer {
        id: aiMiniTimer
        interval: 7000
        onTriggered: miniPencere.konusuyorMu = false
    }
}