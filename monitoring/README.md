# Kubernetes Monitoring with Grafana k8s-monitoring-helm

이 디렉토리는 Grafana의 k8s-monitoring-helm 차트를 사용하여 Kubernetes 클러스터에 완전한 모니터링 환경을 구축하는 스크립트와 설정 파일들을 포함합니다.

## 구성 요소

- **Grafana Alloy**: 메트릭, 로그, 트레이스 수집
- **Prometheus**: 메트릭 저장소 (선택사항)
- **Loki**: 로그 저장소 (선택사항)
- **Grafana**: 시각화 대시보드 (선택사항)

## 파일 구조

```
monitoring/
├── README.md                    # 이 파일
├── install.sh                   # 메인 설치 스크립트
├── uninstall.sh                 # 제거 스크립트
├── values/
│   ├── k8s-monitoring-values.yaml    # k8s-monitoring 차트 설정
│   ├── prometheus-values.yaml        # Prometheus 설정 (선택사항)
│   ├── loki-values.yaml             # Loki 설정 (선택사항)
│   └── grafana-values.yaml          # Grafana 설정 (선택사항)
├── config/
│   ├── cluster-config.yaml          # 클러스터 설정
│   └── destinations.yaml            # 데이터 목적지 설정
└── examples/
    ├── standalone/                   # 독립 실행형 설정 예제
    ├── with-grafana-cloud/          # Grafana Cloud 연동 예제
    └── full-stack/                  # 전체 스택 설치 예제
```

## 사용법

### 1. 기본 설치
```bash
# 기본 k8s-monitoring만 설치 (외부 Prometheus/Loki/Grafana 사용)
./install.sh

# 또는 특정 설정으로 설치
./install.sh --config standalone
```

### 2. 전체 스택 설치
```bash
# Prometheus, Loki, Grafana 포함 전체 설치
./install.sh --config full-stack
```

### 3. Grafana Cloud 연동
```bash
# Grafana Cloud에 데이터 전송
./install.sh --config grafana-cloud
```

### 4. 제거
```bash
./uninstall.sh
```

## 요구사항

- Kubernetes 클러스터 (v1.20+)
- Helm 3.x
- kubectl 설정 완료

## 기능

### 수집 기능
- ✅ 클러스터 메트릭 (CPU, 메모리, 디스크, 네트워크)
- ✅ Pod 로그
- ✅ 클러스터 이벤트
- ✅ 애플리케이션 메트릭 (Annotation 기반)
- ✅ 서비스 메쉬 메트릭 (Istio, Linkerd 등)
- ✅ 분산 트레이싱 (OTLP)
- ✅ 프로파일링 (Pyroscope)

### 대상지 (Destinations)
- 🎯 Prometheus (Remote Write)
- 🎯 Loki
- 🎯 OTLP/OTLPHTTP
- 🎯 Pyroscope
- 🎯 Grafana Cloud

## 설정 커스터마이징

설정을 수정하려면 `values/` 디렉토리의 파일들을 편집하거나, `config/` 디렉토리의 설정을 변경하세요.

## 트러블슈팅

### 일반적인 문제들

1. **권한 부족**: 클러스터 관리자 권한이 필요합니다.
2. **리소스 부족**: 최소 2GB RAM, 2 CPU 권장
3. **네트워크 정책**: Alloy가 다른 서비스와 통신할 수 있어야 합니다.

### 로그 확인
```bash
# Alloy 로그 확인
kubectl logs -n monitoring -l app.kubernetes.io/name=alloy

# 설치 상태 확인
kubectl get pods -n monitoring
```

## 참고 자료

- [Grafana k8s-monitoring-helm 공식 문서](https://github.com/grafana/k8s-monitoring-helm)
- [Grafana Alloy 문서](https://grafana.com/docs/alloy/)
- [Kubernetes 모니터링 가이드](https://grafana.com/docs/grafana-cloud/kubernetes-monitoring/)
