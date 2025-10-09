### Week 6: Advanced Security & HTTPS Traffic Monitoring
This week advances students' understanding of SSH tunneling with dynamic port forwarding and host jumps. We will also work with WAN interfaces on a router to allow WiFi as a WAN interface to get an internet connection.

**Note**: Open this file in VSCode or another editor for better command highlighting. Use Multipass VMs ("noble" and "helperVM") for SSH tasks and HTTPS monitoring; coordinate with the teacher for MikroTik router access.

---

#### Grading (**Total: 2 points**)
Submit screenshots/outputs (e.g., Wireshark captures, command results, mind maps) via the course platform or demonstrate them to the teacher.
- (0.5 points) SSH dynamic port forwarding
- (0.5 points) SSH host jump
- (0.5 points) Monitoring of HTTPS traffic via Wireshark
- (0.5 points) Router configuration of WiFi to be a WAN interface

---

#### Warming Up: SSH access with password.
**NOTE** SSH access with a password is not recommended for real tasks, as it has weak protection compared to the SSH key approach. However, during the exam, we will use this approach to simplify the scenario. It is also important to know that such authorization exists and can be applied for some types of tasks.

1. Start the virtual machine, for example, with `multipass shell noble`.

2. Add a new user with the name `test` (choose any password you like, and all other values can be skipped by pressing Enter):  
`sudo adduser test`

3. Try to open a secure shell for the new user from your host. Open Terminal/PowerShell and use the following command:  
`ssh test@<ip of vm>`  
It should return an error like "Permission denied (publickey)".

4. Edit the SSH config to allow access with a password:  
`sudo nano /etc/ssh/sshd_config`  
and ensure that the following lines are uncommented and set to "yes" (you can use Ctrl+W to search for those lines):  
`PasswordAuthentication yes`  
`KbdInteractiveAuthentication yes`

5. To apply the config, restart the SSH service:  
`sudo systemctl restart ssh`

6. Now repeat step 3. If everything is fine, you should be prompted to enter the password for user "test". Enter the password.

7. Use the commands `whoami` and `pwd` to ensure that you just logged in as the user `test`.

8. Exit from that SSH session. Now open `multipass shell noble` and change the SSH socket to listen for SSH clients on some port from the interval 3000-4000 (choose any you like).

9. Return to Terminal/PowerShell and try to log in as the user `test` using the new port.

10. Ask the teacher to check the results of the previous steps.

11. Revert the configuration (e.g., configs from steps 8 and 4).

12. Ensure that password authentication is not working.

---

#### Task 1 (0.5 points): SSH dynamic port forwarding
# KNOWLEDGE_BASE_START
Dynamic port forwarding allows you to redirect your traffic using another host if you have SSH access to that host.  
Read more: https://www.redhat.com/en/blog/ssh-dynamic-port-forwarding  
View more: https://www.youtube.com/watch?v=AtuAdk4MwWw  
# KNOWLEDGE_BASE_END

1.1. Log in to the noble VM and block access to *kse.ua* using `iptables`. Use the OUTPUT chain, for example:  
`sudo iptables -A OUTPUT -p TCP -d kse.ua -j DROP`  
*NOTE:* This version of the iptables command will automatically detect the current results of nslookup and add them to the rule. However, if the site has more IP addresses, the site may still be reachable.

1.2. Use lynx to ensure that the site is not reachable:  
`lynx kse.ua`

1.3. Start the helperVM machine with `multipass shell helperVM` and ensure that it is accessible from the noble VM (e.g., add the public key from one machine to the other).

1.4. Return to the noble shell and run the following command:  
`ssh -N -D 7000 ubuntu@<ip of helperVM>`

1.5. Open another PowerShell/Terminal and log in to noble with `multipass shell noble`:  
`sudo iptables -D OUTPUT -p TCP -d kse.ua -j DROP`  
`sudo iptables -A OUTPUT -p TCP -d kse.ua -j DROP`  
`lynx kse.ua`

1.6. The site should not be accessible. Add an additional argument with our proxy mapped to localhost:7000:  
`lynx -socks5_proxy=localhost:7000 kse.ua`

1.7. Check `lynx kse.ua` one more time.

1.8. Clean up the iptables rules. You may need to run the command multiple times:  
`sudo iptables -D OUTPUT -p TCP -d kse.ua -j DROP`

1.9. Check that `sudo iptables -L` returns an empty set of rules. Ensure that `lynx kse.ua` works fine.

---

#### Task 2 (0.5 points): SSH host jump
# KNOWLEDGE_BASE_START
Suppose we have our LAPTOP machine and we want to access a SERVER machine. However, we have a problem because the SERVER belongs to a private network of our organization, while our LAPTOP is currently outside of that network. On the other hand, we have a FIREWALL machine that is connected to both the private network and the internet. We also have access to our user account on the FIREWALL machine, and from that account, we can reach the SERVER machine.

LAPTOP =(ssh)=> FIREWALL =(ssh)=> SERVER

To avoid multiple logins to different shells, we can use the host jump functionality of SSH.

Read more: https://wiki.gentoo.org/wiki/SSH_jump_host  
# KNOWLEDGE_BASE_END

2.1. In this task, we will use the following mapping of the machines to the scheme described above:  
LAPTOP = our host operating system  
FIREWALL = noble virtual machine  
SERVER = helperVM virtual machine

2.2. For previous tasks in Practice 9.1, we already added the public key of the noble VM to the helperVM. But let's double-check that everything works fine. To do that, open 2 windows of PowerShell/Terminal and log in to noble and helperVM. Check the IP addresses of both instances.

2.3. In the shell of noble, run:  
`ssh ubuntu@<ip of helperVM>`  
If everything goes well, just use Ctrl+D to exit from SSH. Otherwise, you should properly add the public key from noble to helperVM.

2.4. In PowerShell/Terminal, check that the noble VM is accessible via SSH:  
`ssh ubuntu@<ip of noble>`  
If everything goes well, just use Ctrl+D to exit from SSH. Otherwise, you should properly add the public key of the host to the noble VM.

2.5. In PowerShell/Terminal, check that helperVM is accessible via SSH:  
`ssh ubuntu@<ip of helperVM>`  
If you get "Permission denied (publickey)", then execute step 2.6; otherwise, go to step 2.7.

2.6. Copy the public key from the host (received as output in PowerShell/Terminal):  
`cat ~/.ssh/id_ed25519.pub`  
Add that key to ~/.ssh/authorized_keys inside helperVM. Log out from helperVM and repeat the check from step 2.5.

2.7. Set up an iptables rule for helperVM to reject SSH connections from the host: Log in to helperVM and reject input connections from the host IP:  
`sudo iptables -A INPUT -p tcp --dport 22 -s <ip of host> -j REJECT`  
*NOTE:* Your shell may hang at this time, as this command disables access from the host.

2.8. Open PowerShell/Terminal and try to access helperVM from the host:  
`ssh ubuntu@<ip of helperVM>`  
You should get "port 22: Connection refused".

2.9. Magic time!!!!!  
In PowerShell/Terminal of your host:  
`ssh -J ubuntu@<ip of noble> ubuntu@<ip of helperVM>`  
The shell in helperVM should open on that command; you can check it with the `hostname` command.

2.10. Remove the iptables rule using the shell you accessed in step 2.9:  
`sudo iptables -D INPUT -p tcp --dport 22 -s <ip of host> -j REJECT`  
After that, ensure that you have direct SSH access from the host:  
`ssh ubuntu@<ip of helperVM>`

---

#### Task 3 (0.5 points): Monitoring of HTTPS traffic via Wireshark
**NOTE** For this task, you should use Google Chrome or Firefox browser.  
**KNOWLEDGE_BASE_START**  
The HTTPS protocol uses encryption, which prevents direct monitoring of requests and responses. However, if you have the private key of the client, you will be able to tune Wireshark settings and analyze the traffic. In most browsers, this can be achieved with the SSLKEYLOGFILE environment variable. That file will store all the information needed by Wireshark to do the magic.  
**KNOWLEDGE_BASE_END**

3.1. On your host machine, create a folder that will be used for the key log file. Let it be, for example, ~/TestTLS.

3.2. Open Wireshark and choose the WiFi interface for monitoring. Go to menu Preferences => Protocols => TLS and set (Pre)-Master-Secret log filename to <path to home>/TestTLS/sslkeys.log (or, in the case of Windows, <path to home>\TestTLS\sslkeys.log). Click OK.

3.3. Use Terminal/PowerShell to perform nslookup for kernel.org to find the IP of the server. Add the IP to the Wireshark filter: `ip.addr == ip.you.just.found`.

3.4. Open the browser and go to the site https://kernel.org, then check the output in Wireshark. We are interested mostly in the TLSv1.3 parts of the output. Analyze the handshake and find the first encrypted message after the handshake. It should contain Encrypted Application Data inside the TLS section.

3.5. Close the browser and clear the Wireshark log. In the case of macOS, you may need to go to the Dock, click to open the menu for the browser application, and then Quit to completely close the application.

3.6. Open Terminal/PowerShell and run your browser from it, specifying the SSLKEYLOGFILE variable and the browser you want to run, for example:  
*macOS:*  
`SSLKEYLOGFILE=$HOME/TestTLS/sslkeys.log "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"`  
*Windows:*  
`[System.Environment]::SetEnvironmentVariable('SSLKEYLOGFILE', "$HOME/TestTLS/sslkeys.log"); & "C:\Program Files\Google\Chrome\Application\chrome.exe"`  
*Linux:*  
`SSLKEYLOGFILE=$HOME/TestTLS/sslkeys.log google-chrome`  
`SSLKEYLOGFILE=$HOME/TestTLS/sslkeys.log firefox`

3.7. Ensure that a new file was created in the TestTLS folder. Open it with a text editor and review the content.

3.8. Now open https://kernel.org in the browser and monitor the Wireshark logs. If everything works fine, you should see rows with HTTP2 highlighted with a green background. Analyze the content of the rows.

3.9. Present the teacher with the results of the steps from above.

3.10. Close the browser and remove the folder TestTLS.

---

#### Task 4 (0.5 points): WAN interface configuration and bridges on a real router

**Knowledgebase START**  
In our configuration, each router has 7 different interfaces:  
1. **ether1** - Ethernet port that is used by default as a WAN interface (e.g., allows us to get internet access from an ISP or other network with internet).  
2-5. **ether2-ether5** - Ethernet ports configured to be used as part of a LAN (e.g., Local Area Network). They are connected to a bridge with wlan interfaces; therefore, all clients of the bridged network can communicate with each other.  
6-7. **wlan1-wlan2** - Wireless interfaces used to support 2.4GHz and 5GHz WiFi networks. In our configuration, those interfaces are also part of the bridged network.  
**NOTE** A bridge allows gathering different ports and interfaces into a single logical network that will be managed consistently. This means that any user of any interface will receive an IP that belongs to a single subnet. By default, we have 192.168.88.0/24.  
**Knowledgebase END**

**The main goal** of this task is to replace the current configuration of interfaces  
*Internet ==> ether1 => bridge(ether2, ether3, ether4, ether5, wlan1, wlan2)*  
with the following:  
*Internet ==> wlan2 => bridge(ether1, ether2, ether3, ether4, ether5, wlan1)*  
Therefore, we want to get internet access via a WiFi network and share it to other interfaces.

4.1. During this task, students will be split into groups (2-3 people in every group). Each group will get its own `Router N`. For every router, we have a subnet that should be used for further router setup.

4.2. Find the corresponding WiFi network based on the number *N* and router list from above. The first student of your group should log in to the router via IP 192.168.88.1 and set up your own password for the admin user.

4.3. Now the group should set up the WiFi network `192.168.N.(4*N)/(25 + (N mod 4))` based on your number *N*. For example, if N=30, then we will have `192.168.30.4*30/(25 + 2)`, e.g., `192.168.30.120/27`. The router should get the smallest valid IP in that subnet. Ask the teacher to check the configuration and, after approval, click "Apply configuration".

4.4. Now all participants of the group should find the **Router N** network and connect to it. Now someone from the group should log in to the router. Note that you changed its IP address; therefore, you should use the new one to access the router.

4.5. Add a security profile for the network we want to connect to (**Welcome_to_KSE**). Go to Advanced => Wireless => Security Profiles. Add a new profile—you can name it, for example, **Kse**. Choose mode "Dynamic keys" and select WPA PSK, WPA2 PSK. Also check all the ciphers. You also need to specify the **WiFi password** (aka PreShared key) of the target WiFi network in the corresponding fields. Click OK to save the profile. Later, you will be able to use those settings for the connection.

4.6. Edit the wlan2 interface. Go to **Advanced => Interfaces**. As you can see, all the interfaces from the bridge (ether2-5, wlan1-2) have a mark S (slave) in the second column. Double-click on the wlan2 interface. In the subsection Wireless, we should use Station mode instead of access point. To do that, choose *Station Pseudobridge* mode. Also set the Security profile to the one you created before. Click the Apply button.

4.7. Now we are ready to connect to the Welcome_to_KSE network. Click the *Scan...* button on the same page of wlan2 configuration, and then Start at the bottom of the page. Choose any channel of the target network by double-clicking and then use the button **Connect** to use that WiFi network. Now, you can use **Wireless=>WiFiInterfaces=>wlan2** to check the status: it should be "Connected to ess" at the top part of the page.

Note: But on the other hand, you can go to the MikroTik terminal and type `/ip arp print` to see that no assigned IP is present for . Also, on the **Quick Set** page, you can find some info about the WiFi connection, but no IP address is assigned on wlan2. This is because of a missing DHCP setting - we can't automatically request the IP.
4.8 Let's set up a DHCP client. Go to **Advanced => IP => DHCP Client => Add new**. Now we should specify our wlan2 interface and click *Apply*. Return back to the terminal and check `/ip arp print` and `ping google.com` commands.

4.9. Try to use ping from the laptop connected to our WiFi network it should fail.
The reason is simple: our wlan2 interface is still a part of a bridge, and WAN is eth1.
You should fix this as we want to hav eth1 to be a part of the bridge while wlan2 should be a WAN. Use the following pages: **Advanced => Bridge => Ports** for adjusting bridged interfaces and **Advanced => Interfaces => Interface List** to change WAN interface.

**Important** As you can see, we can specify any interface as WAN. As a result, we may have multiple sources of internet and configure some priority rules so the router will use one as a default source and another as a backup source of the internet.

4.10. Go to the **Advanced => IP => DHCP Client** and ensure that you have dhcp clients for wlan2 and bridge interfaces, if not - adjust accordingly. If everything is ok, you should ping internet resources from the laptop or surfing internet via browser. 

4.11. After the teacher's check, don't forget to reset the router configuration.
