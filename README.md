# vmware-coa-aio-train

## On deploy node configure docker repo to repo-1 and download deloyment docker
 vi /etc/docker/daemon.json
{
  "insecure-registries" : ["repo-1:4000"]
}

docker pull repo-1:4000/openstack.kolla/centos-source-deploy:xena
docker run -d --name deploy-1 repo-1:4000/openstack.kolla/centos-source-deploy:xena
docker exec -it deploy-1 /bin/bash; 

## On deployment docker download requirements file
docker exec deploy-1 git clone https://github.com/chuhakhanh/vmware-coa-aio-train 
cp -u config/hosts /etc/hosts 
curl http://repo-1/images/cirros-0.5.2-x86_64-disk.img --output /root/cirros-0.5.2-x86_64-disk.img 

# Deploy 
ansible-playbook -i config/inventory deploy_coa_lab.yml
ansible-playbook -i config/inventory deploy_coa_lab.yml --start-at-task="Deploy the Openstack Xena by packstack on all host"
ansible-playbook -i config/inventory deploy_coa_lab.yml --start-at-task="Create project flavor"