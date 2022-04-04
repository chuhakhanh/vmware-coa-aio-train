# vmware-coa-aio-train

docker pull kolla-deploy:xena
docker run -d --name deploy-1 kolla-deploy:xena
docker exec -it deploy-1 /bin/bash

