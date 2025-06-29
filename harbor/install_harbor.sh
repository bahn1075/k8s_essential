helm upgrade --install harbor harbor/harbor \
  --namespace harbor \
  --reuse-values \
  --set expose.type=ingress \
  --set expose.tls.enabled=true \
  --set expose.tls.certSource=secret \
  --set expose.tls.secretName=harbor-cert \
  --set expose.tls.notarySecretName=harbor-cert \
  --set expose.ingress.hosts.core=harbor.local \
  --set externalURL=https://harbor.local

echo "[INFO] Harbor Portal 초기 접속 정보:"
echo "  URL: https://harbor.local"
echo "  ID: admin"
echo "  PW: Harbor12345"