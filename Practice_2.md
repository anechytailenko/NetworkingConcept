# Lesson 2.1-2.2: Systemd, Wireshark and OSI Model

## Lesson goals
The main goals of this lesson is to:
- work with multipass virtual machine & improve shell interaction skills;
- learn basics of systemd service management - install http server;
- analyse OSI model approach using Wireshark tool. Use http server on VM, socat TCP4-LISTEN and netcat to generate traffic which will be consumed by Wireshark;
- practice with routers to understand the login procedure, Mikrotik WebUI and some basic operations like network renaming, password setup and so on.

Optional:
- Install Cisco Packet Tracer https://www.netacad.com/resources/lab-downloads?courseLang=en-US and explore emulation

**Grading** (**Total: 2 points**)  
Submit reports/screenshots/outputs (e.g., VM info, script run, tool versions) via course platform if needed, or demonstrate them to teacher during the practice.
- **0.5 points** - setup and analyze http server, use systemd basic commands to start stop service, change it behavior
- **0.5 points** - open Wireshark. produce a traffic with http connection to VM, produce some traffic with socat TCP4-LISTEN and netcat, analyse chunks of data.
- **0.5 points**: - create your own systemd service that will perform some task on system boot and will start some socat command to listen a port
- **0.5 points**: - setup Mikrotik router, change some basic settings, explore RouterOS advanced settings and Terminal.

### 1. Warming up
This is a brief task(10-15 minutes) related to command line skills. You should run your virtual machine, for example `multipass shell noble`. Use knowledge base subsection as a reference.
**Knowledgebase START**
There are some usefull shortcuts and commands when you are working with shell.
**Note** you can use `man <command_name>` to view the manual. Another way is to install package `tldr` command(`sudo apt install -y tldr`). Create the dir `mkdir -p ~/.local/share/tldr` and run `tldr --update`. After that you can use command `tldr command_name` to view examples of `command_name` command usage.

`Ctrl+a` - move cursor to the start of the line
`Ctrl+e` - move cursor to the end of the line
`Ctrl+w` - remove word before cursor. Word are splitted by spaces
`Ctrl+l` - clear the screen.
`Ctrl + Right Arrow ` and `Ctrl + Left Arrow` - use arrows to move one word right or left.
        **NOTE** It doesn't work on MacOS due to conflict with system default shortcuts.
`Tab` - use tab to get autocompletion or the list of suggestion if there are multiple
        completions for the current context.
`history` - command to show history of cocmmands
`Up Arrow`, `Down Arrow` - search in the command history - prev and next command
`Ctrl+r` - reverse search in command history. This will open prompt "(reverse-i-search)"
        and you can start type some word to match in the history.
        The most recent match will be shown, if you need the previous match just type 
`sudo` - execute command with super user permissions.
`echo` - allows to print the text including variables. `echo "Test"` will print line Test.
        `echo -e "line 1\nline 2\nline 3"` will print multiple lines as `-e` flag
        allows to treat `\n` as a special symbol end of line.
`wc` - allows to count statistics of file or stream.
        `wc -l 1.txt` will return the line count in 1.txt.
        `wc -c 1.txt` will count symbols and `wc -b 1.txt` will count bytes.
`|` - pipe. Allows to use output of some command as the input for another command.
        `echo -e "line 1\nline 2\nline 3" | wc -l` will count the lines
        in the output produced by echo command.
`touch` - command to create an empty file `touch empty.txt`
`cat` - will print the content of the file or will print concatenated content from few files
        if you will provide more than 1 file as input.
        `cat 1.txt` will print the content of the file once.
        `cat 1.txt 1.txt` will print content twice.
`head -N` - command to display the first N lines of the file or piped stream.
        `head -3 1.txt` will show the first 3 lines of file `1.txt`
        or the whole file if it contains less than 3 lines.
        The equivalent command with pipe `cat 1.txt | head -3`
`tail -N` - command to display the last N lines of the file or piped stream.
        `tail -3 1.txt` will show 3 last lines of file `1.txt`
        or the whole file if it contains less than 3 lines.
        The equivalent command with pipe `cat 1.txt | tail -3`
`grep` - filter input to show only lines that match patern
        `grep test 1.txt` - show only the lines of the 1.txt file which contain test
        `cat 1.txt | grep "another test"` - if your pattern contains space just wrap it into ""
        `cat 1.txt | grep -v "test"` - option -v allows to print only lines that DO NOT contain test.
        `cat 1.txt | grep  "^test"` - ^ allows to find lines that start with word test.
        `cat 1.txt | grep  "test$"` - $ allows to find lines that start with word test.
        `cat 1.txt | grep  "test\|word"` - `\|` allows to find lines that match one of the patterns
                                    e.g contain at least one of the words test or word
`nano` - is a text editor. Use `nano 1.txt` to start file edit.
        `Ctrl+o` save the changes
        `Ctrl+x` exit editor(use `y` or `n` and `Enter` if some changes were not saved before exit)
**Knowledgebase END**

**Warming Up Tasks**
1. Use `apt` to install `tldr` package inside your virtual machine.
2. Use `tldr` to get some info about `nano` utility.
3. Use arrows to navigate through the command history and return back to tldr installation command.
   Use `Ctrl+w` to remove tldr word and adjust command to setup `cmatrix` package.
4. Start typing `cma` and then press `Tab`. Run proposed cmatrix command and enjoy!
5. Sorry but we should use `Ctrl+C` to interrupt the program.:-(
6. Let's switch to home folder with `cd` command
7. Create directory `week2` in home folder and switch to it.
8. Use nano to create file `1.txt` and put at least 10 lines of any text you like. Save changes and exit from file.
9. Use `|`, `cat` and `head` command to print the first 5 lines from the file 1.txt.
10. Use `|`, `cat`, `head` and `tail` to print 5 lines starting from the second line.
11. Use Ctrl+R to search from matrix word and run that command.
12. Use `cat` and `grep` to filter data from `1.txt` based on some patterns.
13. Use `wc` utility to find the count of symbols.
14. Use `cat` and `sort`(get some info with tldr about it) to display sorted version of file `1.txt`.
15. Run `history` command to view only the last 10 items in the list.
16. Great job! You can run cmatrix one more time if you like! 

### 2. Systemd Service Management and HTTP Server Installation
In this section, we'll dive into systemd, the modern init system used in Ubuntu and most Linux distributions. Systemd replaces older init systems like SysVinit, providing a more efficient way to manage services, boot processes, and system resources. 

**Why We Need Systemd**: Systemd is essential because it parallelizes service startup (faster boots), handles dependencies automatically (e.g., starts networking before web servers), and offers robust logging, monitoring, and control over system daemons. It unifies various system components like device management, logging (via journald), and timers (like cron jobs), making administration consistent and powerful. In networking, systemd manages services like network interfaces or servers, ensuring reliability in production environments.

**How Systemd Can Be Used**: Systemd uses "units" (files like .service for services) to define behaviors. Key commands include `systemctl` for control (start/stop/restart/enable/disable) and `journalctl` for logs. You can create custom services for tasks like running a script on boot or managing network listeners. For our practice, we'll install and manage an HTTP server (e.g., Apache or Nginx) to simulate a web service, tying into OSI layers later.

Use `tldr systemctl` or `man systemctl` for quick references.

**Knowledgebase START**
- `systemctl status <service>`: Check if a service is running, e.g., `systemctl status apache2`.
- `systemctl start <service>`: Start a service immediately.
- `systemctl stop <service>`: Stop a running service.
- `systemctl restart <service>`: Restart a service (stop then start).
- `systemctl enable <service>`: Enable service to start on boot.
- `systemctl disable <service>`: Disable auto-start on boot.
- `systemctl reload <service>`: Reload configuration without restarting (if supported).
- `journalctl -u <service>`: View logs for a specific service.
- Service files are in `/etc/systemd/system/` or `/lib/systemd/system/`. Edit with `nano` and reload with `systemctl daemon-reload`.
- To install an HTTP server: `sudo apt update && sudo apt install -y apache2` (for Apache) or `nginx`.
**Knowledgebase END**

**Tasks for Systemd and HTTP Server**
1. Inside your Multipass VM, update packages: `sudo apt update`.
2. Install Apache HTTP server: `sudo apt install -y apache2`.
3. Check status: `systemctl status apache2`. Note if it's active.
4. Stop the service: `systemctl stop apache2`, then verify with status. Note that you may need to use a proper permissions and `sudo` to get them for some of the `systemctl` commands.
5. Start it again: `systemctl start apache2`.
6. Enable auto-start: `systemctl enable apache2`.
7. View logs: `journalctl -u apache2 -n 20` (last 20 lines).
8. Test the server: From your host, use `curl <VM_IP>:80` (find VM IP with `ip addr show` in VM). You should see HTML output.
9. Modify behavior: Edit `/etc/apache2/ports.conf` with nano (e.g., change ServerName) to change http listen port from 80 to 8000, then `systemctl reload apache2`.
10. Investigate the service file of apache2 with `systemctl cat apache2` command. Use google search or AI to analyse the fields from this file.
11. Create a custom systemd service: Use nano to create `/etc/systemd/system/myservice.service` with content like:
    ```
    [Unit]
    Description=My Custom Service

    [Service]
    ExecStart=/bin/echo "Hello from custom service $(date)" > /tmp/myservice.log

    [Install]
    WantedBy=multi-user.target
    ```
    Reload daemon: `systemctl daemon-reload`, enable and start: `systemctl enable myservice && systemctl start myservice`. Check `/tmp/myservice.log`.
12. For grading: Take screenshots of status outputs, logs, and curl response.

This builds skills for managing network services, preparing for traffic generation.

### 3. Analyzing OSI Model with Wireshark
Now, we'll explore the OSI model (Open Systems Interconnection) by generating and capturing network traffic. The OSI model has 7 layers: Physical (1), Data Link (2), Network (3), Transport (4), Session (5), Presentation (6), Application (7). Wireshark helps dissect packets layer by layer, showing how data flows from application (e.g., HTTP) down to physical bits.

**Why Wireshark and OSI**: Understanding OSI is crucial for networking as it abstracts how devices communicate. Wireshark visualizes this in real traffic, helping debug issues like packet loss or misconfigurations. We'll use your HTTP server (Layer 7), socat/netcat for TCP/UDP (Layer 4), and capture on the host or VM.

Ensure that you have installed Wireshark on your host machine (not VM, for easier GUI access): Download from https://www.wireshark.org/ or via apt on Ubuntu host if needed.

**Knowledgebase START**
- Install tools in VM: `sudo apt install -y socat` (but use host Wireshark for analysis).
- `socat TCP4-LISTEN:<port>,fork STDIO`: Listens on TCP port(choose  unsigned integer less than 2^16, usually >1024), echoes input (simple server).
- `nc <ip> <port>`: Netcat client to connect and send data.
- In Wireshark: Start capture on interface (e.g., loopback or VM bridge - you can hover mouse on the list items to get a popup with IP information, choose the one relevant to your VM's ip), apply filters like `http` or `tcp.port == <your port>`.
- OSI in action: HTTP (App), over TCP (Transport), IP (Network), Ethernet (Data Link).
**Knowledgebase END**

**Tasks for Wireshark and OSI Analysis**
1. In VM, ensure HTTP server is running. Find VM IP with `multipass info` command.
2. From host, open browser to `http://<VM_IP>` or use curl to generate HTTP traffic.
3. Open Wireshark on host, capture on the interface connected to VM.
4. Filter for HTTP: Capture while accessing the server, stop, and analyze packets. Note layers: Ethernet frame > IP > TCP > HTTP.
5. For socat: In VM, run `socat TCP4-LISTEN:9999,fork STDIO`.
6. From the host: `echo "Test data" | nc <VM_IP> 9999`.
7. Capture this in Wireshark: Filter `tcp.port == 9999`. Analyze: double click on any line and check how do this data mapped to OSI approach.
8. For custom service (grading): Modify your systemd service to run `socat TCP4-LISTEN:10000,fork EXEC:/bin/date` (echos date on connect). Enable on boot, reboot VM, connect with nc, capture traffic.
10. Annotate 2-3 packets in screenshots: Label OSI layers and explain (e.g., "Layer 4: TCP ensures reliable delivery").
11. Discuss in mind map: How does this relate to real networks? (e.g., Web traffic vs. raw sockets).

### 4. Practicing with Routers (Mikrotik)
Routers manage traffic between networks (OSI Layer 3). Mikrotik RouterOS is a powerful, affordable platform for learning routing, firewalls, and more. We'll use Winbox (WebUI) for setup.

**Why Routers and Mikrotik**: Routers enable internetworking, handling IP routing, NAT, and security. Mikrotik's WebUI/Terminal teaches CLI/GUI config, similar to Cisco/Juniper. Practice login, basic ops for hands-on networking.

**Knowledgebase START**
- Default login: admin/no password (change immediately!).
- WebUI: Access via browser at router IP (default 192.168.88.1).
- Winbox: Download from Mikrotik site, connect to IP/MAC.
- Commands: `/system identity set name=MyRouter` (rename), `/user set admin password=strongpass`.
- Terminal: In WebUI or Winbox, use for advanced: `/ip address print`, `/interface print`.
**Knowledgebase END**

**Tasks for Router Practice**
For grading: Screenshots of login, renamed router, password change.
1. You will got a number `N` that associated with the router. You should connect to one of the networks `Mikrotik-N-2ghz` or `Mikrotik-N-5ghz`.
2. Login via browser: http://192.168.88.1, user admin, no pass.
3. If you was not prompted to change the password, use : In Advanced > System > Users > Set password. Logout from the router and login with new password.
4. Use QuickSet tab to change wifi network name and set wifi password. Reconnect to the new WiFi network with the password.
5. Explore Advanced tab and Tools in particular.
6. Use Terminal tab to execute some commands. Your task is to find some commands that may print router configuration, network parameters and so on.
7. Present results to the teacher and after that perform factory rese tof router configuration.


### Optional: Cisco Packet Tracer
Install Cisco Packet Tracer https://www.netacad.com/resources/lab-downloads?courseLang=en-US, create a simple network (PC > Switch > Router), simulate pings, and analyze in built-in Wireshark-like tool.
