# https://github.com/n8n-io/n8n/releases
bash ./backup_k8s_postgres.sh
kubectl set image deployment/n8n n8n=n8nio/n8n:1.88.0 -n n8n
kubectl rollout status deployment/n8n -n n8n

# kubectl rollout undo deployment/n8n -n n8n