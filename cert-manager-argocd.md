# Install cert manager
```
wget -q https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
kubectl create -f cert-manager.yaml
```

# Verify cert manager installation
```kubectl get pods -n cert-manager```

# Generating & deploy certificates issuer for selfsigned
```
cat << EOF > certificate-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
EOF
kubectl create -f certificate-issuer.yaml
```

# Check if cluster issuer is ready for signing
```kubectl get clusterissuers -o wide selfsigned-cluster-issuer```

# Setup ArgoCD
```
wget -q https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -O argocd-install.yaml
kubectl create ns argocd
kubectl create -f argocd-install.yaml -n argocd
```

# Argo Ingress
```
cat << EOF > argo-ing.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    cert-manager.io/cluster-issuer: selfsigned-cluster-issuer
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
    host: argocd.34.16.128.26.nip.io
  tls:
  - secretName: https-cert
    hosts:
    - argocd.34.16.128.26.nip.io
EOF
kubectl create -f argocd-ing.yaml
```

# Argo Password
```kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d```

- Minio
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: minio
spec:
  project: default
  destination:
    namespace: minio-store
    server: 'https://kubernetes.default.svc'
  source:
    path: .
    repoURL: 'https://github.com/cloudcafetech/rke2-airgap'
    targetRevision: HEAD
    directory:
      include: minio.yaml
  syncPolicy:
    automated: {}
    syncOptions:
      - CreateNamespace=true
```

- Monitoring
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring
spec:
  project: default
  destination:
    namespace: monitoring
    server: 'https://kubernetes.default.svc'
  source:
    path: monitoring
    repoURL: 'https://github.com/cloudcafetech/kubesetup'
    targetRevision: HEAD
    directory:
      include: kubemon.yaml
  syncPolicy:
    automated: {}
    syncOptions:
      - CreateNamespace=true
```

### Argo CLI

```
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
argopass=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
context=$(kubectl config get-contexts | grep -v NAME | awk '{print $2}')
argocd login localhost:8080 --username admin --password $argopass
argocd cluster add $context

argopass=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
context=$(kubectl config get-contexts | grep -v NAME | awk '{print $2}')
argocd login 172.30.1.2:32629 --username admin --password $argopass
argocd context 
argocd context --delete localhost:8080
```
