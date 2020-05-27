#!/usr/bin/env bash
trap 'displayContents "中国工程师俱乐部（ChineseEngineer.CLUB）祝愿“科技让您的生活更美好”，再见！"' EXIT
set -eo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
THINGREEN='\033[1;32m'
BLUE='\033[0;34m'
BG_CYAN='\033[1;46m'
COLORS_END='\033[00m'

domain=""
email=""
trojanPassword=""
uuid=""
ssrPassword=""
openUndo=0
declare -i readIndex=0

function displayContents(){
	local display
	display="${THINGREEN}\n"
	display="${display}  ==========================================================================================\n"
	for i in "$@"; do
		display="${display}  $i\n"
	done
	display="${display}  ==========================================================================================\n"
	display="${display}${COLORS_END}"
	echo -e $display
	sleep 1
}

function displayInstallItems(){
	local display
	display="${THINGREEN}"
	display="${display}\n  =========================================================================================="
	case "${1:-}" in
		update )
			display="${display}\n  1. 更新软件源"
			display="${display}\n  apt-get update"
			;;
		bbr )
			display="${display}\n  2. 开启BBR加速"
			display="${display}\n  echo \"net.core.default_qdisc=fq\" >> /etc/sysctl.conf"
			display="${display}\n  echo \"net.ipv4.tcp_congestion_control=bbr\" >> /etc/sysctl.conf"
			display="${display}\n  sysctl -p"
			display="${display}\n\n  -------------------------"
			display="${display}  检查运行状态"
			display="${display}  -------------------------"
			display="${display}\n  lsmod | grep bbr"
			display="${display}\n\n  -------------------------"
			display="${display}  BBR一键安装代码（备用）"
			display="${display}  -------------------------"
			display="${display}\n  wget -N --no-check-certificate \"https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh && chmod +x tcp.sh && ./tcp.sh\""
			;;
		needfulSofts )
			display="${display}\n  3. 安装必要软件"
			display="${display}\n  apt-get install nano curl wget apt-transport-https"
			;;
		certs )
			display="${display}\n  4. 申请Letsencrypt证书"
			display="${display}\n  apt-get install certbot"
			display="${display}\n  certbot certonly --standalone -d 已经解析到本主机的域名"
			;;
		nginx )
			display="${display}\n  5. 部署Nginx"
			display="${display}\n\n  -------------------------"
			display="${display}  配置官方仓库"
			display="${display}  -------------------------"
			display="${display}\n  wget https://nginx.org/keys/nginx_signing.key"
			display="${display}\n  apt-key add nginx_signing.key"
			display="${display}\n\n  -------------------------"
			display="${display}  安装"
			display="${display}  -------------------------"
			display="${display}\n  apt-get install nginx"
			;;
		trojan )
			display="${display}\n  6. 部署Trojan"
			display="${display}\n  bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)\""
			;;
		v2ray )
			display="${display}\n  7. 部署V2ray"
			display="${display}\n  bash <(curl -L -s https://install.direct/go.sh)"
			;;
		ssr )
			display="${display}\n  8. 部署Shadowsocks-libev"
			display="${display}\n  apt-get install shadowsocks-libev"
			display="${display}\n  apt-get install libsodium-dev"
			display="${display}\n\n  -------------------------"
			display="${display}  安装v2ray-plugin"
			display="${display}  -------------------------"
			display="${display}\n  wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.0/v2ray-plugin-linux-amd64-v1.3.0.tar.gz"
			display="${display}\n  tar -xzvf v2ray-plugin-linux-amd64-v1.3.0.tar.gz"
			display="${display}\n  mv v2ray-plugin_linux_amd64 /usr/bin/v2ray-plugin"
			;;
		* )
			exit 1
			;;
	esac
	display="${display}\n  =========================================================================================="
	display="${display}\n${COLORS_END}"
	echo -e $display
	sleep 1
}

function displayContentsWithTitle(){
	local display
	display="${THINGREEN}\n"
	display="${display}  ========================="
	display="${display} $1"
	display="${display}  客户端配置参数"
	display="${display}  =========================\n"
	shift
	for i in "$@"; do
  		display="${display}  $i\n"
	done
	display="${display}${COLORS_END}"
	echo -e $display
	sleep 1
}

function readPrompt(){
	read -p ${1:-"回车以继续"}
}

function readDomain(){
	while [ -z "$domain" ]; do
		read -p ${1:-"请输入域名："} domain
	done
	local input=$domain
	if [[ "${input,,}" = "u" ]]; then
		readIndex=$((readIndex-=2))
		if [ $readIndex -lt -1 ]; then
			readIndex=-1
		fi
		domain=""
	fi
}

function readEmail(){
	while [ -z "$email" ]; do
		read -p ${1:-} email
	done
	local input=$email
	if [[ "${input,,}" = "u" ]]; then
		readIndex=$((readIndex-=2))
		if [ $readIndex -lt -1 ]; then
			readIndex=-1
		fi
		email=""
	fi
}

function readPassword(){
	local passwordName=${1:-}Password
	eval ${passwordName}=""
	local name=""
	case ${1:-} in
		trojan )
			name="Trojan"
			;;
		ssr )
			name="Shadowsocks-libev"
			;;
	esac
	local refPasswordName=${2:-}Password
    local ifCopyPassword=0
	if [ "$refPasswordName" != "Password" ] && [ -n "${!refPasswordName}" ]; then
		yes_or_no "$1的密码是否使用$2的密码" "ifCopyPassword=1" "ifCopyPassword=0" "ifCopyPassword=1"
	fi
	if ((ifCopyPassword)); then
		case ${1:-} in
			ssr )
				ssrPassword=${!refPasswordName}
				;;
		esac
	else
		while [ -z "${!passwordName}" ]; do
			read -p "配置$name密码（输入不会显示）：" -s $passwordName
			echo -e "\n"
		done
		local input=${!passwordName}
		if [[ "${input,,}" = "u" ]]; then
			readIndex=$((readIndex-=2))
			if [ $readIndex -lt -1 ]; then
				readIndex=-1
			fi
			eval ${passwordName}=""
		fi
	fi
}

function readWithUndo(){
	openUndo=1
	for (( readIndex = 0; readIndex < $#; readIndex++ )); do
		local i=$((readIndex + 1))
		echo -n "[(U)ndo]"
		eval ${!i}
	done
	openUndo=0
}

function displayConfigs(){
	domain=${domain:=$(cat /usr/local/etc/trojan/config.json)}
    domain=${domain#*/etc/letsencrypt/live/}
    domain=${domain%/fullchain.pem*}

    case $1 in
    	"trojan" )
			displayContentsWithTitle Trojan "服务器地址：$domain\n
			端口：443\n
			密码：$trojanPassword\n
			TLS：是"
    		;;
    	"v2ray" )
			displayContentsWithTitle V2ray "服务器地址：${domain:-\"请安装并配置Trojan\"}\n
		    端口：443\n
		    Alertid：64\n
		    uuid：$uuid\n
		    加密方式：AUTO\n
		    传输协议：WebSocket/WS\n
		    WebSocket Path（路径）：/movies\n
		    TLS：是"
    		;;
    	"ssr" )
			displayContentsWithTitle Shadowsocks-libev "服务器地址：${domain:-\"请安装并配置Trojan\"}\n
			端口：443\n
			密码：$ssrPassword\n
			加密方式：aes-256-cfb\n
			插件：v2ray-plugin\n
			插件参数：tls;host=${domain:-\"请安装并配置Trojan\"};path=/tvshow"
    		;;
    esac
}

function install_bbr(){
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	sysctl -p
	if [ -z "$(lsmod | grep bbr)" ]; then
		read -p "首选安装：7. 使用BBRplus版加速"
		wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
	fi
}

function install_needful_softs(){
	if [[ "${1:-}" = "auto" ]]; then
		/usr/bin/expect << _EOF_
			spawn apt-get install nano curl wget apt-transport-https
			expect "continue" { send "Y\r" }
			expect eof
_EOF_
	else
		apt-get install nano curl wget apt-transport-https
	fi
}

function apply_certs(){
	if [[ "${1:-}" = "auto" ]]; then
		/usr/bin/expect << _EOF_
			spawn apt-get install certbot
			expect "continue" { send "Y\r" }
			expect eof
_EOF_
		/usr/bin/expect << _EOF_
			spawn certbot certonly --standalone -d $domain -m $email
			expect "continue" { send "Y\r" }
			expect "(A)gree/(C)ancel:" { send "A\r" }
			expect "(Y)es/(N)o" { send "N\r" }
			expect eof
_EOF_
	else
		apt-get install certbot
		certbot certonly --standalone -d $domain
	fi
}

function install_nginx(){
	wget https://nginx.org/keys/nginx_signing.key
	apt-key add nginx_signing.key
	echo -e "\ndeb https://nginx.org/packages/mainline/debian/ stretch nginx" >> /etc/apt/sources.list
	echo "deb-src https://nginx.org/packages/mainline/debian/ stretch nginx" >> /etc/apt/sources.list
	apt-get update
	apt-get install nginx
	sed -i "s/80;/8080;/;" /etc/nginx/conf.d/default.conf
	cat > /etc/nginx/conf.d/chineseengineer.club.conf << '_EOF_'
	server {
       listen 8080;
       server_name 127.0.0.1;

       root /usr/share/nginx/html;
       index index.html;

       location /movies {
         proxy_redirect off;
         proxy_pass http://127.0.0.1:16888;
         proxy_http_version 1.1;
         proxy_set_header Upgrade $http_upgrade;
         proxy_set_header Connection "upgrade";
         proxy_set_header Host $http_host;
       }

       location /tvshow {
         proxy_redirect off;
         proxy_pass http://127.0.0.1:16999;
         proxy_http_version 1.1;
         proxy_set_header Upgrade $http_upgrade;
         proxy_set_header Connection "upgrade";
         proxy_set_header Host $http_host;
       }
	}
_EOF_
	systemctl restart nginx
	systemctl enable nginx
}

function install_trojan(){
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
    sed -i "s/\"remote_port\": 80,/\"remote_port\": 8080,/;" /usr/local/etc/trojan/config.json
    sed -i ":label;N;s/\"password1\",\n//;b label" /usr/local/etc/trojan/config.json
    sed -i "s/password2/$trojanPassword/;" /usr/local/etc/trojan/config.json
    sed -i "s/\/path\/to\/certificate.crt/\/etc\/letsencrypt\/live\/$domain\/fullchain.pem/;" /usr/local/etc/trojan/config.json
    sed -i "s/\/path\/to\/private.key/\/etc\/letsencrypt\/live\/$domain\/privkey.pem/;" /usr/local/etc/trojan/config.json
    systemctl restart trojan
    systemctl enable trojan
}

function install_v2ray(){
	bash <(curl -L -s https://install.direct/go.sh)
	ls /etc/v2ray/config.json && rm /etc/v2ray/config.json
	uuid=$(cat /proc/sys/kernel/random/uuid)
	cat > /etc/v2ray/config.json << _EOF_
	{
	  "inbound": {
	    "port": 16888,
	    "listen":"127.0.0.1",
	    "protocol": "vmess",
	    "settings": {
	      "clients": [
	        {
	          "id": "$uuid",
	          "level": 1,
	          "alterId": 64
	        }
	      ]
	    },
	     "streamSettings": {
	      "network": "ws",
	      "wsSettings": {
	         "path": "/movies"
	        }
	     }
	  },
	  "outbound": {
	    "protocol": "freedom",
	    "settings": {}
	  }
	}
_EOF_
    systemctl restart v2ray
    systemctl enable v2ray
}

function install_shadowsocks-libev(){
	if [[ "${1:-}" = "auto" ]]; then
		/usr/bin/expect << _EOF_
			spawn apt-get install shadowsocks-libev
			expect "continue" { send "Y\r" }
			expect eof
_EOF_
	else
		apt-get install shadowsocks-libev
	fi
	apt-get install libsodium-dev
	wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.0/v2ray-plugin-linux-amd64-v1.3.0.tar.gz
	tar -xzvf v2ray-plugin-linux-amd64-v1.3.0.tar.gz
	mv v2ray-plugin_linux_amd64 /usr/bin/v2ray-plugin
	ls /etc/shadowsocks-libev/config.json && rm /etc/shadowsocks-libev/config.json
	cat > /etc/shadowsocks-libev/config.json << _EOF_
	{
	  "server": "127.0.0.1",
	  "server_port": 16999,
	  "local_port": 1080,
	  "method": "aes-256-cfb",
	  "timeout": 300,
	  "password": "$ssrPassword",
	  "fast_open": false,
	  "nameserver": "8.8.8.8",
	  "mode": "tcp_and_udp",
	  "plugin": "v2ray-plugin",
	  "plugin_opts": "server;path=/tvshow"
	}
_EOF_
    systemctl restart shadowsocks-libev
    systemctl enable shadowsocks-libev
}

function install_all(){
	set +x
	displayInstallItems update
	set -x
	apt-get update
	set +x
	displayInstallItems bbr
	set -x
	install_bbr
	set +x
	displayInstallItems needfulSofts
	set -x
	install_needful_softs auto
	set +x
	displayInstallItems certs
	set -x
	apply_certs auto
	set +x
	displayInstallItems nginx
	set -x
	install_nginx
	set +x
	displayInstallItems trojan
	set -x
	install_trojan
	set +x
	displayInstallItems v2ray
	set -x
	install_v2ray
	set +x
	displayInstallItems ssr
	set -x
	install_shadowsocks-libev auto
}

function yes_or_no(){
	if [[ ! ${1:-0} ]] || [[ ! ${2:-0} ]]; then
		exit 1
	fi
	local input=""
	read -p "$1[y/n](y)：" input
	input=${input,,}
	case $input in
		"" )
			eval $2
			;;
		y )
			eval $2
			;;
		n )
            if [[ -n "${3:-}" ]]; then
            	eval $3
            fi
			;;
		u )
			if [[ -n "${4:-}" ]]; then
				eval $4
			fi
			if ((openUndo)); then
				readIndex=$((readIndex-=2))
				if [ $readIndex -lt -1 ]; then
					readIndex=-1
				fi
			else
				echo 输入不符合要求
				yes_or_no $1 $2 ${3:-} ${4:-}
			fi
			;;
		* )
			echo 输入不符合要求
			yes_or_no $1 $2 ${3:-} ${4:-}
			;;
	esac
}

function action(){
	case ${1:-} in
		1)
			displayInstallItems update
			set -x
		    apt-get update
			set +x
			yes_or_no "是否继续下一步：2. 开启BBR加速" "menu $(($1 + 1))" "exit 1"
			;;
		2)
			displayInstallItems bbr
			set -x
			install_bbr
			set +x
			yes_or_no "是否继续下一步：3. 安装必要软件" "menu $(($1 + 1))" "exit 1"
			;;
		3)
			displayInstallItems needfulSofts
			set -x
			install_needful_softs
			set +x
			yes_or_no "是否继续下一步：4. 申请Letsencrypt证书（需要确保80端口已开放并且不被占用）" "menu $(($1 + 1))" "exit 1"
			;;
		4)
			displayInstallItems certs
			readPrompt "请确认80端口已经开放，并且未被占用（确认后回车以继续）！"
			readDomain "请输入一个已经解析到本主机的有效域名："
			set -x
			apply_certs
			set +x
			yes_or_no "是否继续下一步：5. 部署Nginx" "menu $(($1 + 1))" "exit 1"
			;;
		5)
			displayInstallItems nginx
			set -x
			install_nginx
			set +x
			yes_or_no "是否继续下一步：6. 部署Trojan" "menu $(($1 + 1))" "exit 1"
			;;
		6)
			displayInstallItems trojan
			local readRefs
			readRefs[0]="readDomain \"请输入申请证书时所用的域名：\""
			readRefs[1]="readPassword trojan"
			readWithUndo "${readRefs[0]}" "${readRefs[1]}"
			set -x
			install_trojan
			set +x
			displayConfigs trojan
			yes_or_no "是否继续下一步：7. 部署V2ray" "menu $(($1 + 1))" "exit 1"
			;;
		7)
			displayInstallItems v2ray
			set -x
			install_v2ray
			set +x
			displayConfigs v2ray
			yes_or_no "是否继续下一步：8. 部署Shadowsocks-libev" "menu $(($1 + 1))" "exit 1"
			;;
		8)
			displayInstallItems ssr
			readPassword ssr trojan
			set -x
			install_shadowsocks-libev
			set +x
			displayConfigs ssr
			;;
		99)
			displayContents "99. 安装全部（Ctrl+C退出）"
			displayContents "安装依赖"
			apt-get install expect
			displayContents "输入个性化内容："
			readPrompt "请确认80端口已经开放，并且未被占用（确认后回车以继续）！"
			local readRefs
			readRefs[0]="readDomain \"请输入一个已经解析到本主机的有效域名：\""
			readRefs[1]="readEmail \"申请证书需要一个有效的电子邮箱地址：\""
			readRefs[2]="readPassword trojan"
			readRefs[3]="readPassword ssr trojan"
			readWithUndo "${readRefs[0]}" "${readRefs[1]}" "${readRefs[2]}" "${readRefs[3]}"
			set -x
			install_all
			set +x
			displayConfigs trojan
			displayConfigs v2ray
			displayConfigs ssr
			;;
		0)
			exit 1
			;;
		*)
			echo 输入不符合要求
			sleep 2
			menu
			;;
	esac
}

function menu(){
	clear
	local display
	display="${GREEN}\n"
	display="${display}\n  ===========================ChineseEngineer.CLUB（中国工程师俱乐部）=========================="
	display="${display}\n  介绍：Nginx Trojan+V2ray+Shadowsocks-libev（TVS） ALL-IN-ONE VPS\n"
	display="${display}  参考系统：Debian 9.5\n"
	display="${display}  作者：Chinese Engineer 中国工程师\n"
	display="${display}  youtube频道：https://www.youtube.com/channel/UCsnE5O7jJzOO_JtFQFASNxw\n"
	display="${display}  网站（中国工程师俱乐部）：ChineseEngineer.CLUB\n"
	display="${display}\n  ===========================ChineseEngineer.CLUB（中国工程师俱乐部）=========================="
	display="${display}\n${COLORS_END}"
	display="${display}${THINGREEN}\n"
	display="${display}  1. 更新软件源\n"
	display="${display}  2. 开启BBR加速\n"
	display="${display}  3. 安装必要软件\n"
	display="${display}  4. 申请Letsencrypt证书（需要确保80端口已开放并且不被占用）\n"
	display="${display}  5. 部署Nginx\n"
	display="${display}  6. 部署Trojan\n"
	display="${display}  7. 部署V2ray\n"
	display="${display}  8. 部署Shadowsocks-libev\n"
	display="${display}  ------------------------------\n"
	display="${display}  99. 安装全部（不建议）\n"
	display="${display}  ------------------------------\n"
	display="${display}  0. 退出\n"
	display="${display}${COLORS_END}"
	echo -e $display
	local str
	if [[ -n ${1:-""} ]]; then
		str=$1
		action $str
	else
		read -p "请输入操作的步骤代号：" str
		action $str
	fi
}

menu
