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

docker exec -it deploy-1 /bin/bash
 git clone --branch study-4-2022 https://github.com/chuhakhanh/vmware-coa-aio-train
cd vmware-coa-aio-train 
cp -u config/hosts /etc/hosts 
ssh-keygen 
curl http://repo-1/images/cirros-0.5.2-x86_64-disk.img --output /root/cirros-0.5.2-x86_64-disk.img 

# Deploy lab

## Deploy Test
ansible-playbook -i config/inventory_test deploy_coa_lab_vmw_test.yml
./key_copy.sh host_list_test.txt
ansible-playbook -i config/inventory_test deploy_coa_lab_os.yml

## Deploy Production
### Deploy all virtual machine

ansible-playbook -i config/inventory deploy_coa_lab_vmw.yml
./key_copy.sh config/host_list.txt 
ansible-playbook -i config/inventory deploy_coa_lab_os.yml

### Deploy demo project on share 
export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
export OS_AUTH_URL=http://172.11.62.1:5000/v3; ./init-runonce.sh 172.12.62.50 172.12.62.100
export OS_AUTH_URL=http://172.11.63.1:5000/v3; ./init-runonce.sh 172.12.63.50 172.12.63.100
export OS_AUTH_URL=http://172.11.64.1:5000/v3; ./init-runonce.sh 172.12.64.50 172.12.64.100
export OS_AUTH_URL=http://172.11.65.1:5000/v3; ./init-runonce.sh 172.12.65.50 172.12.65.100
export OS_AUTH_URL=http://172.11.66.1:5000/v3; ./init-runonce.sh 172.12.66.50 172.12.66.100
export OS_AUTH_URL=http://172.11.67.1:5000/v3; ./init-runonce.sh 172.12.67.50 172.12.67.100
export OS_AUTH_URL=http://172.11.68.1:5000/v3; ./init-runonce.sh 172.12.68.50 172.12.68.100
export OS_AUTH_URL=http://172.11.69.1:5000/v3; ./init-runonce.sh 172.12.69.50 172.12.69.100
export OS_AUTH_URL=http://172.11.70.1:5000/v3; ./init-runonce.sh 172.12.70.50 172.12.70.100
export OS_AUTH_URL=http://172.11.71.1:5000/v3; ./init-runonce.sh 172.12.71.50 172.12.71.100
export OS_AUTH_URL=http://172.11.72.1:5000/v3; ./init-runonce.sh 172.12.72.50 172.12.72.100
openstack server add floating ip demo1 <FLOATING-IP>
# Troubleshooting
tail -f /var/tmp/packstack/latest/openstack-setup.log 
ps -ef | grep -v "\["