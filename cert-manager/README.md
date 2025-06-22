# cert-manager with nginx-ingress

이 디렉토리는 Kubernetes에서 jetstack/cert-manager를 helm으로 설치하고 nginx-ingress와 연동하는 설정을 포함합니다.

## 🚀 설치 순서

### 1. cert-manager 설치
```bash
cd /app/k8s_essential/cert-manager
chmod +x install.sh
./install.sh
```

### 2. ClusterIssuer 설정
```bash
# cluster-issuer-letsencrypt.yaml 파일에서 이메일 주소를 실제 이메일로 변경
kubectl apply -f cluster-issuer-letsencrypt.yaml
```

### 3. 설치 확인
```bash
# cert-manager pods 상태 확인
kubectl get pods -n cert-manager

# ClusterIssuer 상태 확인
kubectl get clusterissuer

# cert-manager 로그 확인
kubectl logs -n cert-manager deployment/cert-manager
```

## 📁 파일 설명

- **install.sh**: cert-manager helm 설치 스크립트
- **uninstall.sh**: cert-manager 제거 스크립트
- **values.yaml**: cert-manager helm chart values
- **cluster-issuer-letsencrypt.yaml**: Let's Encrypt ClusterIssuer 설정
- **test-ingress-with-tls.yaml**: TLS 인증서 자동 발급 테스트용 Ingress

## 🔧 nginx-ingress와 연동 방법

### Ingress에 TLS 인증서 자동 발급 설정

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    # nginx-ingress 클래스 지정
    kubernetes.io/ingress.class: nginx
    
    # cert-manager 자동 인증서 발급
    cert-manager.io/cluster-issuer: letsencrypt-prod
    
    # SSL 리다이렉트 설정
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - your-domain.com
    secretName: your-app-tls  # cert-manager가 자동 생성
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: your-service
            port:
              number: 80
```

## 🧪 테스트

### 1. 테스트 앱 배포
```bash
# 도메인을 실제 도메인으로 변경 후 배포
kubectl apply -f test-ingress-with-tls.yaml
```

### 2. 인증서 발급 상태 확인
```bash
# Certificate 리소스 확인
kubectl get certificate

# CertificateRequest 확인
kubectl get certificaterequest

# 인증서 발급 과정 로그 확인
kubectl describe certificate test-app-tls
```

### 3. 인증서 자동 갱신 확인
cert-manager는 인증서 만료 30일 전에 자동으로 갱신합니다.

## ⚠️  주의사항

1. **이메일 변경**: `cluster-issuer-letsencrypt.yaml`에서 이메일 주소를 실제 이메일로 변경하세요.

2. **도메인 설정**: 테스트용 Ingress에서 도메인을 실제 도메인으로 변경하세요.

3. **스테이징 환경**: 처음 테스트할 때는 `letsencrypt-staging`을 사용하여 Rate Limit을 피하세요.

4. **nginx-ingress 필요**: 이 설정은 nginx-ingress가 설치되어 있어야 동작합니다.

## 🔍 트러블슈팅

### 인증서가 발급되지 않는 경우
```bash
# cert-manager 로그 확인
kubectl logs -n cert-manager deployment/cert-manager

# ACME 챌린지 확인
kubectl get challenges

# Order 상태 확인
kubectl get orders
```

### 일반적인 문제
- 도메인이 클러스터로 올바르게 라우팅되지 않음
- nginx-ingress가 설치되지 않음
- 방화벽에서 80/443 포트가 차단됨
- DNS 설정 오류

## 📚 참고 문서

- [cert-manager 공식 문서](https://cert-manager.io/docs/)
- [nginx-ingress와 cert-manager 연동](https://cert-manager.io/docs/tutorials/acme/nginx-ingress/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
