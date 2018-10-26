#!/bin/sh

# @sacloud-name "OpenFaaS"
# @sacloud-once
# @sacloud-desc-begin
#  Dockerを用いたFaaS環境を構築するOpenFaaSをインストールするスクリプトです。
#  サーバ作成後はブラウザより「http://サーバのIPアドレス:8080」にアクセスすることでGUIを表示できます。
#  (このスクリプトはCentOS7.x でのみ動作します）
# @sacloud-desc-end
# @sacloud-require-archive distro-centos distro-ver-7.*
_motd() {
  log=$(ls /root/.sacloud-api/notes/*log)
  case $1 in
  start)
    echo -e "\n#-- Startup-script is \\033[0;32mrunning\\033[0;39m. --#\n\nPlease check the logfile: ${log}\n" > /etc/motd
  ;;
  fail)
    echo -e "\n#-- Startup-script \\033[0;31mfailed\\033[0;39m. --#\n\nPlease check the logfile: ${log}\n" > /etc/motd
  ;;
  end)
    cp -f /dev/null /etc/motd
  ;;
  esac
}

set -e
trap '_motd fail' ERR

_motd start


echo "[1/6] yum update中"
yum update -y

# Dockerのインストール
echo "[2/6] Dockerインストール中"
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce

systemctl start docker
systemctl enable docker

# docker-composeのインストール
echo "[3/6] docker-composeインストール中"
version=$(curl -s https://api.github.com/repos/docker/compose/releases | grep tag_name | grep -v "rc" | head -1 | cut -d '"' -f 4 | sed -e s/v//)
if [ -z "$version"]; then
  echo 'cannot get docker-compose version'
  exit 1
fi
curl -L "https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# faas-cliのインストール
echo "[4/6] faas-cliインストール中"
curl -sSL https://cli.openfaas.com | sh

# OpenFaasのインストール
echo "[5/6] OpenFaaSインストール中"
docker swarm init
git clone https://github.com/openfaas/faas
cd faas
echo "[6/6] OpenFaaS起動"
./deploy_stack.sh --no-auth

# reboot

_motd end