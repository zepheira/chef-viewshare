application_name = "viewshare"

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
node.set_unless[application_name]["secret_key"] = "#{Array.new(4).fill {secure_password}.join}"
node.save unless Chef::Config[:solo]

db_user = "root"
db_passwd = node['mysql']['server_root_password']

mysql_database 'viewshare' do
  connection ({:host => "localhost", :username => db_user, :password => db_passwd})
  action :create
end
django_packages = ["gunicorn"]

if node[:memcached] then
    django_packages.push("python-memcached")
end

root_path = "/srv/#{application_name}"

application application_name do
    path root_path
    owner "nobody"
    group "nogroup"
    repository node[application_name][:repository]
    revision node[application_name][:revision]
    #deploy_key data_bag_item("deploy", "viewshare")["deploy_key"]
    migrate true
    packages ["csstidy", "git-core", "libpq-dev"]

    django do
        requirements "requirements/deploy.txt"
        settings_template "settings.py.erb"
        debug node[application_name][:debug]
        collectstatic !node[application_name][:debug]
        packages django_packages
        database do
            database "viewshare"
            adapter "mysql"
            username db_user
            password db_passwd
            host "localhost"
        end

        settings "root_path" => root_path
        #    , "email_settings" => data_bag_item(node[application_name][:email_settings_bag], node[application_name][:email_settings_item])

    end

    gunicorn do
        app_module :django
        host "127.0.0.1"
        port node[application_name][:application_port]
        worker_class "eventlet"
        autostart true

        #server_hooks :post_fork => "from psycogreen.eventlet.psyco_eventlet import make_psycopg_green; make_psycopg_green()"
    end

    nginx_load_balancer do
        application_port node[application_name][:application_port]
        template "nginx.conf.erb"
        static_files "/static" => "#{root_path}/shared/static",
                     "/media" => "#{root_path}/shared/media"
        server_name node[application_name][:server_name]
        port node[application_name][:port]
    end
end

nginx_site "000-default" do
  enable false
end

nginx_site "default" do
    enable false
end
