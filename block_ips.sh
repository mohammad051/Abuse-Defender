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

# Function to configure UFW and open specific ports
configure_ufw() {
  ALLOWED_PORTS=(22 443 2053 8443 80)
  echo -e "${YELLOW}Configuring UFW to allow specific ports...${NC}"

  echo "y" | sudo ufw --force reset
  echo "y" | sudo ufw --force enable

  sudo ufw default deny incoming
  sudo ufw default deny outgoing

  for port in "${ALLOWED_PORTS[@]}"; do
    sudo ufw allow in "$port"
    sudo ufw allow out "$port"
    echo -e "${GREEN}Port $port has been opened for both incoming and outgoing traffic.${NC}"
  done

  echo -e "${GREEN}All ports are closed except the allowed ones: ${ALLOWED_PORTS[*]}.${NC}"
}

# Function to open all ports
open_all_ports() {
  echo -e "${YELLOW}Opening all ports...${NC}"
  echo "y" | sudo ufw --force reset
  echo "y" | sudo ufw --force enable
  sudo ufw default allow incoming
  sudo ufw default allow outgoing
  echo -e "${GREEN}All ports are now open.${NC}"
}

# Function to manually allow user-specified ports
allow_user_ports() {
  echo -e "${YELLOW}Enter the ports you want to allow (separated by space): ${NC}"
  read -p "Ports: " -a user_ports

  for port in "${user_ports[@]}"; do
    if [[ "$port" =~ ^[0-9]+$ ]]; then
      sudo ufw allow in "$port"
      sudo ufw allow out "$port"
      echo -e "${GREEN}Port $port has been opened for both incoming and outgoing traffic.${NC}"
    else
      echo -e "${RED}Invalid port: $port. Please enter numeric values only.${NC}"
    fi
  done
}

# Function to remove all iptables rules set by the script
remove_iptables_rules() {
  echo -e "${YELLOW}Removing all iptables rules set by the script...${NC}"
  if sudo iptables -L BLOCKED_IPS -n >/dev/null 2>&1; then
    sudo iptables -D INPUT -j BLOCKED_IPS 2>/dev/null
    sudo iptables -D OUTPUT -j BLOCKED_IPS 2>/dev/null
    sudo iptables -F BLOCKED_IPS 2>/dev/null
    sudo iptables -X BLOCKED_IPS 2>/dev/null
    echo -e "${GREEN}All iptables rules set by the script have been removed.${NC}"
  else
    echo -e "${CYAN}No iptables rules found to remove.${NC}"
  fi
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

# Directly show the main menu after download from GitHub
show_menu
