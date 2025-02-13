#!/bin/bash

# GitHub URL to fetch IP list
GITHUB_URL="https://raw.githubusercontent.com/mohammad051/Abuse-Defender/refs/heads/main/ip"

# Define colors using ANSI codes
RED='\033[0;31m'       # Red
GREEN='\033[0;32m'     # Green
YELLOW='\033[0;33m'    # Yellow
BLUE='\033[0;34m'      # Blue
CYAN='\033[0;36m'      # Cyan
NC='\033[0m'           # No Color (Reset)

# Path to install the script
INSTALL_PATH="/usr/local/bin/iplock"

# Self-installation function
self_install() {
  echo -e "${YELLOW}Starting installation...${NC}"

  # Create temporary directory to download the script
  TEMP_DIR="/tmp/iplock_install"
  mkdir -p "$TEMP_DIR"

  # Download the script to the temporary directory
  echo -e "${YELLOW}Downloading script...${NC}"
  curl -Ls "$0" -o "$TEMP_DIR/iplock.sh"
  
  # Check if the download was successful
  if [[ ! -f "$TEMP_DIR/iplock.sh" ]]; then
    echo -e "${RED}Failed to download the script. Please check your internet connection or the URL.${NC}"
    exit 1
  else
    echo -e "${GREEN}Script downloaded successfully!${NC}"
  fi

  # Copy the script to the installation path
  echo -e "${YELLOW}Copying script to $INSTALL_PATH...${NC}"
  sudo cp "$TEMP_DIR/iplock.sh" "$INSTALL_PATH"
  
  # Check if the copy was successful
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Failed to copy the script. Please check permissions for /usr/local/bin.${NC}"
    exit 1
  fi

  # Make the script executable
  echo -e "${YELLOW}Making the script executable...${NC}"
  sudo chmod +x "$INSTALL_PATH"

  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Installation complete. You can now run the script using the command: iplock${NC}"
    exit 0
  else
    echo -e "${RED}Failed to make the script executable. Please check permissions or the installation path.${NC}"
    exit 1
  fi
}

# Function to update blocked IPs and apply changes
update_blocked_ips() {
  echo -e "${YELLOW}Fetching IP list from GitHub...${NC}"
  ips=$(curl -s --connect-timeout 10 "$GITHUB_URL")
  if [[ -z "$ips" ]]; then
    echo -e "${RED}Error: Failed to fetch IP list from GitHub. Please check the URL or your network connection.${NC}"
    return 1
  fi

  echo -e "${YELLOW}Removing old blocking rules...${NC}"
  if sudo iptables -L BLOCKED_IPS -n >/dev/null 2>&1; then
    sudo iptables -D INPUT -j BLOCKED_IPS 2>/dev/null
    sudo iptables -D OUTPUT -j BLOCKED_IPS 2>/dev/null
    sudo iptables -F BLOCKED_IPS 2>/dev/null
    sudo iptables -X BLOCKED_IPS 2>/dev/null
  fi

  sudo iptables -N BLOCKED_IPS

  unique_ips=$(echo "$ips" | tr -d '\r' | xargs -n1 | sort -u)
  while IFS= read -r ip; do
    if [[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}(/[0-9]{1,2})?$ ]]; then
      sudo iptables -A BLOCKED_IPS -s "$ip" -j DROP
      sudo iptables -A BLOCKED_IPS -d "$ip" -j DROP
    fi
  done <<< "$unique_ips"

  sudo iptables -A INPUT -j BLOCKED_IPS
  sudo iptables -A OUTPUT -j BLOCKED_IPS

  echo -e "${GREEN}All IPs fetched from GitHub were successfully blocked.${NC}"
}

# Main menu
show_menu() {
  clear
  echo -e "${RED}+======================================================================+${NC}"
  echo -e "${RED}                          AbuseDefender                             ${NC}"
  echo -e "${RED}+======================================================================+${NC}"
  echo -e "${YELLOW}1. Apply iptables rules and schedule cron job${NC}"
  echo -e "${YELLOW}2. Configure UFW and allow specific ports (22, 443, 2053, 8443, 80)${NC}"
  echo -e "${YELLOW}3. Open all ports${NC}"
  echo -e "${YELLOW}4. Allow custom ports manually${NC}"
  echo -e "${YELLOW}5. Remove all iptables rules set by this script${NC}"
  echo -e "${YELLOW}6. Exit${NC}"
  echo -e "${RED}+======================================================================+${NC}"
  read -p "$(echo -e "${YELLOW}Your choice: ${NC}")" choice

  case $choice in
    1)
      update_blocked_ips
      ;;
    2)
      configure_ufw
      ;;
    3)
      open_all_ports
      ;;
    4)
      allow_user_ports
      ;;
    5)
      remove_iptables_rules
      ;;
    6)
      echo -e "${GREEN}Exiting AbuseDefender...${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid option! Please try again.${NC}"
      sleep 2
      show_menu
      ;;
  esac
}

# Check if the script is installed
if [[ "$0" != "$INSTALL_PATH" ]]; then
  echo -e "${YELLOW}It looks like the script is not installed.${NC}"
  echo -e "${CYAN}Please choose option 1 to install the script.${NC}"
  echo -e "${RED}+======================================================================+${NC}"
  echo -e "${RED}                          INSTALLATION MENU                          ${NC}"
  echo -e "${RED}+======================================================================+${NC}"
  echo -e "${YELLOW}1. Install the script${NC}"
  echo -e "${YELLOW}2. Exit${NC}"
  echo -e "${RED}+======================================================================+${NC}"
  read -p "$(echo -e "${YELLOW}Your choice: ${NC}")" choice

  case $choice in
    1)
      self_install
      ;;
    2)
      echo -e "${GREEN}Exiting...${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid option! Please try again.${NC}"
      ;;
  esac
else
  # If already installed, show the main menu
  show_menu
fi
