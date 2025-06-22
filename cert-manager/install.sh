#!/bin/bash

# cert-manager 설치 스크립트
# jetstack/cert-manager helm chart를 사용하여 cert-manager 설치

set -e

echo "🚀 cert-manager 설치를 시작합니다..."

# cert-manager namespace 생성
echo "📦 cert-manager namespace 생성..."
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Jetstack Helm repository 추가
echo "📦 Jetstack Helm repository 추가..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

# cert-manager CRDs 설치
echo "📦 cert-manager CRDs 설치..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml

# cert-manager helm chart 설치
echo "📦 cert-manager helm chart 설치..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --values values.yaml \
  --wait

# 설치 확인
echo "✅ cert-manager 설치 확인..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

echo "🎉 cert-manager 설치가 완료되었습니다!"
echo ""
echo "다음 단계:"
echo "1. ClusterIssuer 설정: kubectl apply -f cluster-issuer-letsencrypt.yaml"
echo "2. nginx-ingress에서 TLS 인증서 자동 발급 테스트"
