#!/bin/bash
printf "\n\nsetting executable permssion to all binaries sh\n\n"
ls -l /root/binaries/*.sh | awk '{print $9}' | xargs chmod +x

printf "\nYour available wizards are:\n"
echo -e "\t~/binaries/akstmcwizard.sh"
echo -e "\t~/binaries/akscreateandattach.sh --help"

cd ~

/bin/bash