# Kubernetes Full Stack Monitoring

이 디렉토리는 Kubernetes 클러스터에 완전한 모니터링 스택을 배포하기 위한 설정 파일들을 포함합니다.

## 구성 요소

- **Prometheus**: 메트릭 수집 및 저장
- **Grafana**: 시각화 및 대시보드
- **Loki**: 로그 집계 및 저장
- **Promtail**: 로그 수집 에이전트
- **Tempo**: 분산 추적 시스템

## 주요 특징

- ✅ **최신 이미지 사용**: 모든 컴포넌트는 태그를 명시하지 않아 최신 버전 사용
- ✅ **개별 컴포넌트 설치**: Stack 기술 대신 각 컴포넌트를 개별적으로 설치
- ✅ **Grafana 외부 접근**: `grafana.local` 도메인으로 Ingress 설정
- ✅ **Loki 스토리지 안정성**: 파일시스템 기반 저장소로 오류 방지
- ✅ **영구 저장소**: 모든 데이터는 PersistentVolume에 저장

## 파일 구조

```
monitoring/
├── 00-namespace.yaml           # 네임스페이스 정의
├── prometheus-values.yaml      # Prometheus 설정
├── grafana-values.yaml         # Grafana 설정
├── grafana-ingress.yaml        # Grafana 외부 접근 설정
├── loki-values.yaml           # Loki 설정
├── promtail-values.yaml       # Promtail 설정
├── tempo-values.yaml          # Tempo 설정
├── install.sh                 # 설치 스크립트
├── uninstall.sh              # 제거 스크립트
└── README.md                 # 이 파일
```

## 설치 방법

### 사전 요구사항

1. **Kubernetes 클러스터** (minikube, kind, 실제 클러스터 등)
2. **kubectl** 설치 및 클러스터 연결 설정
3. **Helm 3.x** 설치
4. **Ingress Controller** (nginx-ingress 권장)

```bash
# Ingress Controller 설치 (nginx)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

### 자동 설치

```bash
# 실행 권한 부여
chmod +x install.sh

# 설치 실행
./install.sh
```

### 수동 설치

1. **네임스페이스 생성**
```bash
kubectl apply -f 00-namespace.yaml
```

2. **Helm 저장소 추가**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

3. **각 컴포넌트 설치**
```bash
# Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --values prometheus-values.yaml

# Loki
helm install loki grafana/loki \
  --namespace monitoring --values loki-values.yaml

# Promtail
helm install promtail grafana/promtail \
  --namespace monitoring --values promtail-values.yaml

# Tempo
helm install tempo grafana/tempo \
  --namespace monitoring --values tempo-values.yaml

# Grafana
helm install grafana grafana/grafana \
  --namespace monitoring --values grafana-values.yaml

# Grafana Ingress
kubectl apply -f grafana-ingress.yaml
```

## 접속 정보

### Grafana 접속

- **URL**: http://grafana.local
- **사용자명**: admin
- **비밀번호**: admin123

#### hosts 파일 설정

```bash
# /etc/hosts 파일에 추가
echo '127.0.0.1 grafana.local' | sudo tee -a /etc/hosts
```

### Port Forward를 통한 접속

Ingress가 설정되지 않은 경우 다음 명령어로 접속할 수 있습니다:

```bash
# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# AlertManager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
```

## 데이터 소스 설정

Grafana에 다음 데이터 소스들이 자동으로 설정됩니다:

1. **Prometheus**: `http://prometheus-operated.monitoring.svc.cluster.local:9090`
2. **Loki**: `http://loki.monitoring.svc.cluster.local:3100`
3. **Tempo**: `http://tempo.monitoring.svc.cluster.local:3200`

## 기본 대시보드

설치 시 다음 대시보드들이 자동으로 임포트됩니다:

- **Kubernetes Cluster Monitoring** (ID: 7249)
- **Node Exporter Full** (ID: 1860)
- **Loki Dashboard** (ID: 13639)

## 모니터링 대상

### Prometheus
- Kubernetes 클러스터 메트릭
- Node Exporter 메트릭
- kube-state-metrics
- Loki 메트릭
- Tempo 메트릭

### Loki
- 모든 Pod 로그
- 시스템 로그
- 컨테이너 로그

### Tempo
- Jaeger 프로토콜 지원
- OpenTelemetry 프로토콜 지원
- Zipkin 프로토콜 지원

## 스토리지 설정

모든 컴포넌트는 영구 저장소를 사용합니다:

- **Prometheus**: 10Gi (메트릭 데이터, 30일 보존)
- **AlertManager**: 2Gi (알람 데이터)
- **Grafana**: 5Gi (대시보드 및 설정)
- **Loki**: 10Gi (로그 데이터)
- **Tempo**: 10Gi (추적 데이터, 24시간 보존)

## 제거 방법

```bash
# 실행 권한 부여
chmod +x uninstall.sh

# 제거 실행
./uninstall.sh
```

## 문제 해결

### 1. Pod가 시작되지 않는 경우

```bash
# Pod 상태 확인
kubectl get pods -n monitoring

# 특정 Pod 로그 확인
kubectl logs -n monitoring <pod-name>

# Pod 상세 정보 확인
kubectl describe pod -n monitoring <pod-name>
```

### 2. 스토리지 문제

```bash
# PVC 상태 확인
kubectl get pvc -n monitoring

# 스토리지 클래스 확인
kubectl get storageclass
```

### 3. Ingress 접속 문제

```bash
# Ingress 상태 확인
kubectl get ingress -n monitoring

# Ingress Controller 확인
kubectl get pods -n ingress-nginx

# Ingress Controller 로그 확인
kubectl logs -n ingress-nginx <ingress-controller-pod>
```

### 4. 서비스 연결 문제

```bash
# 서비스 상태 확인
kubectl get svc -n monitoring

# 엔드포인트 확인
kubectl get endpoints -n monitoring
```

## 추가 설정

### Slack 알림 설정

`prometheus-values.yaml`의 AlertManager 설정에서 Slack 웹훅을 추가할 수 있습니다.

### 추가 대시보드 임포트

Grafana UI에서 Dashboard > Import를 통해 추가 대시보드를 임포트할 수 있습니다.

### 커스텀 알람 규칙

`prometheus-values.yaml`에서 추가 알람 규칙을 정의할 수 있습니다.

## 지원

문제가 발생하거나 추가 설정이 필요한 경우, 각 컴포넌트의 공식 문서를 참조하세요:

- [Prometheus](https://prometheus.io/docs/)
- [Grafana](https://grafana.com/docs/)
- [Loki](https://grafana.com/docs/loki/)
- [Tempo](https://grafana.com/docs/tempo/)
