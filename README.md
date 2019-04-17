# How to deploy a Red Hat Enterprise Linux 8 VM, really fast
Using composer, libvirt, QEMU, virsh and some Ansible.

## Example deployment
Below, a test deployment of a RHEL8 VM. It's available for SSH within less than 7 seconds.
Follow the instructions below to do this yourself. Feel free to contribute improvements to rhel8-base.toml and qcow2.ks if you manage to optimize anything.

```
[mglantz@darkred templates]$ time sudo c_vm mtest15
Formatting '/var/lib/libvirt/images/mtest15.qcow2', fmt=qcow2 size=16106127360 backing_file=/home/mglantz/code/ansible/vm/rhel8-base-0.6.0.qcow2 cluster_size=65536 lazy_refcounts=off refcount_bits=16
Domain mtest15 created from /home/mglantz/code/ansible/vm/templates/mtest15.xml

IP-ADDRESS OF SYSTEM: 192.168.122.181
 [WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost
does not match 'all'


PLAY [Provision VM] *************************************************************************************

TASK [Debug] ********************************************************************************************
ok: [localhost] => {
    "msg": "IP of VM is: 192.168.122.181"
}

TASK [Add host into in-memory inventory] ****************************************************************
changed: [localhost]

TASK [Check so that server is online] *******************************************************************
ok: [localhost]

PLAY RECAP **********************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0   


real	0m6.663s
user	0m1.041s
sys	0m0.223s
```

## Installation of composer and sync of repos

1. Install a RHEL8 server
2. Install the following software to be able to build a qcow2 disk image with RHEL8

```
dnf install -y dnf-utils createrepo_c composer-cli lorax-composer httpd git
```

3. Enable and start Apache web server
```
systemctl enable httpd
systemctl start httpd
```

4. Sync RHEL8 to your RHEL8 composer server:
```
reposync -n -p /var/www/html --repoid rhel-8-for-x86_64-baseos-htb-rpms --downloadcomps --download-metadata
reposync -n -p /var/www/html --repoid rhel-8-for-x86_64-appstreams-htb-rpms --downloadcomps --download-metadata
```

5. Disable all repos from RHN on your server
```
subscription-manager repos disable=*
```

6. Create repos
```
createrepo -v /var/www/html/rhel-8-for-x86_64-baseos-htb-rpms/ -g $(ls /var/www/html/rhel-8-for-x86_64-baseos-htb-rpms/repodata/*comps.xml)
createrepo -v /var/www/html/rhel-8-for-x86_64-apptreams-htb-rpms/ -g $(ls /var/www/html/rhel-8-for-x86_64-appstreams-htb-rpms/repodata/*comps.xml)
```

7. Create local repository files which points to your local repos which you've now created
```
cat << 'EOF' >/etc/yum.repos.d/rhel.repo
[baseos-rpms]
name=baseos-rpms
baseurl=http://localhost/rhel-8-for-x86_64-baseos-htb-rpms
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release


[appstream-rpms]
name=appstream-rpms
baseurl=http://localhost/rhel-8-for-x86_64-appstream-htb-rpms
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF
```

8. Clone this git repository
```
git clone http://github.com/mglantz/c_vm
```

9. Replace qcow2.ks with the one from this repo.
```
cp c_vm/qcow2.ks /usr/share/lorax/composer/qcow2.ks
``` 

10. Generate a SSH key and put it into the rhel8-base blueprint from this repo with your own public SSH key
```
ssh-keygen
vi c_vm/rhel8-base.toml
```

11. Set SELinux to permissive
```
setenforce 0
```

12. Copy the edited blueprint into the blueprint folder on your server, publish it and ensure it's published
```
cp c_vm/rhel8-base.toml /var/lib/lorax/composer/blueprints/
composer-cli blueprints push rhel8-base.toml
composer-cli blueprints list|grep rhel8-base
```

13. Start a build with your new blueprint
```
composer-cli compose start rhel8-base
```

14. Verify the build and when completed, download the disk image
```
composer-cli compose status
composer-cli compose image UUID-OF-BUILD
```
15. Copy the disk image to the server you are deploying the VM from.

16. Copy __c_vm__, __provision_vm.yaml__ and __template-vm.xml__ to the server you are deploying from and ensure you have ansible installed.
```
dnf install python-pip
pip install ansible
```

17. Edit c_vm to reflect on where you have your image file, provision_vm.yaml and your template-vm.xml files.

18. Run c_vm
```
sudo c_vm name-of-vm
```

19. Done
