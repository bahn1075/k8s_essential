#!/bin/bash

# WSL2에서 실행: Minikube Ingress(192.168.49.2:80,443)를 Windows(127.0.0.1:80,443)로 포트포워딩
# 관리자 권한 필요 없음

# socat 설치 안내 (필요시)
if ! command -v socat &> /dev/null; then
  echo "[INFO] socat이 설치되어 있지 않습니다. RHEL/CentOS/Fedora 계열은 sudo yum install socat -y 또는 sudo dnf install socat -y 로 설치하세요."
  exit 1
fi

# 80 포트 포워딩
nohup socat TCP-LISTEN:80,fork TCP:192.168.49.2:80 &
# 443 포트 포워딩
nohup socat TCP-LISTEN:443,fork TCP:192.168.49.2:443 &

echo "포트포워딩이 시작되었습니다. Windows 브라우저에서 https://gitlab.gitlab.local 로 접속하세요."
