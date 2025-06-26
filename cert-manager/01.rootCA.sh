brew install mkcert

mkcert -install

cp "$(mkcert -CAROOT)/rootCA.pem" rootCA.crt

cp "$(mkcert -CAROOT)/rootCA-key.pem" rootCA.key

kubectl create secret tls mkcert-root-ca \
  --cert=rootCA.crt \
  --key=rootCA.key \
  -n cert-manager

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: mkcert-issuer
  namespace: cert-manager
spec:
  ca:
    secretName: mkcert-root-ca
EOF

