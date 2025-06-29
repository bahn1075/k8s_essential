#!/bin/zsh
# monitoring 네임스페이스에 mkcert-root-ca Secret을 생성합니다.
# rootCA.crt, rootCA-key.pem 파일이 같은 디렉토리에 있어야 합니다.

set -e
NAMESPACE=monitoring

kubectl get ns $NAMESPACE || kubectl create ns $NAMESPACE

kubectl create secret tls mkcert-root-ca \
  --cert=rootCA.crt \
  --key=rootCA-key.pem \
  -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "[INFO] mkcert-root-ca secret 생성 완료 (monitoring 네임스페이스)"
