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

# Function to update blocked IPs and apply changes
update_blocked_ips() {
  echo -e "${YELLOW}Fetching IP list from GitHub...${NC}"
  ips=$(curl -s --connect-timeout 10 "$GITHUB_URL")
  if [[ -z "$ips" ]]; then
    echo -e "${RED}Error: Failed to fetch IP list from GitHub. Please check the URL or your network connection.${NC}"
    return 1
  fi

  # Check for existing BLOCKED_IPS chain and remove it
  echo -e "${YELLOW}Removing old blocking rules...${NC}"
  if sudo iptables -L BLOCKED_IPS -n >/dev/null 2>&1; then
    sudo iptables -D INPUT -j BLOCKED_IPS 2>/dev/null
    sudo iptables -D OUTPUT -j BLOCKED_IPS 2>/dev/null
    sudo iptables -F BLOCKED_IPS 2>/dev/null
    sudo iptables -X BLOCKED_IPS 2>/dev/null
  fi

  # Create a new chain for blocking IPs
  sudo iptables -N BLOCKED_IPS

  # Remove duplicates and block each unique IP
  unique_ips=$(echo "$ips" | tr -d '\r' | xargs -n1 | sort -u)
  while IFS= read -r ip; do
    if [[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}(/[0-9]{1,2})?$ ]]; then
      sudo iptables -A BLOCKED_IPS -s "$ip" -j DROP
      sudo iptables -A BLOCKED_IPS -d "$ip" -j DROP
    fi
  done <<< "$unique_ips"

  # Apply the new chain to INPUT and OUTPUT
  sudo iptables -A INPUT -j BLOCKED_IPS
  sudo iptables -A OUTPUT -j BLOCKED_IPS

  echo -e "${GREEN}All IPs fetched from GitHub were successfully blocked.${NC}"
}

# Function to configure UFW and open specific ports
configure_ufw() {
  # List of ports to keep open
  ALLOWED_PORTS=(22 443 2053 8443 80)

  echo -e "${YELLOW}Configuring UFW to allow specific ports...${NC}"

  # Reset UFW to default settings
  echo "y" | sudo ufw --force reset

  # Enable UFW
  echo "y" | sudo ufw --force enable

  # Set default policies
  sudo ufw default deny incoming
  sudo ufw default deny outgoing

  # Allow specified ports for both incoming and outgoing traffic
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

  # Reset UFW to default settings
  echo "y" | sudo ufw --force reset

  # Enable UFW
  echo "y" | sudo ufw --force enable

  # Set policies to allow all traffic
  sudo ufw default allow incoming
  sudo ufw default allow outgoing

  echo -e "${GREEN}All ports are now open.${NC}"
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
  echo -e "${YELLOW}4. Exit${NC}"
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

# Execute menu
show_menu
