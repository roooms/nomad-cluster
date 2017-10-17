#!/bin/bash

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
new_hostname="nomad-$${instance_id}"
agent_type="${agent_type}"

# set the hostname
hostnamectl set-hostname "$${new_hostname}"

# install docker on nomad clients
if [ "$${agent_type}" = "client" ]; then
  curl -fsSL get.docker.com -o get-docker.sh
  sh get-docker.sh
fi

# install required packages
apt-get install unzip awscli jq --yes

# install nomad
app="nomad"
version="0.7.0-beta1"
zip="$${app}_$${version}_linux_amd64.zip"
url="https://releases.hashicorp.com/$${app}/$${version}/$${zip}"
config_dir="/etc/$${app}.d"
data_dir="/opt/$${app}"

pushd /tmp > /dev/null
curl -O $${url}
unzip -q -o /tmp/$${zip} -d /usr/local/bin/
chmod 755 /usr/local/bin/$${app}
mkdir -p $${config_dir} && chmod 755 $${config_dir}
mkdir -p $${data_dir} && chmod 755 $${data_dir}
popd > /dev/null

# configure nomad agent defaults
cat > /etc/nomad.d/nomad-default.hcl <<EOF
advertise {
  http = "$${local_ipv4}"
  rpc = "$${local_ipv4}"
  serf = "$${local_ipv4}"
}
data_dir     = "/opt/nomad/data"
log_level    = "INFO"
enable_debug = true
EOF
if [ "$${agent_type}" = "server" ]; then # configure nomad as server
  cat > /etc/nomad.d/nomad-server.hcl <<EOF
server {
  enabled = true
  bootstrap_expect = ${bootstrap_expect}
}
EOF
else # configure nomad as client
  cat > /etc/nomad.d/nomad-client.hcl <<EOF
client {
  enabled = true
  options {
    "docker.cleanup.image"   = "0"
    "driver.raw_exec.enable" = "1"
  }
}
EOF
fi

# configure systemd for nomad
cat > /lib/systemd/system/nomad.service <<EOF
[Unit]
Description=nomad agent
Requires=network-online.target
After=network-online.target
[Service]
EnvironmentFile=-/etc/default/nomad
Restart=on-failure
ExecStart=/usr/local/bin/nomad agent \$OPTIONS -config=/etc/nomad.d
[Install]
WantedBy=multi-user.target
EOF

# start nomad
systemctl enable nomad
systemctl start nomad

# install nomad-join
cat > /usr/local/bin/nomad-join <<EOS
#!/bin/bash

get_server_ips() {
  aws ec2 describe-instances \
  --region "${region}" \
  --filters "Name=tag:aws:autoscaling:groupName,Values=${server_asg_name}" \
            "Name=instance-state-name,Values=running" \
  | jq '.["Reservations"][]["Instances"][]["PrivateIpAddress"]' \
  > /tmp/server_ips
}

get_server_ip_count() {
  cat /tmp/server_ips | wc -l
}

get_server_ip_list() {
  cat /tmp/server_ips | while read line; do echo "[\$${line}]"; done | jq -s 'add'
}

# count the number of servers in the server auto scaling group 
get_server_ips
server_ip_count=\$(get_server_ip_count)

# wait while there are less than three servers
while [ \$${server_ip_count} -lt 3 ]; do
  echo "\$${server_ip_count} servers available"
  echo "Waiting for at least 3 servers"
  echo "Sleeping for 10 seconds"
  sleep 10
  get_server_ips
  server_ip_count=\$(get_server_ip_count)
done
echo "\$${server_ip_count} servers available"

# get the list of servers now enough are available
server_ip_list=\$(get_server_ip_list)

# update nomad config and restart nomad
if [ -f "/etc/nomad.d/nomad-server.hcl" ]; then
  cat > /etc/nomad.d/nomad-join.hcl <<EOF
server {
  retry_join = \$${server_ip_list}
}
EOF
else
  cat > /etc/nomad.d/nomad-join.hcl <<EOF
client {
  servers = \$${server_ip_list}
}
EOF
fi
systemctl restart nomad
EOS
chmod 755 /usr/local/bin/nomad-join

# configure systemd for nomad-join
cat > /lib/systemd/system/nomad-join.service <<EOF
[Unit]
Description=nomad-join
Requires=network-online.target
After=network-online.target nomad.service
[Service]
ExecStart=/usr/local/bin/nomad-join
[Install]
WantedBy=multi-user.target
EOF

# start nomad-join
systemctl enable nomad-join
systemctl start nomad-join
