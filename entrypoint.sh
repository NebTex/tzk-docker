#!/usr/bin/env bash

rm -rf "/etc/tinc/${VPNName:-tzk}/"
mkdir -p "/etc/tinc/${VPNName:-tzk}/"
chmod 755 -R "/etc/tinc/${VPNName:-tzk}/"
/usr/sbin/tinc -n ${VPNName:-tzk} generate-ed25519-keys
mkdir -p "/etc/tinc/${VPNName:-tzk}/hosts"

if [ "${master:-false}" == "true" ];then
    # Place your caddy configuration file ("Caddyfile")
    # in the proper directory and give it appropriate ownership and permissions:
    sigil -p -i "$(cat /templates/Caddyfile)" \
    ConsulHost=${ConsulHost:?} > /etc/caddy/Caddyfile
    chown www-data:www-data /etc/caddy/Caddyfile
    chmod 444 /etc/caddy/Caddyfile


mkdir -p /consul/config
sigil -p -i "$(cat /templates/consul.json)" \
    ACLToken=${ACLToken:?} NodeName=master1> /consul/config/consul.json
    chown consul:consul /consul/config/consul.json
    chmod 400 /consul/config/consul.json
fi
chown consul:consul -R /consul

sigil -p -i "$(cat /templates/tzk.toml)" \
    VPNName=${VPNName:-tzk} ACLToken=${ACLToken:?} master=${master:-false} \
    Subnet=${Subnet:-10.187.0.0/16} ConsulHost=${ConsulHost:?} \
    NodeIP=${NodeIP:-} \
    PodSubnet=${PodSubnet:-}\
    > /etc/tzk.d/tzk.toml

sigil -p -i "$(cat /templates/supervisor.conf)" \
    VPNName=${VPNName:-tzk} master=${master:-false} \
    > /etc/supervisor/conf.d/supervisord.conf

export INTERFACE=${VPNName:-tzk}

#remove device if already exist
ip route del ${Subnet:-10.187.0.0/16} dev $INTERFACE
ip addr flush dev $INTERFACE
ip link set $INTERFACE down

/usr/sbin/tincd -n ${VPNName:-tzk} --pidfile=/etc/tinc/${VPNName:-tzk}/pid --logfile=/etc/tinc/${VPNName:-tzk}/tinc.logs
/usr/bin/supervisord
