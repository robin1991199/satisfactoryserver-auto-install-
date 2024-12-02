#!/bin/bash

# Skip menu option
SKIP_MENU="no"

# Default values
STEAM_USERNAME="your_steam_username"
STEAM_PASSWORD="your_steam_password"
INSTALL_DIR="$(dirname "$(realpath "$0")")/satisfactory_server_installation"
STEAMCMD_DIR="$INSTALL_DIR/steamcmd"
SATISFACTORY_SERVER_DIR="$INSTALL_DIR/satisfactory_server"
SATISFACTORY_APPID=1690800
LOG_DIR="$INSTALL_DIR/logs"  # Log directory
LOG_FILE="$LOG_DIR/satisfactory_install.log"  # Log file location
BACKUP_DIR="$INSTALL_DIR/backup"  # Backup directory
START_SERVER_SCRIPT="$SATISFACTORY_SERVER_DIR/start_server.sh"
MAX_PLAYER="4"
GAME_PORT=7777  # Default game port
QUERY_PORT=15777  # Default query port
BEACON_PORT=15000  # Default beacon port

# Function to log messages
log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to display the menu and get user input
display_menu() {
    log "Displaying the setup menu to the user."
    clear
    echo ""
    echo "    ____________    __      ____________     "
    echo "    \_____     /   /_ \     \     _____/     "
    echo "     \_____    \____/  \____/    _____/      "
    echo "      \_____                    _____/       "
    echo "         \___________  ___________/          "
    echo "                   /____\                    "
    echo "##############################################"
    echo "#        Satisfactory Server Setup Menu      #"
    echo "##############################################"
    echo ""
    
    printf "%-30s : %s\n" "Steam Username" "[default: $STEAM_USERNAME]"
    read -p "Enter Steam Username: " input_username
    STEAM_USERNAME="${input_username:-$STEAM_USERNAME}"

    printf "%-30s : %s\n" "Steam Password" "[default: hidden]"
    read -s -p "Enter Steam Password: " input_password
    echo ""
    if [[ -n "$input_password" ]]; then
        STEAM_PASSWORD="$input_password"
    fi

    printf "%-30s : %s\n" "Installation Directory" "[default: $INSTALL_DIR]"
    read -p "Enter Installation Directory: " input_install_dir
    INSTALL_DIR="${input_install_dir:-$INSTALL_DIR}"
    STEAMCMD_DIR="$INSTALL_DIR/steamcmd"
    SATISFACTORY_SERVER_DIR="$INSTALL_DIR/satisfactory_server"
    LOG_FILE="$LOG_DIR/satisfactory_install.log"

    printf "%-30s : %s\n" "Max Player Count" "[default: $MAX_PLAYER]"
    read -p "Enter Max Player Count: " input_max_player
    MAX_PLAYER="${input_max_player:-$MAX_PLAYER}"

    printf "%-30s : %s\n" "Game Port" "[default: $GAME_PORT]"
    read -p "Enter Game Port: " input_game_port
    GAME_PORT="${input_game_port:-$GAME_PORT}"

    printf "%-30s : %s\n" "Query Port" "[default: $QUERY_PORT]"
    read -p "Enter Query Port: " input_query_port
    QUERY_PORT="${input_query_port:-$QUERY_PORT}"

    printf "%-30s : %s\n" "Beacon Port" "[default: $BEACON_PORT]"
    read -p "Enter Beacon Port: " input_beacon_port
    BEACON_PORT="${input_beacon_port:-$BEACON_PORT}"
    clear 
    echo ""
    echo "    ____________    __      ____________     "
    echo "    \_____     /   /_ \     \     _____/     "
    echo "     \_____    \____/  \____/    _____/      "
    echo "      \_____                    _____/       "
    echo "         \___________  ___________/          "
    echo "                   /____\                    "
    echo "##############################################"
    echo "#            Configuration Summary           #"
    echo "##############################################"
    echo "Steam Username       : $STEAM_USERNAME"
    echo "Installation Directory: $INSTALL_DIR"
    echo "Max Player Count     : $MAX_PLAYER"
    echo "Game Port            : $GAME_PORT"
    echo "Query Port           : $QUERY_PORT"
    echo "Beacon Port          : $BEACON_PORT"
    echo "##############################################"
    log "User configuration: Steam Username=$STEAM_USERNAME, Directory=$INSTALL_DIR, Max Players=$MAX_PLAYER, Ports=($GAME_PORT, $QUERY_PORT, $BEACON_PORT)."
    echo ""
    read -p "Press Enter to confirm and continue..."
}

# Function to check and install SteamCMD for Debian-based systems
install_steamcmd() {
    log "Checking if SteamCMD is installed..."

    if ! command -v steamcmd &> /dev/null; then
        log "steamcmd not found. Installing steamcmd..."

        if [[ -f /etc/debian_version ]]; then
            # For Debian
            log "Detected Debian OS. Installing dependencies for SteamCMD..."
            sudo apt update
            sudo apt install -y software-properties-common
            sudo apt-add-repository non-free
            sudo dpkg --add-architecture i386
            sudo apt update
			sudo apt install zip
			sudo apt install ufw
			sudo ufw enable 
            sudo apt install -y steamcmd
        elif [[ -f /etc/ubuntu_version ]]; then
            # For Ubuntu
            log "Detected Ubuntu OS. Installing dependencies for SteamCMD..."
            sudo add-apt-repository multiverse
            sudo dpkg --add-architecture i386
            sudo apt update
            sudo apt install -y steamcmd
			sudo apt install zip
			sudo apt install ufw
			sudo ufw enable
        elif [[ -f /etc/fedora-release ]]; then
            # For Fedora
            log "Detected Fedora OS. Installing SteamCMD..."
            sudo dnf install -y steamcmd
        else
            log "Unsupported OS. SteamCMD installation failed."
            exit 1
        fi
    else
        log "steamcmd is already installed."
    fi
}

# Function to create the installation directory
create_directories() {
    log "Creating installation directories..."
    mkdir -p "$SATISFACTORY_SERVER_DIR"
    mkdir -p "$LOG_DIR"  # Ensure logs directory is created
    mkdir -p "$BACKUP_DIR"  # Ensure backup directory is created
    log "Directories created at $INSTALL_DIR."
}

# Function to backup the server directory
backup_server() {
    log "Creating backup of the server directory..."
    BACKUP_NAME="backup_$(date +'%Y_%m_%d_%H_%M_%S').zip"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    zip -r "$BACKUP_PATH" "$SATISFACTORY_SERVER_DIR" &>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log "Backup created: $BACKUP_PATH"
    else
        log "Backup failed."
    fi
}

# Function to install or update the Satisfactory server
install_or_update_satisfactory_server() {
    log "Installing or updating Satisfactory server..."

    LOGIN_COMMAND="+login anonymous"
    if [[ "$STEAM_USERNAME" != "your_steam_username" && "$STEAM_PASSWORD" != "your_steam_password" ]]; then
        LOGIN_COMMAND="+login $STEAM_USERNAME $STEAM_PASSWORD"
    fi

    log "Running SteamCMD to install/update the server..."
    {
        steamcmd +force_install_dir "$SATISFACTORY_SERVER_DIR" $LOGIN_COMMAND +app_update $SATISFACTORY_APPID validate +quit
    } &>> "$LOG_FILE"

    if [ $? -eq 0 ]; then
        log "Satisfactory server installation/update complete."
    else
        log "Failed to install/update Satisfactory server. Check the log for details."
    fi
}

# Function to set the maximum player count
set_maxplayer_count() {
    GAME_INI="$SATISFACTORY_SERVER_DIR/FactoryGame/Saved/Config/LinuxServer/Game.ini"

    log "Setting maximum player count to $MAX_PLAYER..."
    if [ ! -f "$GAME_INI" ]; then
        log "Creating Game.ini file."
        mkdir -p "$(dirname "$GAME_INI")"
        echo "[/Script/Engine.GameSession]" > "$GAME_INI"
        echo "MaxPlayers=$MAX_PLAYER" >> "$GAME_INI"
    else
        if grep -q "MaxPlayers=" "$GAME_INI"; then
            log "MaxPlayers already exists. Updating value."
            sed -i "s/MaxPlayers=.*/MaxPlayers=$MAX_PLAYER/" "$GAME_INI"
        else
            log "MaxPlayers entry not found. Adding to Game.ini."
            echo "[/Script/Engine.GameSession]" >> "$GAME_INI"
            echo "MaxPlayers=$MAX_PLAYER" >> "$GAME_INI"
        fi
    fi
    log "Maximum player count set successfully."
}

# Function to configure firewall rules
configure_firewall() {
    log "Configuring firewall rules with ufw..."
    sudo ufw allow $GAME_PORT/udp || { log "Failed to allow UDP game port $GAME_PORT."; }
    sudo ufw allow $QUERY_PORT/udp || { log "Failed to allow UDP query port $QUERY_PORT."; }
    sudo ufw allow $BEACON_PORT/tcp || { log "Failed to allow TCP beacon port $BEACON_PORT."; }
    log "Firewall rules configured successfully."
}

# Function to start the Satisfactory server

start_satisfactory_server() {
    log "Starting the Satisfactory server..."

    if [ -f "$SATISFACTORY_SERVER_DIR/FactoryServer.sh" ]; then
        log "Found start script. Launching server..."
        {
            cd "$SATISFACTORY_SERVER_DIR" || { log "Failed to change directory to $SATISFACTORY_SERVER_DIR"; exit 1; }
            ./FactoryServer.sh -log -Port=$GAME_PORT -QueryPort=$QUERY_PORT -BeaconPort=$BEACON_PORT > "$LOG_DIR/server_output.log" 2>&1 &
            if [ $? -eq 0 ]; then
                log "Satisfactory server started with ports: Game=$GAME_PORT, Query=$QUERY_PORT, Beacon=$BEACON_PORT."
            else
                log "Failed to start the server. Check $LOG_DIR/server_output.log for details."
            fi
        } &>> "$LOG_FILE"
    else
        log "Server start script not found! Check installation."
    fi
}


# Main script execution
log "Script execution started."

if [[ "$SKIP_MENU" == "no" ]]; then
    display_menu
else
    log "Menu skipped by user."
fi

install_steamcmd
create_directories
backup_server
install_or_update_satisfactory_server
set_maxplayer_count
configure_firewall
start_satisfactory_server

log "Satisfactory server setup completed."

