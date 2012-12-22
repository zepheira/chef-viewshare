Description
===========
Installs and configures a Viewshare instance with a mysql database and memcached.


Requirements
============

The following cookbooks are direct dependencies:

 * python
 * application
 * application_python -- Requires the Zepheira fork at https://github.com/zepheira/application_python.git
 * application_nginx -- Requires the Zepheira fork at https://github.com/zepheira/application_nginx.git
 * database
 * nginx


In addition, the following cookbooks should be run prior to applying this one:

 * python
 * nginx
 * mysql::server
 * mysql::client
 * memcached (optional)

Attributes
==========
- node["viewshare"]["server_name"]: The hostname for the service.  Defaults to the node['fqdn'] value

- node["viewshare"]["port"]: The port to serve the web application from in Nginx.  Defaults to 80

- node["viewshare"]["application_port"]: The port to run the gunicorn server on.  Defaults to 8080

- node["viewshare"]["debug"]: A boolean value indicating whether the django server should be run in debug mode

- node["viewshare"]["repository"]: The viewshare repository to clone from

- node["viewshare"]["revision"]: The revision to use.  Defaults to 'master'

Usage
=====

Include recipe["viewshare"] in the run list.
