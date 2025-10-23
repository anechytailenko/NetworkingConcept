# Lesson 7: VLANs, Bridges, and NAT Fundamentals

---

### 0. Lesson goals and grading scope

This lesson focuses on VLAN segmentation, bridge configuration, and basic NAT setup.  
You will simulate VLANs inside a virtual machine and then reproduce a simplified version on a physical router.

**Grading (each task = 0.5 points, total = 2.0):**
- Task 1 — VLAN simulation in one VM (secondary IPs as “hosts”)  
- Task 2 — Two separate L2 domains (one bridge per VLAN) with inter-VLAN routing  
- Task 3 — NAT configuration for VLANs with Internet access  
- Task 4 — MikroTik: bridge + VLAN + NAT

---

### Knowledgebase (short summary)

- **VLAN** – logical subdivision of a network to isolate broadcast domains.  
- **Bridge** – software switch that connects interfaces into one broadcast domain.  
- **NAT (masquerade)** – rewrites the source address for outgoing traffic, allowing private subnets to reach external networks.

---

### Task 1 — VLANs within one VM (secondary IPs as simulated hosts) `(0.5 points)`

**Goal:** create two VLAN interfaces on top of your base interface and simulate one host in each VLAN using additional secondary IPs.  
Each student defines their own addressing scheme and interface names.

1. Start your VM:
   ```bash
   multipass start noble
   multipass shell noble
   ```

2. Identify the base interface (e.g., `eth0`, `ens3`, or other name):

   ```bash
   ip a
   ```
   Set it as an environment variable for convenience:
   ```bash
   export BASE=<base interface name>
   ```

3. Create two VLAN subinterfaces (for example, VLAN IDs 10 and 20):

   ```bash
   sudo ip link add link $BASE name $BASE.10 type vlan id 10
   sudo ip link add link $BASE name $BASE.20 type vlan id 20
   ```

   Check `ip link` or just `ip l` command and then bring new interfaces up:
   ```
   sudo ip link set $BASE.10 up
   sudo ip link set $BASE.20 up
   ```

4. Assign gateway IPs and additional host IPs e.g. choose your own non-overlapping subnets with some CIDR(e.g. subnet mask)—one for vlan10, another for vlan20. From each subnet you should select 2 ip addresses one for gateway(the first valid ip of the range), another for host. So you will have 4 IPs `gateway_vlan10`, `host_vlan10`, `gateway_vlan20`, `host_vlan20` and add those devices:

   ```bash
   sudo ip addr add <gateway_vlan10/CIDR> dev $BASE.10
   sudo ip addr add <host_vlan10/CIDR> dev $BASE.10
   sudo ip addr add <gateway_vlan20/CIDR> dev $BASE.20
   sudo ip addr add <host_vlan20/CIDR> dev $BASE.20
   ```
Check the output of `ip a` command and find the newly added IPs. Here we just created one virtual host in each subnet

5. Test connectivity between VLAN “hosts”:

   ```bash
   ping -I <host_vlan10_ip> <host_vlan20_ip>
   ping -I <host_vlan20_ip> <host_vlan10_ip>
   ```

**Observation:**
Ping succeeds (since routing happens inside one kernel table),
but Wireshark on your host won’t capture this traffic — it never leaves the VM.


**Why VLANs are important?**
VLANs let you divide one physical network into multiple logical networks, improving both security and efficiency. They isolate traffic between departments, projects, or services without needing separate switches or cabling. This reduces broadcast traffic, limits who can see or reach certain devices, and allows flexible network segmentation — for example, separating office users, servers, and IoT devices on the same infrastructure. VLANs are also essential for virtualization, cloud environments, and data centers, where many isolated networks share the same physical hardware.

---

### Task 2 — Two L2 segments (one bridge per VLAN) + routing between them `(0.5 points)`

**Goal:** emulate two isolated VLANs as independent L2 segments, connect them to your Linux system acting as a router, assign gateway IPs on bridges, and enable L3 forwarding between VLANs.

**Why two bridges instead of one?**
- A single bridge merges interfaces into one broadcast domain.
- Two VLANs must remain isolated — each requires its own bridge.

**Why network namespaces matter?**
Network namespaces are a Linux feature that allows one system to behave as if it were many separate networked machines. Each namespace has its own interfaces, IP addresses, and routing table — isolated from all others. This makes it possible to simulate multi-host topologies, routers, or client-server networks on a single computer without additional hardware or virtual machines.

They’re essential for learning and experimentation because they let you build, test, and break complex network setups safely. In modern infrastructure, namespaces are the foundation for containers (like Docker or Kubernetes pods), where each container runs in its own isolated network environment. Understanding namespaces gives you the same insight and control used to design real-world cloud and microservice networks.

1. Make sure you have `$BASE.10` and `$BASE.20` (from Task 1).
   Remove any IPs from them:

   ```bash
   sudo ip addr flush dev $BASE.10
   sudo ip addr flush dev $BASE.20
   ```
   Check `ip a` for vlan interfaces.

2. Check `ip link` output and then create bridges:

   ```bash
   sudo ip link add br-vlan10 type bridge
   sudo ip link add br-vlan20 type bridge
   sudo ip link set br-vlan10 up
   sudo ip link set br-vlan20 up
   ```
   Check `ip link` output.

3. Attach VLAN interfaces to their respective bridges:

   ```bash
   sudo ip link set $BASE.10 master br-vlan10
   sudo ip link set $BASE.20 master br-vlan20
   ```
   Check `ip link` output.

4. Create two namespaces and veth pairs for “hosts”:

   ```bash
   sudo ip netns add hostA
   sudo ip netns add hostB

   sudo ip link add vethA type veth peer name vethA-br
   sudo ip link add vethB type veth peer name vethB-br

   sudo ip link set vethA netns hostA
   sudo ip link set vethB netns hostB

   sudo ip link set vethA-br master br-vlan10
   sudo ip link set vethB-br master br-vlan20

   sudo ip link set vethA-br up
   sudo ip link set vethB-br up
   sudo ip netns exec hostA ip link set vethA up
   sudo ip netns exec hostB ip link set vethB up
   ```
   Check `ip a` and map to the commands from above.

5. Configure addressing (choose your own subnets similar to the task 1):

   * **Gateway IPs** on the bridges (`br-vlan10`, `br-vlan20` - use the first valid ip in the corresponding subnet)
   * **Host IPs** in namespaces (`hostA`, `hostB` - use the second valid ip of corresponding subnet)

   ```bash
   sudo ip addr add <gw_vlan10/CIDR> dev br-vlan10
   sudo ip addr add <gw_vlan20/CIDR> dev br-vlan20

   sudo ip netns exec hostA ip addr add <hostA_ip/CIDR> dev vethA
   sudo ip netns exec hostB ip addr add <hostB_ip/CIDR> dev vethB

   sudo ip netns exec hostA ip route add default via <gw_vlan10_ip>
   sudo ip netns exec hostB ip route add default via <gw_vlan20_ip>

   sudo sysctl -w net.ipv4.ip_forward=1
   ```

5. Bring up interfaces inside namespaces:
```bash
sudo ip -n hostA link set lo up
sudo ip -n hostB link set lo up

sudo ip -n hostA link set vethA up
sudo ip -n hostB link set vethB up
```

6. Test connectivity between VLANs:

   ```bash
   sudo ip netns exec hostA ping -c 3 <hostB_ip>
   sudo ip netns exec hostB ping -c 3 <hostA_ip>
   ```

**Expected:** pings work — your Linux VM now routes packets between VLANs.

7. Let's run in background(`&` specifier at the end of the command) a simple http server inside vlan10 
```bash
sudo ip netns exec hostA python3 -m http.server 8080 --bind 0.0.0.0 &
```

8. Now try to access it from hostB
```bash
sudo ip netns exec hostB curl http://<hostA_ip>:8080
```

9. Block http from vlan20 to vlan10
```bash
sudo iptables -I FORWARD -s <vlan20 subnet> -d <vlan10 subnet> -p tcp --dport 8080 -j DROP
```
**IMPORTANT** We should use `-I` instead of `-A` flag as it inserts the rule before other rules.

10. Try to access the server from hostB as in step 8.
You should see that connection is refused.
11. On completion remove iptables rule.
```bash
sudo iptables -D FORWARD -s <vlan20 subnet> -d <vlan10 subnet> -p tcp --dport 8080 -j DROP
```

---

### Task 3 — NAT for VLANs with Internet access `(0.5 points)`

**Goal:** configure NAT so that both VLAN subnets can access the Internet via your VM’s main external interface (e.g., `enp0s3` or other interface depending on the host OS).

1. Make sure VLAN routing (Task 2) is working and `ip_forward=1`.

2. Check whether internet is accessible from hostA and hostB:
   ```bash
   sudo ip netns exec hostA ping -c 3 8.8.8.8
   sudo ip netns exec hostB ping -c 3 8.8.8.8
   ```

2. Add masquerade rules for both VLAN subnets:

   ```bash
   sudo iptables -t nat -A POSTROUTING -s <vlan10_subnet_mask>/<CIDR> -o $BASE -j MASQUERADE
   sudo iptables -t nat -A POSTROUTING -s <vlan20_subnet_mask>/<CIDR> -o $BASE -j MASQUERADE
   ```

3. Check NAT table counters:

   ```bash
   sudo iptables -t nat -L -v
   ```

4. Test Internet access from both hosts:

   ```bash
   sudo ip netns exec hostA ping -c 3 8.8.8.8
   sudo ip netns exec hostB ping -c 3 8.8.8.8
   ```

**Expected result:**
Both VLAN hosts have Internet connectivity through the main VM interface.
NAT counters increase in `sudo iptables -t nat -L -v` - check bytes column and compare with ping command output e.g. amount of bytes in ping.
Wireshark on the host can see only translated packets (with external IP).

---

### Task 4 — MikroTik Router N: bridge + VLAN + NAT `(0.5 points)`

**Goal:** replicate key concepts (VLAN segmentation + NAT) on your assigned router (**Router N**).

1. **Login** to the router.
2. **Edit a bridge** using **Advanced => Bridge** to toggle on *VLAN Filtering* in `bridge` interface.
3. **Add two VLANs**:
VLAN10:
- Bridge => Ports => (double click on ether2) => VLAN subsection:
- PVID = 10, Frame Types = admit-only-untagged-and-priority-tagged => OK.

VLAN20:
Bridge => Ports => (double click on ether3) => VLAN subsection:
PVID = 20, Frame Types = admit-only-untagged-and-priority-tagged => OK.

4. Go to Bridge => VLANs => New (+) to provide the following VLANs
```
Bridge = bridge VLAN ID = 10 Tagged: bridge Untagged: ether2
```
and
```
VLAN ID = 20 Tagged: bridge Untagged: ether3
```

5. Now we will **assign IPs** for VLAN gateways according to your group’s addressing plan.
- Go to Interfaces => VLAN => New:
```
name = vlan10, VLAN ID = 10, Interface = bridge  => Press OK
```
and
```
name = vlan20, VLAN ID = 20, Interface = bridge  => Press OK
```

- Go to IP => Addresses => New:

address = <GW_IP_for_VLAN10>/<mask>, interface = vlan10

address = <GW_IP_for_VLAN20>/<mask>, interface = vlan20

- Go to IP => DHCP Server => Networks, add your networks e.g. subnet mask and gateway e.g. something like x.y.z.0/24. Set DNS server to 8.8.8.8
- Create IP pools for servers with IP => Pool and create valid ranges vlan10-pool and vlan20-pool according to your subnets. Note: range should be specified in form x.y.z.2-x.y.z.254 where x, y, z and range is defined by your subnet.
- Go to IP => DHCP Server and create server for vlan10 with interface vlan10-dhcp, Address-pool vlan10-pool, then one more for vlan20-dhcp with vlan20-pool.



6. **Validation:**

Connect your laptop to ether2 ( VLAN 10): it should get an IP from VLAN10 and it should be displayed on the quick set page in the list of host. Use terminal to ping the ip form VLAN10 mentioned on the page.

---
