# Grafana Cloud 설정 가이드

## Grafana Cloud 계정 설정

1. **Grafana Cloud 계정 생성**
   - https://grafana.com/products/cloud/ 에서 무료 계정 생성
   - 14일 Pro 트라이얼 또는 무료 티어 선택

2. **API 키 생성**
   - My Account > Security > API Keys
   - 각 서비스별로 API 키 생성 (Metrics Publisher, Logs Publisher, Traces Publisher)

3. **엔드포인트 정보 확인**
   - Stack > Details에서 각 서비스의 URL과 username 확인

## 설정 방법

1. **secrets 파일 생성**
   ```bash
   cp secrets-template.yaml secrets.yaml
   # secrets.yaml 파일을 편집하여 실제 인증 정보 입력
   ```

2. **secrets 적용**
   ```bash
   kubectl apply -f secrets.yaml
   ```

3. **values.yaml 수정**
   - destinations의 URL들을 실제 Grafana Cloud URL로 변경
   - username과 password를 secrets에서 참조하도록 변경

4. **설치 실행**
   ```bash
   cd /app/k8s_essential/monitoring
   ./install.sh grafana-cloud
   ```

## values.yaml에서 secrets 참조하는 방법

```yaml
destinations:
  - name: "grafana-cloud-prometheus"
    type: "prometheus"
    url: "https://your-prometheus-url/api/prom/push"
    auth:
      type: "basic"
      username: 
        valueFrom:
          secretKeyRef:
            name: grafana-cloud-credentials
            key: prometheus-username
      password:
        valueFrom:
          secretKeyRef:
            name: grafana-cloud-credentials
            key: prometheus-password
```

## 확인 방법

1. **데이터 전송 확인**
   ```bash
   # Alloy 로그 확인
   kubectl logs -n monitoring -l app.kubernetes.io/name=alloy
   ```

2. **Grafana Cloud에서 확인**
   - Grafana Cloud 대시보드에서 메트릭과 로그가 수신되는지 확인
   - Explore 메뉴에서 데이터 조회 테스트

## 주의사항

- API 키는 민감한 정보이므로 Git에 커밋하지 마세요
- secrets.yaml 파일은 .gitignore에 추가하세요
- 정기적으로 API 키를 로테이션하세요
- 무료 티어의 제한사항을 확인하세요 (메트릭 시리즈, 로그 볼륨 등)
