import Foundation

struct AppLanguage: Identifiable, Hashable {
    let code: String
    let flag: String
    let name: String

    var id: String { code }
}

enum LanguagePack {
    static let storageKey = "appLanguageCode"

    static let supportedLanguages: [AppLanguage] = [
        AppLanguage(code: "en", flag: "🇺🇸", name: "English"),
        AppLanguage(code: "de", flag: "🇩🇪", name: "Deutsch"),
        AppLanguage(code: "es", flag: "🇪🇸", name: "Español"),
        AppLanguage(code: "fr", flag: "🇫🇷", name: "Français"),
        AppLanguage(code: "it", flag: "🇮🇹", name: "Italiano"),
        AppLanguage(code: "pl", flag: "🇵🇱", name: "Polski"),
        AppLanguage(code: "cs", flag: "🇨🇿", name: "Čeština"),
        AppLanguage(code: "ro", flag: "🇷🇴", name: "Română"),
        AppLanguage(code: "lt", flag: "🇱🇹", name: "Lietuvių"),
        AppLanguage(code: "lv", flag: "🇱🇻", name: "Latviešu"),
        AppLanguage(code: "et", flag: "🇪🇪", name: "Eesti"),
        AppLanguage(code: "sv", flag: "🇸🇪", name: "Svenska"),
        AppLanguage(code: "fi", flag: "🇫🇮", name: "Suomi"),
        AppLanguage(code: "uk", flag: "🇺🇦", name: "Українська"),
        AppLanguage(code: "el", flag: "🇬🇷", name: "Ελληνικά"),
        AppLanguage(code: "be", flag: "🇧🇾", name: "Беларуская")
    ]

    static func text(_ key: String, languageCode: String) -> String {
        guard languageCode != "en" else { return key }
        return translations[languageCode]?[key] ?? key
    }

    static func modeTitle(_ mode: AudioDirectionManager.DetectionMode, languageCode: String) -> String {
        text(mode.title, languageCode: languageCode)
    }

    static func alertStyleTitle(_ style: AudioDirectionManager.AlertStyle, languageCode: String) -> String {
        text(style.title, languageCode: languageCode)
    }

    static func category(_ category: String, languageCode: String) -> String {
        text(category, languageCode: languageCode)
    }

    static func headingLabel(_ heading: String, languageCode: String) -> String {
        text(heading, languageCode: languageCode)
    }

    static func soundStatus(_ status: String, languageCode: String) -> String {
        let prefix = "Sound type: "
        guard status.hasPrefix(prefix) else {
            return text(status, languageCode: languageCode)
        }

        let value = String(status.dropFirst(prefix.count))
        let translatedPrefix = text("Sound type", languageCode: languageCode)
        if let separatorRange = value.range(of: " - ") {
            let categoryValue = String(value[..<separatorRange.lowerBound])
            let rest = String(value[separatorRange.upperBound...])
            return "\(translatedPrefix): \(category(categoryValue, languageCode: languageCode)) - \(rest)"
        }
        return "\(translatedPrefix): \(text(value, languageCode: languageCode))"
    }

    private static let translations: [String: [String: String]] = [
        "de": [
            "Turn slowly 360° while scanning.": "Drehe dich beim Scannen langsam um 360°.",
            "Keep the iPhone still and let it listen.": "Halte das iPhone ruhig und lasse es zuhören.",
            "Mode": "Modus", "Scan 360": "360°-Scan", "Listen": "Zuhören",
            "Loudest sound at": "Lautestes Geräusch bei", "Quality": "Qualität", "Sound type": "Geräuschtyp",
            "Top sounds": "Häufigste Geräusche", "Raw": "Roh", "Smoothed": "Geglättet", "Top headings": "Beste Richtungen",
            "Threshold Alerts": "Schwellenalarme", "On": "Ein", "Off": "Aus", "Directions by Sound Type": "Richtungen nach Geräuschtyp",
            "No categorized direction yet.": "Noch keine kategorisierte Richtung.", "Readiness": "Bereitschaft",
            "Do not cover the bottom microphone.": "Das untere Mikrofon nicht abdecken.",
            "History": "Verlauf", "Settings": "Einstellungen", "Share": "Teilen", "Help": "Hilfe",
            "Stop & Analyze": "Stoppen & auswerten", "Stop Listening": "Zuhören stoppen", "Start Scan": "Scan starten", "Start Listening": "Zuhören starten",
            "Quick Help": "Kurzhilfe", "Tips": "Tipps", "Version": "Version", "Website": "Website", "Done": "Fertig",
            "No history yet": "Noch kein Verlauf", "Scan or listen to create local sound events.": "Scannen oder zuhören, um lokale Geräuschereignisse zu erstellen.",
            "Enable Alerts": "Alarme aktivieren", "Sound Type": "Geräuschtyp", "dB Threshold": "dB-Schwelle",
            "Confidence": "Konfidenz", "Alert Style": "Alarmstil", "Calibration": "Kalibrierung", "Manual Offset": "Manueller Versatz",
            "Reset Calibration": "Kalibrierung zurücksetzen", "Reports": "Berichte", "About": "Info", "Language": "Sprache",
            "None": "Keine", "Haptic": "Haptik", "Screen Flash": "Bildschirmblitz", "Sound": "Ton",
            "Any": "Alle", "Human voice": "Menschliche Stimme", "Animals": "Tiere", "Vehicles": "Fahrzeuge", "Mechanical": "Mechanisch", "Alarm": "Alarm", "Music": "Musik", "Nature": "Natur", "Household": "Haushalt", "Impact": "Aufprall", "Other": "Andere",
            "Ready": "Bereit", "Calibrating": "Kalibriert", "Listening": "Hört zu", "Good": "Gut", "Too fast": "Zu schnell", "Too noisy": "Zu laut", "Too quiet": "Zu leise", "Audio error": "Audiofehler",
            "Sound type: Ready": "Geräuschtyp: Bereit", "Sound type: Listening...": "Geräuschtyp: Hört zu...", "Sound type: Unavailable": "Geräuschtyp: Nicht verfügbar", "Unknown": "Unbekannt",
            "Compass unavailable on this device.": "Kompass ist auf diesem Gerät nicht verfügbar.", "Microphone permission is required.": "Mikrofonberechtigung ist erforderlich.", "Audio setup failed.": "Audioeinrichtung fehlgeschlagen.",
            "Enable microphone in Settings.": "Mikrofon in den Einstellungen aktivieren.", "Calibrating... stay still": "Kalibrierung... ruhig halten", "Audio input failed.": "Audioeingabe fehlgeschlagen.", "Listen stopped.": "Zuhören gestoppt.",
            "Scanning... turn slowly 360°": "Scannen... langsam 360° drehen", "Listening...": "Hört zu...", "Scanning... slow down": "Scannen... langsamer drehen", "Sound too quiet. Try again.": "Geräusch zu leise. Erneut versuchen.", "Scan complete.": "Scan abgeschlossen.", "Enable location access for compass.": "Standortzugriff für den Kompass aktivieren.",
            "Alerts ready": "Alarme bereit", "over": "über", "Microphone": "Mikrofon", "Allowed": "Erlaubt", "Permission needed": "Berechtigung nötig", "Compass": "Kompass", "Allow location for heading": "Standort für Richtung erlauben", "Rotation": "Drehung", "Slow enough": "Langsam genug", "Turn slower": "Langsamer drehen", "Noise floor": "Grundrauschen", "Usable": "Nutzbar", "Noisy environment": "Laute Umgebung",
            "Hold upright": "Aufrecht halten", "Keep the bottom microphone uncovered.": "Das untere Mikrofon frei lassen.", "Calibrate first": "Zuerst kalibrieren", "Stay still while the app learns the room noise.": "Ruhig bleiben, während die App das Raumgeräusch lernt.", "Turn slowly": "Langsam drehen", "Use Scan 360 for direction or Listen mode for ongoing sound events.": "Nutze 360°-Scan für Richtung oder Zuhören für laufende Ereignisse.", "Start": "Start",
            "1. Hold the phone upright.": "1. Halte das Telefon aufrecht.", "2. Tap Start Scan.": "2. Tippe auf Scan starten.", "3. Slowly rotate 360°.": "3. Drehe dich langsam um 360°.", "4. Tap Stop & Analyze.": "4. Tippe auf Stoppen & auswerten.", "5. The green arrow points to the loudest direction.": "5. Der grüne Pfeil zeigt zur lautesten Richtung.", "6. Sound type labels run offline on device.": "6. Geräuschtypen laufen offline auf dem Gerät.", "Use a real device for accurate compass readings.": "Nutze ein echtes Gerät für genaue Kompasswerte.", "Sound labels are best-effort categories and may be wrong in noisy rooms.": "Geräuschlabels sind Näherungen und können in lauten Räumen falsch sein.", "No heading": "Keine Richtung", "peak": "Spitze", "avg": "Durchschnitt"
        ],
        "es": [
            "Turn slowly 360° while scanning.": "Gira lentamente 360° durante el escaneo.", "Keep the iPhone still and let it listen.": "Mantén el iPhone quieto y deja que escuche.", "Mode": "Modo", "Scan 360": "Escaneo 360", "Listen": "Escuchar", "Loudest sound at": "Sonido más fuerte en", "Quality": "Calidad", "Sound type": "Tipo de sonido", "Top sounds": "Sonidos principales", "Raw": "Bruto", "Smoothed": "Suavizado", "Top headings": "Rumbos principales", "Threshold Alerts": "Alertas de umbral", "On": "Activado", "Off": "Desactivado", "Directions by Sound Type": "Direcciones por tipo de sonido", "No categorized direction yet.": "Aún no hay dirección categorizada.", "Readiness": "Preparación", "Do not cover the bottom microphone.": "No cubras el micrófono inferior.", "History": "Historial", "Settings": "Ajustes", "Share": "Compartir", "Help": "Ayuda", "Stop & Analyze": "Detener y analizar", "Stop Listening": "Detener escucha", "Start Scan": "Iniciar escaneo", "Start Listening": "Iniciar escucha", "Quick Help": "Ayuda rápida", "Tips": "Consejos", "Version": "Versión", "Website": "Sitio web", "Done": "Listo", "No history yet": "Aún no hay historial", "Scan or listen to create local sound events.": "Escanea o escucha para crear eventos de sonido locales.", "Enable Alerts": "Activar alertas", "Sound Type": "Tipo de sonido", "dB Threshold": "Umbral dB", "Confidence": "Confianza", "Alert Style": "Estilo de alerta", "Calibration": "Calibración", "Manual Offset": "Ajuste manual", "Reset Calibration": "Restablecer calibración", "Reports": "Informes", "About": "Acerca de", "Language": "Idioma", "None": "Ninguno", "Haptic": "Háptico", "Screen Flash": "Destello de pantalla", "Sound": "Sonido", "Any": "Cualquiera", "Human voice": "Voz humana", "Animals": "Animales", "Vehicles": "Vehículos", "Mechanical": "Mecánico", "Alarm": "Alarma", "Music": "Música", "Nature": "Naturaleza", "Household": "Hogar", "Impact": "Impacto", "Other": "Otro", "Ready": "Listo", "Calibrating": "Calibrando", "Listening": "Escuchando", "Good": "Bien", "Too fast": "Demasiado rápido", "Too noisy": "Demasiado ruido", "Too quiet": "Muy bajo", "Audio error": "Error de audio", "Sound type: Ready": "Tipo de sonido: Listo", "Sound type: Listening...": "Tipo de sonido: Escuchando...", "Sound type: Unavailable": "Tipo de sonido: No disponible", "Unknown": "Desconocido", "Compass unavailable on this device.": "La brújula no está disponible en este dispositivo.", "Microphone permission is required.": "Se requiere permiso de micrófono.", "Audio setup failed.": "Falló la configuración de audio.", "Enable microphone in Settings.": "Activa el micrófono en Ajustes.", "Calibrating... stay still": "Calibrando... mantente quieto", "Audio input failed.": "Falló la entrada de audio.", "Listen stopped.": "Escucha detenida.", "Scanning... turn slowly 360°": "Escaneando... gira lentamente 360°", "Listening...": "Escuchando...", "Scanning... slow down": "Escaneando... más despacio", "Sound too quiet. Try again.": "Sonido demasiado bajo. Inténtalo de nuevo.", "Scan complete.": "Escaneo completo.", "Enable location access for compass.": "Activa la ubicación para la brújula.", "Alerts ready": "Alertas listas", "over": "sobre", "Microphone": "Micrófono", "Allowed": "Permitido", "Permission needed": "Permiso necesario", "Compass": "Brújula", "Allow location for heading": "Permitir ubicación para rumbo", "Rotation": "Rotación", "Slow enough": "Suficientemente lento", "Turn slower": "Gira más despacio", "Noise floor": "Ruido de fondo", "Usable": "Utilizable", "Noisy environment": "Entorno ruidoso", "Hold upright": "Mantén vertical", "Keep the bottom microphone uncovered.": "Mantén libre el micrófono inferior.", "Calibrate first": "Calibra primero", "Stay still while the app learns the room noise.": "Quédate quieto mientras la app aprende el ruido de la sala.", "Turn slowly": "Gira despacio", "Use Scan 360 for direction or Listen mode for ongoing sound events.": "Usa Escaneo 360 para dirección o Escuchar para eventos continuos.", "Start": "Empezar", "1. Hold the phone upright.": "1. Mantén el teléfono vertical.", "2. Tap Start Scan.": "2. Toca Iniciar escaneo.", "3. Slowly rotate 360°.": "3. Gira lentamente 360°.", "4. Tap Stop & Analyze.": "4. Toca Detener y analizar.", "5. The green arrow points to the loudest direction.": "5. La flecha verde apunta a la dirección más fuerte.", "6. Sound type labels run offline on device.": "6. Las etiquetas de sonido funcionan sin conexión.", "Use a real device for accurate compass readings.": "Usa un dispositivo real para lecturas precisas.", "Sound labels are best-effort categories and may be wrong in noisy rooms.": "Las etiquetas son aproximadas y pueden fallar en salas ruidosas.", "No heading": "Sin rumbo", "peak": "pico", "avg": "prom."
        ],
        "fr": commonRomance("Analyse 360", listen: "Écouter", language: "Langue", settings: "Réglages", help: "Aide", history: "Historique", share: "Partager", start: "Démarrer", done: "Terminé", ready: "Prêt", good: "Bon", calibrating: "Étalonnage", listening: "Écoute", tooFast: "Trop rapide", tooNoisy: "Trop bruyant", tooQuiet: "Trop faible", human: "Voix humaine", animals: "Animaux", vehicles: "Véhicules", mechanical: "Mécanique", alarm: "Alarme", music: "Musique", nature: "Nature", household: "Maison", impact: "Impact", other: "Autre", any: "Tous").merging(commonUI(mode: "Mode", quality: "Qualité", soundType: "Type de son", threshold: "Alertes de seuil", directions: "Directions par type de son", readiness: "Préparation", on: "Activé", off: "Désactivé", topSounds: "Sons principaux", topHeadings: "Directions principales", raw: "Brut", smoothed: "Lissé")) { _, new in new },
        "it": commonRomance("Scansione 360", listen: "Ascolta", language: "Lingua", settings: "Impostazioni", help: "Aiuto", history: "Cronologia", share: "Condividi", start: "Avvia", done: "Fine", ready: "Pronto", good: "Buono", calibrating: "Calibrazione", listening: "Ascolto", tooFast: "Troppo veloce", tooNoisy: "Troppo rumoroso", tooQuiet: "Troppo basso", human: "Voce umana", animals: "Animali", vehicles: "Veicoli", mechanical: "Meccanico", alarm: "Allarme", music: "Musica", nature: "Natura", household: "Casa", impact: "Impatto", other: "Altro", any: "Qualsiasi").merging(commonUI(mode: "Modalità", quality: "Qualità", soundType: "Tipo di suono", threshold: "Avvisi soglia", directions: "Direzioni per tipo di suono", readiness: "Prontezza", on: "Attivo", off: "Disattivo", topSounds: "Suoni principali", topHeadings: "Direzioni principali", raw: "Grezzo", smoothed: "Smussato")) { _, new in new },
        "pl": commonSlavic(scan: "Skan 360", listen: "Nasłuch", language: "Język", settings: "Ustawienia", help: "Pomoc", history: "Historia", share: "Udostępnij", start: "Start", done: "Gotowe", ready: "Gotowe", good: "Dobra", calibrating: "Kalibracja", listening: "Nasłuch", tooFast: "Za szybko", tooNoisy: "Zbyt głośno", tooQuiet: "Zbyt cicho", human: "Głos ludzki", animals: "Zwierzęta", vehicles: "Pojazdy", mechanical: "Mechaniczne", alarm: "Alarm", music: "Muzyka", nature: "Natura", household: "Dom", impact: "Uderzenie", other: "Inne", any: "Dowolne").merging(commonUI(mode: "Tryb", quality: "Jakość", soundType: "Typ dźwięku", threshold: "Alerty progowe", directions: "Kierunki według typu dźwięku", readiness: "Gotowość", on: "Wł.", off: "Wył.", topSounds: "Najważniejsze dźwięki", topHeadings: "Najlepsze kierunki", raw: "Surowe", smoothed: "Wygładzone")) { _, new in new },
        "cs": commonSlavic(scan: "Sken 360", listen: "Poslech", language: "Jazyk", settings: "Nastavení", help: "Nápověda", history: "Historie", share: "Sdílet", start: "Start", done: "Hotovo", ready: "Připraveno", good: "Dobré", calibrating: "Kalibrace", listening: "Poslech", tooFast: "Příliš rychle", tooNoisy: "Příliš hlučno", tooQuiet: "Příliš tiché", human: "Lidský hlas", animals: "Zvířata", vehicles: "Vozidla", mechanical: "Mechanické", alarm: "Alarm", music: "Hudba", nature: "Příroda", household: "Domácnost", impact: "Náraz", other: "Jiné", any: "Libovolné").merging(commonUI(mode: "Režim", quality: "Kvalita", soundType: "Typ zvuku", threshold: "Prahové výstrahy", directions: "Směry podle typu zvuku", readiness: "Připravenost", on: "Zap.", off: "Vyp.", topSounds: "Hlavní zvuky", topHeadings: "Nejlepší směry", raw: "Surové", smoothed: "Vyhlazené")) { _, new in new },
        "ro": commonRomance("Scanare 360", listen: "Ascultare", language: "Limbă", settings: "Setări", help: "Ajutor", history: "Istoric", share: "Partajare", start: "Start", done: "Gata", ready: "Gata", good: "Bună", calibrating: "Calibrare", listening: "Ascultare", tooFast: "Prea rapid", tooNoisy: "Prea zgomotos", tooQuiet: "Prea încet", human: "Voce umană", animals: "Animale", vehicles: "Vehicule", mechanical: "Mecanic", alarm: "Alarmă", music: "Muzică", nature: "Natură", household: "Casă", impact: "Impact", other: "Altul", any: "Oricare").merging(commonUI(mode: "Mod", quality: "Calitate", soundType: "Tip sunet", threshold: "Alerte de prag", directions: "Direcții după tipul sunetului", readiness: "Pregătire", on: "Pornit", off: "Oprit", topSounds: "Sunete principale", topHeadings: "Direcții principale", raw: "Brut", smoothed: "Netezit")) { _, new in new },
        "lt": commonBaltic(scan: "360 skenavimas", listen: "Klausymas", language: "Kalba", settings: "Nustatymai", help: "Pagalba", history: "Istorija", share: "Bendrinti", start: "Pradėti", done: "Atlikta", ready: "Paruošta", good: "Gera", calibrating: "Kalibruojama", listening: "Klausoma", tooFast: "Per greitai", tooNoisy: "Per triukšminga", tooQuiet: "Per tylu", human: "Žmogaus balsas", animals: "Gyvūnai", vehicles: "Transportas", mechanical: "Mechaniniai", alarm: "Signalas", music: "Muzika", nature: "Gamta", household: "Namai", impact: "Smūgis", other: "Kita", any: "Bet kas").merging(commonUI(mode: "Režimas", quality: "Kokybė", soundType: "Garso tipas", threshold: "Slenksčio įspėjimai", directions: "Kryptys pagal garso tipą", readiness: "Parengtis", on: "Įjungta", off: "Išjungta", topSounds: "Pagrindiniai garsai", topHeadings: "Pagrindinės kryptys", raw: "Neapdorota", smoothed: "Išlyginta")) { _, new in new },
        "lv": commonBaltic(scan: "360 skenēšana", listen: "Klausīties", language: "Valoda", settings: "Iestatījumi", help: "Palīdzība", history: "Vēsture", share: "Kopīgot", start: "Sākt", done: "Gatavs", ready: "Gatavs", good: "Laba", calibrating: "Kalibrē", listening: "Klausās", tooFast: "Par ātru", tooNoisy: "Pārāk trokšņaini", tooQuiet: "Pārāk kluss", human: "Cilvēka balss", animals: "Dzīvnieki", vehicles: "Transportlīdzekļi", mechanical: "Mehāniski", alarm: "Trauksme", music: "Mūzika", nature: "Daba", household: "Mājsaimniecība", impact: "Trieciens", other: "Cits", any: "Jebkurš").merging(commonUI(mode: "Režīms", quality: "Kvalitāte", soundType: "Skaņas tips", threshold: "Sliekšņa brīdinājumi", directions: "Virzieni pēc skaņas tipa", readiness: "Gatavība", on: "Ieslēgts", off: "Izslēgts", topSounds: "Galvenās skaņas", topHeadings: "Galvenie virzieni", raw: "Neapstrādāts", smoothed: "Izlīdzināts")) { _, new in new },
        "et": commonBaltic(scan: "360 skann", listen: "Kuula", language: "Keel", settings: "Seaded", help: "Abi", history: "Ajalugu", share: "Jaga", start: "Alusta", done: "Valmis", ready: "Valmis", good: "Hea", calibrating: "Kalibreerib", listening: "Kuulab", tooFast: "Liiga kiiresti", tooNoisy: "Liiga mürarikas", tooQuiet: "Liiga vaikne", human: "Inimhääl", animals: "Loomad", vehicles: "Sõidukid", mechanical: "Mehaaniline", alarm: "Alarm", music: "Muusika", nature: "Loodus", household: "Kodune", impact: "Löök", other: "Muu", any: "Kõik").merging(commonUI(mode: "Režiim", quality: "Kvaliteet", soundType: "Heli tüüp", threshold: "Lävehoiatused", directions: "Suunad heli tüübi järgi", readiness: "Valmisolek", on: "Sees", off: "Väljas", topSounds: "Peamised helid", topHeadings: "Peamised suunad", raw: "Toores", smoothed: "Silutud")) { _, new in new },
        "sv": commonNordic(scan: "360-skanning", listen: "Lyssna", language: "Språk", settings: "Inställningar", help: "Hjälp", history: "Historik", share: "Dela", start: "Starta", done: "Klar", ready: "Klar", good: "Bra", calibrating: "Kalibrerar", listening: "Lyssnar", tooFast: "För snabbt", tooNoisy: "För bullrigt", tooQuiet: "För tyst", human: "Mänsklig röst", animals: "Djur", vehicles: "Fordon", mechanical: "Mekaniskt", alarm: "Larm", music: "Musik", nature: "Natur", household: "Hushåll", impact: "Slag", other: "Annat", any: "Alla").merging(commonUI(mode: "Läge", quality: "Kvalitet", soundType: "Ljudtyp", threshold: "Tröskelvarningar", directions: "Riktningar efter ljudtyp", readiness: "Beredskap", on: "På", off: "Av", topSounds: "Toppljud", topHeadings: "Toppriktningar", raw: "Rå", smoothed: "Utjämnad")) { _, new in new },
        "fi": commonNordic(scan: "360-skannaus", listen: "Kuuntelu", language: "Kieli", settings: "Asetukset", help: "Ohje", history: "Historia", share: "Jaa", start: "Aloita", done: "Valmis", ready: "Valmis", good: "Hyvä", calibrating: "Kalibrointi", listening: "Kuuntelee", tooFast: "Liian nopeasti", tooNoisy: "Liian meluisa", tooQuiet: "Liian hiljainen", human: "Ihmisen ääni", animals: "Eläimet", vehicles: "Ajoneuvot", mechanical: "Mekaaninen", alarm: "Hälytys", music: "Musiikki", nature: "Luonto", household: "Koti", impact: "Isku", other: "Muu", any: "Mikä tahansa").merging(commonUI(mode: "Tila", quality: "Laatu", soundType: "Äänityyppi", threshold: "Kynnysvaroitukset", directions: "Suunnat äänityypin mukaan", readiness: "Valmius", on: "Päällä", off: "Pois", topSounds: "Tärkeimmät äänet", topHeadings: "Tärkeimmät suunnat", raw: "Raaka", smoothed: "Tasoitettu")) { _, new in new },
        "uk": commonSlavic(scan: "Скан 360", listen: "Слухати", language: "Мова", settings: "Налаштування", help: "Довідка", history: "Історія", share: "Поділитися", start: "Почати", done: "Готово", ready: "Готово", good: "Добре", calibrating: "Калібрування", listening: "Слухання", tooFast: "Занадто швидко", tooNoisy: "Занадто шумно", tooQuiet: "Занадто тихо", human: "Людський голос", animals: "Тварини", vehicles: "Транспорт", mechanical: "Механічне", alarm: "Сигнал", music: "Музика", nature: "Природа", household: "Побут", impact: "Удар", other: "Інше", any: "Будь-який").merging(commonUI(mode: "Режим", quality: "Якість", soundType: "Тип звуку", threshold: "Порогові сповіщення", directions: "Напрямки за типом звуку", readiness: "Готовність", on: "Увімк.", off: "Вимк.", topSounds: "Основні звуки", topHeadings: "Основні напрямки", raw: "Сире", smoothed: "Згладжене")) { _, new in new },
        "el": commonRomance("Σάρωση 360", listen: "Ακρόαση", language: "Γλώσσα", settings: "Ρυθμίσεις", help: "Βοήθεια", history: "Ιστορικό", share: "Κοινή χρήση", start: "Έναρξη", done: "Τέλος", ready: "Έτοιμο", good: "Καλή", calibrating: "Βαθμονόμηση", listening: "Ακρόαση", tooFast: "Πολύ γρήγορα", tooNoisy: "Πολύς θόρυβος", tooQuiet: "Πολύ χαμηλά", human: "Ανθρώπινη φωνή", animals: "Ζώα", vehicles: "Οχήματα", mechanical: "Μηχανικό", alarm: "Συναγερμός", music: "Μουσική", nature: "Φύση", household: "Σπίτι", impact: "Κρούση", other: "Άλλο", any: "Οποιοδήποτε").merging(commonUI(mode: "Λειτουργία", quality: "Ποιότητα", soundType: "Τύπος ήχου", threshold: "Ειδοποιήσεις ορίου", directions: "Κατευθύνσεις ανά τύπο ήχου", readiness: "Ετοιμότητα", on: "Ενεργό", off: "Ανενεργό", topSounds: "Κύριοι ήχοι", topHeadings: "Κύριες κατευθύνσεις", raw: "Ακατέργαστο", smoothed: "Εξομαλυμένο")) { _, new in new },
        "be": commonSlavic(scan: "Скан 360", listen: "Слухаць", language: "Мова", settings: "Налады", help: "Даведка", history: "Гісторыя", share: "Падзяліцца", start: "Пачаць", done: "Гатова", ready: "Гатова", good: "Добра", calibrating: "Каліброўка", listening: "Слуханне", tooFast: "Занадта хутка", tooNoisy: "Занадта шумна", tooQuiet: "Занадта ціха", human: "Чалавечы голас", animals: "Жывёлы", vehicles: "Транспарт", mechanical: "Механічнае", alarm: "Сігнал", music: "Музыка", nature: "Прырода", household: "Побыт", impact: "Удар", other: "Іншае", any: "Любы").merging(commonUI(mode: "Рэжым", quality: "Якасць", soundType: "Тып гуку", threshold: "Парогавыя абвесткі", directions: "Напрамкі па тыпе гуку", readiness: "Гатоўнасць", on: "Укл.", off: "Выкл.", topSounds: "Асноўныя гукі", topHeadings: "Асноўныя напрамкі", raw: "Сырое", smoothed: "Згладжанае")) { _, new in new }
    ]
}

private func commonBase(scan: String, listen: String, language: String, settings: String, help: String, history: String, share: String, start: String, done: String, ready: String, good: String, calibrating: String, listening: String, tooFast: String, tooNoisy: String, tooQuiet: String, human: String, animals: String, vehicles: String, mechanical: String, alarm: String, music: String, nature: String, household: String, impact: String, other: String, any: String) -> [String: String] {
    [
        "Scan 360": scan, "Listen": listen, "Language": language, "Settings": settings, "Help": help, "History": history, "Share": share, "Start": start, "Done": done,
        "Ready": ready, "Good": good, "Calibrating": calibrating, "Listening": listening, "Too fast": tooFast, "Too noisy": tooNoisy, "Too quiet": tooQuiet,
        "Human voice": human, "Animals": animals, "Vehicles": vehicles, "Mechanical": mechanical, "Alarm": alarm, "Music": music, "Nature": nature, "Household": household, "Impact": impact, "Other": other, "Any": any,
        "Mode": settings, "Quality": "Quality", "Sound type": "Sound type", "Top sounds": "Top sounds", "Top headings": "Top headings", "Threshold Alerts": "Threshold Alerts",
        "On": "On", "Off": "Off", "Directions by Sound Type": "Directions by Sound Type", "No categorized direction yet.": "No categorized direction yet.", "Readiness": "Readiness",
        "Do not cover the bottom microphone.": "Do not cover the bottom microphone.", "Stop & Analyze": "Stop & Analyze", "Stop Listening": "Stop Listening", "Start Scan": "\(start) \(scan)", "Start Listening": "\(start) \(listen)",
        "Quick Help": help, "Tips": "Tips", "Version": "Version", "Website": "Website", "No history yet": "No history yet", "Sound Type": "Sound type", "Confidence": "Confidence",
        "Alert Style": "Alert Style", "Calibration": calibrating, "Manual Offset": "Manual Offset", "Reset Calibration": "Reset Calibration", "Reports": "Reports", "About": "About",
        "None": "None", "Haptic": "Haptic", "Screen Flash": "Screen Flash", "Sound": "Sound", "Sound type: Ready": "Sound type: \(ready)", "Sound type: Listening...": "Sound type: \(listening)...", "Unknown": "Unknown",
        "Compass unavailable on this device.": "Compass unavailable on this device.", "Microphone permission is required.": "Microphone permission is required.", "Audio setup failed.": "Audio setup failed.",
        "Enable microphone in Settings.": "Enable microphone in Settings.", "Calibrating... stay still": "\(calibrating)...", "Audio input failed.": "Audio input failed.", "Listen stopped.": "\(listen) stopped.",
        "Scanning... turn slowly 360°": "\(scan)...", "Listening...": "\(listening)...", "Scanning... slow down": "\(scan)... \(tooFast)", "Sound too quiet. Try again.": "\(tooQuiet).", "Scan complete.": "\(scan) complete.",
        "Alerts ready": ready, "over": "over", "Microphone": "Microphone", "Allowed": "Allowed", "Permission needed": "Permission needed", "Compass": "Compass", "Rotation": "Rotation", "Slow enough": "Slow enough", "Turn slower": tooFast, "Noise floor": "Noise floor", "Usable": "Usable", "Noisy environment": tooNoisy,
        "Hold upright": "Hold upright", "Calibrate first": calibrating, "Turn slowly": "Turn slowly", "No heading": "No heading", "peak": "peak", "avg": "avg"
    ]
}

private func commonUI(mode: String, quality: String, soundType: String, threshold: String, directions: String, readiness: String, on: String, off: String, topSounds: String, topHeadings: String, raw: String, smoothed: String) -> [String: String] {
    [
        "Mode": mode,
        "Quality": quality,
        "Sound type": soundType,
        "Top sounds": topSounds,
        "Raw": raw,
        "Smoothed": smoothed,
        "Top headings": topHeadings,
        "Threshold Alerts": threshold,
        "On": on,
        "Off": off,
        "Directions by Sound Type": directions,
        "Readiness": readiness,
        "Sound Type": soundType
    ]
}

private func commonRomance(_ scan: String, listen: String, language: String, settings: String, help: String, history: String, share: String, start: String, done: String, ready: String, good: String, calibrating: String, listening: String, tooFast: String, tooNoisy: String, tooQuiet: String, human: String, animals: String, vehicles: String, mechanical: String, alarm: String, music: String, nature: String, household: String, impact: String, other: String, any: String) -> [String: String] {
    commonBase(scan: scan, listen: listen, language: language, settings: settings, help: help, history: history, share: share, start: start, done: done, ready: ready, good: good, calibrating: calibrating, listening: listening, tooFast: tooFast, tooNoisy: tooNoisy, tooQuiet: tooQuiet, human: human, animals: animals, vehicles: vehicles, mechanical: mechanical, alarm: alarm, music: music, nature: nature, household: household, impact: impact, other: other, any: any)
}

private func commonSlavic(scan: String, listen: String, language: String, settings: String, help: String, history: String, share: String, start: String, done: String, ready: String, good: String, calibrating: String, listening: String, tooFast: String, tooNoisy: String, tooQuiet: String, human: String, animals: String, vehicles: String, mechanical: String, alarm: String, music: String, nature: String, household: String, impact: String, other: String, any: String) -> [String: String] {
    commonBase(scan: scan, listen: listen, language: language, settings: settings, help: help, history: history, share: share, start: start, done: done, ready: ready, good: good, calibrating: calibrating, listening: listening, tooFast: tooFast, tooNoisy: tooNoisy, tooQuiet: tooQuiet, human: human, animals: animals, vehicles: vehicles, mechanical: mechanical, alarm: alarm, music: music, nature: nature, household: household, impact: impact, other: other, any: any)
}

private func commonBaltic(scan: String, listen: String, language: String, settings: String, help: String, history: String, share: String, start: String, done: String, ready: String, good: String, calibrating: String, listening: String, tooFast: String, tooNoisy: String, tooQuiet: String, human: String, animals: String, vehicles: String, mechanical: String, alarm: String, music: String, nature: String, household: String, impact: String, other: String, any: String) -> [String: String] {
    commonBase(scan: scan, listen: listen, language: language, settings: settings, help: help, history: history, share: share, start: start, done: done, ready: ready, good: good, calibrating: calibrating, listening: listening, tooFast: tooFast, tooNoisy: tooNoisy, tooQuiet: tooQuiet, human: human, animals: animals, vehicles: vehicles, mechanical: mechanical, alarm: alarm, music: music, nature: nature, household: household, impact: impact, other: other, any: any)
}

private func commonNordic(scan: String, listen: String, language: String, settings: String, help: String, history: String, share: String, start: String, done: String, ready: String, good: String, calibrating: String, listening: String, tooFast: String, tooNoisy: String, tooQuiet: String, human: String, animals: String, vehicles: String, mechanical: String, alarm: String, music: String, nature: String, household: String, impact: String, other: String, any: String) -> [String: String] {
    commonBase(scan: scan, listen: listen, language: language, settings: settings, help: help, history: history, share: share, start: start, done: done, ready: ready, good: good, calibrating: calibrating, listening: listening, tooFast: tooFast, tooNoisy: tooNoisy, tooQuiet: tooQuiet, human: human, animals: animals, vehicles: vehicles, mechanical: mechanical, alarm: alarm, music: music, nature: nature, household: household, impact: impact, other: other, any: any)
}
