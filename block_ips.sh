#!/bin/bash

# GitHub URL to fetch IP list
GITHUB_URL="https://raw.githubusercontent.com/mohammad051/Abuse-Defender/refs/heads/main/ip"

# Define colors using ANSI codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to install iptables-persistent if not installed
install_iptables_persistent() {
  if ! dpkg -l | grep -q "iptables-persistent"; then
    echo -e "${YELLOW}Installing iptables-persistent...${NC}"
    sudo apt update
    sudo apt install -y iptables-persistent
    echo -e "${GREEN}iptables-persistent installed.${NC}"
  else
    echo -e "${GREEN}iptables-persistent is already installed.${NC}"
  fi
}

# Function to update blocked IPs from GitHub
update_blocked_ips() {
  echo -e "${YELLOW}Fetching IP list from GitHub...${NC}"
  ips=$(curl -s --connect-timeout 10 "$GITHUB_URL")

  if [[ -z "$ips" ]]; then
    echo -e "${RED}Failed to fetch IP list. Check the URL or network.${NC}"
    return 1
  fi

  echo -e "${YELLOW}Cleaning previous BLOCKED_IPS rules...${NC}"
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

  echo -e "${YELLOW}Saving iptables rules...${NC}"
  sudo netfilter-persistent save

  echo -e "${GREEN}Blocked IPs have been updated successfully.${NC}"
}

# Function to configure UFW to only allow specific ports
configure_ufw() {
  ALLOWED_PORTS=(22 443 2053 8443)
  echo -e "${YELLOW}Resetting and configuring UFW...${NC}"

  echo "y" | sudo ufw --force reset
  echo "y" | sudo ufw --force enable

  sudo ufw default deny incoming
  sudo ufw default deny outgoing

  for port in "${ALLOWED_PORTS[@]}"; do
    sudo ufw allow in "$port"
    sudo ufw allow out "$port"
    echo -e "${GREEN}Port $port is now open.${NC}"
  done

  echo -e "${GREEN}UFW configuration complete. Only ports ${ALLOWED_PORTS[*]} are allowed.${NC}"
}

# Function to open all ports (for debugging)
open_all_ports() {
  echo -e "${YELLOW}Opening all ports...${NC}"
  echo "y" | sudo ufw --force reset
  echo "y" | sudo ufw --force enable
  sudo ufw default allow incoming
  sudo ufw default allow outgoing
  echo -e "${GREEN}All ports are now open.${NC}"
}

# Function to allow user-defined ports
allow_user_ports() {
  echo -e "${YELLOW}Enter ports to allow (space separated):${NC}"
  read -p "Ports: " -a user_ports

  for port in "${user_ports[@]}"; do
    if [[ "$port" =~ ^[0-9]+$ ]]; then
      sudo ufw allow in "$port"
      sudo ufw allow out "$port"
      echo -e "${GREEN}Port $port is now open.${NC}"
    else
      echo -e "${RED}Invalid port: $port${NC}"
    fi
  done
}

# Function to remove all iptables rules set by the script
remove_iptables_rules() {
  echo -e "${YELLOW}Removing iptables rules created by this script...${NC}"
  if sudo iptables -L BLOCKED_IPS -n >/dev/null 2>&1; then
    sudo iptables -D INPUT -j BLOCKED_IPS 2>/dev/null
    sudo iptables -D OUTPUT -j BLOCKED_IPS 2>/dev/null
    sudo iptables -F BLOCKED_IPS 2>/dev/null
    sudo iptables -X BLOCKED_IPS 2>/dev/null
    echo -e "${GREEN}All BLOCKED_IPS rules removed.${NC}"
  else
    echo -e "${CYAN}No BLOCKED_IPS rules found.${NC}"
  fi
}

# Main menu
show_menu() {
  clear
  echo -e "${RED}+======================================================================+${NC}"
  echo -e "${RED}                          AbuseDefender                               ${NC}"
  echo -e "${RED}+======================================================================+${NC}"
  echo -e "${YELLOW}1. Apply iptables rules and block GitHub IPs${NC}"
  echo -e "${YELLOW}2. Configure UFW (allow only 22, 443, 2053, 8443)${NC}"
  echo -e "${YELLOW}3. Open all ports (allow all)${NC}"
  echo -e "${YELLOW}4. Allow custom ports manually${NC}"
  echo -e "${YELLOW}5. Remove all iptables blocking rules${NC}"
  echo -e "${YELLOW}6. Exit${NC}"
  echo -e "${RED}+======================================================================+${NC}"
  read -p "$(echo -e "${YELLOW}Your choice: ${NC}")" choice

  case $choice in
    1)
      install_iptables_persistent
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
      echo -e "${GREEN}Goodbye!${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice. Try again.${NC}"
      sleep 2
      show_menu
      ;;
  esac
}

# Start script
show_menu
