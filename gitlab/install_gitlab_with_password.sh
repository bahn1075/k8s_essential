#!/bin/bash
minikube addons enable ingress

set -e

NAMESPACE=gitlab
RELEASE=gitlab
VALUES_FILE=./values.yaml

# 네임스페이스 생성 (이미 있으면 무시)
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "[1/3] Helm으로 GitLab Chart 설치 중..."
helm repo add gitlab https://charts.gitlab.io/ || true
helm repo update
echo "[2/3] Helm 설치 진행 중..."
helm upgrade --install $RELEASE gitlab/gitlab \
  --namespace $NAMESPACE \
  -f $VALUES_FILE \
  --timeout 20m

echo "[3/3] root 패스워드 확인 중..."
# 패스워드가 생성될 때까지 대기
echo "GitLab root 패스워드(아래):"
for i in {1..30}; do
  PASS=$(kubectl get secret -n $NAMESPACE ${RELEASE}-gitlab-initial-root-password -ojsonpath="{.data.password}" 2>/dev/null | base64 --decode)
  if [ -n "$PASS" ]; then
    echo "$PASS"
    exit 0
  fi
  sleep 10
done
echo "[오류] 패스워드를 찾을 수 없습니다. 설치가 완료될 때까지 잠시 후 다시 시도하세요."
exit 1
