#!/bin/bash

DOMAIN=
MAIL=
URL=
PASSWORD=
CONFIGFILE="/etc/hysteria/config.yaml"

has_command() {
  local _command=$1

  type -P "$_command" > /dev/null 2>&1
}


tput() {
  if has_command tput; then
    command tput "$@"
  fi
}

tred() {
  tput setaf 1
}

tgreen() {
  tput setaf 2
}

tyellow() {
  tput setaf 3
}

tblue() {
  tput setaf 4
}

taoi() {
  tput setaf 6
}

tbold() {
  tput bold
}

treset() {
  tput sgr0
}

<<COMMENT
# listen: :443 

acme:
  domains:
    - your.domain.net 
  email: your@email.com 

auth:
  type: password
  password: Se7RAuFZ8Lzg 

masquerade: 
  type: proxy
  proxy:
    url: https://news.ycombinator.com/ 
    rewriteHost: true
COMMENT

get_all(){
  get_domain
  get_mail
  get_password
  get_url
}

get_domain(){
  DOMAIN=$(sed  -n "/domains:/{n;p;}" $CONFIGFILE | awk '{print $2}' )
  echo "当前的域名是：$(tgreen)${DOMAIN}$(treset)"
}

get_mail(){
  MAIL=$(sed -n "/email:/p" $CONFIGFILE | awk -F': ' '{print $2}')
  echo "当前的邮箱是：$(tgreen)${MAIL}$(treset)"
}

get_password(){
  PASSWORD=$(sed -n "/password:/p" $CONFIGFILE | awk -F': ' '{print $2}')
  echo "当前的密码是：$(tgreen)${PASSWORD}$(treset)"
}

get_url(){
  URL=$(sed -n "/url:/p" $CONFIGFILE | awk -F': ' '{print $2}')
  echo "当前的密码是：$(tgreen)${URL}$(treset)"
}

set_all(){
  set_domain
  set_mail
  set_password
  set_url
}

set_domain(){
  echo "请输入你要改成的域名："
  read DOMAIN
}

set_mail(){
  echo "请输入你要改成的邮箱："
  read MAIL
}

set_password(){
  echo "请输入你要改成的密码："
  read PASSWORD
}

set_url(){
  echo "请输入你要改成的URL："
  read URL
}

print_now(){
  echo "当前的域名是：$(tgreen)${DOMAIN}$(treset)"
  echo "当前的邮箱是：$(tgreen)${MAIL}$(treset)"
  echo "当前的密码是：$(tgreen)${PASSWORD}$(treset)"
  echo "当前的URL是：$(tgreen)${URL}$(treset)"
}

print_config(){
cat <<EOF
$(tyellow)# listen: :443 

acme:
  domains:
    - ${DOMAIN} 
  email: ${MAIL} 

auth:
  type: password
  password: ${PASSWORD}

masquerade: 
  type: proxy
  proxy:
    url: ${URL}
    rewriteHost: true$(treset)
EOF
}

save_config(){
  local _config_now=$(print_config)
  #如果是多行变量必须要双引号括起来
  echo -e "${_config_now}"
  echo "确认保存当前配置吗y/n"
  read is_save
  if [[ $is_save == "y" ]];then
    echo "${_config_now}">config.yml
	restart_server
	echo "已保存并重启服务"
	return
  fi
}

print_client_conf(){
  cat <<EOF
$(tblue)server: ${DOMAIN}:443 

auth: ${PASSWORD}

bandwidth: 
  up: 10 mbps
  down: 10 mbps

socks5:
  listen: 127.0.0.1:1080 

http:
  listen: 127.0.0.1:8080
$(treset)
EOF
}

restart_server(){
  systemctl restart hysteria-server.service
}

install(){
  bash install_server.sh
  enable_server  
}

remove(){
  bash install_server.sh --remove
  rm -rf /etc/hysteria
  userdel -r hysteria
  rm -f /etc/systemd/system/multi-user.target.wants/hysteria-server.service
  systemctl daemon-reload
}

check_update(){
  bash install_server.sh --check
}

install_version(){
  echo "请输入你要安装的版本"
  local _ver
  read _ver
  bash install_server.sh --version "$_ver"
}

enable_server(){
  if $(systemctl enable hysteria-server.service);then
    echo "$(tgreen)设置自启动成功$(treset)"
  else
    echo "$(tred)没有hysteria服务$(treset)"
  fi
}

start_server(){
  if $(systemctl start hysteria-server.service);then
    echo "$(tgreen)启动成功$(treset)"
  else
    echo "$(tred)启动失败$(treset)"
  fi
}

stop_server(){
  if $(systemctl stop hysteria-server.service);then
    echo "$(tgreen)已停止服务$(treset)"
  else
    echo "$(tred)停止服务失败$(treset)"
  fi
}


menu(){
  while true
  do
    echo -e "\n=========================="
	echo "0、退出"
    echo "1、修改全部配置"
	echo "2、修改域名"
	echo "3、修改邮箱"
	echo "4、修改密码"
	echo "5、修改伪造url"
	echo "6、查看当前配置"
	echo "7、预览配置"
	echo "8、保存到配置文件"
	echo "9、重启服务"
	echo "10、输出客户端配置"
	echo "i、安装hysteria"
	echo "r、卸载hysteria"
	echo "c、检查版本升级"
	echo "v、安装特定版本"
	echo "e、设置自启动"
	echo "s、启动服务"
	echo "t、停止服务"
	echo "请选择你的选项:"
	read i
    echo -e "\n"
	case "$i" in
	  "1")
	    set_all
	    ;;
	  "2")
	    set_domain
	    ;;
	  "3")
	    set_mail
	    ;;
	  "4")
	    set_password
	    ;;
	  "5")
	    set_url
	    ;;
	  "6")
	    print_now
	    ;;
	  "7")
	    print_config
		;;
	  "8")
	    save_config
		;;
	  "9")
	    restart_server
		;;
	  "10")
	    print_client_conf
	    ;;
	  "i")
	    install
		;;
	  "r")
	    remove
		;;
	  "c")
	    check_update
		;;
	  "v")
	    install_version
		;;
	  "e")
	    enable_server
		;;
	  "s")
	    start_server
		;;
	  "t")
	    stop_server
		;;
	  "0")
	    exit
	    ;;
	  *)
	    echo "$(tred)请输入正确的选项$(treset)"
	    ;;
	esac
  done
}

main(){
  get_all
  menu
}

main