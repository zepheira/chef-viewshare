maintainer       "Zepheira"
maintainer_email "systems@zepheira.com"
license          "All rights reserved"
description      "Installs/Configures viewshare"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.2"
name			 "viewshare"

depends 'application'
depends 'application_python'
depends 'application_nginx'
depends 'database'
depends 'nginx'
depends 'iptables'
depends 'rabbitmq'
