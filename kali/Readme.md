Important: if you are not running reconftw as root, run `sudo echo "${USERNAME}  ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/buddha`, to make sure no sudo prompts are required to run the tool and to avoid any permission issues.

## Switch java version


```bash
update-alternatives --config java
```