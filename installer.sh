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
SCRIPT_VERSION="1.0.0"  # Set your current script version
GITHUB_REPO="https://raw.githubusercontent.com/robin1991199/satisfactoryserver-auto-install-/refs/heads/main/installer.sh"  # Replace with your GitHub username/repository

# Function to log messages
log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to check for script updates
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
            curl -sL "https://github.com/$GITHUB_REPO/raw/$latest_version/installer.sh" -o "$0"
            chmod +x "$0"
            log "Script updated successfully to version $latest_version."
            exec "$0"  # This restarts the script after the update.
        else
            log "Update skipped by the user."
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

# Main execution

# Optionally display a menu
if [ "$SKIP_MENU" == "no" ]; then
    display_menu
fi

# Check for script update based on user input
check_script_update

# Proceed with the installation if not skipped
update_system
install_steamcmd
create_directories
install_or_update_satisfactory_server
set_maxplayer_count
start_server
