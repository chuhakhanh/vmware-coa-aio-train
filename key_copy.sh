#!/bin/bash
filename=$1
while read line; do
# reading each line
sshpass -p C0@lab!2022 ssh-copy-id -f -i ~/.ssh/id_rsa.pub root@$line
done < $filename