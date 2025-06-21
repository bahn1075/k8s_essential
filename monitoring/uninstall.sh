#!/bin/bash

# k8s-monitoring 제거 스크립트

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 기본 설정
NAMESPACE="monitoring"
RELEASE_NAME="k8s-monitoring"

# 로그 함수들
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 사용자 확인
confirm_uninstall() {
    echo -e "${YELLOW}주의: 이 작업은 모든 모니터링 컴포넌트를 제거합니다.${NC}"
    echo "네임스페이스 '$NAMESPACE'의 모든 리소스가 삭제됩니다."
    echo ""
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "제거 작업이 취소되었습니다."
        exit 0
    fi
}

# Helm 릴리스 제거
uninstall_helm_releases() {
    info "Helm 릴리스 제거 중..."
    
    # k8s-monitoring 제거
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
        success "k8s-monitoring 제거 완료"
    else
        warning "k8s-monitoring 릴리스를 찾을 수 없습니다."
    fi
    
    # 추가 컴포넌트들 제거
    local releases=("prometheus" "loki" "grafana")
    
    for release in "${releases[@]}"; do
        if helm list -n "$NAMESPACE" | grep -q "$release"; then
            info "$release 제거 중..."
            helm uninstall "$release" -n "$NAMESPACE"
            success "$release 제거 완료"
        fi
    done
}

# PVC 제거 (선택사항)
remove_pvcs() {
    info "PVC 제거 여부를 확인합니다..."
    
    local pvcs
    pvcs=$(kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    
    if [ "$pvcs" -gt 0 ]; then
        echo "다음 PVC들이 발견되었습니다:"
        kubectl get pvc -n "$NAMESPACE"
        echo ""
        read -p "PVC도 함께 제거하시겠습니까? (데이터가 영구적으로 삭제됩니다) (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl delete pvc --all -n "$NAMESPACE"
            success "모든 PVC 제거 완료"
        else
            warning "PVC는 보존됩니다."
        fi
    fi
}

# 네임스페이스 제거
remove_namespace() {
    info "네임스페이스 제거 여부를 확인합니다..."
    
    read -p "네임스페이스 '$NAMESPACE'를 제거하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
        success "네임스페이스 '$NAMESPACE' 제거 완료"
    else
        warning "네임스페이스는 보존됩니다."
    fi
}

# CRD 제거 (선택사항)
remove_crds() {
    info "Alloy CRD 제거 여부를 확인합니다..."
    
    if kubectl get crd alloys.alloy.grafana.com &> /dev/null; then
        read -p "Alloy CRD를 제거하시겠습니까? (다른 클러스터에서 사용 중일 수 있습니다) (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl delete crd alloys.alloy.grafana.com
            success "Alloy CRD 제거 완료"
        else
            warning "Alloy CRD는 보존됩니다."
        fi
    fi
}

# 정리 상태 확인
check_cleanup() {
    info "정리 상태 확인 중..."
    
    # 네임스페이스 확인
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo ""
        info "남은 리소스:"
        kubectl get all -n "$NAMESPACE" 2>/dev/null || true
    else
        success "모든 리소스가 정리되었습니다."
    fi
}

# 메인 실행 함수
main() {
    info "Kubernetes 모니터링 환경 제거를 시작합니다..."
    
    # 네임스페이스 존재 확인
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        warning "네임스페이스 '$NAMESPACE'를 찾을 수 없습니다."
        info "이미 제거되었거나 설치되지 않았을 수 있습니다."
        exit 0
    fi
    
    confirm_uninstall
    uninstall_helm_releases
    remove_pvcs
    remove_namespace
    remove_crds
    
    success "제거가 완료되었습니다!"
    
    check_cleanup
    
    echo ""
    info "모니터링 환경이 성공적으로 제거되었습니다."
}

# 스크립트 실행
main "$@"
