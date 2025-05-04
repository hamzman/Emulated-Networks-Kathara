#!/bin/bash

function usage() {
cat << EOM
usage:
  start	Start lab.
  stop	Stop and clean Lab.
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
  declare -a devices=("pc1" "pc2" "web_sheldon" "web_leonard" "web_howard" "web_penny" "web_bernadette" "web_amy" "r3" "dns_root" "dns_lb" "traefik_lb" "web_vpn" "web_cascade")
  for i in "${devices[@]}"
  do
    xterm -hold -e "kathara connect $i --logs" &
  done
}

function stop() {
  kathara lclean
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
