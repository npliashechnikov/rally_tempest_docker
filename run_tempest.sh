#!/bin/bash -xe

source /home/rally/$SOURCE_FILE

tempest_config = /var/lib/tempest_conf/tempest.conf

wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
mv cirros-0.3.5-x86_64-disk.img /var/lib/tempest_conf/cirros.img


image_ref = `glance image-list | grep image_cirros_qa_1 | awk '{print $2}'`
if [[ ! -n ${image_ref} ]]
then
	exec glance image-create --name image_cirros_qa_1 --disk-format qcow2 --container-format bare --visibility public --from-file /var/lib/tempest_conf/cirros.img --min-disk 0
	image_ref = `glance image-list | grep image_cirros_qa_1 | awk '{print $2}'`
fi

sed -e s/insert_image_here_1/${image_ref}/g ${tempest_config}

image_ref_alt = `glance image-list | grep image_cirros_qa_2 | awk '{print $2}'`
if [[ ! -n ${image_ref_alt} ]] 
then
        exec glance image-create --name image_cirros_qa_2 --disk-format qcow2 --container-format bare --visibility public --from-file /var/lib/tempest_conf/cirros.img --min-disk 0
		image_ref_alt = `glance_alt image-list | grep image_cirros_qa_2 | awk '{print $2}'`
fi
sed -e s/insert_image_here_2/${image_ref_alt}/g ${tempest_config}

flavor_ref = `nova flavor-list | grep testing_1 | awk '{print $2}'`
if [[ ! -n ${flavor_ref} ]]
then
	exec nova flavor-create qa_flavor_1 testing_1 256 0 1
fi
sed -e s/insert_flavor_here_1/${flavor_ref}/g ${tempest_config}

flavor_ref = `nova flavor-list | grep testing_2 | awk '{print $2}'`
if [[ ! -n ${flavor_ref} ]]
then
        exec nova flavor-create qa_flavor_2 testing_2 384 0 1
fi
sed -e s/insert_flavor_here_2/${flavor_ref}/g ${tempest_config}

public_net_id = `neutron net-list | grep public | awk '{print $2}'`
sed -e s/insert_public_net_id/${public_net_id} ${tempest_config}

rally-manage db recreate
rally deployment create --fromenv --name=tempest
rally verify create-verifier --type tempest --name tempest-verifier --source /var/lib/tempest --version 15.0.0 --system-wide
rally verify configure-verifier --extend /var/lib/tempest_conf/$TEMPEST_CONF
rally verify configure-verifier --show
rally verify start --skip-list /var/lib/skip_lists/$SKIP_LIST $CUSTOM
rally verify report --type junit-xml --to report.xml
