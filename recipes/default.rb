application_name = "viewshare"
app_node = node[application_name]

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
node.set_unless[application_name]["secret_key"] = "#{Array.new(4).fill {secure_password}.join}"
node.save unless Chef::Config[:solo]

db_user = "root"
db_passwd = node['mysql']['server_root_password']
db_name = app_node['database_name']

mysql_database db_name do
  connection ({:host => "localhost", :username => db_user, :password => db_passwd})
  action :create
end

rabbitmq_vhost "/viewshare" do
  action :add
end

rabbitmq_user "viewshare_user" do
  password app_node[:rabbitmq_user_pass]
  action :add
end

rabbitmq_user "viewshare_user" do
  vhost "/viewshare"
  permissions "\".*\" \".*\" \".*\""
  action :set_permissions
end

django_packages = ["gunicorn"]

if node[:memcached] then
    django_packages.push("python-memcached")
end

root_path = "/srv/#{application_name}"

django_settings = {"root_path"=>root_path}

if app_node["email_settings_bag"] && app_node["email_settings_item"] then
    django_settings["email_settings"] = data_bag_item(app_node[:email_settings_bag], app_node[:email_settings_item])
end


application application_name do
    path root_path
    owner "nobody"
    group "nogroup"
    repository app_node[:repository]
    revision app_node[:revision]

    migrate true
    packages ["csstidy", "git-core", "libevent-dev"]

    django do
        requirements "requirements.txt"
        settings_template "settings.py.erb"
        local_settings_file "viewshare_site_settings.py"
        debug app_node[:debug]
        collectstatic !app_node[:debug]
        packages django_packages
        database do
            database db_name
            adapter "mysql"
            username db_user
            password db_passwd
            host "localhost"
        end

        settings django_settings

    end

    gunicorn do
        app_module :django
        host "127.0.0.1"
        port app_node[:application_port]
        worker_class "gevent"
        autostart true
        timeout 600
        max_requests 1500

        #server_hooks :post_fork => "from psycogreen.gevent import patch_psycopg; patch_psycopg()"
    end

    celery do
      config "celeryconfig.py"
      django true
      celerybeat true
      broker do
        transport "amqplib"
      end
    end

    nginx_load_balancer do
        application_port app_node[:application_port]
        template "nginx.conf.erb"
        static_files "/static" => "#{root_path}/shared/static",
                     "/media" => "#{root_path}/shared/media"
        locations "/static/CACHE" => {"alias" => "#{root_path}/shared/static/CACHE",
                                      "expires" => "max",
                                      "gzip_static" => "on"},
                  "/fileuploads" => {"alias" => "#{root_path}/shared/upload",
                                     "internal" => nil}
        server_name app_node[:server_name]
        port app_node[:port]
    end
end

if app_node["auth_protect"] then
  cookbook_file "#{node['nginx']['dir']}/conf.d/#{application_name}.htpass" do
    source "htpasswd"
    owner node['nginx']['user']
    mode 00600
    notifies :restart, resources(:service => "nginx")
  end
end

nginx_site "000-default" do
  enable false
end

nginx_site "default" do
    enable false
end

if node[:recipes].include?("iptables")
  iptables_rule application_name do
    variables(:port => node[application_name][:port])
  end
end
