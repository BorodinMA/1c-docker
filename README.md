## 1С в контейнере
Создание контейнера с клиентом 1С и доступ к нему через браузер.
Используем web-публикацию noVNC.

### Структура каталогов
Для полноценной работы нужно 2 контейнера:
1. с установленной платформой 1С
2. вспомогательный для доступа через web

### Последовательность (список) команд создания контейнеров

```bash
mkdir ~/1c-docker
cd ~/1c-docker/

nano ~/1c-docker/Dockerfile
nano ~/1c-docker/xorg.conf
nano ~/1c-docker/keyboard.conf
nano ~/1c-docker/menu.xml
nano ~/1c-docker/supervisord.conf

docker build -t 1c-docker .
docker network create 1c-docker-net
docker volume create 1c-bases-data
docker volume create 1c-licenses-data

docker run --detach --restart=always \
	--volume=1c-bases-data:/data \
	--volume=1c-licenses-data:/var/1C \
	--net=1c-docker-net \
	--name=1c-docker-app 1c-docker



mkdir ~/caddy
cd ~/caddy
nano ~/caddy/Dockerfile
nano ~/caddy/Caddyfile

docker build -t 1c-docker-caddy .
docker run --rm -it 1c-docker-caddy caddy hash-password -plaintext 'mypass'
docker run --detach --restart=always \
	--volume=1c-docker-data:/data \
	--net=1c-docker-net \
	--name=1c-docker-web \
	--env=APP_USERNAME="myuser" \
	--env=APP_PASSWORD_HASH="JDJhJDEwJHdjUzVKU2V3ellLNE5hUExtRFdFYS51bHFIaEVzdVQwMUFSVmREdm9yb2lWUUFKMXE3ZU9L" \
	--publish=8080:8080 1c-docker-caddy
```
