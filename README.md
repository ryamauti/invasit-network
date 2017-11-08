# INVASIT (WPA/WPA2 Fast Cracker)

Invasit is an automatizated bash script to invade WPA2 networks with wordlist method. Maybe you are tired (as me) to open several terminals and write several lines just to put the nic in monitor mode, get the bssids' and bla bla bla. Here is a new way, easy way, that I hope to grow up and become a monster of network invasions. It's a housemade script so you maybe find some errors. If you know some tricks to let it easier, please, let me know and fix them as you well want. To a b{etter,rilliant} future.
## PURE BASH ##

Made for Kali.

How to:

\# git clone https://github.com/valvesss/invasit-network.git

\# cd invasit-network

\# chmod +x invasit.sh

\# ./invasit.sh

Note: The part of the code that was retrieved from fluxion is specified inside the code.
https://github.com/FluxionNetwork/fluxion

Contact: sleepyhollow.lockwood@protonmail.ch

-----
Edit 08-nov-2017:
Just added an one-time-one-machine-tested code for Raspberry Pi 3 with kali Linux.

\# bash ./invasitrpi.sh

It works on NEXMON's image: kali-2017.2-rpi3-nexmon.img
Environment setup: make sure you have installed Kali Linux Full:
\# apt-get install kali-linux-full

The wireless device on Raspberry Pi doesn't support by default monitor mode, but thanks to NEXMON's image it does.
The code itself runs a command to allow monitor mode:
\# nexutil -m2

In case this doesn't work, try ruunning it with '-m1' prior to execute the code.

Do not start the code as sh ./invasitrpi.sh, because it will invoke dash, not bash.

The last part of the code, wordlist matching, really takes a considerable amount of time running on RPi. it is adviseable to break the code in two and send the handshake to a more efficient CPU.
The code to run it and stop before wordlist search is:

\# bash invasitrpistop.sh


Please contribute!
