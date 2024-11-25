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
LOG_FILE="$INSTALL_DIR/satisfactory_install.log"
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
    clear
    log "Displaying setup menu to the user."
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
    LOG_FILE="$INSTALL_DIR/satisfactory_install.log"

    printf "%-30s : %s\n" "Max Player Count" "[default: $MAX_PLAYER]"
    read -p "Enter Max Player Count: " input_max_player
    MAX_PLAYER="${input_max_player:-$MAX_PLAYER}"

    if [ "$MAX_PLAYER" -gt 25 ]; then
        echo ""
        log "Warning: You have selected a player count greater than 25. This may cause high levels of lag, especially on less powerful machines. It is not recommended."
        echo "Warning: Allowing more than 25 players can result in lag. It is highly recommended to keep the player count below 25."
        
        # Ask the user if they want to proceed with high player count or lower it
        read -p "Do you wish to proceed with this player count? (y/n): " choice
        if [[ "$choice" == "n" || "$choice" == "N" ]]; then
            read -p "Enter a new Max Player Count (recommended: 25 or less): " new_max_player
            MAX_PLAYER="${new_max_player:-$MAX_PLAYER}"
            log "User chose to lower the player count to $MAX_PLAYER."
        else
            log "User chose to proceed with the high player count of $MAX_PLAYER."
        fi
    fi

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

# Function to update and upgrade the system
update_system() {
    log "Updating and upgrading the system..."
    sudo apt-get update && sudo apt-get upgrade -y || log "System update failed."
    log "System update and upgrade complete."
}

# Function to install SteamCMD
install_steamcmd() {
    log "Installing SteamCMD..."
    sudo add-apt-repository multiverse -y || { log "Failed to add multiverse repository."; exit 1; }
    sudo dpkg --add-architecture i386
    sudo apt-get update || { log "Failed to update package lists."; exit 1; }
    sudo apt-get install steamcmd -y || { log "Failed to install SteamCMD."; exit 1; }
    log "SteamCMD installed successfully."
}

# Function to create the installation directory
create_directories() {
    log "Creating installation directories..."
    mkdir -p "$SATISFACTORY_SERVER_DIR"
    mkdir -p "$INSTALL_DIR/logs"
    log "Directories created at $INSTALL_DIR."
}

# Function to install or update the Satisfactory server
install_or_update_satisfactory_server() {
    log "Installing or updating Satisfactory server..."
    LOGIN_COMMAND="+login anonymous"
    if [[ "$STEAM_USERNAME" != "your_steam_username" && "$STEAM_PASSWORD" != "your_steam_password" ]]; then
        LOGIN_COMMAND="+login $STEAM_USERNAME $STEAM_PASSWORD"
    fi

    {
        echo "Running SteamCMD..."
        /usr/games/steamcmd +force_install_dir "$SATISFACTORY_SERVER_DIR" $LOGIN_COMMAND +app_update $SATISFACTORY_APPID validate +quit
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
            sed -i "s/MaxPlayers=.*/MaxPlayers=$MAX_PLAYER/" "$GAME_INI"
        else
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
        {
            cd "$SATISFACTORY_SERVER_DIR"
            nohup ./FactoryServer.sh -log -Port=$GAME_PORT -QueryPort=$QUERY_PORT -BeaconPort=$BEACON_PORT > "$INSTALL_DIR/logs/server_output.log" 2>&1 &
            log "Satisfactory server started with ports: Game=$GAME_PORT, Query=$QUERY_PORT, Beacon=$BEACON_PORT."
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
    log "Menu skipped. Using default configuration: Steam Username=$STEAM_USERNAME, Directory=$INSTALL_DIR, Max Players=$MAX_PLAYER, Ports=($GAME_PORT, $QUERY_PORT, $BEACON_PORT)."
fi

update_system
install_steamcmd
create_directories
install_or_update_satisfactory_server
set_maxplayer_count
configure_firewall
start_satisfactory_server

log "Satisfactory server setup completed."
