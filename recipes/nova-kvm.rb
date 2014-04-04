include_recipe 'chef-openstack::common'
#include_recipe "chef-openstack::libvirt"

bash 'Clean libvirt networks' do
  user 'root'
  code <<-EOH
  virsh net-destroy default
  virsh net-undefine default
  EOH
  action :nothing
end

package "nova-compute" do
  action :install
  if node[:node_info][:is_vm] == 'True'
    package_name "nova-compute-qemu"
  else
    package_name "nova-compute-kvm"
  end
  notifies :run, "bash[Clean libvirt networks]", :immediately
end

service 'nova-compute' do
  provider Chef::Provider::Service::Upstart
  action :nothing
end

bash 'grant privileges' do
  not_if 'grep nova /etc/sudoers'
  code <<-CODE
  echo 'nova ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
  CODE
end

template 'Nova compute api-paste' do
  path '/etc/nova/api-paste.ini'
  source 'nova/api-paste.ini.erb'
  owner 'nova'
  group 'nova'
  mode '0600'
  notifies :restart, resources(:service => 'nova-compute')
end

template 'Nova compute configuration' do
  path '/etc/nova/nova.conf'
  source 'nova/nova.conf.erb'
  owner 'nova'
  group 'nova'
  mode '0600'
  notifies :restart, resources(:service => 'nova-compute'), :immediately
end

include_recipe "chef-openstack::neutron-compute"
