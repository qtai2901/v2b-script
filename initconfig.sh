#!/bin/bash
# 一键配置

# 检查系统是否有 IPv6 地址
check_ipv6_support() {
    if ip -6 addr | grep -q "inet6"; then
        echo "1"  # 支持 IPv6
    else
        echo "0"  # 不支持 IPv6
    fi
}

add_node_config() {
    echo -e "${green}Vui lòng chọn loại core：${plain}"
    echo -e "${green}1. xray${plain}"
    echo -e "${green}2. singbox${plain}"
    read -rp "Vui lòng nhập：" core_type
    if [ "$core_type" == "1" ]; then
        core="xray"
        core_xray=true
    elif [ "$core_type" == "2" ]; then
        core="sing"
        core_sing=true
    else
        echo "Lựa chọn không hợp lệ. Vui lòng chọn 1 hoặc 2."
        continue
    fi
    while true; do
        read -rp "请输入节点Node ID：" NodeID
        # 判断NodeID是否为正整数
        if [[ "$NodeID" =~ ^[0-9]+$ ]]; then
            break  # 输入正确，退出循环
        else
            echo "Lỗi: Vui lòng nhập đúng số làm Node ID。"
        fi
    done
    
    echo -e "${yellow}Vui lòng chọn một giao thức vận chuyển nút：${plain}"
    echo -e "${green}1. Shadowsocks${plain}"
    echo -e "${green}2. Vless${plain}"
    echo -e "${green}3. Vmess${plain}"
    echo -e "${green}4. Hysteria${plain}"
    echo -e "${green}5. Hysteria2${plain}"
    echo -e "${green}6. Tuic${plain}"
    echo -e "${green}7. Trojan${plain}"
    read -rp "Loại nút：" NodeType
    case "$NodeType" in
        1 ) NodeType="shadowsocks" ;;
        2 ) NodeType="vless" ;;
        3 ) NodeType="vmess" ;;
        4 ) NodeType="hysteria" ;;
        5 ) NodeType="hysteria2" ;;
        6 ) NodeType="tuic" ;;
        7 ) NodeType="trojan" ;;
        * ) NodeType="shadowsocks" ;;
    esac
    if [ $NodeType == "vless" ]; then
        read -rp "Có bật reality không？(y/n)" isreality
    fi
    certmode="none"
    certdomain="example.com"
    if [ "$isreality" != "y" ] && [ "$isreality" != "Y" ]; then
        read -rp "Bật TLS？(y/n)" istls
        if [ "$istls" == "y" ] || [ "$istls" == "Y" ]; then
            
            
              certmode="file" 
             certdomain="8.8.8.8"
          
            
        fi
    fi
    ipv6_support=$(check_ipv6_support)
    listen_ip="0.0.0.0"
    if [ "$ipv6_support" -eq 1 ]; then
        listen_ip="::"
    fi
    node_config=""
    if [ "$core_type" == "1" ]; then 
    node_config=$(cat <<EOF
{
            "Core": "$core",
            "ApiHost": "https://$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "Timeout": 30,
            "ListenIP": "0.0.0.0",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 100,
            "EnableProxyProtocol": false,
            "EnableUot": true,
            "EnableTFO": true,
            "DNSType": "UseIPv4",
            "CertConfig": {
                "CertMode": "$certmode",
                "RejectUnknownSni": false,
                "CertDomain": "$certdomain",
                "CertFile": "/etc/V2bX/quoctai.crt",
                "KeyFile": "/etc/V2bX/quoctai.key",
                "Email": "v2bx@github.com",
                "Provider": "cloudflare",
                "DNSEnv": {
                    "EnvName": "env1"
                }
            }
        },
EOF
)
    elif [ "$core_type" == "2" ]; then
    node_config=$(cat <<EOF
{
            "Core": "$core",
            "ApiHost": "$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "Timeout": 30,
            "ListenIP": "$listen_ip",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 100,
            "TCPFastOpen": true,
            "SniffEnabled": true,
            "EnableDNS": true,
            "CertConfig": {
                "CertMode": "$certmode",
                "RejectUnknownSni": false,
                "CertDomain": "$certdomain",
                "CertFile": "/etc/V2bX/fullchain.cer",
                "KeyFile": "/etc/V2bX/cert.key",
                "Email": "v2bx@github.com",
                "Provider": "cloudflare",
                "DNSEnv": {
                    "EnvName": "env1"
                }
            }
        },
EOF
)
    fi
    nodes_config+=("$node_config")
}

generate_config_file() {
    # echo -e "${yellow}Trình hướng dẫn tạo tệp cấu hình V2bX${plain}"
    # echo -e "${red}请阅读以下注意事项：${plain}"
    # echo -e "${red}1. 目前该功能正处测试阶段${plain}"
    # echo -e "${red}2. 生成的配置文件会保存到 /etc/V2bX/config.json${plain}"
    # echo -e "${red}3. 原来的配置文件会保存到 /etc/V2bX/config.json.bak${plain}"
    # echo -e "${red}4. 目前仅部分支持TLS${plain}"
    # echo -e "${red}5. 使用此功能生成的配置文件会自带审计，确定继续？(y/n)${plain}"
    # read -rp "请输入：" continue_prompt
    # if [[ "$continue_prompt" =~ ^[Nn][Oo]? ]]; then
    #     exit 0
    # fi
    
    nodes_config=()
    first_node=true
    core_xray=false
    core_sing=false
    fixed_api_info=false
    check_api=false
    
    while true; do
        if [ "$first_node" = true ]; then
            read -rp "Domain(không cần https://)：" ApiHost
            read -rp "Key web：" ApiKey
            
            
                fixed_api_info=true
                # echo -e "${red}成功固定地址${plain}"
           
            first_node=false
            add_node_config
        else
            read -rp "Bạn có muốn tiếp tục thêm cấu hình nút không? (Nhấn enter để tiếp tục, nhập n hoặc không để thoát)" continue_adding_node
            if [[ "$continue_adding_node" =~ ^[Nn][Oo]? ]]; then
                break
            elif [ "$fixed_api_info" = false ]; then
                read -rp "Domain(không cần https://)：" ApiHost
                read -rp "Key web：" ApiKey
            fi
            add_node_config
        fi
    done

    # 根据核心类型生成 Cores
    if [ "$core_xray" = true ] && [ "$core_sing" = true ]; then
        cores_config="[
        {
            \"Type\": \"xray\",
            \"Log\": {
                \"Level\": \"error\",
                \"ErrorPath\": \"/etc/V2bX/error.log\"
            },
            \"OutboundConfigPath\": \"/etc/V2bX/custom_outbound.json\",
            \"RouteConfigPath\": \"/etc/V2bX/route.json\"
        },
        {
            \"Type\": \"sing\",
            \"Log\": {
                \"Level\": \"error\",
                \"Timestamp\": true
            },
            \"NTP\": {
                \"Enable\": false,
                \"Server\": \"time.apple.com\",
                \"ServerPort\": 0
            },
            \"OriginalPath\": \"/etc/V2bX/sing_origin.json\"
        }]"
    elif [ "$core_xray" = true ]; then
        cores_config="[
        {
            \"Type\": \"xray\",
            \"Log\": {
                \"Level\": \"error\",
                \"ErrorPath\": \"/etc/V2bX/error.log\"
            },
            \"OutboundConfigPath\": \"/etc/V2bX/custom_outbound.json\",
            \"RouteConfigPath\": \"/etc/V2bX/route.json\"
        }]"
    elif [ "$core_sing" = true ]; then
        cores_config="[
        {
            \"Type\": \"sing\",
            \"Log\": {
                \"Level\": \"error\",
                \"Timestamp\": true
            },
            \"NTP\": {
                \"Enable\": false,
                \"Server\": \"time.apple.com\",
                \"ServerPort\": 0
            },
            \"OriginalPath\": \"/etc/V2bX/sing_origin.json\"
        }]"
    fi

    # 切换到配置文件目录
    cd /etc/V2bX
    
    # 备份旧的配置文件
    mv config.json config.json.bak
    nodes_config_str="${nodes_config[*]}"
    formatted_nodes_config="${nodes_config_str%,}"

    # 创建 config.json 文件
    cat <<EOF > /etc/V2bX/config.json
{
    "Log": {
        "Level": "error",
        "Output": ""
    },
    "Cores": $cores_config,
    "Nodes": [$formatted_nodes_config]
}
EOF
    
    # 创建 custom_outbound.json 文件
    cat <<EOF > /etc/V2bX/custom_outbound.json
    [
        {
            "tag": "IPv4_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv4"
            }
        },
        {
            "tag": "IPv6_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6"
            }
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
EOF
    
    # 创建 route.json 文件
    cat <<EOF > /etc/V2bX/route.json
    {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "geoip:private",
                    "geoip:cn"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "domain": [
                    "geosite:cn"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "domain": [
                    "regexp:(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
                    "regexp:(.+.|^)(360|so).(cn|com)",
                    "regexp:(Subject|HELO|SMTP)",
                    "regexp:(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
                    "regexp:(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
                    "regexp:(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
                    "regexp:(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
                    "regexp:(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
                    "regexp:(.+.|^)(360).(cn|com|net)",
                    "regexp:(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
                    "regexp:(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
                    "regexp:(.*.||)(netvigator|torproject).(com|cn|net|org)",
                    "regexp:(..||)(visa|mycard|gash|beanfun|bank).",
                    "regexp:(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
                    "regexp:(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
                    "regexp:(.*.||)(mycard).(com|tw)",
                    "regexp:(.*.||)(gash).(com|tw)",
                    "regexp:(.bank.)",
                    "regexp:(.*.||)(pincong).(rocks)",
                    "regexp:(.*.||)(taobao).(com)",
                    "regexp:(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
                    "regexp:(flows|miaoko).(pages).(dev)"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "127.0.0.1/32",
                    "10.0.0.0/8",
                    "fc00::/7",
                    "fe80::/10",
                    "172.16.0.0/12"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "protocol": [
                    "bittorrent"
                ]
            }
        ]
    }
EOF

    # 创建 sing_origin.json 文件           
    cat <<EOF > /etc/V2bX/sing_origin.json
{
  "outbounds": [
    {
      "tag": "direct",
      "type": "direct",
      "domain_strategy": "prefer_ipv4"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "rules": [
      {
        "outbound": "block",
        "geoip": [
          "private"
        ]
      },
      {
        "geosite": [
          "cn"
        ],
        "outbound": "block"
      },
      {
        "geoip": [
          "cn"
        ],
        "outbound": "block"
      },
      {
        "domain_regex": [
            "(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
            "(.+.|^)(360|so).(cn|com)",
            "(Subject|HELO|SMTP)",
            "(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
            "(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
            "(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
            "(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
            "(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
            "(.+.|^)(360).(cn|com|net)",
            "(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
            "(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
            "(.*.||)(netvigator|torproject).(com|cn|net|org)",
            "(..||)(visa|mycard|gash|beanfun|bank).",
            "(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
            "(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
            "(.*.||)(mycard).(com|tw)",
            "(.*.||)(gash).(com|tw)",
            "(.bank.)",
            "(.*.||)(pincong).(rocks)",
            "(.*.||)(taobao).(com)",
            "(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
            "(flows|miaoko).(pages).(dev)"
        ],
        "outbound": "block"
      },
      {
        "outbound": "direct",
        "network": [
          "udp","tcp"
        ]
      }
    ]
  }
}
EOF

    echo -e "${green}V2bX Quá trình tạo tệp cấu hình đã hoàn tất và dịch vụ đang được khởi động lại.${plain}"
    v2bx restart
}

install_bbr() {
    bash <(curl -L -s https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh)
}
