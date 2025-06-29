#!/bin/zsh
# monitoring 네임스페이스에 mkcert-root-ca Secret을 생성합니다.
# mkcert가 설치되어 있어야 하며, rootCA.pem, rootCA-key.pem을 자동 복사합니다.

set -e
NAMESPACE=monitoring

cp "$(mkcert -CAROOT)/rootCA.pem" rootCA.crt
cp "$(mkcert -CAROOT)/rootCA-key.pem" rootCA-key.pem

kubectl get ns $NAMESPACE || kubectl create ns $NAMESPACE

kubectl create secret tls mkcert-root-ca \
  --cert=rootCA.crt \
  --key=rootCA-key.pem \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

rm -f rootCA.crt rootCA-key.pem

echo "[INFO] mkcert-root-ca secret 생성 완료 (monitoring 네임스페이스)"
