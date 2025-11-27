#!/bin/bash

# 使用方式：
#   ./gen_cert.sh example.com
#
# 将生成：
#   server.key 私钥
#   server.crt 自签名证书
#   server.csr CSR 请求文件

DOMAIN="$1"

if [ -z "$DOMAIN" ]; then
    echo "请提供域名，例如："
    echo "./gen_cert.sh example.com"
    exit 1
fi

WWW_DOMAIN="www.$DOMAIN"

echo "生成 SAN 域名证书:"
echo " - $DOMAIN"
echo " - $WWW_DOMAIN"

# 创建私钥
openssl genrsa -out server.key 2048

# 生成 SAN 配置文件
cat > san.cnf <<EOF
[req]
default_bits = 2048
prompt = no
distinguished_name = req_distinguished_name
req_extensions = req_ext

[req_distinguished_name]
CN = $DOMAIN

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = $WWW_DOMAIN
EOF

# 生成 CSR
openssl req -new -key server.key -out server.csr -config san.cnf

# 生成自签名证书
openssl x509 -req -in server.csr -signkey server.key -out server.crt \
  -days 3650 -extensions req_ext -extfile san.cnf

echo ""
echo "证书生成完成："
echo " - server.key"
echo " - server.crt"
echo ""
echo "有效期：10 年"

