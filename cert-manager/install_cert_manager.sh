helm repo add jetstack https://charts.jetstack.io --force-update

# cert-manager 설치 (ingress 포함)
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.18.1 \
  --set crds.enabled=true
