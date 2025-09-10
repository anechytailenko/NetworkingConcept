# Lesson 1.1-1.2: Multipass and Tools Installation, Basic Shell Commands

## Lesson Goals
This lesson focuses on setting up your working environment for the course. You will install Multipass for virtual machines (VMs), configure SSH and VSCode integration, practice basic shell commands, write a simple script for tool installation, and install networking tools like Wireshark (on host) and nmap, ncat, socat, net-tools (in VM).

**Definitions**  
- **Host machine/host OS**: Your laptop and its operating system where Multipass runs.  
- **Virtual machine (VM)**: An isolated software-emulated OS on your host for experiments.  
- **Guest OS**: The OS inside the VM (Ubuntu 24.04 "Noble" here).  

**Grading** (Total: 2 points)  
Submit screenshots/outputs (e.g., VM info, script run, tool versions) via course platform.  
- **0.75 points**: VM `noble` launched/configured; basic commands (`cd`, `pwd`, `ls`) run in VM shell; host folder mounted to VM.  
- **0.25 points**: SSH config for `ssh noble`; VSCode with Remote-SSH connected to `noble`.  
- **0.25 points**: Functional script for package checks/installation with output.  
- **0.25 points**: `socat`, `nmap`, `net-tools` installed in VM.  
- **0.25 points**: Wireshark installed on host.  
- **0.25 points**: VM `noble_new` created; Multipass commands practiced.  

**Resources**  
- Setup documents: Multipass Setup for Windows.docx, Multipass Setup for Ubuntu.docx, Multipass Setup for MacOS.docx.  
- Online: Multipass docs (https://multipass.run/docs), VSCode Remote-SSH extension.  

**Estimated Time**: 2-3 hours.

## Knowledge Base

### Virtual Machines (VMs)
VMs provide isolation for network experiments. Benefits: Test configs safely; emulate multiple devices; consistent setups. Use Multipass for easy Ubuntu VM management.

### Multipass Commands
- `multipass version`: Check install.  
- `multipass launch --name noble --disk 5GiB --mem 1GiB --cpus 1`: Create VM.  
- `multipass info noble`: View details (e.g., IP).  
- `multipass shell noble`: Enter shell.  
- `multipass exec noble -- <command>`: Run remote command.  
- `multipass stop/start noble`: Manage state.  
- `multipass mount /path/on/host noble:/path/in/vm`: Share folders.  
- `multipass delete --purge noble`: Cleanup.  

### SSH Configuration
Edit `~/.ssh/config`:  
```
Host noble
    HostName <VM_IP>
    User ubuntu
```
Test: `ssh noble`. Uses key auth for secure access.

### VSCode Remote-SSH
Install extension; connect via bottom-left icon to "noble". Edit VM files remotely.

### Basic Shell Commands
- Navigation: `pwd`, `ls -la`, `cd <dir>`, `mkdir <dir>`.  
- Files: `touch <file>`, `echo "text" > file.txt`, `cat file.txt`, `grep "pattern" file.txt`.  
- Packages: `apt update`, `apt install <pkg>`, `which <cmd>`.  
- Permissions: `chmod +x script.sh`. Shebang: `#!/bin/bash`.  
- Pipes/Redirection: `command | grep`, `echo > file`.

### Scripting
Automate tasks. Example: Check/install with conditionals.  

### APT Utility
- `apt update`: Refresh repos with available packages.
- `apt upgrade`: Upgrade all the packages.
- `apt install -y <pkg>`: Install package.
- `apt list`: View all available packages.
- `apt list --installed`: View installed packages.
- `apt remove <pkg>`: Uninstall (for testing).

## 1. Warming Up
Use host terminal (PowerShell on Windows, Terminal on macOS/Ubuntu).

**Exercise 1:**
Create a folder `TestFolder`, switch to it and create `test.txt` file with the following command `echo "Hello, Networking Concepts!" > test.txt`.Verify: `cat test.txt` (or `type` on Windows).

**Exercise 2:**  
Create `test2.txt` with these lines using `echo >>`:  
```
Apple Pen
Pineapple Pen
Pen Pineapple Apple Pen
Apple Pineapple
Pen Pen Long Pen
```
Display lines with "Apple": `grep "Apple" test2.txt` (or `findstr`). With "Pen": Similar. Without "Pineapple": `grep -v "Pineapple"`.

## 2. Multipass Installation and VM Setup
**Task 1:** Select setup document for your OS; follow to install Multipass.

**Task 2:** Create VM: `multipass launch --name noble --disk 5GiB --mem 1GiB --cpus 1`. Get IP: `multipass info noble`. Setup SSH: Generate key (`ssh-keygen -t ed25519`), copy pubkey to VM, edit config. Test: `ssh noble`. Integrate VSCode: Install Remote-SSH, connect to "noble", open `/home/ubuntu/tasks`.

**Task 3:** Mount host folder: `multipass mount ~/NetworkingTasks noble:/home/ubuntu/shared`. Verify in VM: `ls /home/ubuntu/shared`.

## 3. Basic Shell and Scripting
In VM shell (`ssh noble` or VSCode terminal).

**Task 4:** Practice: `pwd`, `ls -la`, `mkdir test_dir`, `cd test_dir`, `touch file.txt`, `echo "Test" > file.txt`, `cat file.txt`.

**Task 5:** Create `install_tools.sh`:
```bash
#!/bin/bash
packages=("nmap" "netcat-traditional" "socat" "net-tools")
for pkg in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo "$pkg already installed."
    else
        echo "Installing $pkg..."
        sudo apt update
        sudo apt install -y $pkg
    fi
done
```
`chmod +x install_tools.sh; ./install_tools.sh`. Test by removing a package first. Adjust this script to take the list of the packages from script arguments, check whether package is available 

## 4. Wireshark Installation
**Task 6:** On host, download/install from https://www.wireshark.org. Verify: Run and check version.

## 5. VM Usage and Tools Practice
**Task 7:** Create `noble_new`: `multipass launch --name noble_new`. Practice: `multipass list`, `multipass exec noble_new -- lsb_release -a`, `multipass stop noble_new`, etc.

**Task 8:** In `noble`, verify tools: `nmap --version`, `ncat --version`, `socat -V`, `ifconfig`.

**Task 9:** Simple chat demo: In VM, `ncat -l -p 1234` (listen). From host: `ncat <VM_IP> 1234` and send messages. Scan ports: `nmap localhost` in VM; `nmap kse.org.ua` (public sites only).

## Expected Results
You can: Install VMs; access via SSH/VSCode; use shell commands; script installations; use basic tools. Troubleshoot with docs or course support.