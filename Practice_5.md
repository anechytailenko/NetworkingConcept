### Week 5: Application Layer Protocols and Advanced Security (DNS, SSH Tunneling, and Firewalls)
This week advances students' understanding of application-layer services like DNS for name resolution, while integrating secure access techniques through SSH tunneling and port forwarding. It also deepens security skills with firewall configurations on routers to block unauthorized access and advanced iptables for fine-grained TCP/UDP traffic control. We will also learn about SSH forwarding types, and firewall principles.

**Note**: Open this file in VSCode or another editor for better command highlighting. Use Multipass VMs ("noble" and "helperVM") for DNS/SSH/iptables tasks; coordinate with teacher for MikroTik router access.

---

#### Grading (**Total: 2 points**)
Submit screenshots/outputs (e.g., Wireshark captures, command results, mind maps) via course platform or demonstrate to teacher.
- (0.5 points) DNS Resolution and Analysis
- (0.5 points) SSH Tunneling and Local Port Forwarding
- (0.5 points) Remote Port Forwarding
- (0.5 points) Router Firewall Configuration to Block Access
- (1 point) Advanced iptables for TCP/UDP Traffic Control

---

#### Warming Up
This brief task refreshes protocol analysis and prepares for DNS/SSH. Work in groups of 2–3, using the knowledge base as reference.

**Knowledgebase START**
- `nslookup <domain>`: Query DNS for IP resolution.
- `dig <domain>`: Advanced DNS lookup with details (install via `sudo apt install dnsutils`).
- `ssh -L <local_port>:<remote_host>:<remote_port> user@host`: Local port forwarding.
- Wireshark filters: `dns` for DNS packets, `ssh` for SSH traffic.
- MikroTik => Advanced => Firewall : Access via browser at router IP for firewall rules.
- `iptables -A INPUT -p tcp --dport <port> -j DROP`: Basic drop rule.
**Knowledgebase END**

**Warming Up Tasks**
1. Start VM with `multipass start noble` and log in via `multipass shell noble`.
2. Install `dnsutils` and run `nslookup google.com` to resolve IP; note the server used.
3. Open Wireshark on host, select VM interface, filter `dns`, run `dig kse.ua` in VM, and observe query/response packets. Analyse Domain Name System query and response to find the information and map it to the one from dig command output.
4. How does DNS enable human-readable addressing? Why DNS is not secure?

---

#### Task 1 (0.5 points): DNS Resolution and Analysis
This task introduces DNS as a critical application-layer protocol, with hands-on resolution and packet inspection. Work individually, then compare in groups.

**Knowledgebase START**
- DNS hierarchy: Root servers, TLDs, authoritative servers.
- Types: A (IP), MX (mail), NS (nameserver).
- `dnsmasq`: Simple DNS forwarder (install via `sudo apt install dnsmasq`).
- Wireshark: Analyze DNS for opcode, flags (QR, AA), and resource records.
**Knowledgebase END**

**Tasks**
1. In VM, install `dnsutils` and `dnsmasq`. Verify that dig utility is installed: use `dig +short google.com` to get IP; then `dig google.com MX` for mail servers.
2. Ubuntu use the systemd-resolved service by default, which occupies DNS port 53. To allow `dnsmasq` to use this port, we first need to stop and disable the existing service.
```
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

3. Configure `dnsmasq` for local caching. Create a new configuration file to tell `dnsmasq` to listen only on the local loopback address `127.0.0.1`:
```
sudo nano /etc/dnsmasq.d/local.conf
```
add:
```
listen-address=127.0.0.1
bind-interfaces
server=8.8.8.8
```

4. Configure the VM to use dnsmasq as we need to tell the operating system to send all its DNS queries to our new local server. To do this, we'll replace the system-managed `/etc/resolv.conf` symbolic link with our own static file.
Remove the symbolic link that was managed by systemd-resolved and create a new `resolv.conf` file pointing to our local `dnsmasq` instance
```
sudo rm /etc/resolv.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
```

5. Restart the dnsmasq service with `sudo systemctl restart dnsmasq`.

6. Check that dnsmasq is listening only on 127.0.0.1:53. To do this run `ss -tlpn 'sport = :53'`. The output should show "127.0.0.1:53", NOT "0.0.0.0:53"

7. Perform a test query `dig kse.ua` and run it twice. The second query should have a much lower Query time (0-1 msec) because the result is now being served from your local cache.

8. Simulate a custom resolution. Add a line `192.168.1.1 myfake.domain` to `/etc/hosts` and restart `dnsmasq` service. Try to resolve it with `dig myfake.domain`.

9. Use `dig kse.ua` and note the output. How does the output changed?

10. Ensure that you have both `apache2` server and `lynx` browser installed inside VM. 
Let's browse the site kse.ua with `lynx kse.ua` command. Use q to quit from the lynx browser.

11. Now find the IP of your VM with `ip a` command. Repeat step 8 but with your ip instead of `192.168.1.1` and `kse.ua` instead of  `192.168.105.2 kse.ua`. Ensure that you restarted dnsmasq service and run `lynx kse.ua` again. Explain the observed behavior.

12. Uninstall dnsmasq with `sudo apt purge dnsmasq && sudo rm -rf /etc/dnsmasq.d`. Enable and start systemd-resolved service:
```
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl enable systemd-resolved
sudo systemctl restart systemd-resolved
```
Restart virtual machine and ensure that `dig kse.ua` resolves the name properly.

Questions: How does DNS caching improve performance but introduce risks (e.g., poisoning)? How do the approaches from this tasks can be used for different types of attacks?

---

#### Task 2 (0.5 points): SSH Tunneling and Port Forwarding
This and the next task build secure tunneling skills, focusing on local/remote forwarding to bypass restrictions. Work in pairs for testing.

- Local forwarding (-L): Maps local port to remote resource.
- Remote forwarding (-R): Exposes local service to remote.
- Dynamic forwarding (-D): Creates SOCKS proxy for broader tunneling.
- Firewall bypass or jump: Tunnel over SSH to access blocked ports.
We will explore local and remote forwarding today.

# KNOWLEDGE_BASE_START
The main idea of port forwarding is to get access to some resources on machine with firewall rules using ssh tunnel. In the case of local port forwarding ssh allows to map remote port to local port of your machine so you will be able to access the resource as long as corresponding command is running.
View more: https://www.youtube.com/watch?v=AtuAdk4MwWw
Read more: https://builtin.com/software-engineering-perspectives/ssh-port-forwarding
# KNOWLEDGE_BASE_END

2.1. Check whether you have apache2 running on VM then let's open browser on host system to access http server on VM. Use ip address in address line. You should see the default page from apache2 server. If not, install apache2 package.

2.2. Use iptables on VM to allow access to the port 80 only from localhost, all other input connections to that port should be rejected.
Ensure that rules works fine: check on host that http server is not available, while inside VM you can use `nc localhost 80` command and after typing any line to nc console http server sends a response.

2.3. Open Powershell on Windows or Terminal for MacOS/Linux. Let's do some magic with ssh port forwarding. We want to map our local port 12000  to the remote port 80. Run the command
`ssh -N -L localhost:12000:localhost:80 ubuntu@<IP of VM>`
**NOTE:** -N - non-interactive;
          -L local forwarding e.g. the first 2 components localhost:12000 belongs to our host, localhost:80 belongs to the remote machine.

2.4. Let's open browser and type http://localhost:12000 if everything was executed properly then you should be able to view apache2 page.

2.5. Return to PowerShell or Terminal and cancel command from step 3 of this task.
Go back to the browser and try to open http://localhost:12000 one more time.
Ensure also that direct IP to port is not working by checking http://<noble IP>:80

2.6. Keep calm: We will use that firewall rules and blocked access to the port 80 for the next task.

#### Task 3 (0.5 points): SSH remote port forwarding aka SSH reverse tunneling

# KNOWLEDGE_BASE_START
Let's suppose we have a local network and 2 machines:
- Machine1 is running service on some port but has no public ip address or even no access to internet.
- Machine2 has public ip address.
The task is to expose service from Machine1 to be accessible via Machine2 ip address. To do that we can run the following command on Machine1:
`ssh -N -R <IP of Machine2>:<port to be mapped on Machine2>:localhost:<Port with service on Machine1> <user on machine 2>@<IP of Machine2>`
Example: map port 80 of Machine1 to port 8080 of Machine2(192.168.0.105)
`ssh -N -R 192.168.0.105:8080:localhost:8080 ubuntu@192.168.0.105`

View more: https://www.youtube.com/watch?v=AtuAdk4MwWw
Read more: https://builtin.com/software-engineering-perspectives/ssh-port-forwarding
# KNOWLEDGE_BASE_END

3.1. To perform this task you will need another VM. Let's call it `helperVM`(you can reuse any existing one) - create a new one if needed.

3.2. Let's login to our old VM `multipass shell noble` and generate SSH key(use defaults, do not set password)
`ssh-keygen -t ed25519`

3.3. Copy public part of generated SSH key so you can use it for further steps
`cat ~/.ssh/id_ed25519.pub`

3.4. Use another PowerShell/Terminal window to login to helperVM `multipass shell helperVM` and add public key from step 3.3 to authorized_keys
`mkdir -p ~/.ssh`
`nano ~/.ssh/authorized_keys`
Save the document(Ctrl + O) and exit(Ctrl+X).

3.5. Let's edit ssh config of helperVM to allow remove port forwarding:
`sudo nano /etc/ssh/sshd_config`
and find options, uncomment them if needed and ensure that both are set to yes:
GatewayPorts yes
AllowTCPForwarding yes

3.6. Save the document(Ctrl + O) and exit(Ctrl+X) and restart sshd service to reload config:
`sudo systemctl restart ssh`
*NOTE* your connection to helperVM may be dropped after that command. In that case just re-login to helperVM.

3.7. Find the ip address of `helperVM` with `ip a` and ensure that this address can be pinged from noble VM.

3.8. Open shell in noble VM or reuse existing one and try to check ssh connection from noble to helperVM:
`ssh ubuntu@<IP address of helperVM>`
then exit from ssh shell with Ctrl+D.

3.9. Let's do some magic with reverse ssh tunneling inside terminal of noble VM.
`ssh -N -R <IP of helperVM>:8000:localhost:80 ubuntu@<IP of helperVM>`

**NOTE** We want to expose our http server(port 80 of noble VM) to the port 8000 on helperVM
 -N is just to open non-interactive connection e.g. without login to VM and terminal access.
 -R is to create a remote tunnel that will expose our server on remote port 8000.
 <IP of helperVM>:8000:localhost:80
 |____________________||_____________|
  helperVM port          noble port

3.10. Open browser and try to access http server on helperVM port 8000 with http://<IP of helperVM>:8000

3.11. In shell of noble VM stop command execution from step 3.9.
Also remove iptables rules created during step 2 of the task 2 and ensure that http://<IP of noble> is now reachable.

---

#### Task 4 (0.5 points): Router Firewall Configuration to Block Access
This task applies firewall rules on MikroTik routers to control access, simulating real-world network security. Work in groups of 2–3.

**Knowledgebase START**
- MikroTik Firewall: Chains (input, forward, output), actions (accept/drop/reject).
- Address lists: Group IPs for rules.
- Advanced: IP > Firewall for rule addition.
- WAN/LAN: Block based on src/dst.
**Knowledgebase END**

**Tasks**
**4.1** During this task students will be split into groups(2-3 people in every group). Each group will get its own `Router N`. For every router we will setup it's own subnet that should be used for further router setup.

**4.2** Find corresponding WiFi network based on the number *N* and router list from above. One person of your group should login to the router via IP 192.168.88.1 and setup your own password for admin user.

**4.3** Now the group should setup wifi network `192.168.N.(3*N)/(25 + (N mod 4))` based on your number *N*. For example, if N=30 then we will have `192.168.30.3*30/(25 + 2)` e.g. `192.168.30.90/27`. Router should get the smallest valid ip in that subnet. Ask teacher to check configuration and after approve "Apply configuration".

**4.4** Now all participants of the group should find **Router N** network and connect to it. Another person from the group should login to the router. Note, that you changed its IP address therefore you should use the new one to access the router.

**4.5** Before you start creation of new firewall rule check that all people from the group can ping the router.

**4.6** Go to Advanced => IP => Firewall, select **all** in combobox on the top right corner to display all the rules. Click New button to create a new rule. We want to reject pings from a chosen ip. To do that find an IP of a laptop that is connected to your router. Let's add some text to the comment field for example "Reject ping" so it will be easy to find the rule in the list. Now let's add the core fields to the rule. Like with iptables approach we should select **chain**, **src address**, **protocol** and **action** that should be performed for certain IP packets. In this case we want to block the **input** chain for some **src address** IP  and **icmp** protocol. To set the action scroll to the bottom and find section **Action**. Choose **drop**. Now click Ok. Try to ping the router IP from the IP you set in the rule. Most likely ping will be still work fine because the new rule was just appended after existing rules and as we already saw in iptables - the order of the rules matters.

**4.7** Let's change the priority of the rules. Find your rule in the list (IP=>Firewall=>Filter Rules), check its checkbox and click Move button. Ensure that your rule will be before other rules related to ICMP(usually it is item `#3` *defconf: accept ICMP*). Try to ping the router from the IP - ping should fail.

**4.8** Now double click on your rule and scroll to the bottom of the page to find section *Action*. Choose *accept* action, click Apply button and run ping from the laptop. Then select *reject* action and some value from *Reject with* combo box. Apply and check ping. You can check different reject reason and compare how it impacts the behavior of the ping on your laptop.

**4.9** Let's add a couple of rules. Open `kse.ua` in your browser to ensure that it is reachable. Now you can use nslookup to find IP addresses associated with that site.
Let's add a single rule for multiple IPs. To do that in IP=>Firewall choose **Address lists => Add new =>** Specify one ip address and name of the list you want to use **=> ok**. Then you can add another IP to the list **Add new =>** new IP but old list name **=>Ok**. You can add as much addresses as nedeed. After list configuration you can use it for firewall rules: instead of *src address* use *src address list*

**4.10** Go to IP=>Firewall=> Filter Rules and add a firewall forwarding rule that will drop or rejects all the packets for all the protocols(e.g. left protocol field empty) if ip address belongs to the list of IPs we created in the previous step. Apply the rule and use browser to ensure that site is not available.

**4.11** Reset your router configuration. Connect back to it after reset with 5ghz network, open Advanced=>Interfaces, Click on wlan1
 and use toggle at the top of the page to disable 2ghz network.
---

#### Task 5 (Additional Task, 0.5 points): Advanced iptables for TCP/UDP Traffic Control
This task extends iptables for protocol-specific controls, if not fully covered (e.g., rate limiting, stateful inspection). Work individually, share in groups.

**Knowledgebase START**
- Modules: `-m state --state NEW/ESTABLISHED`, `-m limit --limit 5/s` for rate.
- Chains: INPUT for incoming, FORWARD for routing.
- TCP/UDP: `--sport/--dport`, `--tcp-flags`.
**Knowledgebase END**

**Tasks**
1. In VM, run UDP listener on 2025: `nc -ul 2024`.
2. Add stateful rule: `sudo iptables -A INPUT -p udp --dport 2024 -m state --state NEW -j ACCEPT; sudo iptables -A INPUT -p udp --dport 2024 -j DROP` (allow new, drop others).
3. Test from host: Send data with `nc -u <VM_IP> 2024`; capture in Wireshark, note drops.
4. Rate limit TCP: Run socat TCP on 2025, add `sudo iptables -A INPUT -p tcp --dport 2025 -m limit --limit 10/min -j ACCEPT; sudo iptables -A INPUT -p tcp --dport 2025 -j REJECT`.
5. Flood test: Script rapid connections (e.g., loop `nc <VM_IP> 2025`), observe rejects.
6. Advanced UDP: Block based on flags or ports, e.g., `sudo iptables -A INPUT -p udp --sport 53 -j ACCEPT` (allow DNS responses).
7. Cleanup: `sudo iptables -F`.

Questions: How does stateful filtering improve over basic drops? Integrate into mind map with TCP/UDP reliability branches.
