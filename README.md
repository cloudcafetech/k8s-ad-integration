# Kubernetes Dashboard Active Directory Integration

### Create K8S Cluster

https://killercoda.com/playgrounds/scenario/kubernetes

### Setup Ingress

```
wget https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/deploy.yaml
kubectl create -f deploy.yaml
```

### Generate Certificate 

```
wget https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/certgen.sh
chmod 755 certgen.sh
./certgen.sh
```
