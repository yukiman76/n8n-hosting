# Exit immediately if a command fails
set -e

echo "Starting deployment of n8n and PostgreSQL to Kubernetes cluster..."

# Create the namespace first
echo "Creating namespace..."
kubectl delete -f namespace.yaml

# delete ConfigMap and Secret for PostgreSQL
echo "deleteing PostgreSQL ConfigMap and Secret..."
kubectl delete -f postgres-configmap.yaml
kubectl delete -f postgres-secret.yaml

# delete PersistentVolumeClaims
echo "Creating PersistentVolumeClaims..."
kubectl delete -f postgres-claim0-persistentvolumeclaim.yaml
kubectl delete -f n8n-claim0-persistentvolumeclaim.yaml

# Deploy PostgreSQL first (since n8n will likely depend on it)
echo "Deploying PostgreSQL..."
kubectl delete -f postgres-deployment.yaml
kubectl delete -f postgres-service.yaml


# Deploy n8n
echo "Deploying n8n..."
kubectl delete -f n8n-deployment.yaml
kubectl delete -f n8n-service.yaml

echo "Deployment completed successfully!"
echo "To check status of the pods, run: kubectl get pods -n ${NAMESPACE}"
