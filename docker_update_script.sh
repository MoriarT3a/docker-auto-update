#!/bin/bash

# Docker Compose Auto-Update Script
# Findet automatisch alle laufenden Docker Compose Services und aktualisiert sie

# Konfiguration
LOG_FILE="$HOME/docker-update.log"
DEBUG_MODE=false

# Augenschonende Farben (Solarized-inspiriert)
RED='\033[0;91m'      # Helles Rot
GREEN='\033[0;92m'    # Helles Grün  
YELLOW='\033[0;93m'   # Helles Gelb
CYAN='\033[0;96m'     # Helles Cyan
MAGENTA='\033[0;95m'  # Helles Magenta
GRAY='\033[0;90m'     # Grau
NC='\033[0m'          # No Color

# Terminal Funktionen
clear_screen() { echo -e '\033[2J\033[H'; }
hide_cursor() { echo -e '\033[?25l'; }
show_cursor() { echo -e '\033[?25h'; }
clear_to_end() { echo -e '\033[0J'; }  # Löscht vom Cursor bis zum Ende des Bildschirms
get_terminal_size() {
    TERM_ROWS=$(tput lines)
    TERM_COLS=$(tput cols)
}

# Cleanup bei Exit
cleanup() {
    show_cursor
    exit $1
}
trap 'cleanup $?' EXIT INT TERM

# Logging Funktion
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Fortschrittsbalken
show_progress() {
    local current=$1
    local total=$2
    local width=$3
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    # Erstelle Balken ohne printf direkt mit Zeichen
    local bar="["
    local i
    for ((i=0; i<completed; i++)); do
        bar+="#"
    done
    for ((i=0; i<remaining; i++)); do
        bar+="-"
    done
    bar+="]"
    
    echo "$bar $percentage% ($current/$total)"
}

# Container Status
get_container_status() {
    local step=$1
    case $step in
        0) echo "🔍 Checking..." ;;
        1) echo "📥 Pulling..." ;;
        2) echo "🚀 Starting..." ;;
        3) echo "✅ Complete!" ;;
        "error") echo "❌ Failed!" ;;
    esac
}

# Finde alle Docker Compose Projekte
find_compose_projects() {
    docker ps --format "table {{.Names}}\t{{.Label \"com.docker.compose.project.working_dir\"}}" | \
    tail -n +2 | \
    grep -v "^$" | \
    awk '{print $2}' | \
    sort -u | \
    grep -v "^$"
}

# Screen Content erstellen
create_screen_content() {
    local current_project=$1
    local total_projects=$2
    local projects=("${@:3}")
    
    get_terminal_size
    local content=""
    
    # Header
    content+="${CYAN}🐳 Docker Compose Auto-Update${NC}\n"
    # Erstelle Trennlinie ohne printf
    local separator=""
    local sep_length=$((TERM_COLS > 50 ? 50 : TERM_COLS))
    for ((i=0; i<sep_length; i++)); do separator+="="; done
    content+="${GRAY}${separator}${NC}\n\n"
    
    # Overall Progress
    local overall_width=$((TERM_COLS > 60 ? 40 : TERM_COLS - 20))
    content+="🚀 ${CYAN}Gesamt-Fortschritt:${NC}\n"
    content+="$(show_progress $current_project $total_projects $overall_width)\n\n"
    
    # Projects List
    content+="📋 ${YELLOW}Projekte (${total_projects}):${NC}\n"
    
    for i in "${!projects[@]}"; do
        local project_dir="${projects[$i]}"
        local project_name=$(basename "$project_dir")
        local project_index=$((i + 1))
        
        if [ $project_index -lt $current_project ]; then
            # Abgeschlossen
            content+="  ${GREEN}✅ $project_name${NC}\n"
        elif [ $project_index -eq $current_project ]; then
            # Aktuell
            content+="  ${CYAN}🔄 $project_name${NC} ${PROJECT_STATUS:-}\n"
            if [ -n "${PROJECT_CONTAINERS:-}" ]; then
                content+="$PROJECT_CONTAINERS"
            fi
            if [ -n "${PROJECT_PROGRESS:-}" ]; then
                # Stelle sicher, dass die Fortschrittszeile vollständig ist
                local progress_line="     $PROJECT_PROGRESS"
                # Fülle die Zeile mit Leerzeichen auf, um Artefakte zu vermeiden
                local padding_length=$((TERM_COLS - ${#progress_line}))
                if [ $padding_length -gt 0 ]; then
                    local padding=""
                    for ((i=0; i<padding_length; i++)); do padding+=" "; done
                    progress_line+="$padding"
                fi
                content+="$progress_line\n"
            fi
        else
            # Wartend
            content+="  ${GRAY}⏳ $project_name${NC}\n"
        fi
    done
    
    # Stats am Ende
    content+="\n"
    # Erstelle Trennlinie ohne printf
    local separator=""
    local sep_length=$((TERM_COLS > 50 ? 50 : TERM_COLS))
    for ((i=0; i<sep_length; i++)); do separator+="-"; done
    content+="${GRAY}${separator}${NC}\n"
    content+="📊 ${CYAN}Status:${NC} ${SUCCESS_COUNT:-0} ✅  ${FAIL_COUNT:-0} ❌  ${REMAINING_COUNT:-$total_projects} ⏳\n"
    content+="📋 ${GRAY}Log: $LOG_FILE${NC}\n"
    
    echo -e "$content"
}

# Screen aktualisieren
update_screen() {
    hide_cursor
    clear_screen
    create_screen_content "$@"
    clear_to_end  # Lösche alles nach dem Content
}

# Debug-Ausgabe für ein Projekt
debug_update_project() {
    local project_dir=$1
    local project_name=$(basename "$project_dir")
    
    echo -e "\n${CYAN}=== 🔄 Aktualisiere $project_name ($project_dir) ===${NC}"
    
    if [ ! -d "$project_dir" ]; then
        echo -e "${RED}❌ Verzeichnis $project_dir existiert nicht mehr${NC}"
        return 1
    fi
    
    if [ ! -f "$project_dir/docker-compose.yml" ] && [ ! -f "$project_dir/docker-compose.yaml" ]; then
        echo -e "${RED}❌ Keine docker-compose.yml gefunden in $project_dir${NC}"
        return 1
    fi
    
    cd "$project_dir" || return 1
    
    echo -e "${YELLOW}📦 Laufende Container:${NC}"
    docker compose ps --format "table {{.Service}}\t{{.Image}}\t{{.Status}}"
    
    log "Starte Update für $project_name in $project_dir"
    
    if docker compose pull --quiet; then
        if docker compose up --detach --remove-orphans; then
            echo -e "${GREEN}✅ $project_name erfolgreich aktualisiert${NC}"
            log "SUCCESS: $project_name aktualisiert"
            
            echo -e "${YELLOW}🔍 Status nach Update:${NC}"
            docker compose ps --format "table {{.Service}}\t{{.Image}}\t{{.Status}}"
            return 0
        else
            echo -e "${RED}❌ Fehler beim Starten von $project_name${NC}"
            log "ERROR: Fehler beim Starten von $project_name"
            return 1
        fi
    else
        echo -e "${RED}❌ Fehler beim Pullen der Images für $project_name${NC}"
        log "ERROR: Fehler beim Pullen der Images für $project_name"
        return 1
    fi
}

# Fancy Update mit Full-Screen Interface
fancy_update_project() {
    local project_dir=$1
    local project_name=$(basename "$project_dir")
    local current_project=$2
    local total_projects=$3
    local projects=("${@:4}")
    
    # Prüfe Verzeichnis
    if [ ! -d "$project_dir" ] || ([ ! -f "$project_dir/docker-compose.yml" ] && [ ! -f "$project_dir/docker-compose.yaml" ]); then
        PROJECT_STATUS="❌ ${RED}Verzeichnis/Compose-Datei fehlt${NC}"
        update_screen $current_project $total_projects "${projects[@]}"
        log "ERROR: $project_name - Verzeichnis oder docker-compose.yml fehlt"
        sleep 2
        return 1
    fi
    
    cd "$project_dir" || return 1
    
    # Container auflisten
    local containers=($(docker compose ps --services 2>/dev/null))
    PROJECT_CONTAINERS=""
    for container in "${containers[@]}"; do
        PROJECT_CONTAINERS+="     ${GRAY}└─ $container${NC}\n"
    done
    
    log "Starte Update für $project_name in $project_dir"
    
    # Schritt 1: Checking
    PROJECT_STATUS="$(get_container_status 0)"
    PROJECT_PROGRESS="$(show_progress 0 3 20)"
    update_screen $current_project $total_projects "${projects[@]}"
    sleep 0.5
    
    # Schritt 2: Pulling
    PROJECT_STATUS="$(get_container_status 1)"
    PROJECT_PROGRESS="$(show_progress 1 3 20)"
    update_screen $current_project $total_projects "${projects[@]}"
    
    if docker compose pull --quiet >/dev/null 2>&1; then
        # Schritt 3: Starting
        PROJECT_STATUS="$(get_container_status 2)"
        PROJECT_PROGRESS="$(show_progress 2 3 20)"
        update_screen $current_project $total_projects "${projects[@]}"
        
        if docker compose up --detach --remove-orphans >/dev/null 2>&1; then
            # Schritt 4: Complete
            PROJECT_STATUS="$(get_container_status 3)"
            PROJECT_PROGRESS="$(show_progress 3 3 20)"
            update_screen $current_project $total_projects "${projects[@]}"
            
            log "SUCCESS: $project_name aktualisiert"
            sleep 1
            return 0
        else
            PROJECT_STATUS="$(get_container_status error)"
            PROJECT_PROGRESS=""
            PROJECT_CONTAINERS=""
            update_screen $current_project $total_projects "${projects[@]}"
            log "ERROR: Fehler beim Starten von $project_name"
            sleep 2
            return 1
        fi
    else
        PROJECT_STATUS="$(get_container_status error)"
        PROJECT_PROGRESS=""
        PROJECT_CONTAINERS=""
        update_screen $current_project $total_projects "${projects[@]}"
        log "ERROR: Fehler beim Pullen der Images für $project_name"
        sleep 2
        return 1
    fi
}

# Hauptfunktion
main() {
    # Prüfe ob Docker läuft
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker ist nicht verfügbar oder läuft nicht!${NC}"
        exit 1
    fi
    
    # Erstelle Log-Verzeichnis falls nötig
    mkdir -p "$(dirname "$LOG_FILE")"
    log "=== Docker Auto-Update gestartet ==="
    
    # Finde alle laufenden Compose-Projekte
    COMPOSE_DIRS=($(find_compose_projects))
    
    if [ ${#COMPOSE_DIRS[@]} -eq 0 ]; then
        clear_screen
        echo -e "${YELLOW}⚠️  Keine laufenden Docker Compose Projekte gefunden${NC}"
        show_cursor
        exit 0
    fi
    
    # Initialer Screen
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    REMAINING_COUNT=${#COMPOSE_DIRS[@]}
    update_screen 0 ${#COMPOSE_DIRS[@]} "${COMPOSE_DIRS[@]}"
    
    # Bereinige ungenutzte Images vor dem Update
    PROJECT_STATUS="🧹 ${YELLOW}Bereinige Docker Images...${NC}"
    update_screen 0 ${#COMPOSE_DIRS[@]} "${COMPOSE_DIRS[@]}"
    docker image prune -f >/dev/null 2>&1
    sleep 1
    
    # Update alle gefundenen Projekte
    for i in "${!COMPOSE_DIRS[@]}"; do
        project_dir="${COMPOSE_DIRS[$i]}"
        current=$((i + 1))
        
        # Reset project variables
        PROJECT_STATUS=""
        PROJECT_CONTAINERS=""
        PROJECT_PROGRESS=""
        
        if [ "$DEBUG_MODE" = true ]; then
            show_cursor
            if debug_update_project "$project_dir"; then
                ((SUCCESS_COUNT++))
            else
                ((FAIL_COUNT++))
            fi
            ((REMAINING_COUNT--))
        else
            if fancy_update_project "$project_dir" $current ${#COMPOSE_DIRS[@]} "${COMPOSE_DIRS[@]}"; then
                ((SUCCESS_COUNT++))
            else
                ((FAIL_COUNT++))
            fi
            ((REMAINING_COUNT--))
        fi
    done
    
    # Final Screen
    PROJECT_STATUS=""
    PROJECT_CONTAINERS=""
    PROJECT_PROGRESS=""
    update_screen ${#COMPOSE_DIRS[@]} ${#COMPOSE_DIRS[@]} "${COMPOSE_DIRS[@]}"
    
    # Bereinige verwaiste Images nach dem Update
    PROJECT_STATUS="🧹 ${YELLOW}Abschluss-Bereinigung...${NC}"
    update_screen ${#COMPOSE_DIRS[@]} ${#COMPOSE_DIRS[@]} "${COMPOSE_DIRS[@]}"
    docker image prune -f >/dev/null 2>&1
    sleep 1
    
    # Erfolgs-Screen
    clear_screen
    echo -e "${GREEN}🎉 Update-Prozess abgeschlossen!${NC}\n"
    echo -e "${CYAN}📊 Zusammenfassung:${NC}"
    echo -e "   ${GREEN}✅ Erfolgreich: $SUCCESS_COUNT${NC}"
    echo -e "   ${RED}❌ Fehlgeschlagen: $FAIL_COUNT${NC}"
    echo -e "   📋 ${GRAY}Logs: $LOG_FILE${NC}\n"
    
    # Docker System Info
    echo -e "${CYAN}💽 Docker System Status:${NC}"
    docker system df
    
    log "=== Docker Auto-Update beendet ==="
    show_cursor
}

# Script-Optionen
case "${1:-}" in
    --debug)
        DEBUG_MODE=true
        main
        ;;
    --list)
        echo -e "${CYAN}📋 Gefundene laufende Docker Compose Projekte:${NC}"
        COMPOSE_DIRS=($(find_compose_projects))
        if [ ${#COMPOSE_DIRS[@]} -eq 0 ]; then
            echo -e "${YELLOW}⚠️  Keine laufenden Docker Compose Projekte gefunden${NC}"
        else
            for dir in "${COMPOSE_DIRS[@]}"; do
                echo -e "  • ${GREEN}$(basename "$dir")${NC} ${GRAY}($dir)${NC}"
            done
        fi
        ;;
    --help|-h)
        echo -e "${CYAN}🐳 Docker Compose Auto-Update Script${NC}"
        echo ""
        echo -e "Findet automatisch alle laufenden Docker Compose Services"
        echo -e "und aktualisiert diese mit einem fancy Full-Screen Interface! 🚀"
        echo ""
        echo -e "${YELLOW}Verwendung:${NC} $0 [OPTION]"
        echo ""
        echo -e "${YELLOW}Optionen:${NC}"
        echo -e "  ${GREEN}--debug${NC}      Ausführliche Ausgabe mit Details"
        echo -e "  ${GREEN}--list${NC}       Zeige alle gefundenen laufenden Compose-Projekte"
        echo -e "  ${GREEN}--help, -h${NC}   Zeige diese Hilfe"
        echo ""
        echo -e "Ohne Optionen: Full-Screen Update-Interface"
        ;;
    *)
        main
        ;;
esac