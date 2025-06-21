#!/bin/bash

# Grafana Monitoring Stack Installation Script
# This script installs Grafana, Prometheus, Loki, and Promtail using Helm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing Grafana Monitoring Stack...${NC}"

# Create namespace
echo -e "${YELLOW}Creating monitor namespace...${NC}"
kubectl create namespace monitor --dry-run=client -o yaml | kubectl apply -f -

# Add Grafana Helm repository
echo -e "${YELLOW}Adding Grafana Helm repository...${NC}"
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus Stack (includes Grafana and Prometheus)
echo -e "${YELLOW}Installing Prometheus Stack (Prometheus + Grafana + AlertManager)...${NC}"
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitor \
  --values prometheus-stack-values.yaml \
  --wait

# Install Loki
echo -e "${YELLOW}Installing Loki...${NC}"
helm upgrade --install loki grafana/loki-stack \
  --namespace monitor \
  --values loki-values.yaml \
  --wait

# Install Promtail
echo -e "${YELLOW}Installing Promtail...${NC}"
helm upgrade --install promtail grafana/promtail \
  --namespace monitor \
  --values promtail-values.yaml \
  --wait

# Apply ingress
echo -e "${YELLOW}Applying Ingress configurations...${NC}"
kubectl apply -f ingress.yaml

echo -e "${GREEN}Installation completed!${NC}"
echo -e "${YELLOW}Access URLs:${NC}"
echo "Grafana: http://grafana.local (admin/prom-operator)"
echo "Prometheus: http://prometheus.local"
echo "AlertManager: http://alertmanager.local"

echo -e "${YELLOW}To get Grafana admin password:${NC}"
echo "kubectl get secret --namespace monitor prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 --decode ; echo"
