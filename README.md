# IP Block Script

This script automatically fetches a list of IPs from GitHub, blocks them using `iptables`, and opens specific ports using `ufw`.

## Table of Contents
1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Cron Job Setup (Optional)](#cron-job-setup-optional)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

---

## Features
- Fetches a list of IPs from a GitHub repository.
- Blocks the fetched IPs using `iptables`.
- Opens predefined ports (e.g., 22, 80, 443) using `ufw`.
- Automatically updates the blocked IPs every 3 days (if cron job is set up).

---

## Prerequisites
Before running the script, ensure the following tools are installed on your system:
- `curl` or `wget`: To download the script.
- `iptables`: For managing firewall rules.
- `ufw`: For managing open ports.

You can install these tools using the following commands:

#### For Ubuntu/Debian:
```bash
sudo apt update
sudo apt install curl iptables ufw -y

Installation
1. Download the Script
Download the script directly from the GitHub repository using one of the following commands:

Using wget:
