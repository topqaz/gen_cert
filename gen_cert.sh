#!/bin/bash

set -e

# ================================
#   彩色输出函数
# ================================
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

green "======================================"
green "     自签名 SSL 证书自动生成脚本"
green "======================================"

# ================================
#   输入域名（支持自动提示）
# ================================
DOMAIN="$1"

if [ -z "$DOMAIN" ]; then
  read -p "请输入要生成证书的域名（例如 example.com）: " DOMAIN
fi

if [ -z "$DOMAIN" ]; then
  red "❌ 域名不能为空！"
  exit 1
fi

green "✔ 域名已确认：$DOMAIN"

# ================================
#   创建目录
# ================================
CERT_DIR="./certs/$DOMAIN"
mkdir -p "$CERT_DIR"

green "✔ 证书文件将生成在：$CERT_DIR"

# ================================
#   生成 OpenSSL 配置（含 SAN）
# ================================
OPENSSL_CNF="$CERT_DIR/openssl.cnf"

cat > "$OPENSSL_CNF" << EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[dn]
C  = CN
ST = Internet
L  = Web
O  = SelfSigned
OU = IT
CN = $DOMAIN

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = www.$DOMAIN

[v3_ext]
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
EOF

green "✔ SAN 配置已生成"

# ================================
#   生成私钥
# ================================
KEY_FILE="$CERT_DIR/$DOMAIN.key"
openssl genrsa -out "$KEY_FILE" 2048
green "✔ 私钥生成完成：$KEY_FILE"

# ================================
#   生成 CSR
# ================================
CSR_FILE="$CERT_DIR/$DOMAIN.csr"
openssl req -new -key "$KEY_FILE" -out "$CSR_FILE" -config "$OPENSSL_CNF"
green "✔ CSR 生成完成：$CSR_FILE"

# ================================
#   生成自签名证书
# ================================
CRT_FILE="$CERT_DIR/$DOMAIN.crt"
openssl x509 -req -in "$CSR_FILE" -signkey "$KEY_FILE" -out "$CRT_FILE" -days 3650 -extensions v3_ext -extfile "$OPENSSL_CNF"
green "✔ 自签名证书生成完成：$CRT_FILE"

# ================================
#   输出结果
# ================================
green ""
green "======================================"
green "         🎉 证书生成成功！"
green "======================================"
echo ""
yellow "📌 私钥: $KEY_FILE"
yellow "📌 CSR:  $CSR_FILE"
yellow "📌 CRT:  $CRT_FILE"
yellow "📌 OpenSSL 配置:  $OPENSSL_CNF"
echo ""
green "你可以在 Nginx 中这样配置："
echo ""
echo "    ssl_certificate     $CRT_FILE;"
echo "    ssl_certificate_key $KEY_FILE;"
echo ""
green "======================================"
green "          完 成！"
green "======================================"
