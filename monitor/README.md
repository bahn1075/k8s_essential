# Grafana Monitoring Stack

이 디렉토리에는 Kubernetes 클러스터에 완전한 모니터링 스택을 배포하는 구성이 포함되어 있습니다.

## 포함된 구성 요소

- **Prometheus**: 메트릭 수집 및 저장
- **Grafana**: 시각화 및 대시보드
- **AlertManager**: 알림 관리
- **Loki**: 로그 집계
- **Promtail**: 로그 수집 에이전트

## 사전 요구 사항

1. Kubernetes 클러스터가 실행 중이어야 합니다
2. `kubectl`이 클러스터에 연결되어 있어야 합니다
3. `helm`이 설치되어 있어야 합니다
4. NGINX Ingress Controller가 설치되어 있어야 합니다

## 설치

### 1. 모든 구성 요소 설치

```bash
chmod +x install.sh
./install.sh
```

### 2. 개별 구성 요소 설치

#### Prometheus Stack (Prometheus + Grafana + AlertManager)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitor \
  --create-namespace \
  --values prometheus-stack-values.yaml
```

#### Loki
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install loki grafana/loki-stack \
  --namespace monitor \
  --values loki-values.yaml
```

#### Promtail (별도 설치 시)
```bash
helm upgrade --install promtail grafana/promtail \
  --namespace monitor \
  --values promtail-values.yaml
```

#### Ingress 적용
```bash
kubectl apply -f ingress.yaml
```

## 접속 정보

설치 완료 후 다음 URL로 접속할 수 있습니다:

- **Grafana**: http://grafana.local
- **Prometheus**: http://prometheus.local
- **AlertManager**: http://alertmanager.local
- **Loki**: http://loki.local

### /etc/hosts 설정

로컬에서 접속하려면 `/etc/hosts` 파일에 다음을 추가하세요:

```
<CLUSTER_IP> grafana.local prometheus.local alertmanager.local loki.local
```

Minikube를 사용하는 경우:
```bash
echo "$(minikube ip) grafana.local prometheus.local alertmanager.local loki.local" | sudo tee -a /etc/hosts
```

## 로그인 정보

### Grafana
- **사용자명**: admin
- **비밀번호**: admin (기본값) 또는 다음 명령으로 확인:

```bash
kubectl get secret --namespace monitor prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## 주요 설정

### Prometheus
- **데이터 보존**: 30일
- **스토리지**: 50Gi
- **메트릭 수집**: 클러스터 전체 메트릭

### Loki
- **로그 보존**: 설정에 따라
- **스토리지**: 50Gi
- **로그 수집**: 모든 Kubernetes 파드

### Grafana
- **스토리지**: 10Gi
- **기본 대시보드**: 활성화
- **데이터소스**: Prometheus, Loki 자동 구성

## 데이터소스 설정

Grafana에서 다음 데이터소스가 자동으로 구성됩니다:

### Prometheus
- URL: `http://prometheus-stack-kube-prom-prometheus:9090`

### Loki
- URL: `http://loki:3100`

## 유용한 명령어

### 상태 확인
```bash
kubectl get pods -n monitor
kubectl get svc -n monitor
kubectl get pvc -n monitor
```

### 로그 확인
```bash
kubectl logs -n monitor deployment/prometheus-stack-grafana
kubectl logs -n monitor statefulset/loki
kubectl logs -n monitor daemonset/promtail
```

### 포트 포워딩 (Ingress 없이 접속)
```bash
# Grafana
kubectl port-forward -n monitor svc/prometheus-stack-grafana 3000:80

# Prometheus
kubectl port-forward -n monitor svc/prometheus-stack-kube-prom-prometheus 9090:9090

# Loki
kubectl port-forward -n monitor svc/loki 3100:3100
```

## 삭제

전체 스택을 삭제하려면:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## 파일 설명

- `install.sh`: 전체 모니터링 스택 설치 스크립트
- `uninstall.sh`: 전체 모니터링 스택 삭제 스크립트
- `prometheus-stack-values.yaml`: Prometheus Stack Helm 값
- `loki-values.yaml`: Loki Stack Helm 값
- `promtail-values.yaml`: Promtail Helm 값
- `ingress.yaml`: 모든 서비스에 대한 Ingress 설정
- `grafana-ingress.yaml`: 기존 Grafana Ingress (참고용)

## 트러블슈팅

### 1. 파드가 시작되지 않는 경우
```bash
kubectl describe pod -n monitor <pod-name>
```

### 2. 스토리지 문제
- PVC 상태 확인: `kubectl get pvc -n monitor`
- StorageClass 확인: `kubectl get storageclass`

### 3. Ingress 접속 불가
- Ingress Controller 상태 확인
- `/etc/hosts` 설정 확인
- DNS 해상도 확인

### 4. 메트릭/로그가 수집되지 않는 경우
- ServiceMonitor 확인: `kubectl get servicemonitor -n monitor`
- Promtail 로그 확인: `kubectl logs -n monitor daemonset/promtail`
