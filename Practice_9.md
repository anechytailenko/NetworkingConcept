# Practice 9: Intensive Exam Preparation (IPv4 and Iptables)

### Lesson Goals
This session is designed to consolidate the critical knowledge and skills required for the successful completion of the practical part of the Final Exam, focusing entirely on virtual machine environments and Linux command-line tools.
1. Deep understanding and proficiency in IPv4 network calculations (subnetting).
2. Mastery of the Linux firewall (`iptables`) for complex access control scenarios.
3. Consolidating networking tools (`nmap`, `nc`, `socat`) usage within the VM environment.

**Environment:** Multipass Virtual Machines (VMs) and Host terminal.

---

### Grading (Total: 2.0 Points)

| Task | Description | Points |
| :--- | :--- | :--- |
| **Warming Up** | Scanning VM Subnet and Port Discovery | — |
| **Task 1** | Complex IPv4 Subnetting Scenarios (3x) | 1.0 |
| **Task 2** | Complex iptables Filtering (Access Control) | 1.0 |

---

### Warming Up: Scanning Virtual Subnet and Port Discovery

This brief task refreshes skills related to network scanning and port identification, a fundamental skill required for the exam.

**Tools:** `nmap`, `ip a`, `nc`.

1.  Start your main virtual machine: `multipass start noble` and log in: `multipass shell noble`.
2.  Determine the IP address of your VM (`ip a`) and, crucially, the **virtual subnet** (e.g., `192.168.64.0/24`) used by Multipass to connect the host and the VM.
3.  On your host machine or other VM, use `nmap` to perform a comprehensive scan of the entire virtual subnet (e.g., `nmap 192.168.64.0/24`) to find all active devices.
4.  Identify and note the **IP address of your host machine** within the scan results.
5.  Use `nmap` to scan the top 100 ports on your VM's IP address (e.g., `nmap -F <VM_IP>`) to confirm open services (like SSH, port 22).
6.  In the VM, run a simple listener on a high port (e.g., 6767): `nc -l -p 6767`.
7.  From the host, confirm the service is open using a targeted scan: `nmap -p 6767 <VM_IP>`.
8.  Now stop nc and use a random port with `nc -l -p $(shuf -i 10000-30000 -n 1)` and then use nmap with range scan from host machine or other VM to find which port number was open.
9.  Repeat step 8 multiple times to practice the nmap.

---

### Task 1 (1.0 points): Complex IPv4 Subnetting Scenarios (Exam Focus)

This task evaluates proficiency in calculating IPv4 network parameters based on specific organizational requirements, simulating critical exam scenarios (related to,).

**Concepts:** CIDR notation, Network Address, Broadcast Address, Usable Host Count.

**For each of the three scenarios below, you must calculate and specify:**
1.  **The smallest possible Subnet Mask (in CIDR notation, e.g., /26).**
2.  **The Network Address** (the first IP in the calculated range).
3.  **The Broadcast Address** (the last IP in the calculated range).
4.  **The Usable IP Range** (the range of IPs assignable to devices).

#### Task 1.1 (Large Enterprise Network)
An organization plans to build a large Wi-Fi network. The regular device count is 240, but during major events, it must support up to **350 devices**. Calculate the smallest subnet that meets the requirement of **351 usable host IPs** (350 clients + 1 router), if the router must be assigned the IP address **10.3.115.1**.

#### Task 1.2 (Mid-Sized Departmental Network)
A development department requires an isolated network segment capable of supporting exactly **80 devices** (including workstations and internal servers). Calculate the smallest subnet that satisfies this need, if the departmental router must use the IP address **172.16.50.10**.

#### Task 1.3 (Small Test Segment)
A small team needs a secure test segment for **15 devices**. Calculate the smallest subnet that can be used, if the router of this segment must be assigned the IP address **192.168.1.137**.

---

### Task 2 (1.0 points): Complex iptables Filtering (Access Control)

This task tests the ability to implement precise network access policies using the Linux firewall utility `iptables`, focusing on the sequential nature and priority of rules.

**Concepts:** `INPUT` Chain, Source Address Filtering (`-s`), Sequential Rule Processing (`-A` vs `-I`), Service Isolation.

1.  **Setup the Target Service:**
    *   In your VM (`noble`), install `apache2` if not already present.
    *   Run a simple TCP server on port **5555** using `socat`. This port will simulate a sensitive service (e.g., an internal database):
        `socat TCP-LISTEN:5555,fork system:"echo HTTP/1.1 200 OK; echo Content-Length: 18; echo; echo Service Accessed"`
    *   Verify that you can access this service from your host machine: `nc <VM_IP> 5555`.

2.  **Define Access Policy (Restrictive):**
    The company mandates that the service running on TCP port **5555** must be blocked for all incoming connections, **except for two specific source addresses**:
    *   The VM itself (`localhost`).
    *   The assumed Administrator IP address: **10.12.24.5**.

3.  **Apply `iptables` Rules:**
    *   Implement a set of `iptables` rules in the **`INPUT` chain** that satisfies the policy defined in step 2. *Hint: The order of ACCEPT and DROP rules is critical here.*
    *   *Note:* Ensure you use the specific IP **10.12.24.5** in your rules, even if it is not your actual host IP (this simulates an external administrator).

4.  **Verification:**
    *   Verify access is maintained from the VM itself (`nc localhost 5555`).
    *   Verify that access from your host machine (assuming its IP is *not* `10.12.24.5`) is **blocked** or **rejected**.
    *   Verify that if your host IP *were* **10.12.24.5**, access would be permitted (explain how your rules ensure this, focusing on rule position).
    *   Display the final, active `iptables` rules: `sudo iptables -L -v -n`.

5.  **Cleanup:**
    *   Flush all `iptables` rules when finished: `sudo iptables -F`.
