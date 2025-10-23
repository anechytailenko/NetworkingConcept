# Lesson 7: Network Design, SSH, and Find Utility

## Lesson Goals and Grading Scope
The main goal of this lesson is to deepen SSH configuration skills (password authentication and port changes), advance data searching with `find`/`grep` on generated datasets, and apply prior knowledge in a collaborative router design project. This fosters self-directed learning through flipped preparation (individual mind maps) and group decision-making. Students will simulate enterprise scenarios, debating designs for hierarchical networks with asymmetric access.

## Grading (Total: 2 Points)
- **0.5 points** - SSH password/port setup and extra tunneling practice (Task 1).
- **0.5 points** - Advanced `find`/`grep` on generated data + CSV analysis (Task 2).
- **1 point** - Collaborative network design with routers (Task 3).

## Warming Up
This is a brief task (5–10 minutes) related to command-line skills. Use Windows PowerShell or macOS/Linux terminal (depending on your operating system) or the VM shell (`multipass shell noble`).

### Knowledgebase
**SSH:** `adduser`, `sshd_config` (PasswordAuthentication/KbdInteractiveAuthentication), `systemctl restart ssh`, `systemctl edit ssh.socket` (ListenStream for ports).  
**Data tools:** `find -name "*pattern*"`, `grep -Ri "word" .` (recursive content search), `tldr find`/`grep` for examples.  
**Flipped tip:** Pre-class, create a personal mind map in Miro ("SSH Security → Data Tools: Branches for auth methods vs. search patterns"). Share in the group chat.

### Warming-Up Tasks
1. Run `tldr ssh` and `tldr find` in the VM/host shell; note 2–3 key options for password authentication and name searches.
2. Quick test: In the VM, run `find /usr/bin -name "*ls*"` (list matching files); `grep -i "error" /var/log/auth.log | head -3` (search recent SSH logs).
3. Discuss in pairs: How might mind mapping link SSH changes to data auditing (e.g., `grep` logs post-config)?

## Task 1: SSH Access with Password and Extra Tunneling (0.5 Points)

> **NOTE:** SSH access with passwords is not recommended for real tasks, as it has weak protection compared to the SSH key approach. However, during the exam, we will use this approach to simplify the scenario. It is also important to know that this authorization method exists and can be applied for some types of tasks.

1.0. Start the virtual machine, for example: `multipass shell noble`.

1.1. Add a new user named `test` (choose any password you like; skip all other values by pressing Enter):  
   `sudo adduser test`

1.2. Try to open a secure shell for the new user from your host. Open Terminal/PowerShell and use the following command:  
   `ssh test@<IP of VM>`  
   It should return an error like "Permission denied (publickey)."

1.3. Edit the SSH config to allow access with a password:  
   `sudo nano /etc/ssh/sshd_config`  
   Ensure that the following lines are uncommented and set to `yes` (use Ctrl+W to search for those lines):  
   `PasswordAuthentication yes`  
   `KbdInteractiveAuthentication yes`

1.4. To apply the config, restart the SSH service:  
   `sudo systemctl restart ssh`

1.5. Now repeat step 1.2. If everything is fine, you should be prompted to enter the password for user `test`. Enter the password.

1.6. Use the commands `whoami` and `pwd` to ensure that you have just logged in as the user `test`.

1.7. Exit that SSH session.

1.8. Now open `multipass shell noble` and change the `ssh.socket` to listen for SSH clients on some port from the interval 3000–4000 (choose any you like).

1.9. Return to Terminal/PowerShell and try to log in as the user `test` on the new port.

1.10. Ask the teacher to check the results of the previous steps.

1.11. Revert the configurations from steps 1.7 and 1.3.

1.12. Ensure that password authentication is no longer working.

1.13. Present the result of 1.12 to the teacher.

## Task 2: Advanced Find/Grep & Data Analysis (0.5 Points)

2.1. Log in to the virtual machine and `cd` to the folder `week8` (or create it if needed): `mkdir -p ~/week8 && cd ~/week8`. Create an empty shell script named `generate_files.sh` and grant it execution permissions:  
   `touch generate_files.sh`  
   `chmod +x generate_files.sh`

2.2. Use `nano` or VS Code to add the following Bash script logic into `generate_files.sh`:

   ```bash
   #!/bin/bash

   get_random_name() {
      VALUE=$(($(date +%s) % 1000))
      echo $(sed "${VALUE}q;d" /usr/share/dict/american-english | sed "s/[^a-zA-Z]//g")
   }

   gen_random() {
      VALUE=$(($(date +%s) % 1000))
      echo "${VALUE}"
   }

   FILE_COUNT=1000
   TOP_DIR=`pwd`/test_random

   rm -rf ${TOP_DIR}
   mkdir ${TOP_DIR}
   cd ${TOP_DIR}

   apt list --installed | grep wamerican
   if [ $? -ne 0 ]; then
      sudo apt install -y wamerican
   fi

   for((i=0; i<=${FILE_COUNT}; i++))
   do
      if [ $((i % 100)) -eq 0 ]; then
         NEW_DIR=${TOP_DIR}/"$(get_random_name)"
         mkdir -p ${NEW_DIR}
         cd ${NEW_DIR} > /dev/null
      fi
      if [ $((i % 100)) -eq 20 ]; then
         NEW_SUBDIR="$(get_random_name)"
         mkdir -p ${NEW_SUBDIR}
         cd ${NEW_SUBDIR}
      fi
      if [ $((i % 3)) -eq 0 ]; then
         EXT="sh"
      else
         EXT="txt"
      fi
      RANDOM_FILE="$(get_random_name)".${EXT}
      CUR_VALUE=$(gen_random)
      for((j=0; j < $(($CUR_VALUE % 5)); j++)); do
         echo "$(get_random_name)" >> ${RANDOM_FILE}
      done
      echo -e -n "\rFile ${i}/${FILE_COUNT}"
   done

   echo ""
   ```

   > **NOTE:** This script uses the dictionary from the `wamerican` package and randomly generated numbers to create directories, files, and file content.

2.3. Run the script: `./generate_files.sh` to generate the test data.

2.4. Use the `find` command to find files with names that match some pattern, for example, files that contain the first 2 letters of your name or surname (or try other combinations if nothing is found). Search for some files with a specific extension:  
   `find ./test_random -name "*jo*\.txt"`  
   `find ./test_random -name "*tr*\.sh"`

2.5. Search through the file content for a random word or sequence of letters:  
   `grep -Ri "du" ./test_random`  
   `grep -Ri "inf" ./test_random`  
   (and so on)

2.6. Use the `cat` command on some of the files to view the content.

2.7. Choose a random word and check whether it is present either in file/folder names or inside file content. Use `find` for names and `grep` for content.

2.8. Use the `find` command to get the list of all files from the `/usr/bin` folder that contain "star" in the name. Find all the files from the `/usr/lib` folder that contain "sky" in the name:  
   `find /usr/bin -name "*star*"`  
   `find /usr/lib -name "*sky*"`

### Extra: CSV Data Analysis (from Shell Basics)
1. Go to https://data.gov.ua/en/dataset?res_format=CSV via your browser and select one of the datasets. Click the CSV button. Find the download link on the new page and use the right mouse button to copy the link address.
2. Open the shell in the virtual machine and go to the `week8` folder. Read about `wget` using `tldr wget` and, based on that, download the file from the copied link.
3. Use the `ls` command to ensure that the file was stored in the folder.
4. Rename that file to `input.csv` with the `mv` command (use `tldr mv` as a reference).
5. Use `cat` and `head` commands to print a few lines and understand the format of the data.
6. Use `grep` to filter data by some criteria you like.
7. Read about the `cut` command and use it to filter some columns. For this task, you should understand what symbol is used as a separator—usually `;` or `,`.
8. Use piping to send the result to `sort` and `uniq`.

## Task 3: Collaborative Network Design with Routers (1 Point)
This task fosters group creativity and decision-making in a simulated enterprise scenario. Groups of 4–5 students will access 3 MikroTik routers (Master, RouterMajor, RouterMinor) and independently design a hierarchical network: Master uses WiFi as WAN for internet; Major and Minor connect via eth1 for upstream access to the Master network; enforce asymmetric routing (Major → Minor allowed, Minor → Major blocked). Draw from Weeks 4–7 (routing, firewalls, bridges, WAN) to make your own choices on IPs, configs, and security—no predefined schemes!
