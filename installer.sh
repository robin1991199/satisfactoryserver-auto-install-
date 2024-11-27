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
SERVICE_NAME="satisfactory_server"
MAX_PLAYER="4"
GAME_PORT=7777
QUERY_PORT=15777
BEACON_PORT=15000
GITHUB_RAW_URL="https://github.com/robin1991199/satisfactoryserver-auto-install-/raw/refs/heads/main/installer.sh"
BACKUP_DIR="$HOME/.satisfactory_backups"
SAVE_DIR="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/526870/pfx/drive_c/users/steamuser/AppData/Local/FactoryGame"

# Function to log messages
log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to update the script from GitHub
update_script() {
    log "Checking for updates..."
    TEMP_SCRIPT="$(mktemp)"
    if curl -fsSL "$GITHUB_RAW_URL" -o "$TEMP_SCRIPT"; then
        log "Latest version downloaded successfully."
        cp "$0" "${0}.bak" || { log "Failed to create a backup."; exit 1; }
        mv "$TEMP_SCRIPT" "$0" && chmod +x "$0"
        log "Script updated successfully. Exiting..."
        exit 0
    else
        log "Failed to download the latest version."
    fi
}

# Function to create a systemd service file
create_systemd_service() {
    log "Setting up the server to run on boot..."
    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Satisfactory Server
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$SATISFACTORY_SERVER_DIR
ExecStart=$SATISFACTORY_SERVER_DIR/FactoryServer.sh -log -Port=$GAME_PORT -QueryPort=$QUERY_PORT -BeaconPort=$BEACON_PORT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    log "Service created at $SERVICE_FILE. The server is now configured to run on boot."
}

# Function to display the menu
display_menu() {
    clear
    log "Displaying setup menu."
    echo ""
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
}

# Function to update and upgrade the system
update_system() {
    log "Updating and upgrading the system..."
    sudo apt-get update && sudo apt-get upgrade -y
}

# Function to install SteamCMD
install_steamcmd() {
    log "Installing SteamCMD..."
    sudo apt-get install steamcmd -y
}

# Function to create installation directories
create_directories() {
    log "Creating installation directories..."
    mkdir -p "$SATISFACTORY_SERVER_DIR" "$INSTALL_DIR/logs" "$BACKUP_DIR"
}

# Function to install/update the Satisfactory server
install_or_update_satisfactory_server() {
    log "Installing or updating the Satisfactory server..."
    /usr/games/steamcmd +force_install_dir "$SATISFACTORY_SERVER_DIR" +login anonymous +app_update $SATISFACTORY_APPID validate +quit
}

# Function to configure firewall
configure_firewall() {
    log "Configuring firewall..."
    sudo ufw allow $GAME_PORT/udp
    sudo ufw allow $QUERY_PORT/udp
    sudo ufw allow $BEACON_PORT/tcp
}

# Function to create a backup
create_backup() {
    log "Creating backup of the server and save files..."
    TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
    BACKUP_FILE="$BACKUP_DIR/satisfactory_backup_$TIMESTAMP.zip"

    if [ -d "$SATISFACTORY_SERVER_DIR" ] && [ -d "$SAVE_DIR" ]; then
        zip -r "$BACKUP_FILE" "$SATISFACTORY_SERVER_DIR" "$SAVE_DIR" &>> "$LOG_FILE"
        log "Backup created at $BACKUP_FILE."
    else
        log "Failed to create backup. One or more directories do not exist."
    fi
}

# Function to start the server
start_satisfactory_server() {
    log "Starting the Satisfactory server..."
    nohup "$SATISFACTORY_SERVER_DIR/FactoryServer.sh" -log -Port=$GAME_PORT -QueryPort=$QUERY_PORT -BeaconPort=$BEACON_PORT > "$INSTALL_DIR/logs/server_output.log" 2>&1 &
}

# Main script execution
log "Script execution started."

if [[ "$1" == "--update" ]]; then
    update_script "$@"
fi

if [[ "$SKIP_MENU" == "no" ]]; then
    display_menu
fi

update_system
install_steamcmd
create_directories
install_or_update_satisfactory_server
configure_firewall
create_backup
start_satisfactory_server
create_systemd_service

log "Setup completed. The server will now run on boot."
