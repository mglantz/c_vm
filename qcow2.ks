# Lorax Composer qcow2 output kickstart template

# Firewall configuration
firewall --disable

# NOTE: The root account is locked by default
# Network information
network  --bootproto=dhcp --onboot=on --activate
# System keyboard
keyboard --xlayouts=us --vckeymap=us
# System language
lang en_US.UTF-8
# SELinux configuration
selinux --enforcing
# Installation logging level
logging --level=info
# Shutdown after installation
shutdown
# System timezone
timezone  EU/Stockholm
# System bootloader configuration
bootloader --location=mbr

%post
# Remove random-seed
rm /var/lib/systemd/random-seed

# Clear /etc/machine-id
rm /etc/machine-id
touch /etc/machine-id

# Boot time optimization
sed -i -e 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
echo "GRUB_HIDDEN_TIMEOUT=0" >>/etc/default/grub
echo "GRUB_HIDDEN_TIMEOUT_QUIET=true" >>/etc/default/grub
sed -i -e 's/rhgb quiet/text quiet fastboot cryptomgr.notests tsc.reliable=1 rd.shell=0 ipv6.disable=1 rd.udev.log-priority=3 noprobe no_timer_check printk.time=1 usbcore.nousb cgroup_disable=memory/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

for item in firewalld.service auditd.service rhsmcertd.service tuned.service spice-vdagentd.socket remote-fs.target dnf-makecache.service chronyd.service kdump.service sssd.service; do systemctl disable $item; done

%end

%packages
kernel
-dracut-config-rescue
selinux-policy-targeted
grub2

# Make sure virt guest agents are installed
qemu-guest-agent
spice-vdagent

# NOTE lorax-composer will add the blueprint packages below here, including the final %end
