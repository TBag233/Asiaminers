#!/bin/bash
stty erase ^H

red='\e[91m'
green='\e[92m'
yellow='\e[94m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

# Root
[[ $(id -u) != 0 ]] && echo -e "\n 请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n" && exit 1

cmd="apt-get"

sys_bit=$(uname -m)

case $sys_bit in
'amd64' | x86_64) ;;
*)
    echo -e " 
	 这个 ${red}安装脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}

	备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
	" && exit 1
    ;;
esac

# 笨笨的检测方法
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then

    if [[ $(command -v yum) ]]; then

        cmd="yum"

    fi

else

    echo -e " 
	 这个 ${red}安装脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}

	备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
	" && exit 1

fi

if [ ! -d "/etc/ccworker/" ]; then
    mkdir /etc/ccworker/
fi

error() {

    echo -e "\n$red 输入错误！$none\n"

}

log_config_ask() {
    echo
    while :; do
        echo -e "是否开启 日志记录， 输入 [${magenta}Y/N${none}] 按回车"
        read -p "$(echo -e "(默认: [${cyan}Y${none}]):")" enableLog
        [[ -z $enableLog ]] && enableLog="y"

        case $enableLog in
        Y | y)
            enableLog="y"
            break
            ;;
        N | n)
            enableLog="n"
            echo
            echo
            echo -e "$yellow 不启用日志记录 $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
}

eth_miner_config_ask() {
    echo
    while :; do
        echo -e "是否开启 ETH抽水中转， 输入 [${magenta}Y/N${none}] 按回车"
        read -p "$(echo -e "(默认: [${cyan}Y${none}]):")" enableEthProxy
        [[ -z $enableEthProxy ]] && enableEthProxy="y"

        case $enableEthProxy in
        Y | y)
            enableEthProxy="y"
            eth_miner_config
            break
            ;;
        N | n)
            enableEthProxy="n"
            echo
            echo
            echo -e "$yellow 不启用ETH抽水中转 $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
}

eth_miner_config() {
    echo
    while :; do
        echo -e "请输入ETH矿池域名，例如 eth.f2pool.com，不需要输入矿池端口"
        read -p "$(echo -e "(默认: [${cyan}eth.f2pool.com${none}]):")" ethPoolAddress
        [[ -z $ethPoolAddress ]] && ethPoolAddress="eth.f2pool.com"

        case $ethPoolAddress in
        *[:$]*)
            echo
            echo -e " 由于这个脚本太辣鸡了..所以矿池地址不能包含端口.... "
            echo
            error
            ;;
        *)
            echo
            echo
            echo -e "$yellow ETH矿池地址 = ${cyan}$ethPoolAddress${none}"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        esac
    done
    while :; do
        echo -e "是否使用SSL模式连接到ETH矿池， 输入 [${magenta}Y/N${none}] 按回车"
        read -p "$(echo -e "(默认: [${cyan}N${none}]):")" ethPoolSslMode
        [[ -z $ethPoolSslMode ]] && ethPoolSslMode="n"

        case $ethPoolSslMode in
        Y | y)
            ethPoolSslMode="y"
            echo
            echo
            echo -e "$yellow 使用SSL模式连接到ETH矿池 $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        N | n)
            ethPoolSslMode="n"
            echo
            echo
            echo -e "$yellow 使用TCP模式连接到ETH矿池 $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
    while :; do
        if [[ "$ethPoolSslMode" = "y" ]]; then
            echo -e "请输入ETH矿池"$yellow"$ethPoolAddress"$none"的SSL端口，不要使用矿池的TCP端口！！！"
        else
            echo -e "请输入ETH矿池"$yellow"$ethPoolAddress"$none"的TCP端口，不要使用矿池的SSL端口！！！"
        fi
        read -p "$(echo -e "(默认端口: ${cyan}6688${none}):")" ethPoolPort
        [ -z "$ethPoolPort" ] && ethPoolPort=6688
        case $ethPoolPort in
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
            echo
            echo
            echo -e "$yellow ETH矿池端口 = $cyan$ethPoolPort$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            echo
            echo " ..端口要在1-65535之间啊哥哥....."
            error
            ;;
        esac
    done
    local randomTcp="6688"
    while :; do
        echo -e "请输入ETH本地TCP中转的端口 ["$magenta"1-65535"$none"]，不能选择 "$magenta"80"$none" 或 "$magenta"443"$none" 端口"
        read -p "$(echo -e "(默认TCP端口: ${cyan}${randomTcp}${none}):")" ethTcpPort
        [ -z "$ethTcpPort" ] && ethTcpPort=$randomTcp
        case $ethTcpPort in
        80)
            echo
            echo " ...都说了不能选择 80 端口了咯....."
            error
            ;;
        443)
            echo
            echo " ..都说了不能选择 443 端口了咯....."
            error
            ;;
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
            echo
            echo
            echo -e "$yellow ETH本地TCP中转端口 = $cyan$ethTcpPort$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
    local randomTls="12345"
    while :; do
        echo -e "请输入ETH本地SSL中转的端口 ["$magenta"1-65535"$none"]，不能选择 "$magenta"80"$none" 或 "$magenta"443"$none" 或 "$magenta"$ethTcpPort"$none" 端口"
        read -p "$(echo -e "(默认端口: ${cyan}${randomTls}${none}):")" ethTlsPort
        [ -z "$ethTlsPort" ] && ethTlsPort=$randomTls
        case $ethTlsPort in
        80)
            echo
            echo " ...都说了不能选择 80 端口了咯....."
            error
            ;;
        443)
            echo
            echo " ..都说了不能选择 443 端口了咯....."
            error
            ;;
        $ethTcpPort)
            echo
            echo " ..不能和 TCP端口 $ethTcpPort 一毛一样....."
            error
            ;;
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
            echo
            echo
            echo -e "$yellow ETH本地SSL中转端口 = $cyan$ethTlsPort$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
    while :; do
        echo -e "请输入你的ETH钱包地址或者你在矿池的用户名"
        read -p "$(echo -e "(一定不要输入错误，错了就抽给别人了):")" ethUser
        if [ -z "$ethUser" ]; then
            echo
            echo
            echo " ..一定要输入一个钱包地址或者用户名啊....."
            echo
        else
            echo
            echo
            echo -e "$yellow ETH抽水用户名/钱包名 = $cyan$ethUser$none"
            echo "----------------------------------------------------------------"
            echo
            break
        fi
    done
    while :; do
        echo -e "请输入你喜欢的矿工名，抽水成功后你可以在矿池看到这个矿工名"
        read -p "$(echo -e "(默认: [${cyan}worker${none}]):")" ethWorker
        [[ -z $ethWorker ]] && ethWorker="worker"
        echo
        echo
        echo -e "$yellow ETH抽水矿工名 = ${cyan}$ethWorker${none}"
        echo "----------------------------------------------------------------"
        echo
        break
    done
    while :; do
        echo -e "请输入ETH抽水比例 ["$magenta"0.1-50"$none"]"
        read -p "$(echo -e "(默认: ${cyan}10${none}):")" ethTaxPercent
        [ -z "$ethTaxPercent" ] && ethTaxPercent=10
        case $ethTaxPercent in
        0\.[1-9] | 0\.[1-9][0-9]* | [1-9] | [1-4][0-9] | 50 | [1-9]\.[0-9]* | [1-4][0-9]\.[0-9]*)
            echo
            echo
            echo -e "$yellow ETH抽水比例 = $cyan$ethTaxPercent%$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            echo
            echo " ..输入的抽水比例要在0.1-50之间，如果用的是整数不要加小数点....."
            error
            ;;
        esac
    done
    while :; do
        echo -e "是否归集ETH抽水到另外的矿池，部分矿池可能不支持，仅测试E池通过 输入 [${magenta}Y/N${none}] 按回车"
        read -p "$(echo -e "(默认: [${cyan}N${none}]):")" enableEthDonatePool
        [[ -z $enableEthDonatePool ]] && enableEthDonatePool="n"

        case $enableEthDonatePool in
        Y | y)
            enableEthDonatePool="y"
            eth_tax_pool_config_ask
            echo
            echo
            echo -e "$yellow 归集ETH抽水到指定矿池 $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        N | n)
            enableEthDonatePool="n"
            echo
            echo
            echo -e "$yellow 不归集ETH抽水到指定矿池 $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
}

eth_tax_pool_config_ask() {
    echo
    while :; do
        echo -e "请输入ETH归集抽水矿池域名，例如 asia1.ethermine.org，不需要输入矿池端口"
        read -p "$(echo -e "(默认: [${cyan}asia1.ethermine.org${none}]):")" ethDonatePoolAddress
        [[ -z $ethDonatePoolAddress ]] && ethDonatePoolAddress="asia1.ethermine.org"

        case $ethDonatePoolAddress in
        *[:$]*)
            echo
            echo -e " 由于这个脚本太辣鸡了..所以矿池地址不能包含端口.... "
            echo
            error
            ;;
        *)
            echo
            echo
            echo -e "$yellow ETH抽水归集矿池地址 = ${cyan}$ethDonatePoolAddress${none}"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        esac
    done
    while :; do
        echo -e "是否使用SSL模式连接到ETH抽水归集矿池， 输入 [${magenta}Y/N${none}] 按回车"
        read -p "$(echo -e "(默认: [${cyan}N${none}]):")" ethDonatePoolSslMode
        [[ -z $ethDonatePoolSslMode ]] && ethDonatePoolSslMode="n"

        case $ethDonatePoolSslMode in
        Y | y)
            ethDonatePoolSslMode="y"
            echo
            echo
            echo -e "$yellow 使用SSL模式连接到ETH抽水归集矿池 $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        N | n)
            ethDonatePoolSslMode="n"
            echo
            echo
            echo -e "$yellow 使用TCP模式连接到ETH抽水归集矿池 $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
    while :; do
        if [[ "$ethDonatePoolSslMode" = "y" ]]; then
            echo -e "请输入ETH抽水归集矿池"$yellow"$ethDonatePoolAddress"$none"的SSL端口，不要使用矿池的TCP端口！！！"
        else
            echo -e "请输入ETH抽水归集矿池"$yellow"$ethDonatePoolAddress"$none"的TCP端口，不要使用矿池的SSL端口！！！"
        fi
        read -p "$(echo -e "(默认端口: ${cyan}4444${none}):")" ethDonatePoolPort
        [ -z "$ethDonatePoolPort" ] && ethDonatePoolPort=4444
        case $ethDonatePoolPort in
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
            echo
            echo
            echo -e "$yellow ETH抽水归集矿池端口 = $cyan$ethDonatePoolPort$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            echo
            echo " ..端口要在1-65535之间啊哥哥....."
            error
            ;;
        esac
    done
}

print_all_config() {
    clear
    echo
    echo " ....准备安装了咯..看看配置正确了吗..."
    echo
    echo "---------- 安装信息 -------------"
    echo
    echo -e "$yellow MinerTaxProxy将被安装到$installPath${none}"
    echo
    echo "----------------------------------------------------------------"
    if [[ "$enableLog" = "y" ]]; then
        echo -e "$yellow 软件日志设置 = ${cyan}启用${none}"
        echo "----------------------------------------------------------------"
    else
        echo -e "$yellow 软件日志设置 = ${cyan}禁用${none}"
        echo "----------------------------------------------------------------"
    fi
    if [[ "$enableEthProxy" = "y" ]]; then
        echo "ETH 中转抽水配置"
        echo -e "$yellow ETH矿池地址 = ${cyan}$ethPoolAddress${none}"
        if [[ "$ethPoolSslMode" = "y" ]]; then
            echo -e "$yellow ETH矿池连接方式 = ${cyan}SSL${none}"
        else
            echo -e "$yellow ETH矿池连接方式 = ${cyan}TCP${none}"
        fi
        echo -e "$yellow ETH矿池端口 = $cyan$ethPoolPort$none"
        echo -e "$yellow ETH本地TCP中转端口 = $cyan$ethTcpPort$none"
        echo -e "$yellow ETH本地SSL中转端口 = $cyan$ethTlsPort$none"
        echo -e "$yellow ETH抽水用户名/钱包名 = $cyan$ethUser$none"
        echo -e "$yellow ETH抽水矿工名 = ${cyan}$ethWorker${none}"
        echo -e "$yellow ETH抽水比例 = $cyan$ethTaxPercent%$none"
        if [[ "$enableEthDonatePool" = "y" ]]; then
            echo -e "$yellow ETH强制归集抽水 = ${cyan}启用${none}"
            echo -e "$yellow ETH强制归集抽水矿池地址 = ${cyan}$ethDonatePoolAddress${none}"
            if [[ "$ethDonatePoolSslMode" = "y" ]]; then
                echo -e "$yellow ETH强制归集抽水矿池连接方式 = ${cyan}SSL${none}"
            else
                echo -e "$yellow ETH强制归集抽水矿池连接方式 = ${cyan}TCP${none}"
            fi
            echo -e "$yellow ETH强制归集矿池端口 = ${cyan}$ethDonatePoolPort${none}"
        fi
        echo "----------------------------------------------------------------"
    fi
    echo
    while :; do
        echo -e "确认以上配置项正确吗，确认输入Y，可选输入项[${magenta}Y/N${none}] 按回车"
        read -p "$(echo -e "(默认: [${cyan}Y${none}]):")" confirmConfigRight
        [[ -z $confirmConfigRight ]] && confirmConfigRight="y"

        case $confirmConfigRight in
        Y | y)
            confirmConfigRight="y"
            break
            ;;
        N | n)
            confirmConfigRight="n"
            echo
            echo
            echo -e "$yellow 退出安装 $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
}

install_download() {
    $cmd update -y
    if [[ $cmd == "apt-get" ]]; then
        $cmd install -y lrzsz git zip unzip curl wget supervisor
        service supervisor restart
    else
	$cmd install -y epel-release
        $cmd update -y
        $cmd install -y lrzsz git zip unzip curl wget supervisor
        systemctl enable supervisord
        service supervisord restart
    fi
    cp -rf /tmp/worker/gitcode/linux $installPath
    rm -rf $installPath/install.sh
    if [[ ! -d $installPath ]]; then
        echo
        echo -e "$red 哎呀呀...复制文件出错了...$none"
        echo
        echo -e " 温馨提示..... 使用最新版本的Ubuntu或者CentOS再试试"
        echo
        exit 1
    fi
}

write_json() {
    rm -rf $installPath/config.json
    jsonPath="$installPath/config.json"
    echo "{" >>$jsonPath
    if [[ "$enableLog" = "y" ]]; then
        echo "  \"enableLog\": true," >>$jsonPath
    else
        echo "  \"enableLog\": false," >>$jsonPath
    fi

    if [[ "$enableEthProxy" = "y" ]]; then
        echo "  \"ethPoolAddress\": \"${ethPoolAddress}\"," >>$jsonPath
        if [[ "$ethPoolSslMode" = "y" ]]; then
            echo "  \"ethPoolSslMode\": true," >>$jsonPath
        else
            echo "  \"ethPoolSslMode\": false," >>$jsonPath
        fi
        echo "  \"ethPoolPort\": ${ethPoolPort}," >>$jsonPath
        echo "  \"ethTcpPort\": ${ethTcpPort}," >>$jsonPath
        echo "  \"ethTlsPort\": ${ethTlsPort}," >>$jsonPath
        echo "  \"ethUser\": \"${ethUser}\"," >>$jsonPath
        echo "  \"ethWorker\": \"${ethWorker}\"," >>$jsonPath
        echo "  \"ethTaxPercent\": ${ethTaxPercent}," >>$jsonPath
        echo "  \"enableEthProxy\": true," >>$jsonPath
        if [[ "$enableEthDonatePool" = "y" ]]; then
            echo "  \"enableEthDonatePool\": true," >>$jsonPath
            echo "  \"ethDonatePoolAddress\": \"${ethDonatePoolAddress}\"," >>$jsonPath
            if [[ "$ethDonatePoolSslMode" = "y" ]]; then
                echo "  \"ethDonatePoolSslMode\": true," >>$jsonPath
            else
                echo "  \"ethDonatePoolSslMode\": false," >>$jsonPath
            fi
            echo "  \"ethDonatePoolPort\": ${ethDonatePoolPort}," >>$jsonPath
        else
            echo "  \"enableEthDonatePool\": false," >>$jsonPath
            echo "  \"ethDonatePoolAddress\": \"eth.f2pool.com\"," >>$jsonPath
            echo "  \"ethDonatePoolSslMode\": false," >>$jsonPath
            echo "  \"ethDonatePoolPort\": ${ethPoolPort}," >>$jsonPath
        fi
        if [[ $cmd == "apt-get" ]]; then
            ufw allow $ethTcpPort
            ufw allow $ethTlsPort
        else
            firewall-cmd --zone=public --add-port=$ethTcpPort/tcp --permanent
            firewall-cmd --zone=public --add-port=$ethTlsPort/tcp --permanent
        fi
    else
        echo "  \"ethPoolAddress\": \"eth.f2pool.com\"," >>$jsonPath
        echo "  \"ethPoolSslMode\": false," >>$jsonPath
        echo "  \"ethPoolPort\": 6688," >>$jsonPath
        echo "  \"ethTcpPort\": 6688," >>$jsonPath
        echo "  \"ethTlsPort\": 12345," >>$jsonPath
        echo "  \"ethUser\": \"UserOrAddress\"," >>$jsonPath
        echo "  \"ethWorker\": \"worker\"," >>$jsonPath
        echo "  \"ethTaxPercent\": 6," >>$jsonPath
        echo "  \"enableEthProxy\": false," >>$jsonPath
        echo "  \"enableEthDonatePool\": false," >>$jsonPath
        echo "  \"ethDonatePoolAddress\": \"eth.f2pool.com\"," >>$jsonPath
        echo "  \"ethDonatePoolSslMode\": false," >>$jsonPath
        echo "  \"ethDonatePoolPort\": 6688," >>$jsonPath
    fi

    echo "  \"version\": \"4.1.0\"" >>$jsonPath
    echo "}" >>$jsonPath
    if [[ $cmd == "apt-get" ]]; then
        ufw reload
    elif [ $(systemctl is-active firewalld) = 'active' ]; then
        systemctl restart firewalld
    fi
}

start_write_config() {
    echo
    echo "下载完成，开始写入配置"
    echo
    chmod a+x $installPath/ccminertaxproxy
    if [ -d "/etc/supervisor/conf/" ]; then
        rm /etc/supervisor/conf/worker${installNumberTag}.conf -f
        echo "[program:workertaxproxy${installNumberTag}]" >>/etc/supervisor/conf/worker${installNumberTag}.conf
        echo "command=${installPath}/minertaxproxy" >>/etc/supervisor/conf/worker${installNumberTag}.conf
        echo "directory=${installPath}/" >>/etc/supervisor/conf/worker${installNumberTag}.conf
        echo "autostart=true" >>/etc/supervisor/conf/worker${installNumberTag}.conf
        echo "autorestart=true" >>/etc/supervisor/conf/worker${installNumberTag}.conf
    elif [ -d "/etc/supervisor/conf.d/" ]; then
        rm /etc/supervisor/conf.d/worker${installNumberTag}.conf -f
        echo "[program:workertaxproxy${installNumberTag}]" >>/etc/supervisor/conf.d/worker${installNumberTag}.conf
        echo "command=${installPath}/minertaxproxy" >>/etc/supervisor/conf.d/worker${installNumberTag}.conf
        echo "directory=${installPath}/" >>/etc/supervisor/conf.d/worker${installNumberTag}.conf
        echo "autostart=true" >>/etc/supervisor/conf.d/worker${installNumberTag}.conf
        echo "autorestart=true" >>/etc/supervisor/conf.d/worker${installNumberTag}.conf
    elif [ -d "/etc/supervisord.d/" ]; then
        rm /etc/supervisord.d/worker${installNumberTag}.ini -f
        echo "[program:workertaxproxy${installNumberTag}]" >>/etc/supervisord.d/worker${installNumberTag}.ini
        echo "command=${installPath}/minertaxproxy" >>/etc/supervisord.d/worker${installNumberTag}.ini
        echo "directory=${installPath}/" >>/etc/supervisord.d/worker${installNumberTag}.ini
        echo "autostart=true" >>/etc/supervisord.d/worker${installNumberTag}.ini
        echo "autorestart=true" >>/etc/supervisord.d/worker${installNumberTag}.ini
    else
        echo
        echo "----------------------------------------------------------------"
        echo
        echo " Supervisor安装目录没了，安装失败"
        echo
        exit 1
    fi
    write_json

    echo
    while :; do
        echo -e "需要修改系统连接数限制吗，确认输入Y，可选输入项[${magenta}Y/N${none}] 按回车"
        read -p "$(echo -e "(默认: [${cyan}Y${none}]):")" needChangeLimit
        [[ -z $needChangeLimit ]] && needChangeLimit="y"

        case $needChangeLimit in
        Y | y)
            needChangeLimit="y"
            break
            ;;
        N | n)
            needChangeLimit="n"
            break
            ;;
        *)
            error
            ;;
        esac
    done
    changeLimit="n"
    if [[ "$needChangeLimit" = "y" ]]; then
        if [ $(grep -c "root soft nofile" /etc/security/limits.conf) -eq '0' ]; then
            echo "root soft nofile 100000" >>/etc/security/limits.conf
            changeLimit="y"
        fi
        if [ $(grep -c "root hard nofile" /etc/security/limits.conf) -eq '0' ]; then
            echo "root hard nofile 100000" >>/etc/security/limits.conf
            changeLimit="y"
        fi
    fi

    clear
    echo
    echo "----------------------------------------------------------------"
    echo
    echo " 本机防火墙端口已经开放，如果还无法连接，请到云服务商控制台操作安全组，放行对应的端口"
    echo
    echo " 安装好了...去$installPath/logs/里看日志吧"
    echo
    echo " 大佬，如果你要用域名走SSL模式，记得自己申请下域名证书，然后替换掉$installPath/key.pem和$installPath/cer.pem哦，不然很多内核不支持自签名证书的"
    echo
    if [[ "$changeLimit" = "y" ]]; then
        echo " 系统连接数限制已经改了，记得重启一次哦"
        echo
    fi
    echo "----------------------------------------------------------------"
    supervisorctl reload
}

install() {
    clear
    while :; do
        echo -e "请输入这次安装的标记ID，如果多开请设置不同的标记ID，只能输入数字1-999"
        read -p "$(echo -e "(默认: ${cyan}1$none):")" installNumberTag
        [ -z "$installNumberTag" ] && installNumberTag=1
        installPath="/etc/worker/worker"$installNumberTag
        oldversionInstallPath="/etc/miner/miner"$installNumberTag
        case $installNumberTag in
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9])
            echo
            echo
            echo -e "$yellow MinerTaxProxy将被安装到$installPath${none}"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            echo
            echo " ..端口必须在1-65535之间.."
            error
            ;;
        esac
    done

    if [ -d "$oldversionInstallPath" ]; then
        rm -rf $oldversionInstallPath -f
        if [ -d "/etc/supervisor/conf/" ]; then
            rm /etc/supervisor/conf/miner${installNumberTag}.conf -f
        elif [ -d "/etc/supervisor/conf.d/" ]; then
            rm /etc/supervisor/conf.d/miner${installNumberTag}.conf -f
        elif [ -d "/etc/supervisord.d/" ]; then
            rm /etc/supervisord.d/miner${installNumberTag}.ini -f
        fi
        supervisorctl reload
    fi

    if [ -d "$installPath" ]; then
        echo
        echo " 您已经安装了 MinerTaxProxy 的标记为$installNumberTag的多开程序啦...重新运行脚本设置个新的吧..."
        echo
        echo -e " $yellow 如要删除，重新运行脚本选择卸载即可${none}"
        echo
        exit 1
    fi

    log_config_ask
    eth_miner_config_ask
    http_logger_config_ask

    if [[ "$enableEthProxy" = "n" ]]; then
        echo
        echo " 请退出重新安装吧..."
        echo
        exit 1
    fi

    print_all_config

    if [[ "$confirmConfigRight" = "n" ]]; then
        exit 1
    fi
    install_download
    start_write_config
}

uninstall() {
    clear
    while :; do
        echo -e "请输入要删除的软件的标记ID，只能输入数字1-999"
        read -p "$(echo -e "(输入标记ID:)")" installNumberTag
        installPath="/etc/worker/worker"$installNumberTag
        oldversionInstallPath="/etc/miner/miner"$installNumberTag
        case $installNumberTag in
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9])
            echo
            echo
            echo -e "$yellow 标记ID为${installNumberTag}的MinerTaxProxy将被卸载${none}"
            echo
            break
            ;;
        *)
            echo
            echo " 输入一个标记ID好吗"
            error
            ;;
        esac
    done

    if [ -d "$oldversionInstallPath" ]; then
        rm -rf $oldversionInstallPath -f
        if [ -d "/etc/supervisor/conf/" ]; then
            rm /etc/supervisor/conf/miner${installNumberTag}.conf -f
        elif [ -d "/etc/supervisor/conf.d/" ]; then
            rm /etc/supervisor/conf.d/miner${installNumberTag}.conf -f
        elif [ -d "/etc/supervisord.d/" ]; then
            rm /etc/supervisord.d/miner${installNumberTag}.ini -f
        fi
        supervisorctl reload
    fi

    if [ -d "$installPath" ]; then
        echo
        echo "----------------------------------------------------------------"
        echo
        echo " 大佬...马上为您删除..."
        echo
        rm -rf $installPath -f
        if [ -d "/etc/supervisor/conf/" ]; then
            rm /etc/supervisor/conf/worker${installNumberTag}.conf -f
        elif [ -d "/etc/supervisor/conf.d/" ]; then
            rm /etc/supervisor/conf.d/worker${installNumberTag}.conf -f
        elif [ -d "/etc/supervisord.d/" ]; then
            rm /etc/supervisord.d/worker${installNumberTag}.ini -f
        fi
        echo "----------------------------------------------------------------"
        echo
        echo -e "$yellow 删除成功，如要安装新的，重新运行脚本选择即可${none}"
        supervisorctl reload
    else
        echo
        echo " 大佬...你压根就没安装这个标记ID的..."
        echo
        echo -e "$yellow 如要安装新的，重新运行脚本选择即可${none}"
        echo
        exit 1
    fi
}

clear
while :; do
    echo
    echo "....... AsiaminersTaxProxy 一键安装脚本 & 管理脚本  ......."
    echo
    echo " 1. 安装"
    echo
    echo " 2. 卸载"
    echo
    read -p "$(echo -e "请选择 [${magenta}1-2$none]:")" choose
    case $choose in
    1)
        install
        break
        ;;
    2)
        uninstall
        break
        ;;
    *)
        error
        ;;
    esac
done
