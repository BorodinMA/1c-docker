FROM golang:1.14-buster AS easy-novnc-build
WORKDIR /src
RUN go mod init build && \
    go get github.com/geek1011/easy-novnc@v1.1.0 && \
    go build -o /bin/easy-novnc github.com/geek1011/easy-novnc



#FROM debian:buster
#FROM ubuntu:kinetic
#FROM ubuntu:jammy
#FROM ubuntu:20.04
FROM ubuntu:focal

## Установка 1С
#
## -01- подготовительная настройка
ENV PLATFORM_VERSION 83
ENV SERVER_VERSION 8.3.17-2760

RUN  set -xe \
  && apt update \
  && apt-get install -y --no-install-recommends \
      locales \
      ca-certificates

RUN localedef --inputfile ru_RU --force --charmap UTF-8 --alias-file /usr/share/locale/locale.alias ru_RU.UTF-8
ENV LANG ru_RU.utf8
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD xorg.conf /usr/share/X11/xorg.conf.d/10-dummy.conf
ADD keyboard.conf /etc/default/keyboard

RUN  set -xe \
  && apt-get install -y vim nano

## -02- добавляем нужный источник для установки libwebkitgtk-3.0-0
#> nano /etc/apt/sources.list 
#> deb http://ru.archive.ubuntu.com/ubuntu/ bionic main universe

RUN  cp /etc/apt/sources.list /etc/apt/sources.list.standart
RUN  echo "\ndeb http://ru.archive.ubuntu.com/ubuntu/ bionic main universe\n" >> /etc/apt/sources.list
RUN  apt ${COMMENT_INSTALL} update
RUN  apt ${COMMENT_INSTALL} list --upgradable

## переменные окружения для apt отключающие интерактивный режим
ENV DEBIAN_FRONTEND=noninteractive 
ENV DEBCONF_NONINTERACTIVE_SEEN=true 

RUN echo "keyboard-configuration keyboard-configuration/variant select Russian" > /tmp/pressed.txt; \ 
    echo "keyboard-configuration keyboard-configuration/layout select Russian" >> /tmp/pressed.txt; \ 
    echo "keyboard-configuration keyboard-configuration/toggle select Alt+Shift" >> /tmp/pressed.txt; \  
    debconf-set-selections /tmp/pressed.txt && apt ${COMMENT_INSTALL} install -y libwebkitgtk-3.0-0 
#RUN  apt-get ${COMMENT_INSTALL} install -y libwebkitgtk-3.0-0
	#>> Geographic area = 8
	#>> Time zone = 34
	#>> Coutry = 78
	#>> Keyboard = 1
	#>> Method toggling = 7 (alt+shift)

## -03- восстанавливаем системный файл
RUN  rm /etc/apt/sources.list
RUN  mv /etc/apt/sources.list.standart /etc/apt/sources.list
RUN  apt list --upgradable

## -04- копируем файлы дистрибутива и устанавливаем
ADD  1c-dist/*.deb /tmp/
RUN  dpkg --install /tmp/1c-enterprise83-common_8.3.17-2760_amd64.deb \
  && dpkg --install /tmp/1c-enterprise83-server_8.3.17-2760_amd64.deb \

  && dpkg --install /tmp/1c-enterprise83-client_8.3.17-2760_amd64.deb \
  && dpkg --install /tmp/1c-enterprise83-ws_8.3.17-2760_amd64.deb \

  && rm /tmp/*.deb \
  && mkdir --parents /var/log/1C /home/usr1cv8/.1cv8/1C/1cv8/conf \
  && chown --recursive usr1cv8:grp1cv8 /var/log/1C /home/usr1cv8 \
  && rm -rf /var/lib/apt/lists

## (конец) установки 1С

RUN set -xe && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends openbox tigervnc-standalone-server supervisor gosu && \
    rm -rf /var/lib/apt/lists && \
    mkdir -p /usr/share/desktop-directories

RUN set -xe && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends lxterminal nano wget openssh-client rsync ca-certificates xdg-utils htop tar xzip gzip bzip2 zip unzip && \
    rm -rf /var/lib/apt/lists

###
#RUN apt-get update -y && \
#    apt-get install -y --no-install-recommends thunderbird && \
#    rm -rf /var/lib/apt/lists

COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY menu.xml /etc/xdg/openbox/
COPY supervisord.conf /etc/
EXPOSE 8080

RUN groupadd --gid 1000 app && \
    useradd --home-dir /data --shell /bin/bash --uid 1000 --gid 1000 app && \
    mkdir -p /data
VOLUME /data

CMD ["sh", "-c", "chown app:app /data /dev/stdout && exec gosu app supervisord"]
#CMD ["sh", "-c", "chown usr1cv8:grp1cv8 /data /dev/stdout && exec gosu usr1cv8 supervisord"]
