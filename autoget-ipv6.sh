#!/bin/bash

# 获取第二个网卡名称
NIC_NAME=$(ip link show | grep "^[0-9]*:" | awk -F': ' 'NR==2{print $2}')

# 检查是否成功获取到网卡名
if [ -z "$NIC_NAME" ]; then
    echo "未找到网卡名称。"
    exit 1
fi

# 设置文件路径
NETWORK_FILE="/etc/systemd/network/$NIC_NAME.network"

# 如果文件不存在则创建并写入内容
if [ ! -f "$NETWORK_FILE" ]; then
    echo "创建文件 $NETWORK_FILE"
    cat <<EOF > "$NETWORK_FILE"
[Match]
Name=$NIC_NAME

[Network]
DHCP=ipv4
LinkLocalAddressing=ipv6
NTP=169.254.169.254
EOF
else
    echo "文件 $NETWORK_FILE 已存在。"
fi

# 停止并启动服务
systemctl stop networking && systemctl stop ifup@"$NIC_NAME" && systemctl start systemd-networkd

systemctl enable systemd-networkd
apt purge -y --auto-remove ifupdown isc-dhcp-client

echo "配置已完成并已设置开机自启。"