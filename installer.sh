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
BACKUP_DIR="$INSTALL_DIR/backups"
SCRIPT_VERSION="1.0.0"  # Current version of the script
GITHUB_REPO="your_github_username/your_repository"  # Replace with your actual GitHub repo

# Function to log messages
log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to create a full backup of the server files
create_backup() {
    local backup_name="backup_$(date +'%Y%m%d%H%M%S').tar.gz"
    log "Creating full backup of the server files..."

    # Create the backups directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Archive the server directory
    tar -czf "$BACKUP_DIR/$backup_name" -C "$INSTALL_DIR" satisfactory_server || {
        log "Failed to create backup."
        return 1
    }

    log "Backup created successfully: $BACKUP_DIR/$backup_name"
}

# Function to check if the script has an update
check_script_update() {
    log "Checking for script updates..."

    # Fetch the latest release version from the GitHub API
    latest_version=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | jq -r '.tag_name')

    if [ "$latest_version" != "$SCRIPT_VERSION" ]; then
        log "An update is available! Latest version: $latest_version. Current version: $SCRIPT_VERSION."
        read -p "Do you want to update the script now? (y/n): " update_choice
        if [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
            log "Updating the script to version $latest_version..."
            # Download the latest version of the script from GitHub
            curl -sL "https://github.com/$GITHUB_REPO/raw/$latest_version/setup.sh" -o "$0"
            chmod +x "$0"
            log "Script updated successfully to version $latest_version."
            exit 0  # Exit to run the updated script immediately
        fi
    else
        log "No updates available. Current version is up to date."
    fi
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

# Function to create necessary directories
create_directories() {
    log "Creating necessary directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$SATISFACTORY_SERVER_DIR"
    mkdir -p "$LOG_FILE"
    log "Directories created successfully."
}

# Function to install or update the Satisfactory server
install_or_update_satisfactory_server() {
    log "Installing or updating Satisfactory server..."
    if [ ! -d "$SATISFACTORY_SERVER_DIR" ]; then
        steamcmd +login "$STEAM_USERNAME" "$STEAM_PASSWORD" +force_install_dir "$SATISFACTORY_SERVER_DIR" +app_update $SATISFACTORY_APPID validate +quit
        log "Satisfactory server installed."
    else
        steamcmd +login "$STEAM_USERNAME" "$STEAM_PASSWORD" +force_install_dir "$SATISFACTORY_SERVER_DIR" +app_update $SATISFACTORY_APPID validate +quit
        log "Satisfactory server updated."
    fi
}

# Function to set the maximum player count
set_maxplayer_count() {
    log "Setting maximum player count..."
    GAME_INI="$SATISFACTORY_SERVER_DIR/FactoryGame/Saved/Config/LinuxServer/Game.ini"
    
    if [ -f "$GAME_INI" ]; then
        grep -q "MaxPlayers" "$GAME_INI" || {
            echo "[SystemSettings]" >> "$GAME_INI"
            echo "MaxPlayers=$MAX_PLAYER" >> "$GAME_INI"
        }
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

# Check for script update
check_script_update

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
