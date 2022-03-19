# vmware-coa-aio-train

# prepare openstack environment

## Should be 6 cluster: each 5 VMs. Name would be: <cluster_name#>-<m#>. Eg: c1-m1, c1-m2 ...
## create VM

ansible-playbook deploy_vmware_coa_cluster.yml

## inject public key
cat inventory | while read line || [[ -n $line ]];
do
   # do something with $line here
   ssh-copy-id -f -i ~/.ssh/id_rsa.pub root@'$line'
done

# prepare openstack 
ansible-playbook -i inventory prepare_all_node.yml
ansible-playbook -i inventory prepare_repo_node.yml
ansible-playbook -i inventory prepare_packstack_node.yml
ansible-playbook -i inventory deploy_openstack_coa_train.yml
ansible-playbook -i inventory deploy_demo_project.yml
# # openstack
source /root/keystonerc_admin
openstack image create "cirros" --file /root/cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public
openstack flavor create --id x1 --ram 1024 --disk 1  --vcpu 1 tiny
openstack flavor create --id x2 --ram 4096 --disk 10 --vcpu 2 small
openstack flavor create --id x4 --ram 8096 --disk 50 --vcpu 2 medium
# provider netrwork: external + flat + share
openstack network create --provider-network-type flat --provider-physical-network physnet1 --external --share provider
openstack router set --external-gateway provider --enable-snat cusA-router1