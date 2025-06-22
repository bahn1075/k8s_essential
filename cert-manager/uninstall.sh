#!/bin/bash

# cert-manager 제거 스크립트

set -e

echo "🗑️  cert-manager 제거를 시작합니다..."

# ClusterIssuer 제거
echo "📦 ClusterIssuer 제거..."
kubectl delete -f cluster-issuer-letsencrypt.yaml --ignore-not-found=true

# cert-manager helm chart 제거
echo "📦 cert-manager helm chart 제거..."
helm uninstall cert-manager -n cert-manager --ignore-not-found

# cert-manager CRDs 제거
echo "📦 cert-manager CRDs 제거..."
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml --ignore-not-found=true

# cert-manager namespace 제거
echo "📦 cert-manager namespace 제거..."
kubectl delete namespace cert-manager --ignore-not-found=true

echo "🎉 cert-manager 제거가 완료되었습니다!"
