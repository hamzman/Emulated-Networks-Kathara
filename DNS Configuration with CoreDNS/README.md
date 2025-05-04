## Kathara automation

To reduce the amount of both time and efforts, one should favor the automation approach in Kathara framework. It can be achieved by combining `startup` files and shell scripts as well as other special kinds of files, depends on the requirement.

### Kathara's startup files
- "This file is a shell script that will be **launched** during the startup of the device.", stated by kathara documentation (ref: https://www.kathara.org/man-pages/kathara-lab-dirs.7.html). The linux commands included in these files will be automatically executed whenever you start the lab. This kind of file is frequently used in Kathara, esp. in lab strategy. A typical content of a startup file of an end-user device (e.g., pc1, web2...) is shown in the following snippet.

  ```
  #!/bin/sh
  ip address add 10.10.0.1/24 dev eth0
  ip route add default via 10.10.0.1 dev eth0
  ```

**NOTE**:
- The "shebang" (i.e., "bang") line: `#!/bin/sh` can be omitted.
- If one or some of the commands included in the startup file have not successfully executed, the terminal of that device (created by Kathara) will show you the error message, so be watchful.

### Kathara mounting
- Checkout the section **lab-path/device** found in https://www.kathara.org/man-pages/kathara-lab-dirs.7.html to understand how one can mount files into devices in a Kathara lab.

### Vyatta automation.

- First, you should check the version of vyos used in the docker image `unibaktr/vyos` by inspecting its official repository at https://github.com/uniba-ktr/vyos-docker. The implemented version is 1.1.8, so you should find the documentation of the nearest version (if possible). In this case, you should read the 1.2.x docs at https://docs.vyos.io/en/crux/.

- The 1.2.x wiki of VyOS has a section called "VyOS Automation" under the "ADMINGUIDE": https://docs.vyos.io/en/crux/automation/command-scripting.html. So we can create a shell script and include required commands so vyatta system can run these commands without human interventions. Please checkout the content of **r1/init.vbash** file for a typical example.

- However, if you try to run that file by invoking it in the startup file, as shown in the snippet below, it will not work.

  ```
  #!/bin/sh
  /bin/su -c "/bin/vbash /init.vbash" - vyos
  ```

- **WHY????**. The answer is that the **vyatta** router device needs a few seconds to initiate the vyos but the startup file is executed immediately after the device is booted. So when the startup file is executed, the vyos is not ready to run the /init.vbash file.

## Time for some magic.

![magic](mgc.gif)

- Let's take a look at the content of **r1.startup** file, shown as follows:

  ```
  #!/bin/sh
  touch /test.txt
  for i in {1..15}; do echo "Count: $i" >> /test.txt && sleep 1; done
  FILE=/init.vbash
  if [[ -f "$FILE" ]]; then
    /bin/su -c "/bin/vbash $FILE" - vyos
    rm $FILE
  fi
  ```

  Essentially, the commands included in **r1.startup** will wait for 15 seconds (line 1 - 2) and after that threshold, it will try to execute the **/init.vbash** file which holds all VyOS configuration commands.
  
- Another important file is the **lab.sh**:
  
  ```
  #!/bin/bash

  function usage() {
  cat << EOM
  usage:
    start			Start lab.
    stop			Stop and clean Lab.
  EOM
  }

  function start() {
    sudo kathara lstart --privileged
    sleep 20
    # connect to vyatta routers
    declare -a vyatta_routers=("r1" "r2")
    for i in "${vyatta_routers[@]}"
    do
      xterm -hold -e "kathara connect $i --logs" &
    done
    # connect to other devices
    declare -a devices=("pc1" "pc2" "web1" "web2" "r3")
    for i in "${devices[@]}"
    do
      xterm -hold -e "kathara connect $i --logs" &
    done
    # xterm -e "kathara connect r2" &
  }

  function stop() {
    kathara lclean
    # kill all xterm processes
    xterm_processes=`ps aux | grep xterm | grep -v root | grep -v grep | awk '{print $2}'`
    if [ $? -eq "0" ]; then
      for i in $xterm_processes; do kill -9 $i; done
    fi
  }

  if [ $# -eq 1 ]; then
    case "${1}" in
      "start" )
        start
        ;;
      "stop" )
        stop
        ;;
      * )
        usage
        ;;
    esac
  else
    usage
  fi
  exit 0
  ```
  
### TODO

- **r1/init.vbash** will need to be changed in order to accomodate DHCP approach. Try your own solution!

- If you are familliar with shell script programming, you can skip the following materials. Otherwise, here are some good online tutorials I found useful when learn "shell script programming":

  - https://www.shellscript.sh/index.html
  - https://www.youtube.com/watch?v=cQ81k1vXvcU
  - https://linuxhint.com/30_bash_script_examples/
  - TL;DR: https://tldp.org/LDP/abs/html/
  - https://www.unix.com/shell-programming-and-scripting/134781-script-kill-process-name.html
  - https://linux.die.net/man/1/xterm