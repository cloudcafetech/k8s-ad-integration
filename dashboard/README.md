## 1) Deploy the Dashboard UI

```
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl apply -f recommended.yaml
```

## 2) Creating the Service Account and ClusterRoleBinding

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

## 3) Get a Bearer Token

Now we need to find token we can use to log in. Execute following command:

For Bash:

```bash
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```

It should print the data with line like:

```
token: <YOUR TOKEN HERE>
```

Now save it. You need to use it whe login the dashboard.


## 4) Create the ingress controller

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: kubernetes-dashboard
  name: kubernetes-dashboard-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    # Uncomment next if you use https://cert-manager.io/
    # cert-manager.io/cluster-issuer: "<YOUR CLUSTER ISSUER>"
spec:
  tls:
  - hosts:
    - dashboard.172.30.2.2.nip.io
    secretName: kubernetes-dashboard-cert
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kubernetes-dashboard
            port:
               number: 443
EOF
```

## 5) Login to dashboard

Go to `https://dashboard.172.30.2.2.nip.io` and insert the previous created token into `Enter token` field.
