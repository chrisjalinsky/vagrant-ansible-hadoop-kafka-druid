VAGRANTFILE_API_VERSION = "2"

base_dir = File.expand_path(File.dirname(__FILE__))

# Cluster, VM and network settings
NETWORK_SUBNET = "172.16.8"
NUM_COORDS = 3
NUM_HISTS = 0
NUM_BROKERS = 0
NUM_REALs = 0
COORD_IPS_START = 10
HIST_IPS_START = 100
BROKER_IPS_START = 200
REAL_IPS_START = 50
COORD_MEMORY = 4096
HIST_MEMORY = 1024
BROKER_MEMORY = 1024
REAL_MEMORY = 1024
COORD_CPU = 1
HIST_CPU = 1
BROKER_CPU = 1
REAL_CPU = 1
CLUSTER = {}

# Build the cluster
(1..NUM_COORDS).each do |i|
  CLUSTER["cd#{i}.lan"] = {:ip => "#{NETWORK_SUBNET}.#{COORD_IPS_START + i}",  :cpus => "#{COORD_CPU}", :mem => "#{COORD_MEMORY}"}
end

(1..NUM_HISTS).each do |i|
  CLUSTER["dhist#{i}"] = {:ip => "#{NETWORK_SUBNET}.#{HIST_IPS_START + i}",  :cpus => "#{HIST_CPU}", :mem => "#{HIST_MEMORY}"}
end

(1..NUM_BROKERS).each do |i|
  CLUSTER["dbrok#{i}"] = {:ip => "#{NETWORK_SUBNET}.#{BROKER_IPS_START + i}",  :cpus => "#{BROKER_CPU}", :mem => "#{BROKER_MEMORY}"}
end

(1..NUM_REALs).each do |i|
  CLUSTER["dreal#{i}"] = {:ip => "#{NETWORK_SUBNET}.#{REAL_IPS_START + i}",  :cpus => "#{REAL_CPU}", :mem => "#{REAL_MEMORY}"}
end

ansible_provision = proc do |ansible|
  # Note: Can't do ranges like ans[0-2] in groups because
  # these aren't supported by Vagrant, see
  # https://github.com/mitchellh/vagrant/issues/3539
  #  ansible.groups = {
  #    "local" => ["localhost"],
  #    "druid_coordinators"  => (1..NUM_COORDS).map { |i| CLUSTER["dcoord#{i}"][:ip] },
  #    "druid_historicals" => (1..NUM_HISTS).map { |i| CLUSTER["dhist#{i}"][:ip] },
  #    "druid_brokers" => (1..NUM_BROKERS).map { |i| CLUSTER["dbrok#{i}"][:ip] },
  #    "druid_realtimes" => (1..NUM_REALS).map { |i| CLUSTER["dreal#{i}"][:ip] },
  #    "druid_cluster:children" => ["druid_coordinators","druid_historicals", "druid_brokers","druid_realtimes"]
  #  }
  ansible.verbose = "v"
  ansible.inventory_path = base_dir + "/inventory/vagrant"
  ansible.playbook = base_dir + "/cluster.yml"
  ansible.limit = "#{info[:ip]}" # Ansible hosts are identified by ip
end


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :machine
    config.cache.enable :apt
  end

  CLUSTER.each do |hostname, info|

    config.vm.define hostname do |cfg|

      cfg.vm.provider :virtualbox do |vb, override|
        override.vm.box = "ubuntu/trusty64"
        override.vm.network :private_network, ip: "#{info[:ip]}"
        override.vm.hostname = hostname

        vb.name = hostname
        vb.customize ["modifyvm", :id, "--memory", info[:mem], "--cpus", info[:cpus], "--hwvirtex", "on" ]
      end

      # provision nodes with ansible
      cfg.vm.provision :ansible do |ansible|
        ansible.verbose = "v"

        ansible.inventory_path = "hosts"
        ansible.playbook = base_dir + "/site.yml"
        ansible.limit = "#{hostname}"
      end

    end

  end

end