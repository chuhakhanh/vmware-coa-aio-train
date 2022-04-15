#!/bin/bash
filename=$1
while read line; do
# reading each line
sshpass -p "P@ssw0rd@12345" ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$line
done < $filename