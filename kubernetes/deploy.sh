# Exit immediately if a command fails
set -e

echo "Starting deployment of n8n and PostgreSQL to Kubernetes cluster..."

# Create the namespace first
echo "Creating namespace..."
kubectl apply -f namespace.yaml

# Apply ConfigMap and Secret for PostgreSQL
echo "Applying PostgreSQL ConfigMap and Secret..."
kubectl apply -f postgres-configmap.yaml
kubectl apply -f postgres-secret.yaml

# Apply PersistentVolumeClaims
echo "Creating PersistentVolumeClaims..."
kubectl apply -f postgres-claim0-persistentvolumeclaim.yaml
kubectl apply -f n8n-claim0-persistentvolumeclaim.yaml

# Deploy PostgreSQL first (since n8n will likely depend on it)
echo "Deploying PostgreSQL..."
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Wait for PostgreSQL to be ready before deploying n8n
echo "Waiting for PostgreSQL deployment to be ready..."
# Extract namespace from the namespace.yaml file
NAMESPACE=$(grep -o 'name: [a-zA-Z0-9-]*' namespace.yaml | awk '{print $2}')
kubectl wait --namespace=${NAMESPACE} \
  --for=condition=available deployment/postgres \
  --timeout=120s

# Deploy n8n
echo "Deploying n8n..."
kubectl apply -f n8n-deployment.yaml
kubectl apply -f n8n-service.yaml

echo "Deployment completed successfully!"
echo "To check status of the pods, run: kubectl get pods -n ${NAMESPACE}"
