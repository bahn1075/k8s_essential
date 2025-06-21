#!/bin/bash

# Grafana Monitoring Stack Complete Uninstall Script
# This script completely removes all monitoring components from the cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}=== Complete Monitoring Stack Uninstall ===${NC}"

# Function to check if resource exists
check_resource() {
    local resource=$1
    local namespace=${2:-""}
    if [ -n "$namespace" ]; then
        kubectl get $resource -n $namespace >/dev/null 2>&1
    else
        kubectl get $resource >/dev/null 2>&1
    fi
}

# 1. Remove Helm releases
echo -e "${YELLOW}Step 1: Removing Helm releases...${NC}"
helm list -n monitor -o table 2>/dev/null | tail -n +2 | while read -r release namespace revision updated status chart app_version; do
    if [ -n "$release" ] && [ "$release" != "" ]; then
        echo -e "${BLUE}  Uninstalling Helm release: $release${NC}"
        helm uninstall "$release" --namespace monitor --ignore-not-found
    fi
done || echo -e "${BLUE}  No releases found in monitor namespace${NC}"

# Check for any remaining releases across all namespaces
echo -e "${BLUE}  Checking for monitoring releases in all namespaces...${NC}"
helm list -A | grep -E "(prometheus|grafana|loki|promtail|alertmanager)" | while read -r line; do
    release=$(echo $line | awk '{print $1}')
    namespace=$(echo $line | awk '{print $2}')
    echo -e "${BLUE}  Uninstalling $release from namespace $namespace${NC}"
    helm uninstall "$release" --namespace "$namespace" --ignore-not-found
done || true

# 2. Remove ingress configurations
echo -e "${YELLOW}Step 2: Removing ingress configurations...${NC}"
if [ -f "ingress.yaml" ]; then
    kubectl delete -f ingress.yaml --ignore-not-found=true
fi

# 3. Delete all monitoring-related resources
echo -e "${YELLOW}Step 3: Cleaning up monitoring resources...${NC}"

# Delete PVCs
echo -e "${BLUE}  Deleting PVCs...${NC}"
kubectl get pvc -A | grep -E "(prometheus|grafana|loki|alertmanager)" | while read -r namespace name status volume capacity access_modes storageclass age; do
    if [ "$namespace" != "NAMESPACE" ]; then
        echo -e "${BLUE}    Deleting PVC $name in namespace $namespace${NC}"
        kubectl delete pvc "$name" -n "$namespace" --ignore-not-found=true
    fi
done || true

# Delete ConfigMaps
echo -e "${BLUE}  Deleting ConfigMaps...${NC}"
kubectl get configmap -A | grep -E "(prometheus|grafana|loki|alertmanager)" | while read -r namespace name data age; do
    if [ "$namespace" != "NAMESPACE" ]; then
        echo -e "${BLUE}    Deleting ConfigMap $name in namespace $namespace${NC}"
        kubectl delete configmap "$name" -n "$namespace" --ignore-not-found=true
    fi
done || true

# Delete Secrets
echo -e "${BLUE}  Deleting Secrets...${NC}"
kubectl get secret -A | grep -E "(prometheus|grafana|loki|alertmanager)" | while read -r namespace name type data age; do
    if [ "$namespace" != "NAMESPACE" ]; then
        echo -e "${BLUE}    Deleting Secret $name in namespace $namespace${NC}"
        kubectl delete secret "$name" -n "$namespace" --ignore-not-found=true
    fi
done || true

# Delete Ingress
echo -e "${BLUE}  Deleting Ingress resources...${NC}"
kubectl get ingress -A | grep -E "(prometheus|grafana|loki|alertmanager)" | while read -r namespace name class hosts address ports age; do
    if [ "$namespace" != "NAMESPACE" ]; then
        echo -e "${BLUE}    Deleting Ingress $name in namespace $namespace${NC}"
        kubectl delete ingress "$name" -n "$namespace" --ignore-not-found=true
    fi
done || true

# 4. Delete Prometheus Operator CRDs
echo -e "${YELLOW}Step 4: Removing Prometheus Operator CRDs...${NC}"
CRD_LIST="alertmanagerconfigs.monitoring.coreos.com alertmanagers.monitoring.coreos.com podmonitors.monitoring.coreos.com probes.monitoring.coreos.com prometheusagents.monitoring.coreos.com prometheuses.monitoring.coreos.com prometheusrules.monitoring.coreos.com scrapeconfigs.monitoring.coreos.com servicemonitors.monitoring.coreos.com thanosrulers.monitoring.coreos.com"
for crd in $CRD_LIST; do
    if kubectl get crd "$crd" >/dev/null 2>&1; then
        echo -e "${BLUE}  Deleting CRD: $crd${NC}"
        kubectl delete crd "$crd" --ignore-not-found=true
    fi
done

# Also check for any other monitoring-related CRDs dynamically
echo -e "${BLUE}  Checking for additional monitoring CRDs...${NC}"
kubectl get crd 2>/dev/null | grep -E "(monitoring|prometheus|grafana|loki|alertmanager)" | awk '{print $1}' | while read -r crd; do
    if [ -n "$crd" ]; then
        echo -e "${BLUE}  Deleting additional CRD: $crd${NC}"
        kubectl delete crd "$crd" --ignore-not-found=true
    fi
done || true

# 5. Clean up kube-system services
echo -e "${YELLOW}Step 5: Cleaning up kube-system services...${NC}"
kubectl get service -n kube-system | grep -E "(prometheus|grafana|loki|alertmanager|kubelet)" | grep "prometheus-stack" | while read -r name type cluster_ip external_ip ports age; do
    if [ "$name" != "NAME" ]; then
        echo -e "${BLUE}  Deleting service $name in kube-system${NC}"
        kubectl delete service "$name" -n kube-system --ignore-not-found=true
    fi
done || true

# 6. Delete monitor namespace
echo -e "${YELLOW}Step 6: Deleting monitor namespace...${NC}"
if kubectl get namespace monitor >/dev/null 2>&1; then
    kubectl delete namespace monitor --ignore-not-found=true
    echo -e "${BLUE}  Monitor namespace deleted${NC}"
else
    echo -e "${BLUE}  Monitor namespace not found${NC}"
fi

# 7. Final verification
echo -e "${YELLOW}Step 7: Final verification...${NC}"
echo -e "${BLUE}  Checking for remaining monitoring resources...${NC}"

# Check for any remaining resources
REMAINING_RESOURCES=$(kubectl get all,pvc,configmap,secret,ingress -A 2>/dev/null | grep -E "(prometheus|grafana|loki|alertmanager)" || true)
if [ -z "$REMAINING_RESOURCES" ]; then
    echo -e "${GREEN}  ✅ No monitoring resources found${NC}"
else
    echo -e "${YELLOW}  ⚠️  Some resources may still exist:${NC}"
    echo "$REMAINING_RESOURCES"
fi

# Check for remaining CRDs
REMAINING_CRDS=$(kubectl get crd 2>/dev/null | grep -E "(monitoring|prometheus|grafana|loki|alertmanager)" || true)
if [ -z "$REMAINING_CRDS" ]; then
    echo -e "${GREEN}  ✅ No monitoring CRDs found${NC}"
else
    echo -e "${YELLOW}  ⚠️  Some CRDs may still exist:${NC}"
    echo "$REMAINING_CRDS"
fi

echo -e "${GREEN}=== Complete Uninstallation Finished! ===${NC}"
echo -e "${GREEN}All monitoring components have been removed from the cluster.${NC}"
