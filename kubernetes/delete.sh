#!/bin/bash

# Source aliases file
source ~/.bash_aliases

# Enable alias expansion
shopt -s expand_aliases

# Exit immediately if a command fails
set -e

echo "Starting deployment of n8n and PostgreSQL to Kubernetes cluster..."

# Deploy n8n
echo "Deleting n8n..."
kubectl delete -f n8n-deployment.yaml
kubectl delete -f n8n-service.yaml

# Deleting PostgreSQL first (since n8n will likely depend on it)
echo "Deleting PostgreSQL..."
kubectl delete -f postgres-deployment.yaml
kubectl delete -f postgres-service.yaml


# delete ConfigMap and Secret for PostgreSQL
echo "Deleting PostgreSQL ConfigMap and Secret..."
kubectl delete -f postgres-configmap.yaml
kubectl delete -f postgres-secret.yaml

# delete PersistentVolumeClaims
echo "Deleting PersistentVolumeClaims..."
kubectl delete -f postgres-claim0-persistentvolumeclaim.yaml
kubectl delete -f n8n-claim0-persistentvolumeclaim.yaml


# Create the namespace first
echo "Deleting namespace..."
kubectl delete -f namespace.yaml

echo "Delete completed successfully!"
