#!/bin/sh

OPEN_TCP_PORT=(80 443 995 875 8080 8000)
OPEN_UDP_PORT=(443 8080 995)
TMP_DIR="/root/tmp"

output() {
    echo -en "\x1b[22;32m"
    echo -n $(date +"[%F %T]") $*
    echo -e "\x1b[0m"
}

check_environment() {
    [ `id -u` -eq 0 ] || echo "you should run this script as root" && return 2
    return 0
}

install_depend() {
    output "update yum repo and install default software"
    yum update -y && yum upgrade -y
    yum install -y git ctags tmux openssl-devel gcc g++ mariadb zlib-devel nload fail2ban vim
    clear
}

install_dotfiles() {
    output "install dot files"
    git clone https://github.com/meliuyue/linux-user-config.git >/dev/null 2>&1
    cd linux-user-config && chmod a+x run.sh && ./run.sh && cd - >/dev/null
}

install_ocserv() {
    output "install ocserv"
    curl -s https://raw.githubusercontent.com/travislee8964/ocserv-auto/master/ocserv-auto.sh -o ocserv-auto.sh && sh ocserv-auto.sh
}

install_ss() {
    output "install shadowsocks"
    git clone https://github.com/shadowsocks/shadowsocks-libev.git >/dev/null 2>&1
    cd shadowsocks-libev && ./configure && make -j4 && make install
    cd - >/dev/null
    clear
}

update_firewall() {
    output "update firewall"
    git clone https://github.com/shadowsocks/shadowsocks-libev.git >/dev/null 2>&1
    for port in $OPEN_TCP_PORT; do
        firewall-cmd -q --add-port=$port/tcp --permanent
    done
    for port in $OPEN_UDP_PORT; do
        firewall-cmd -q --add-port=$port/udp --permanent
    done
    firewall-cmd --reload
}

config_server() {
    output "config server"
    # close selinux
    setenforce 0
    [ -f /etc/selnux/config ] && sed -ri '/^SELINUX/c\SELINUX=disabled' /etc/selinux/config

    # config ssh
    sed -ri '/ClientAliveInterval/c\ClientAliveInterval = 30' /etc/ssh/sshd_config
    sed -ri '/ClientAliveCountMax/c\ClientAliveCountMax = 3' /etc/ssh/sshd_config
    sed -ri '/GatewayPorts/c\GatewayPorts = yes' /etc/ssh/sshd_config
    
    sed -ri '/^#/b;/nofile/d' /etc/security/limits.conf
    cat <<-EOF >>/etc/security/limits.conf
    * soft nofile 65535
    * hard nofile 65535
EOF
}

check_environment && exit 1

mkdir -p ${TMP_DIR}
cd ${TMP_DIR}

install_depend
install_dotfiles
install_ocserv
install_ss
update_firewall
config_server
output "all ok,enjoy~"

