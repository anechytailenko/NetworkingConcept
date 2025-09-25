### Practice 3: Introduction to Network and Transport Layers

#### Lesson Goals
The main goal of this practice is to introduce and reinforce foundational concepts of the Network layer (IP, ICMP, ARP, DHCP, routing) and provide an initial exploration of the Transport layer (TCP, UDP). Students will gain hands-on experience with IP address calculations, packet analysis, and basic socket operations using virtual machines and Wireshark. The session aligns with the collaborative mind mapping flipped lesson format, encouraging students to structure their understanding through group work and real-world application.

**Note**: You can open this file in VSCode or another editor for better command highlighting.

---

**Grading** (**Total: 2 points**)  
Submit reports/screenshots/outputs (e.g., VM info, script run, tool versions) via course platform if needed, or demonstrate them to teacher during the practice.
- (0.5 points) IPv4 Network Calculation
- (0.5 points) IPv4 Routing
- (0.25 points) Introduction to UDP
- (0.25 points) Introduction to TCP
- (0.5 points) IPv4 Network Calculation and Router Setup

---

#### Warming up
This is a brief task to familiarize students with command-line tools, packet capture, and network protocols. Use the knowledge base below as a reference and work in groups of 2–3 to discuss observations.

**Knowledgebase START**
- `arp -a`: View the ARP cache (IP-to-MAC mapping) on the host.
- `ping <IP>`: Send ICMP echo requests to test connectivity.
- `multipass start noble`: Start a virtual machine named "noble".
- `multipass shell noble`: Access the shell of the "noble" VM.
- `ip a`: Display IP addresses and network interfaces on the VM.
- `traceroute <site>`: Trace the route packets take to a destination (use `tracert` on Windows).
- `nc -u <IP> <port>`: Send UDP data to a specified IP and port.
- `socat - TCP-LISTEN:<port>,fork`: Create a TCP listener on a specified port.
- Wireshark filters: `arp` for ARP packets, `icmp` for ICMP packets, `dhcp` for DHCP packets.
**Knowledgebase END**

**Warming Up Tasks**
1. Open PowerShell (Windows) or Terminal (MacOS/Linux) on your host system.
2. Start your virtual machine with `multipass start noble` and note its IP address using `multipass list`.
3. Open Wireshark, select the interface connected to the VM (hover cursor over interface names to see network masks), and apply the filter `arp` to capture ARP packets.
4. Run `arp -a` on the host to view the ARP cache, then clear it (Windows: `arp -a -d`; MacOS/Linux: `sudo arp -d <ip>` for each entry) and refresh by opening `google.com` in a browser or using `curl google.com`.
5. Switch to Wireshark, observe ARP request/reply packets, and note the IP-to-MAC mappings.
6. In the VM (via `multipass shell noble`), run `ping /n 10 <host_IP>` (Windows) or `ping -c 10 <host_IP>` (MacOS/Linux) to test connectivity.
7. In Wireshark, change the filter to `icmp`, select an echo request packet, and analyze the ICMP details at the bottom (e.g., sequence numbers).
8. Restart the VM with `multipass stop noble && multipass start noble`, then in Wireshark, apply the filter `dhcp` to capture DHCP packets (Discover, Offer, Request, ACK) and review the User Datagram Protocol and DHCP sections.
9. Discuss in your group: How do ARP, ICMP, and DHCP interact to establish network connectivity?

---

#### Task 1: IPv4 Network Calculation
This task focuses on understanding IPv4 subnetting and address allocation. Work individually, then compare results in groups.

**Knowledgebase START**
- Subnet mask `/n` defines `2^(32-n)` addresses, with the first (network) and last (broadcast) reserved, leaving `2^(32-n)-2` for devices (including 1 router).
- Example: `192.168.1.130/25` → `m=32-25=7`, `2^7=128` addresses, range `192.168.1.128–192.168.1.255`, 126 usable devices.
- `echo "obase=2;$NUMBER" | bc`: Convert decimal to binary.
- `echo "$((2#<binary>))"`: Convert binary to decimal.
- Note that if we consider ip address as a 4 byte unsigned integer, then the range of addresses that belong to subnet can be considered as sequential numbers and the idea of subnetting is to split the whole range from `0` to `2^32-1` to such ranges without any intersection in public(or global) ranges and without intersection of local subnets for private ranges. So if we have subnet `192.168.0.1/24` - it can be represented with unsigned integers from `192*256^3 + 168*256^2 + 0 * 256 + 0 = 3232235520` to `3232235520 + 255 = 3232235775`. If we have mask 25, then we should take into acount most significant bit from the last octet therefore `192.168.0.1/25` will result in `192*256^3 + 168*256^2 + 0 * 256 + 0 * 2^7 = 3232235520` and `3232235647`, while `192.168.0.128/25` will be `192*256^3 + 168*256^2 + 0 * 256 + 1 * 2^7 = 3232235648` to `3232235775`

1 subnet with mask 24(256 addresses in the subnet):
3232235520                                      3232235775
|________________________________________________________|

or 2 subnets with mask 25(128 addresses in each subnet):
3232235520              323223564(7,8)              3232235775
|____________________________|____________________________|
**Knowledgebase END**

**Tasks**
1. Log into the VM with `multipass shell noble`.
2. Generate 3 unique subnets:
   - Subnet 1: `echo "10.$(shuf --head-count=1 --input-range=0-255).$(shuf --head-count=1 --input-range=0-255).$(shuf --head-count=1 --input-range=0-255)/$(shuf --head-count=1 --input-range=18-23)"`
   - Subnet 2: `echo "10.$(shuf --head-count=1 --input-range=0-255).$(shuf --head-count=1 --input-range=0-255).$(shuf --head-count=1 --input-range=0-255)/$(shuf --head-count=1 --input-range=25-27)"`
   - Subnet 3: `echo "10.$(shuf --head-count=1 --input-range=0-255).$(shuf --head-count=1 --input-range=0-255).$(shuf --head-count=1 --input-range=0-255)/$(shuf --head-count=1 --input-range=18-27)"`
3. For each subnet, calculate:
   - IP range (e.g., `10.x.y.z - 10.a.b.c`).
   - Broadcast address.
   - Maximum number of client devices (assuming 1 router).
4. Check for IP conflicts between subnets and discuss findings with your group.

---

#### Task 2: IPv4 Routing
This task introduces basic routing concepts using multiple VMs.

**Knowledgebase START**
- `sysctl net.ipv4.ip_forward`: Check/enable IP forwarding (set to 1 with `sudo sysctl -w net.ipv4.ip_forward=1`).
- `ip route add default via <IP>`: Add a default route via another VM's IP.
- `ip route delete <route>`: Remove a route.
- `traceroute 8.8.8.8`: Trace the route to a public server.
**Knowledgebase END**

**Tasks**
1. Start two VMs: `multipass start noble` (main VM) and create a helper VM (e.g., `multipass launch --name helper`, for Windows Home you may need additional steps to setup network properly).
2. In the `noble` VM, run `ip route` and `traceroute 8.8.8.8` to see the default route.
3. Check if IP forwarding is enabled with `sysctl net.ipv4.ip_forward`. If not, enable it with `sudo sysctl -w net.ipv4.ip_forward=1`.
4. In the `helper` VM, run `ip route` and `traceroute 8.8.8.8`.
5. Add a default route in `helper` VM to `noble` VM’s IP: `sudo ip route add default via <noble_IP>`.
6. Run `traceroute 8.8.8.8` again in `helper` VM and compare the output.
7. Remove the route with `sudo ip route delete default` and verify with `traceroute 8.8.8.8`.
Question to discuss: How does routing affect packet paths?

---

#### Task 3: Introduction to UDP
This task explores the UDP protocol at the Transport layer.

**Knowledgebase START**
- `nc -u <IP> <port>`: Send UDP data to a specified IP and port.
- UDP is connectionless, with minimal overhead (source port, destination port, length, checksum, and payload).
**Knowledgebase END**

**Tasks**
1. In the VM, open a UDP listener on port 2024: `nc -ul 2024`.
2. On the host, send data to the VM: `nc -u <VM_IP> 2024` and type a string (e.g., "test").
3. In Wireshark (with filter `udp.port==2024`), select the UDP segment, expand the "User Datagram Protocol" and "Data" sections, and note the header details (ports, length) and payload.
4. Send an empty string (press Enter) and observe the packet length (should be 9 bytes: 8 bytes header + 1 byte payload).
5. Discuss in your group: What are the advantages of UDP’s simplicity?

---

#### Task 4: Introduction to TCP
This task introduces the TCP protocol, focusing on connection establishment.

**Knowledgebase START**
- `socat - TCP-LISTEN:<port>,fork`: Create a TCP listener.
- `nc <IP> <port>`: Connect to a TCP port.
- TCP handshake: SYN → SYN/ACK → ACK; flags include SYN, ACK, FIN; sequence and acknowledgment numbers ensure reliable delivery.
**Knowledgebase END**

**Tasks**
1. In the VM, start a TCP listener on port 2024: `socat - TCP-LISTEN:2024,fork`.
2. On the host, connect to the VM: `nc <VM_IP> 2024` and send a string (e.g., "TCPTest").
3. In Wireshark (with filter `tcp.port==2024`), analyze the three-way handshake:
   - Identify SYN, SYN/ACK, and ACK packets.
   - Note sequence numbers, acknowledgment numbers, and flags.
4. Send a response from the VM (type in the socat terminal, e.g., "TCPResponse") and analyze the corresponding TCP segment.
5. Close the connection (Ctrl+C on host and VM) and observe the FIN/ACK exchange in Wireshark.
Question to discuss: How does TCP ensure reliability compared to UDP?

---

#### Task 5: IPv4 Network Calculation and Router Setup
This task applies subnetting knowledge to a real router setup.

**Knowledgebase START**
- Subnet mask `/n` defines address range and count of usable devices (2^(32-n)-2).
- MikroTik Quick Set: Configure IP, subnet mask, DHCP, and WiFi settings.
**Knowledgebase END**

**Tasks**
1. Log into the VM and generate a personal IP: `echo "10.$(shuf --head-count=1 --input-range=0-255).$(shuf --head-count=1 --input-range=0-255).$(shuf --head-count=1 --input-range=0-255)/$(shuf --head-count=1 --input-range=21-27)"`.
2. Calculate the IP range, subnet mask (e.g., 255.255.255.0), broadcast address, and router IP.
3. Connect to the MikroTik router via WiFi (e.g., `MikroTik-N-2ghz` or `MikroTik-N-5ghz`) using `192.168.88.1`, log in (admin, no password), and set a new password for admin.
4. In Quick Set, rename the WiFi network (e.g., "GroupX"), set the country to Ukraine, and configure the Local Network with the calculated IP, subnet mask, and enable DHCP/NAT.
5. Set the DHCP Server Range based on the IP range.
6. Ask a teacher to verify the setup, then click "Apply Configuration".
7. Connect to the new WiFi, log into the router with the new IP, and check your IP with `ipconfig` (Windows) or `ifconfig` (MacOS/Linux).
8. Reset the router configuration (no checkboxes) for the next group member.
Question to Discuss: How does DHCP simplify network management?

---

#### Notes
- Use Multipass VMs ("noble" and a helper VM) for Tasks 2–4.
- Ensure Wireshark is installed on the host for packet analysis.
- For Task 5, coordinate with the teacher for MikroTik router access - you should get your number N to identify your router.
