Debian_IPv6(){

    # 获取接口名称
    iName=$(ip link show | grep "^[0-9]*:" | awk -F': ' 'NR==2{print $2}')
    echo "网卡名称：$iName" # 输出网卡名称供检查

    # 临时开启IPv6
    dhclient -6 $iName

    # 备份原始的网络配置文件
    cp /etc/network/interfaces /root/interfaces.bak

    # 检查并添加IPv6的配置行
    if ! grep -q "iface $iName inet6 dhcp" /etc/network/interfaces; then
        echo "iface $iName inet6 dhcp" | sudo tee -a /etc/network/interfaces
    fi

    # 重启网络服务
    systemctl restart networking

    # 确认IPv6地址
    sleep 2s
    echo "Your IPv6 address is: $(curl -s -6 ip.sb)"
}

Ubuntu_IPv6(){

    yamlName=$(find /etc/netplan/ -iname "*.yaml")
    iName=$(ip link show | grep "^[0-9]*:" | awk -F': ' 'NR==2{print $2}')
    dhclient -6 $iName
    MAC=$(ip link show $iName | awk '/link\/ether/ {print $2}')
    IPv6=$(ip -6 addr show $iName | awk '/inet6 .* global/ {print $2}')

    if [[ -z "$IPv6" ]]; then
        echo "Can't find IPv6 address";
        exit 1;
    fi

    cp "$yamlName" /root/netplan_backup.yaml

    cat <<EOF >"$yamlName"
network:
   version: 2
   ethernets:
      $iName:
          dhcp4: true
          dhcp6: false
          match:
              macaddress: $MAC
          addresses:
              - $IPv6
EOF

    netplan apply
    sleep 2s
    echo "Your IPv6 address is: $(curl -s -6 ip.sb)"
}

myOS=$(hostnamectl | grep "Operating System" | awk '{print $3}')
if [[ "$myOS" =~ "Ubuntu" ]]; then
    echo "Ubuntu detected"
    Ubuntu_IPv6
elif [[ "$myOS" =~ "Debian" ]]; then
    echo "Debian detected"
    Debian_IPv6
else
    echo "Unsupported OS"
fi
