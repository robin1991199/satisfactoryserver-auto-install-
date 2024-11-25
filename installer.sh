#!/bin/bash
# start config place 
# Steam credentials
STEAM_USERNAME="your_steam_username"  # Change if necessary
STEAM_PASSWORD="your_steam_password"  # Change if necessary

# Choose the installation directory (where the script is located)
INSTALL_DIR="$(dirname "$(realpath "$0")")/satisfactory_server_installation"
STEAMCMD_DIR="$INSTALL_DIR/steamcmd"
SATISFACTORY_SERVER_DIR="$INSTALL_DIR/satisfactory_server"
SATISFACTORY_APPID=1690800
LOG_FILE="$INSTALL_DIR/satisfactory_install.log"
START_SERVER_SCRIPT="$SATISFACTORY_SERVER_DIR/start_server.sh"

# Server configuration
MAX_PLAYER="4"
PORT=7777  # Change this to your desired port

# stop config place 



# Function to update and upgrade the system
update_system() {
    echo "Updating and upgrading the system..."
    sudo apt-get update && sudo apt-get upgrade -y
    echo "System update and upgrade complete."
}

# Function to install SteamCMD
install_steamcmd() {
    echo "Installing SteamCMD..."
    sudo add-apt-repository multiverse -y || { echo "Failed to add multiverse repository."; exit 1; }
    sudo dpkg --add-architecture i386
    sudo apt-get update || { echo "Failed to update package lists."; exit 1; }
    sudo apt-get install steamcmd -y || { echo "Failed to install SteamCMD."; exit 1; }
    echo "SteamCMD installed successfully."
}

# Function to create the installation directory
create_directories() {
    echo "Creating installation directories..."
    mkdir -p "$SATISFACTORY_SERVER_DIR"
    mkdir -p "$INSTALL_DIR/logs"
    echo "Directories created at $INSTALL_DIR"
}

# Function to determine login type (anonymous or using credentials)
get_login_command() {
    if [[ "$STEAM_USERNAME" == "your_steam_username" && "$STEAM_PASSWORD" == "your_steam_password" ]]; then
        echo "+login anonymous"
    else
        echo "+login $STEAM_USERNAME $STEAM_PASSWORD"
    fi
}

# Function to install or update the Satisfactory server
install_or_update_satisfactory_server() {
    echo "Installing or updating Satisfactory server..."

    # Get the appropriate login command (anonymous or credentials-based)
    LOGIN_COMMAND=$(get_login_command)

    # Run SteamCMD with the chosen login to install or update the Satisfactory server
    {
        echo "Running SteamCMD..."
        /usr/games/steamcmd +force_install_dir "$SATISFACTORY_SERVER_DIR" $LOGIN_COMMAND +app_update $SATISFACTORY_APPID validate +quit
    } &> "$LOG_FILE"

    if [ $? -eq 0 ]; then
        echo "Satisfactory server installation/update complete."
    else
        echo "Failed to install/update Satisfactory server. Check the log for details: $LOG_FILE"
    fi
}

# Function to set the maximum player count
set_maxplayer_count() {
    GAME_INI="$SATISFACTORY_SERVER_DIR/FactoryGame/Saved/Config/LinuxServer/Game.ini"

    if [ ! -f "$GAME_INI" ]; then
        echo "Creating Game.ini file..."
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
}

# Function to start the Satisfactory server
start_satisfactory_server() {
    echo "Starting the Satisfactory server..."

    if [ -f "$SATISFACTORY_SERVER_DIR/FactoryServer.sh" ]; then
        # Run the server start script with the specified port
        {
            cd "$SATISFACTORY_SERVER_DIR"
            nohup ./FactoryServer.sh -log -port=$PORT > "$INSTALL_DIR/logs/server_output.log" 2>&1 &
            echo "Satisfactory server started on port $PORT."
        } &>> "$LOG_FILE"
    else
        echo "Server start script not found! Check installation. Log: $LOG_FILE"
    fi
}

# Main script execution
echo "Starting the Satisfactory server setup process..."
update_system
install_steamcmd
create_directories
install_or_update_satisfactory_server
set_maxplayer_count
start_satisfactory_server
echo "Setup script completed."
