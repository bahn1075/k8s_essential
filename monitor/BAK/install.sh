
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitor

helm install prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitor
