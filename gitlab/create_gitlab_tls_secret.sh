#!/bin/zsh
# gitlab 네임스페이스에 SAN이 포함된 self-signed 인증서로 gitlab-local-tls secret을 생성합니다.

set -e
NAMESPACE=gitlab
DOMAIN=gitlab.local

kubectl get ns $NAMESPACE || kubectl create ns $NAMESPACE

cat > san.cnf <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
CN = $DOMAIN

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
EOF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -config san.cnf -extensions req_ext \
  -keyout tls.key -out tls.crt

kubectl create secret tls gitlab-local-tls --cert=tls.crt --key=tls.key -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

rm -f tls.crt tls.key san.cnf

echo "[INFO] gitlab-local-tls secret 생성 완료 (SAN 포함)"
