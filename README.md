# vmware-coa-aio-train
This help for create several openstack AIO in a VMware vsphere.
repo-1 is a precreated virtual machine includes:
- yum repository at Mar 2022
- regedit docker images of docker images for kolla-ansible xena and a deploy image with required lib(pythone, openstack client, etc..)
- cirros images
vars folder: 
   vmw_env.yml: environment file to create virtual machines in vsphere
   os_env.yml: environment file to create virtual machines in openstack
config folder: var and files to deploy

## On deploy node configure docker repo to repo-1 and download deloyment docker
### remove podman and install docker-ce
yum remove buildah skopeo podman containers-common atomic-registries docker container-tools
yum install docker-ce; systemctl start docker; systemctl enable docker
vi /etc/docker/daemon.json
{
  "insecure-registries" : ["repo-1:4000"]
}

docker pull repo-1:4000/openstack.kolla/centos-source-deploy:xena
docker run -d --name deploy-1 repo-1:4000/openstack.kolla/centos-source-deploy:xena
docker exec -it deploy-1 /bin/bash; 

## On deployment docker download requirements file

docker exec -it  deploy-1 /bin/bash
git clone https://github.com/chuhakhanh/vmware-coa-aio-train@study-4-2022 
cd vmware-coa-aio-train 
cp -u config/hosts /etc/hosts 
ssh-keygen 
curl http://repo-1/images/cirros-0.5.2-x86_64-disk.img --output /root/cirros-0.5.2-x86_64-disk.img 

# Deploy lab

## Deploy Test
ansible-playbook -i config/inventory_test deploy_coa_lab_vmw.yml
ansible-playbook -i config/inventory_test deploy_coa_lab_os.yml

## add hosts to ansible_host.txt ( this should be generated from invneotry file instead by manually )
key_copy.sh ansible_host.txt


## Deploy Product
### Deploy all virtual machine

ansible-playbook -i config/inventory deploy_coa_lab_vmw.yml

### Deploy openstack on share 
ansible-playbook -i config/inventory deploy_coa_lab_os.yml
ansible-playbook -i config/inventory deploy_coa_lab_os.yml --start-at-task="Create project flavor"

# Troubleshooting
tail -f /var/tmp/packstack/latest/openstack-setup.log 