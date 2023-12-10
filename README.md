# Kubernetes Dashboard Active Directory Integration

### Create K8S Cluster

https://killercoda.com/playgrounds/scenario/kubernetes

### Setup Ingress
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/deploy.yaml
kubectl create -f deploy.yaml
```

### Generate Certificate 
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/certgen.sh
chmod 755 certgen.sh
./certgen.sh
```

### Install DEX [OpenID Connect (OIDC)]
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dex.yaml
kubectl create -f dex.yaml
```

### Install Oauth2 Proxy [A reverse proxy and static file server that provides authentication using Providers (Google, GitHub, and others) to validate accounts]
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/oauth-proxy.yaml
kubectl create -f oauth-proxy.yaml
```
