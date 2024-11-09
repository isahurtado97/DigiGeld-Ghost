# Parameters
param (
    [string]$ResourceGroup = "myResourceGroup",
    [string]$ClusterName = "myAKSCluster",
    [string]$Namespace = "monitoring"
)

# Enable Azure Monitor
Write-Host "Enabling Azure Monitor for AKS..."
az aks enable-addons --addons monitoring --resource-group $ResourceGroup --name $ClusterName

# Create namespace for monitoring
Write-Host "Creating namespace: $Namespace"
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repo for Prometheus and Grafana
Write-Host "Adding Prometheus and Grafana Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
Write-Host "Installing Prometheus..."
helm install prometheus prometheus-community/kube-prometheus-stack --namespace $Namespace

# Verify Prometheus
Write-Host "Prometheus installation status:"
kubectl get pods -n $Namespace | Select-String "prometheus"

Write-Host "Prometheus installed successfully."

# Install Grafana (optional if not part of the above stack)
Write-Host "Installing Grafana..."
helm install grafana prometheus-community/grafana --namespace $Namespace

# Verify Grafana
Write-Host "Grafana installation status:"
kubectl get pods -n $Namespace | Select-String "grafana"

Write-Host "Grafana installed successfully."

Write-Host "Observability tools are deployed successfully. Use the AKS dashboard or Prometheus/Grafana for monitoring."
