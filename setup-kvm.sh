#!/bin/bash

# libvirt appears to be the cleanest abstraction of KVM/QEMU, Xen, LXC, and
# others

sudo apt-get install -y libvirt-bin

curl -LO http://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img

sudo cp trusty-server-cloudimg-amd64-disk1.img /var/lib/libvirt/images/

# tell libvirt to re-scan for new files
virsh pool-refresh default

cat <<EOF | sudo tee -a /etc/network/interfaces
	auto br0
	iface br0 inet dhcp
	  bridge_ports eth0
	  EOF
	  
sudo ifup br0

cat <<EOF > meta-data
instance-id: iid-local01;
local-hostname: ubuntu
EOF

cat <<EOF > user-data
#cloud-config

# upgrade packages on startup
package_upgrade: true

# install git
packages:
  - git

password: ubuntu
ssh_pwauth: True
chpasswd: { expire: False }

ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAkuglTT9z6rVe1OYQKmKs2wGszXlIfDL1i+dUSCPnD0umkR1PM+Qki7fDWw99YZeTYqWBZSTub0VH4AOOmfZR6ODzisa1siZ6yTEuJSE1AVuY4lC7uYtvRqy8Ez7SDRJgaJ3ZdsI2h+a0h0QsE4Y1vbVmH9TvLq7dQkDlm6GhOXM= rsa-key-20080613

EOF

genisoimage -output configuration.iso -volid cidata -joliet -rock user-data meta-data
sudo cp configuration.iso /var/lib/libvirt/images/
virsh pool-refresh default

virsh vol-clone --pool default trusty-server-cloudimg-amd64-disk1.img test.img

virt-install -r 1024 \
  -n test \
  --vcpus=1 \
  --autostart \
  --memballoon virtio \
  --network bridge=br0 \
  --boot hd \
  --disk vol=default/test.img,format=qcow2,bus=virtio \
  --disk vol=default/configuration.iso,bus=virtio

virsh list

virsh dumpxml test
