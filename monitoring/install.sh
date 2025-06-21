#!/bin/bash

# k8s-monitoring 설치 스크립트
# Grafana의 k8s-monitoring-helm 차트를 사용하여 Kubernetes 모니터링 환경 구축

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
CHART_VERSION="3.0.2"
CONFIG_TYPE="${1:-basic}"

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# 사용법 출력
usage() {
    cat << EOF
Usage: $0 [CONFIG_TYPE]

CONFIG_TYPE:
  basic       - 기본 k8s-monitoring만 설치 (기본값)
  standalone  - Prometheus, Loki, Grafana 포함 독립 설치
  full-stack  - 전체 모니터링 스택 설치
  grafana-cloud - Grafana Cloud 연동 설치

예제:
  $0                    # 기본 설치
  $0 standalone         # 독립 설치
  $0 full-stack         # 전체 스택 설치
  $0 grafana-cloud      # Grafana Cloud 연동

EOF
}

# 필수 도구 확인
check_prerequisites() {
    info "필수 도구 확인 중..."
    
    local missing_tools=()
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "다음 도구들이 필요합니다: ${missing_tools[*]}"
        exit 1
    fi
    
    # Kubernetes 클러스터 연결 확인
    if ! kubectl cluster-info &> /dev/null; then
        error "Kubernetes 클러스터에 연결할 수 없습니다. kubectl 설정을 확인하세요."
        exit 1
    fi
    
    success "모든 필수 도구가 준비되었습니다."
}

# 네임스페이스 생성
create_namespace() {
    info "네임스페이스 생성 중..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        warning "네임스페이스 '$NAMESPACE'가 이미 존재합니다."
    else
        kubectl create namespace "$NAMESPACE"
        success "네임스페이스 '$NAMESPACE' 생성 완료"
    fi
}

# Helm 리포지토리 설정
setup_helm_repos() {
    info "Helm 리포지토리 설정 중..."
    
    # Grafana 리포지토리 추가
    helm repo add grafana https://grafana.github.io/helm-charts
    
    # 추가 리포지토리들 (필요시)
    if [[ "$CONFIG_TYPE" == "standalone" || "$CONFIG_TYPE" == "full-stack" ]]; then
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    fi
    
    helm repo update
    success "Helm 리포지토리 설정 완료"
}

# Alloy Operator CRD 설치
install_alloy_operator_crd() {
    info "Alloy Operator CRD 설치 중..."
    
    if kubectl get crd alloys.alloy.grafana.com &> /dev/null; then
        warning "Alloy CRD가 이미 설치되어 있습니다."
    else
        kubectl apply -f https://github.com/grafana/alloy-operator/releases/latest/download/collectors.grafana.com_alloy.yaml
        success "Alloy Operator CRD 설치 완료"
    fi
}

# 설정 파일 선택
get_values_file() {
    case "$CONFIG_TYPE" in
        "basic")
            echo "$SCRIPT_DIR/values/k8s-monitoring-values.yaml"
            ;;
        "standalone")
            echo "$SCRIPT_DIR/examples/standalone/values.yaml"
            ;;
        "full-stack")
            echo "$SCRIPT_DIR/examples/full-stack/values.yaml"
            ;;
        "grafana-cloud")
            echo "$SCRIPT_DIR/examples/with-grafana-cloud/values.yaml"
            ;;
        *)
            error "지원하지 않는 설정 타입: $CONFIG_TYPE"
            usage
            exit 1
            ;;
    esac
}

# k8s-monitoring 설치
install_k8s_monitoring() {
    local values_file
    values_file=$(get_values_file)
    
    if [ ! -f "$values_file" ]; then
        error "값 파일을 찾을 수 없습니다: $values_file"
        exit 1
    fi
    
    info "k8s-monitoring 설치 중... (설정: $CONFIG_TYPE)"
    
    helm upgrade --install "$RELEASE_NAME" \
        grafana/k8s-monitoring \
        --namespace "$NAMESPACE" \
        --version "$CHART_VERSION" \
        --values "$values_file" \
        --wait \
        --timeout=10m
    
    success "k8s-monitoring 설치 완료"
}

# 추가 컴포넌트 설치 (standalone/full-stack)
install_additional_components() {
    case "$CONFIG_TYPE" in
        "standalone"|"full-stack")
            install_prometheus
            install_loki
            if [[ "$CONFIG_TYPE" == "full-stack" ]]; then
                install_grafana
            fi
            ;;
    esac
}

# Prometheus 설치
install_prometheus() {
    info "Prometheus 설치 중..."
    
    helm upgrade --install prometheus \
        prometheus-community/kube-prometheus-stack \
        --namespace "$NAMESPACE" \
        --values "$SCRIPT_DIR/values/prometheus-values.yaml" \
        --wait \
        --timeout=15m
    
    success "Prometheus 설치 완료"
}

# Loki 설치
install_loki() {
    info "Loki 설치 중..."
    
    helm upgrade --install loki \
        grafana/loki \
        --namespace "$NAMESPACE" \
        --values "$SCRIPT_DIR/values/loki-values.yaml" \
        --wait \
        --timeout=10m
    
    success "Loki 설치 완료"
}

# Grafana 설치
install_grafana() {
    info "Grafana 설치 중..."
    
    helm upgrade --install grafana \
        grafana/grafana \
        --namespace "$NAMESPACE" \
        --values "$SCRIPT_DIR/values/grafana-values.yaml" \
        --wait \
        --timeout=10m
    
    success "Grafana 설치 완료"
}

# 설치 상태 확인
check_installation() {
    info "설치 상태 확인 중..."
    
    # Pod 상태 확인
    echo ""
    info "Pod 상태:"
    kubectl get pods -n "$NAMESPACE" -o wide
    
    # 서비스 상태 확인
    echo ""
    info "서비스 상태:"
    kubectl get svc -n "$NAMESPACE"
    
    # Grafana 접속 정보 (standalone/full-stack인 경우)
    if [[ "$CONFIG_TYPE" == "standalone" || "$CONFIG_TYPE" == "full-stack" ]]; then
        echo ""
        info "Grafana 접속 정보:"
        echo "URL: http://$(kubectl get svc grafana -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):3000"
        echo "Username: admin"
        echo "Password: $(kubectl get secret grafana -n $NAMESPACE -o jsonpath='{.data.admin-password}' | base64 -d)"
    fi
}

# 메인 실행 함수
main() {
    # 헬프 옵션 처리
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi
    
    info "Kubernetes 모니터링 환경 설치를 시작합니다..."
    info "설정 타입: $CONFIG_TYPE"
    
    check_prerequisites
    create_namespace
    setup_helm_repos
    install_alloy_operator_crd
    install_k8s_monitoring
    install_additional_components
    
    success "설치가 완료되었습니다!"
    
    check_installation
    
    echo ""
    info "다음 명령어로 모니터링 상태를 확인할 수 있습니다:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=alloy"
    
    if [[ "$CONFIG_TYPE" == "standalone" || "$CONFIG_TYPE" == "full-stack" ]]; then
        echo ""
        info "Grafana에 접속하여 대시보드를 확인하세요."
    fi
}

# 스크립트 실행
main "$@"
