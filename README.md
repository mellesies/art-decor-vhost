# art-decor-vhost
Script and assets for a full install of ART-DECOR (www.art-decor.org) on debian (or Ubuntu).

# Usage
The following steps should get you up and running:
* Setup a new (virtual) machine running debian Stretch
* install git 
* clone the repo

Or just use the following script as *root*:
```bash
apt-get update
apt-get install git

git clone https://github.com/mellesies/art-decor-vhost.git ./
./install_art_decor.sh

```
