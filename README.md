qcow2.ks get's put in /usr/share/lorax/composer

rhel8-base.toml in /var/lib/lorax/composer/blueprints/ followed by 
```
composer-cli blueprint push rhel8-base
composer-cli compose start rhel8-base qcow2
composer-cli compose image hash-from-build
```
read c_vm for rest of the details, but basically, put playbook, image from composer on your host here you deploy the vm
