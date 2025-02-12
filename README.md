IP Block Script
This script automatically fetches a list of IPs from GitHub, blocks them using iptables, and opens specific ports using ufw.

Table of Contents
Features
Prerequisites
Installation
Usage
Cron Job Setup (Optional)
Verification
Troubleshooting
Features
Fetches a list of IPs from a GitHub repository.
Blocks the fetched IPs using iptables.
Opens predefined ports using ufw.
Automatically updates the blocked IPs every 3 days (if cron job is set up).
Prerequisites
Before running the script, ensure the following tools are installed on your system:

curl or wget: To download the script.
iptables: For managing firewall rules.
ufw: For managing open ports.
You can install these tools using the following commands:

For Ubuntu/Debian:
bash
Copy
1
2
sudo apt update
sudo apt install curl iptables ufw -y
For CentOS/RHEL:
bash
Copy
1
2
sudo yum update
sudo yum install curl iptables ufw -y
Installation
1. Download the Script
Download the script directly from the GitHub repository using one of the following commands:

Using wget:
bash
Copy
1
wget https://raw.githubusercontent.com/mohammad051/ipblock/refs/heads/main/block_ips.sh -O block_ips.sh
Using curl:
bash
Copy
1
curl -o block_ips.sh https://raw.githubusercontent.com/mohammad051/ipblock/refs/heads/main/block_ips.sh
2. Make the Script Executable
Grant execution permissions to the script:

bash
Copy
1
chmod +x block_ips.sh
Usage
Run the Script
Execute the script with root privileges:

bash
Copy
1
sudo ./block_ips.sh
The script will:

Fetch the list of IPs from the GitHub repository.
Block the IPs using iptables.
Open predefined ports (e.g., 22, 80, 443) using ufw.
Cron Job Setup (Optional)
To automate the execution of the script every 3 days, you can set up a cron job.

Add the Script to Cron
Run the following command to add the script to the cron jobs:

bash
Copy
1
echo "0 0 */3 * * $(pwd)/block_ips.sh" | sudo tee -a /etc/crontab
This will execute the script at midnight every 3 days.

Verify the Cron Job
To verify that the cron job has been added successfully, view the cron jobs:

bash
Copy
1
sudo cat /etc/crontab
Verification
Check Blocked IPs
To verify that the IPs have been blocked, use the following command:

bash
Copy
1
sudo iptables -L -n
Look for the BLOCKED_IPS chain in the output.

Check Open Ports
To verify that the predefined ports have been opened, use the following command:

bash
Copy
1
sudo ufw status
You should see the list of open ports (e.g., 22, 80, 443).

Troubleshooting
1. Script Not Executing
If the script does not execute, ensure that:

You have granted execution permissions using chmod +x block_ips.sh.
You are running the script with sudo.
2. IPs Not Blocked
If the IPs are not blocked:

Check the GitHub URL (https://raw.githubusercontent.com/mohammad051/ipblock/refs/heads/main/ip) to ensure it is accessible.
Verify that iptables is installed and working correctly.
3. Ports Not Open
If the ports are not open:

Ensure that ufw is installed and enabled.
Check the output of sudo ufw status to confirm the ports are listed.
4. Cron Job Not Running
If the cron job is not running:

Verify that the cron service is active:
bash
Copy
1
sudo systemctl status cron
Check the cron logs for errors:
bash
Copy
1
sudo grep CRON /var/log/syslog
Support
If you encounter any issues or have questions, feel free to open an issue in this repository or contact the maintainer.

License
This project is licensed under the MIT License. See the LICENSE file for details.
