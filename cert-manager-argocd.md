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

# guestbook.yaml
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
spec:
  project: default
  destination:
    namespace: guestbook
    server: 'https://kubernetes.default.svc'
  source:
    path: kustomize-guestbook
    repoURL: 'https://github.com/argoproj/argocd-example-apps'
    targetRevision: HEAD
  syncPolicy:
    automated: {}
    syncOptions:
      - CreateNamespace=true
```
