#!/bin/zsh
# jenkins를 helm chart로 설치하고, ingress를 통해 jenkins.local로 접속할 수 있도록 구성합니다.

set -e

NAMESPACE=jenkins
RELEASE_NAME=jenkins
DOMAIN=jenkins.local

# 네임스페이스 생성
kubectl get ns $NAMESPACE || kubectl create ns $NAMESPACE

# TLS Secret이 없으면 생성 (self-signed 예시)
if ! kubectl get secret jenkins-tls -n $NAMESPACE > /dev/null 2>&1; then
  echo "[INFO] self-signed 인증서로 jenkins-tls secret 생성"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -subj "/CN=$DOMAIN" \
    -keyout tls.key -out tls.crt
  kubectl create secret tls jenkins-tls \
    --cert=tls.crt --key=tls.key -n $NAMESPACE
  rm -f tls.crt tls.key
fi

# Jenkins Helm repo 추가 및 업데이트
helm repo add jenkinsci https://charts.jenkins.io || true
helm repo update

# Jenkins 설치 (ingress 포함)
helm upgrade --install $RELEASE_NAME jenkinsci/jenkins \
  --namespace $NAMESPACE \
  --set controller.ingress.enabled=true \
  --set controller.ingress.hostName=$DOMAIN \
  --set controller.ingress.annotations."kubernetes\.io/ingress\.class"=nginx \
  --set controller.ingress.ingressClassName=nginx \
  --set 'controller.ingress.tls[0].hosts[0]'=$DOMAIN \
  --set 'controller.ingress.tls[0].secretName'=jenkins-tls \
  --set controller.admin.username=admin \
  --set controller.admin.password=admin

# Ingress 정보 출력
echo "\n[INFO] Jenkins Ingress 생성 완료!"
echo "접속: https://$DOMAIN (hosts 파일에 $DOMAIN 등록 필요)"
echo "기본 관리자 계정: admin / admin"
