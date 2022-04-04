# vmware-coa-aio-train
 vi /etc/docker/daemon.json
{
  "insecure-registries" : ["repo-1:4000"]
}

docker pull repo-1:4000/openstack.kolla/centos-source-deploy:xena
docker run -d --name deploy-1 repo-1:4000/openstack.kolla/centos-source-deploy:xena
docker exec deploy-1 git clone https://github.com/chuhakhanh/vmware-coa-aio-train 
docker exec -it deploy-1 /bin/bash; cd vmware-coa-aio-train/; cp -u config/hosts /etc/hosts 
ansible-playbook -i config/inventory deploy_coa_lab.yml
ansible-playbook -i config/inventory deploy_coa_lab.yml --start-at-task="Create security group rules"