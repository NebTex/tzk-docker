#!/usr/bin/env bash

rm -rf "/etc/tinc/${VPNName:-tzk}/"
mkdir -p "/etc/tinc/${VPNName:-tzk}/"
chown tzk:tzk -R "/etc/tinc/${VPNName:-tzk}/"
chmod 755 -R "/etc/tinc/${VPNName:-tzk}/"
/usr/sbin/tinc -n ${VPNName:-tzk} generate-ed25519-keys
mkdir -p "/etc/tinc/${VPNName:-tzk}/hosts"

if [ "${master:-false}" == "true" ];then
    # Place your caddy configuration file ("Caddyfile")
    # in the proper directory and give it appropriate ownership and permissions:
    sigil -p -i "$(cat /templates/Caddy)" \
    ConsulHost=${ConsulHost:?} > /etc/caddy/Caddyfile
    chown www-data:www-data /etc/caddy/Caddyfile
    chmod 444 /etc/caddy/Caddyfile

sigil -p -i "$(cat /templates/consul.json)" \
    ACLToken=${ACLToken:?} NodeName=master1> /etc/consul/consul.json
    chown consul:consul /etc/consul/consul.json
    chmod 400 /etc/consul/consul.json

fi

sigil -p -i "$(cat /templates/tzk.toml)" \
    VPNName=${VPNName:-tzk} ACLToken=${ACLToken:?} master=${master:-false} \
    Subnet=${Subnet:-10.187.0.0/16} ConsulHost=${ConsulHost:?} \
    KubernetesServiceCIDR=${KubernetesServiceCIDR:-10.96.0.0/12}
    > /etc/tzk.d/tzk.toml
    chown tzk:tzk /etc/tzk.d/tzk.toml
    chmod 400 /etc/tzk.d/tzk.toml

sigil -p -i "$(cat /templates/supervisor.conf)" \
    VPNName=${VPNName:-tzk} master=${master:-false} \
    > /etc/supervisor/conf.d/supervisord.conf

export INTERFACE=${VPNName:-tzk}

#remove device if already exist
ip route del ${KubernetesServiceCIDR:-10.96.0.0/12} dev $INTERFACE >
ip route del ${Subnet:-10.187.0.0/16} dev $INTERFACE
ip addr flush dev $INTERFACE
ip link set $INTERFACE down

/usr/bin/supervisord