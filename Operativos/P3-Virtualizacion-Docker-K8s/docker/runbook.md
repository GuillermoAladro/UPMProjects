# Docker runbook — Questions 1 to 14

Every command runs inside the Debian VM of the practice, as user `estudiante`
unless stated otherwise. `install-docker.sh` covers Question 1 and must be run
as root; the group membership it grants only applies after reopening the session.

## Checking the installation (Q2)

```bash
id                    # estudiante must appear in the docker group
docker run hello-world
docker images
```

## Container lifecycle (Q3)

Several containers, started in different ways:

```bash
docker run --detach eclipse-mosquitto   # detached, long-running broker
docker run -d ubuntu sleep 1000         # detached, exits after 1000 s
docker run --name servidorweb nginx     # foreground: needs a second session
```

From another session:

```bash
docker ps                               # running containers
docker logs <id|name>                   # stdout/stderr of a container
docker exec -it <id|name> bash          # shell inside the container
```

Inside that shell, the isolation is visible: `id`, `df`, `mount`, `cat /etc/hosts`,
`ps ax`, `netstat -an` and `ifconfig` show a filesystem, a process table and a
network stack of the container's own, while the kernel is the host's. Network
tools usually need installing first (`apt update && apt install procps net-tools
inetutils-ping curl`), because images ship only what the application needs.

Copying files across the boundary, stopping and restarting:

```bash
docker cp servidorweb:/usr/share/nginx/html/index.html .
docker cp fichero.txt servidorweb:/tmp

docker stop <id|name>       # SIGTERM, ordered shutdown
docker kill <id|name>       # SIGKILL, abrupt
docker start <id|name>
docker restart <id|name>
docker rm <id|name>         # definitive removal

docker stats                # live CPU / memory per container
docker network ls
docker network inspect <id|name>
```

## Images (Q4)

```bash
docker search nginx
docker pull nginx
docker images
docker history nginx        # the layers the image is built from
docker rmi nginx
```

## External resources (Q5 – Q7)

```bash
# Q5 - host directory as persistent storage inside the container
docker run --volume ~/contenedores/c1:/datos -d ubuntu sleep 1000

# Q6 - publish a host TCP port into the container
docker run --publish 12345:80 -d nginx
curl http://localhost:12345

# Q7 - inject an environment variable
docker run --name prueba --env VARIABLE=valor -d ubuntu sleep 1000
```

## Resource limits (Q8 – Q10, optional)

```bash
docker run --cpus 1.5 --memory 128m --name limitado -d ubuntu sleep 1000

docker exec -it limitado bash
apt update && apt install stress-ng
stress-ng --vm 4 --vm-bytes 1G --timeout 60s
```

With `top` on the host and `docker stats` side by side, the cgroup limits are
what make the difference visible: the container is capped at 1.5 CPUs whatever
`stress-ng` asks for, and its memory stays at the 128 MiB ceiling — the workers
that exceed it are killed by the OOM killer rather than swapping the host.

## WordPress by hand (Q11 – Q12)

```bash
docker run -d --name servidormdb \
  -e MYSQL_ROOT_PASSWORD=sesamo \
  -e MYSQL_DATABASE=bdwp \
  -e MYSQL_USER=usuwp \
  -e MYSQL_PASSWORD=contrawp \
  -v ~/contenedores/servidormdb:/var/lib/mysql \
  mariadb

docker run -d --name servidorwp \
  -e WORDPRESS_DB_HOST=servidormdb:3306 \
  -e WORDPRESS_DB_NAME=bdwp \
  -e WORDPRESS_DB_USER=usuwp \
  -e WORDPRESS_DB_PASSWORD=contrawp \
  -v ~/contenedores/servidorwp:/var/www/html/wp-content \
  -p 80:80 \
  --link servidormdb:3306 \
  wordpress

docker logs servidorwp
```

The site answers on `http://localhost` inside the VM, or on the VM's IP from the
host. `bind: address already use` means the host port is taken by an earlier
activity — free it or publish a different port. To start over:

```bash
docker rm servidorwp servidormdb
sudo rm -fr ~/contenedores/servidorwp ~/contenedores/servidormdb
```

## WordPress with Compose (Q13 – Q14)

The same stack, declared once in [`wordpress.yaml`](wordpress.yaml):

```bash
docker compose -f wordpress.yaml up -d
docker compose -f wordpress.yaml ps
docker compose -f wordpress.yaml logs
docker compose -f wordpress.yaml stop | start | restart | rm
```

Different names and port 9001, so it does not collide with the manual
deployment. Compose creates a network for the project, which is why
`WORDPRESS_DB_HOST: serv_mariadb` resolves without the legacy `--link`.
