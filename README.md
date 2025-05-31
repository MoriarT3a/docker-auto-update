# 🐳 Docker Compose Auto-Update

Ein elegantes, interaktives Script zum automatischen Update aller laufenden Docker Compose Services mit einem modernen Full-Screen Interface.

![Demo Picture](https://github.com/MoriarT3a/docker-auto-update/blob/main/grafik.png)

## ✨ Features

### 🎯 Intelligente Erkennung
- **Automatische Service-Erkennung**: Findet alle laufenden Docker Compose Projekte automatisch
- **Null Konfiguration**: Keine manuellen Service-Listen oder Pfad-Konfigurationen nötig
- **Dynamische Anpassung**: Funktioniert mit neuen Services ohne Änderungen am Script

### 🎨 Modernes Interface
- **Full-Screen UI**: Professionelles Interface wie `htop` oder moderne CLI-Tools
- **Live-Updates**: Echtzeit-Fortschrittsanzeige ohne Artefakte
- **Emoji-Icons**: Intuitive visuelle Orientierung
- **Farbkodierung**: Solarized-inspirierte, augenschonende Farben

### 📊 Fortschritts-Tracking
- **Doppelte Fortschrittsbalken**: Overall-Progress + Container-spezifischer Progress
- **Aufklapp-Animation**: Services zeigen kurz ihre Container, dann kompakte Anzeige
- **Live-Statistiken**: Erfolg/Fehler/Wartend Counter in Echtzeit
- **Detailliertes Logging**: Vollständige Logs für Debugging

### 🛡️ Sicherheit & Kontrolle
- **Manueller Trigger**: Läuft nur wenn Sie es starten (kein automatisches watchtower)
- **Fehlerbehandlung**: Robuste Behandlung von Fehlern und Edge Cases
- **Debug-Modus**: Ausführliche Ausgabe für Troubleshooting

## 🚀 Installation

### Voraussetzungen
- Docker & Docker Compose
- Bash (ab Version 4.0)
- `tput` (normalerweise vorinstalliert)

### Schnell-Installation
```bash
# Script herunterladen
curl -o docker-update.sh https://raw.githubusercontent.com/MoriarT3a/docker-auto-update/main/docker-update.sh

# Ausführbar machen
chmod +x docker-update.sh

# Optional: In PATH verschieben
sudo mv docker-update.sh /usr/local/bin/docker-update
```

### Manuelle Installation
1. Repository klonen oder Script herunterladen
2. Ausführungsrechte setzen: `chmod +x docker-update.sh`
3. Script ausführen: `./docker-update.sh`

## 📖 Verwendung

### Standard-Modus (Fancy Interface)
```bash
./docker-update.sh
```

Zeigt ein interaktives Full-Screen Interface mit:
- Live-Fortschrittsbalken
- Aufklapp-Animation pro Service
- Overall-Progress Tracking
- Kompakte, übersichtliche Darstellung

### Verfügbare Optionen

#### Service-Liste anzeigen
```bash
./docker-update.sh --list
```
Zeigt alle gefundenen Docker Compose Projekte an.

#### Debug-Modus
```bash
./docker-update.sh --debug
```
Ausführliche Ausgabe mit detaillierten Informationen für jedes Update.

#### Hilfe
```bash
./docker-update.sh --help
```
Zeigt alle verfügbaren Optionen an.

## 🎯 Wie es funktioniert

1. **Automatische Erkennung**: Das Script analysiert alle laufenden Docker Container und identifiziert deren Compose-Projekte
2. **Verzeichnis-Mapping**: Ermittelt automatisch die Pfade zu den docker-compose.yml Dateien
3. **Sequenzielles Update**: Führt für jedes Projekt folgende Schritte aus:
   - `docker compose pull` (neue Images laden)
   - `docker compose up --detach --remove-orphans` (Container mit neuen Images starten)
4. **Cleanup**: Bereinigt ungenutzte Docker Images nach dem Update

## 🖥️ Interface-Beispiel

```
🐳 Docker Compose Auto-Update
==================================================

🚀 Gesamt-Fortschritt:
[##################----------------------] 45% (5/11)

📋 Projekte (11):
  ✅ grav
  ✅ joplin-server  
  ✅ paperless-ngx
  ✅ vaultwarden
  🔄 searxng 📥 Pulling...
     └─ searxng
     └─ redis
     [########------------] 66% (2/3)
  ⏳ vikunja
  ⏳ wallabag
  ⏳ trilium-notes
  ⏳ ntfy
  ⏳ memos
  ⏳ cal-proxy

──────────────────────────────────────────────────
📊 Status: 4 ✅  0 ❌  7 ⏳
📋 Log: /home/user/docker-update.log
```

## ⚙️ Konfiguration

Das Script ist standardmäßig für maximale Benutzerfreundlichkeit ohne Konfiguration ausgelegt. Falls gewünscht, können folgende Aspekte angepasst werden:

### Log-Datei Pfad
Standardmäßig: `$HOME/docker-update.log`

```bash
# Im Script ändern (Zeile ~7):
LOG_FILE="/ihr/gewünschter/pfad/docker-update.log"
```

### Farben anpassen
Die Farbdefinitionen finden Sie in Zeile 11-16 des Scripts.

## 🔧 Troubleshooting

### Häufige Probleme

#### "Permission denied" beim Ausführen
```bash
chmod +x docker-update.sh
```

#### Script findet keine Container
- Prüfen Sie, ob Docker läuft: `docker ps`
- Prüfen Sie, ob Container mit docker-compose gestartet wurden
- Verwenden Sie `--debug` für detaillierte Ausgabe

#### Container starten nicht nach Update
- Prüfen Sie die Logs: `docker compose logs -f`
- Überprüfen Sie die docker-compose.yml auf Syntax-Fehler
- Verwenden Sie `--debug` für ausführliche Informationen

### Log-Datei überprüfen
```bash
tail -f ~/docker-update.log
```

## 🤝 Beitragen

Beiträge sind willkommen! Hier sind einige Wege, wie Sie helfen können:

### Bug Reports
- Verwenden Sie GitHub Issues
- Fügen Sie Ausgabe von `--debug` bei
- Beschreiben Sie Ihr Setup (OS, Docker Version, etc.)

### Feature Requests
- Beschreiben Sie den gewünschten Use Case
- Erläutern Sie, warum das Feature nützlich wäre

### Pull Requests
1. Forken Sie das Repository
2. Erstellen Sie einen Feature Branch: `git checkout -b feature/amazing-feature`
3. Committen Sie Ihre Änderungen: `git commit -m 'Add amazing feature'`
4. Pushen Sie den Branch: `git push origin feature/amazing-feature`
5. Öffnen Sie einen Pull Request

## 📝 Changelog

### v2.0.0 - Fancy Interface
- ✨ Full-Screen Interface mit Live-Updates
- 🎨 Aufklapp-Animation für Services
- 📊 Doppelte Fortschrittsbalken
- 🎯 Automatische Service-Erkennung
- 🌈 Solarized-inspirierte Farben

### v1.0.0 - Initial Release
- 🐳 Grundlegende Docker Compose Update-Funktionalität
- 📋 Service-Listen Konfiguration
- 📝 Logging-Support

## 📄 Lizenz

Dieses Projekt steht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE) Datei für Details.

## 🙏 Danksagungen

- Inspiriert von modernen CLI-Tools wie `htop`, `npm install` und `cargo build`
- Docker Community für die ausgezeichnete Dokumentation
- Alle Mitwirkenden und Beta-Tester

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/MoriarT3a/docker-auto-update/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/MoriarT3a/docker-auto-update/discussions)
- 📖 **Dokumentation**: [Wiki](https://github.com/MoriarT3a/docker-auto-update/wiki)

---

⭐ **Hat Ihnen das Projekt geholfen?** Geben Sie uns einen Stern auf GitHub!

🐳 **Happy Dockering!**
