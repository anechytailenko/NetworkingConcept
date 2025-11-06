# Practice 10: Intensive Exam Preparation (nmap, SSH)

### Lesson Goals
This session is designed to consolidate the critical knowledge and skills required for the successful completion of the practical part of the Final Exam, focusing entirely on virtual machine environments and Linux command-line tools.
1. Setup of custom port for ssh and explore it with `nmap`
2. Mastery of the Linux firewall (`iptables`) and `nslookup` command for complex access control scenarios.
3. Understanding of the `ip` command output.

**Environment:** Multipass Virtual Machines (VMs) and Host terminal.

---

### Grading (Total: 2.0 Points)

| Task | Description | Points |
| :--- | :--- | :--- |
| **Task 1** | SSH custom port setup and nmap scanning | 1.0 |
| **Task 2** | `iptables` and `nslookup` | 0.5 |
| **Task 3** | `ip` command output analysis | 0.5 |

---

### Task 1: SSH custom port and network scan
**IMPORTANT** In case of misconfiguration of ssh you may loose access to VM, therefore use a new VM or VM that you not really needed.
0. Ensure that you can access this VM with ssh command e.g. you copied public part of the key to VM's ~/.ssh/authorized_keys.
1. Choose some range of ports for example 10000-15000.
2. Use shuf command to generate a random number N in this range e.g. something like `shuf -i 10000-15000 -n 1`
3. Review the config of SSH socket with `sudo systemctl cat ssh.socket`.
4. We want to create an override file(usually stored as `/etc/systemd/system/ssh.socket.d/override.conf`) that will be used as a patch for a regular unit file. In this case we should redefine `ListenStream` field. But we will not do it manually 
instead use `sudo systemctl edit ssh.socket` command inside VM to generate this override file.
**IMPORTANT** Read the comments carefully - all the content after `### Edits below this comment will be discarded` will be ignored so put the config before that.

For our task we should create a section in override file which will reset old value and then set a new port PORT_NUMBER with the generated number N from the step 2. Note that we allow it for IPv4 access only(0.0.0.0)
```
[Socket]
ListenStream=
ListenStream=0.0.0.0:PORT_NUMBER
```

5. Use `systemctl cat ssh.socket` and note that the new data is present at the bottom of the file.
6. Use `sudo ss -tlpn` to check that port 22 is used by sshd.
7. Ensure that everything is correct and call `sudo systemctl daemon-reload`.
8. Then we can restart `ssh` and `ssh.socket` units with `sudo systemctl restart ssh ssh.socket`.
9. Ensure that sshd is using the port you specified in the step 4 by running `sudo ss -tlpn`.
10. Use you host Terminal or Powershell to scan the ip of VM with `nmap <IP> -p 22` command and try to login with ssh without arguments e.g. `ssh ubuntu@<IP>`
11. Let's try to find the PORT_NUMBER with `nmap <IP> -p 10000-15000`
12. Try to use `-p PORT_NUMBER` flag in ssh command e.g. `ssh ubuntu@<IP> -p PORT_NUMBER` to login.
13. Let's return back to port 22. You can just replace your port to 22 in `systemctl edit ssh.socket` and then repeat steps 7-9.
14. Try to login to VM without port argument `ssh ubuntu@IP`.


### Task 2: `iptables` and `nslookup`
Your task is to choose any site you like(or don't like), find its IP addresses with `nslookup` and block both ping to the addresses and access to HTTP and HTTPS ports with `iptables`. You can use `lynx` to verify that filtering works fine.


### Task 3: `ip` command output
You must use `ip a` and `ip l` commands to find the following information for each *interface* - its ip address, its mac address, its default gateway. The result should be a formatted table with interface names as a first column and other parameters in the other columns.