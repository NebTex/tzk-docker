# tzk-docker

### requirements


 * generate and acl token with `uuidgen`
 * the master server should be public and have a public domain or subdomain
  associated with it

### Create a master server

    ```docker run --env ACLToken=$ACLToken --env ConsulHost=$ConsulHost
     --env master=true --net=host --device=/dev/net/tun --cap-add NET_ADMIN
      --volume /consul:/consul --volume /caddy:/root/.caddy tzk```


### Create a node

    ```docker run --env ACLToken=${ACLToken} --env ConsulHost=$ConsulHost
        --net=host --device=/dev/net/tun --cap-add NET_ADMIN tzk```

