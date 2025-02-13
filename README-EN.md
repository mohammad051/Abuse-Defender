# ip-blocker

This script is designed to block IPs using `iptables` from a list fetched from GitHub. It also opens specific ports for allowed communications and sets up a cron job for automatic updates.

## Features
- Fetching a list of IPs from GitHub
- Blocking the fetched IPs using `iptables`
- Opening specific ports for allowed communications
- Setting up a cron job for automatic updates every 3 days

## Prerequisites
- Linux operating system (Ubuntu is recommended)
- Root or sudo access to execute `iptables` and `ufw` commands
- `curl` and `ufw` must be installed on the system

## Installation

1. **Download the script from GitHub**
   To download the script from GitHub, use the following command:
   ```bash
   bash <(curl -Ls https://raw.githubusercontent.com/mohammad051/Abuse-Defender/main/block_ips.sh)
   ```

2. **Grant execution permissions to the script**
   After downloading the script, give it executable permissions:
   ```bash
   chmod +x block_ips.sh
   ```

3. **Run the script**
   Now, you can run the script with the following command:
   ```bash
   sudo ./block_ips.sh
   ```

4. **Set up the cron job**
   The cron job will automatically be set up to run the script every 3 days. This will update the IP list and apply the new rules.

## Usage

- The script automatically fetches the blocked IPs from GitHub and blocks them using `iptables`.
- After running the script, the necessary ports (22, 2053, 443, 8443, 80) will be opened.
- A cron job will be set up to run the script every 3 days to automatically update the IP list.

## Uninstall

If you wish to remove the script and restore the settings, you can use the following commands to flush `iptables` rules and disable `ufw`:
```bash
sudo iptables -F
sudo ufw disable
```

## Attention

- Make sure to run this script only on systems you trust the security of.
- The script requires internet access to fetch the updated IP list from GitHub.
