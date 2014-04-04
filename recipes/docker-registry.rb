packages = %w[build-essential
              python-dev
        	  libevent-dev
        	  python-pip
        	  libssl-dev
        	  liblzma-dev
            libffi-dev
        	  git] 

packages.each do |pkg|
  package pkg do
    action :install
  end
end

bash "Install registry pip requirements file" do
	user "root"
	cwd "/opt/docker-registry"
	code <<-EOH
	pip install -r requirements.txt
	EOH
	action :nothing
end

git "/opt/docker-registry" do
  repository "https://github.com/dotcloud/docker-registry.git"
  reference "master"
  action :sync
  notifies :run, "bash[Install registry pip requirements file]", :immediately
end

template '/root/dockerrc.sh' do
  owner 'root'
  group 'root'
  mode '0644'
  source 'docker/dockerrc.erb'
end

template "/opt/docker-registry/config/config.yml" do
  source "docker/config.yml"
  owner "root"
  group "root"
  mode "0644"
end