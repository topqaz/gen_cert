#!/bin/bash

set -e

echo "====================================="
echo "     自签名 SSL 证书生成脚本"
echo "====================================="

# ================================
#   自动提示输入域名
# ================================
read -p "请输入要生成证书的域名（例如 example.com）: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ 域名不能为空！"
    exit 1
fi

echo "✔ 域名已确认：$DOMAIN"

# ================================
#   创建目录
# ================================
CERT_DIR="./certs/$DOMAIN"
mkdir -p "$CERT_DIR"

echo "✔ 证书将生成到：$CERT_DIR"

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

echo "✔ SAN 配置已生成"

# ================================
#   生成私钥
# ================================
KEY_FILE="$CERT_DIR/$DOMAIN.key"
openssl genrsa -out "$KEY_FILE" 2048
echo "✔ 私钥生成完成：$KEY_FILE"

# ================================
#   生成 CSR
# ================================
CSR_FILE="$CERT_DIR/$DOMAIN.csr"
openssl req -new -key "$KEY_FILE" -out "$CSR_FILE" -config "$OPENSSL_CNF"
echo "✔ CSR 生成完成：$CSR_FILE"

# ================================
#   生成自签名证书
# ================================
CRT_FILE="$CERT_DIR/$DOMAIN.crt"
openssl x509 -req -in "$CSR_FILE" -signkey "$KEY_FILE" -out "$CRT_FILE" -days 3650 -extensions v3_ext -extfile "$OPENSSL_CNF"
echo "✔ 自签名证书生成完成：$CRT_FILE"

echo ""
echo "====================================="
echo "         🎉 证书生成成功！"
echo "====================================="
echo ""
echo "私钥: $KEY_FILE"
echo "CSR : $CSR_FILE"
echo "CRT : $CRT_FILE"
echo ""
echo "nginx 配置示例："
echo "ssl_certificate     $CRT_FILE;"
echo "ssl_certificate_key $KEY_FILE;"
echo ""
