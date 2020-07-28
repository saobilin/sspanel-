#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# My SSPANEL SSR
Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "没管理员权限玩你妈？？？" 1>&2
       exit 1
    fi
}

checkos(){
    if [[ -f /etc/redhat-release ]];then
        OS=CentOS
    elif cat /etc/issue | grep -q -E -i "debian";then
        OS=Debian
    elif cat /etc/issue | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    elif cat /proc/version | grep -q -E -i "debian";then
        OS=Debian
    elif cat /proc/version | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    else
        echo "Not supported OS, Please reinstall OS and try again."
        exit 1
    fi
}
disable_firewall(){
	if [ "${OS}" == 'CentOS' ];then
    systemctl stop firewalld.service 
    systemctl disable firewalld.service 
	else
	ufw disable
	fi
}

get_ip(){
    ip=`curl ip.sb`
}

install_docker(){
	    echo -e "${Green}即将安装Docker${Font}"
        if [ -s /var/lib/docker ]; then
        echo -e "Docker installed!"
        else
        curl -sSL https://get.docker.com/ | sh
        fi
        if [ "${OS}" == 'CentOS' ];then
        systemctl start docker && systemctl enable docker
        else
        echo -e "Debian/Ubuntu is good"
        fi
}
config_ssr_webapi(){
echo -e "${Green}请输入SSR后端配置信息！WEBAPI${Font}"
    read -p "请输入官网（前端）地址:" website
    read -p "请输入对接密密钥(mukey)：" key 
    read -p "请输入Node ID节点id：" id
    read -p "容器的名称(随意填写)：" cname
    read -p "容器的DNS(如果恁配置流媒体解锁请输入，不然没用)：" dns1
    read -p "容器的DNS 2(如果恁配置流媒体解锁请输入，不然没用)：" dns2
}
start_ssr_webapi(){
echo -e "${Green}正在配置SSR后端...${Font}"
	get_ip
    docker run -d --name=${cname} -e NODE_ID=${id} -e API_INTERFACE=modwebapi -e WEBAPI_URL=${website} -e SPEEDTEST=0 -e WEBAPI_TOKEN=${key} -e DNS_1="${dns1}" -e DNS_2="${dns2}" --network=host --log-opt max-size=5m --log-opt max-file=3 --restart=always fanvinga/docker-ssrmu
    echo
    echo -e "${Green}SSR后端安装并配置成功!${Font}"
    echo -e "${Blue}你的前端地址:${website}${Font}"
    echo -e "${Blue}你的后端服务器IP为:${ip}${Font}"
}
config_ssr_db(){
echo -e "${Green}请输入SSR后端配置信息！WEBAPI${Font}"
    read -p "请输入数据库地址:" dbip
    read -p "请输入数据库名:" dbname
    read -p "请输入数据库用户名:" dbuser
    read -p "请输入对Database密码：" dbpass 
    read -p "请输入Node ID节点id：" id
    read -p "容器的名称(随意填写)：" cname
}
start_ssr_db(){
echo -e "${Green}正在配置SSR后端...${Font}"
	get_ip
    docker run -d --name=${cname} -e NODE_ID=${id} -e API_INTERFACE=glzjinmod -e MYSQL_HOST=${dbip} -e SPEEDTEST=0 -e MYSQL_USER=${dbuser} -e MYSQL_DB=${dbname} -e MYSQL_PASS=${dbpass} --network=host --log-opt max-size=5m --log-opt max-file=3 --restart=always fanvinga/docker-ssrmu    echo
    echo -e "${Green}SSR后端安装并配置成功!${Font}"
    echo -e "${Blue}你的前端数据库:${db}${Font}"
    echo -e "${Blue}你的后端服务器IP为:${ip}${Font}"
}
install_f2(){
clear
#CheckIfRoot
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }


#ReadSSHPort
[ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`

#CheckOS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ]; then
  OS=CentOS
  [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
  [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
  [ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ]; then
  OS=CentOS
  CentOS_RHEL_version=6
elif [ -n "$(grep 'bian' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Debian" ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep 'Deepin' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Deepin" ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
# kali rolling
elif [ -n "$(grep 'Kali GNU/Linux Rolling' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Kali" ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  if [ -n "$(grep 'VERSION="2016.*"' /etc/os-release)" ]; then
    Debian_version=8
  else
    echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
    kill -9 $$
  fi
elif [ -n "$(grep 'Ubuntu' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Ubuntu" -o -n "$(grep 'Linux Mint' /etc/issue)" ]; then
  OS=Ubuntu
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
  [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
elif [ -n "$(grep 'elementary' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'elementary' ]; then
  OS=Ubuntu
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Ubuntu_version=16
else
  echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
  kill -9 $$
fi
#Read Imformation From The User
echo "欢迎来到Fail2ban的安装流程！"
echo "--------------------"
echo "这个Shell脚本可以在Fail2ban和iptables的支持下保护服务器免受SSH爆破"
echo ""

while :; do echo
  read -p "你想要改变你的ssh端口吗? [y/n]: " IfChangeSSHPort
  if [ ${IfChangeSSHPort} == 'y' ]; then
    if [ -e "/etc/ssh/sshd_config" ];then
    [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
    while :; do echo
        read -p "请输入您需要更改的ssh端口！(默认端口: $ssh_port): " SSH_PORT
        [ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
        if [ $SSH_PORT -eq 22 >/dev/null 2>&1 -o $SSH_PORT -gt 1024 >/dev/null 2>&1 -a $SSH_PORT -lt 65535 >/dev/null 2>&1 ];then
            break
        else
            echo "${CWARNING}你输入尼玛呢,输入错误,范围是: 22,1025~65534${CEND}"
        fi
    done
    if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "$SSH_PORT" != '22' ];then
        sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
    elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ];then
        sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
    fi
    fi
    break
  elif [ ${IfChangeSSHPort} == 'n' ]; then
    break
  else
    echo "${CWARNING}你输入尼玛呢，输入y或n${CEND}"
  fi
done
ssh_port=$SSH_PORT
echo ""
	read -p "最大的尝试次数 [2-10]:  " maxretry
echo ""
read -p "请输入要封禁的时间 [小时]:  " bantime
if [ ${maxretry} == '' ]; then
	maxretry=3
fi
if [ ${bantime} == '' ];then
	bantime=24
fi
((bantime=$bantime*60*60))
#Install
if [ ${OS} == CentOS ]; then
  yum -y install epel-release
  yum -y install fail2ban
fi

if [ ${OS} == Ubuntu ] || [ ${OS} == Debian ];then
  apt-get -y update
  apt-get -y install fail2ban
fi

#Configure
rm -rf /etc/fail2ban/jail.local
touch /etc/fail2ban/jail.local
if [ ${OS} == CentOS ]; then
cat <<EOF >> /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1
bantime = 86400
maxretry = 3
findtime = 1800

[ssh-iptables]
enabled = true
filter = sshd
action = iptables[name=SSH, port=ssh, protocol=tcp]
logpath = /var/log/secure
maxretry = $maxretry
findtime = 3600
bantime = $bantime
EOF
else
cat <<EOF >> /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1
bantime = 86400
maxretry = $maxretry
findtime = 1800

[ssh-iptables]
enabled = true
filter = sshd
action = iptables[name=SSH, port=ssh, protocol=tcp]
logpath = /var/log/auth.log
maxretry = $maxretry
findtime = 3600
bantime = $bantime
EOF
fi

#Start
if [ ${OS} == CentOS ]; then
  if [ ${CentOS_RHEL_version} == 7 ]; then
    systemctl restart fail2ban
    systemctl enable fail2ban
  else
    service fail2ban restart
    chkconfig fail2ban on
  fi
fi

if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]]; then
  service fail2ban restart
fi

#Finish
echo "安装完了，赶紧给老子重启"

if [ ${OS} == CentOS ]; then
  if [ ${CentOS_RHEL_version} == 7 ]; then
    systemctl restart sshd
  else
    service ssh restart
  fi
fi

if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]]; then
  service ssh restart
fi
echo "Fail2ban正在运行！没撒子事我就溜了"
echo "安装成功"
}
status_ssr(){
echo -e "${Green}机场管理脚本。从入门到入狱。loc精装版${Font}"
echo -e "${Green}1:安装SSR后端 docker and webapi${Font}"
echo -e "${Green}2:安装SSR后端 docker and database${Font}"
echo -e "${Green}3:安装fail2ban防止被爆破${Font}"
echo -e "${Green}4:安装BBR2内核并自动开启${Font}"
echo -e "${Green}6.删除后端${Font}"
echo -e "${Green}7.更换源（阿里云）${Font}"
echo -e "${Green}8.DNS更换（阿里）${Font}"
echo -e "${Green}9.安装锐速(CentOS7)${Font}"
echo -e "${Green}10:对接V2ray Rico免费版${Font}"
echo -e "${Green}11.重装VPS系统${Font}"
read -e -p "请输入数字:" num
case "$num" in
	1)
	install_ssr_webapi
	;;
	2)
    install_ssr_db
	;;
    3)
    install_f2
    ;;
    4)
    install_bbr2
    ;;
    5)
    rm_docker_ssr
    ;;
    6)
    change_yuan_aliyun
    ;;
    7)
    change_dns_aliyun
    ;;
    8)
    install_ruisu
    ;;
    9)
    install_v2ray_free
    ;;
    10)
    reinstall_system
    ;;
esac
}
exit(){
echo -e "停止对接"
exit
}
install_ssr_db(){
rootness
checkos
install_docker
}
install_ssr_webapi(){
rootness
checkos
install_docker
config_ssr_webapi
start_ssr_webapi
}
install_bbr2(){
wget --no-check-certificate -q -O bbr2.sh "https://raw.githubusercontent.com/yeyingorg/bbr2.sh/master/bbr2.sh" && chmod +x bbr2.sh && bash bbr2.sh auto
}
rm_docker_ssr(){
echo -e "${Green}您要删除那个容器？${Font}"
read -p "请输入容器名称:" cname
docker rm -f ${cname}
echo -e "${Green}删除完成.!${Font}"
}
change_dns_aliyun(){
echo "nameserver 223.5.5.5">>/etc/resolv.conf
service network restart
}
change_yuan_aliyun(){
wget file.saobilin.online/yuan.sh && bash yuan.sh aliyun
}
status_ssr