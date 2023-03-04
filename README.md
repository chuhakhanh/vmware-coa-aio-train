# Openstack AIO on VMware vsphere - COA Lab

## Introduction

This guide used to create a number of virtual machine on VMware vsphere. Each VM has a AIO Openstack. 

VM description:
- deploy-1 is a VM server for deployment with Docker containers. Container deploy-1 with ansible is used to run Ansible Playbook from source.
- repo-1 is a repository server with a httpd Package Repository, a docker registry  

VM repo-1 includes:
- yum repository at Mar 2022
- regedit docker images of docker images for kolla-ansible xena and a deploy image with required lib(pythone, openstack client, etc..)
- cirros images

vars folder structure: 
- vmw_env.yml: environment file to create virtual machines in vsphere
- os_env.yml: environment file to create virtual machines in openstack
- config folder: var and files to deploy

## Setup VMware vsphere infrastructure cluster

### Prepare template 

    https://opendev.org/openstack/nova/commit/2a6bdf8f0e0e22fc7703faa9669ace7380dc73c3
    VMware: Enable disk.EnableUUID=True in vmx
    Currently there is no link in /dev/disk/by-id for SCSI (sdx) devices because by default VMWare doesn't provide information needed by udev to generate /dev/disk/by-id. When this specific parameter disk.EnableUUID
    is set to True in vmx file inside the guest vm /dev/disk/by-id shows a link to UUID of the attached SCSI device

    Edit Settings>VM Options>Advanced>Edit Configuration in Configuration Parameters>Add parameter
    disk.EnableUUID = TRUE
          
### Prepare provisioning VM deploy-1

From repo-1 export images

    docker save -o centos-source-deploy.tar 4b4369be8793

From deploy-1 

Run docker container deploy

    podman load -i centos-source-deploy.tar
    podman run -d --name deploy-1 4b4369be8793
    podman exec -it deploy-1 /bin/bash; 
    vi ~/.bashrc 
    alias ll='ls -lG'
    dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
    yum install sshpass
    yum install tmux

### Create a virtual machine cluster

    cp -f config/cluster/lab1/hosts /etc/hosts

    docker exec -it deploy-1 -u0 /bin/bash;
    git clone https://github.com/chuhakhanh/ansible-vmware-kolla-centos8
    cd /root/ansible-vmware-kolla-centos8
    git checkout poc-cgnat

    for i in lab-1 
    do
        ansible-playbook -i config/inventory_all playbooks/cluster_infra_vsphere/setup_vmware_cluster.yml -e "action=create" -l $i
    done

## Provisioning application(openstack with kolla ansible) cluster

### Push public ssh key into this machines due to predefined password (i=lab#)
    
    ssh-keygen
    chmod u+x ./scripts/key_copy.sh
    
For all cluster 
    
    for i in lab-1
    do
        ./scripts/key_copy.sh "config/cluster/$i/inventory"
    done
    
    sshpass -p "alo1234" ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@10.1.17.117
    
### Install OS prequisite for cluster

For all cluster 

    for i in lab-1 
    do
        ansible-playbook -i config/cluster/$i/inventory playbooks/cluster_app_provisioning/prepare_node_all.yml -e "lab_name=$i"
    done

Configure storage node, in this case we use NFS 

    for i in lab-1 
    do
        ansible-playbook -i config/cluster/$i/inventory playbooks/cluster_app_provisioning/prepare_node_storage.yml -e "lab_name=$i"
    done

## Prepare kolla-ansible environment

Prepare kolla-ansible

    ansible-galaxy collection install community.vmware
    pip3 install "kolla-ansible==13.7.0"
    pip3 install git+https://opendev.org/openstack/kolla-ansible@stable/xena

Prepare images ([Following steps in other gudie setup local repo ](https://github.com/chuhakhanh/local-repo-centos-stream8/Readme.md))

## Provisioning Openstack for cluster with kolla-ansible

### Prepare snapshot

Snapshot virtual machine cluster before run install 
    [Following steps in docs/guide.md to operate the cluster](docs/guide.md)

### Deploy Openstack

There may be a bug that I cannot use a specific config_dir as below command become failed
    kolla-ansible -i ./config/kolla/multinode --configdir ./config/kolla/config deploy
So that use node_config as default : /etc/kolla (https://github.com/openstack/kolla-ansible/blob/master/ansible/group_vars/all.yml) to deploy

    cp -r ./config/kolla/ /etc/

    kolla-ansible -i /etc/kolla/multinode prechecks
    kolla-ansible -i /etc/kolla/multinode pull
    kolla-ansible -i /etc/kolla/multinode deploy
    kolla-ansible -i /etc/kolla/multinode post-deploy
    kolla-ansible -i /etc/kolla/multinode reconfigure

    cp -r ./scripts/ /etc/kolla; chmod u+x /etc/kolla/scripts/init-runonce.sh; /etc/kolla/scripts/init-runonce.sh vlan
 
Initilization the Openstack Cluster node
    docker restart $(docker ps -a -q)


### Preprare deploy-1 

On deploy node configure docker repo to repo-1 and download deloyment docker

remove podman and install docker-ce
  
    yum remove buildah skopeo podman containers-common atomic-registries docker container-tools
    yum install docker-ce; systemctl start docker; systemctl enable docker
    vi /etc/docker/daemon.json
    {
      "insecure-registries" : ["repo-1:4000"]
    }
    systemctl restart docker
    docker pull repo-1:4000/openstack.kolla/centos-source-deploy:xena
    docker run -d --name deploy-1 repo-1:4000/openstack.kolla/centos-source-deploy:xena
    docker exec -it deploy-1 /bin/bash; 

On deployment docker download requirements file

    docker exec -it deploy-1 /bin/bash
    git clone --branch study-4-2022 https://github.com/chuhakhanh/vmware-coa-aio-train
    cd vmware-coa-aio-train 
    cp -u config/hosts /etc/hosts 
    ssh-keygen 
    curl http://repo-1/images/cirros-0.5.2-x86_64-disk.img --output /root/cirros-0.5.2-x86_64-disk.img 
    wget http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/sshpass-1.09-4.el8.x86_64.rpm

### Deploy lab

    chmod u+x init-runonce.sh key_copy.sh

Deploy Test

    git pull --branch study-4-2022 https://github.com/chuhakhanh/vmware-coa-aio-train
    ansible-playbook -i config/inventory_test deploy_coa_lab_vmw_test.yml
    ./key_copy.sh host_list_test.txt
    ansible-playbook -i config/inventory_test deploy_coa_lab_os.yml

## Deploy Production

Deploy all virtual machine

    ansible-playbook -i config/inventory deploy_coa_lab_vmw.yml
    ./key_copy.sh config/host_list.txt 
    ansible-playbook -i config/inventory deploy_coa_lab_os.yml

Deploy demo project on share 

    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
    export OS_AUTH_URL=http://172.11.61.1:5000/v3; ./init-runonce.sh 172.12.61.50 172.12.61.100
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

Troubleshooting
  
    tail -f /var/tmp/packstack/latest/openstack-setup.log 
    ps -ef | grep -v "\["