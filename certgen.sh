#!/bin/bash

mkdir -p ssl

cat << EOF > ssl/req.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = auth.172.30.1.2.nip.io
DNS.2 = auth.172.30.2.2.nip.io
DNS.3 = dashboard.172.30.1.2.nip.io
DNS.4 = dashboard.172.30.2.2.nip.io
DNS.5 = oauth-proxy.172.30.1.2.nip.io
DNS.6 = oauth-proxy.172.30.2.2.nip.io
DNS.7 = k8s-dashboard.172.30.1.2.nip.io
DNS.8 = k8s-dashboard.172.30.2.2.nip.io
IP.1 = 172.30.1.2
IP.2 = 172.30.2.2
EOF

openssl genrsa -out ssl/ca.key 4096
openssl req -x509 -new -nodes -key ssl/ca.key -days 3650 -out ssl/ca.crt -subj "/CN=kube-ca"

openssl genrsa -out ssl/tls.key 4096
openssl req -new -key ssl/tls.key -out ssl/tls.csr -subj "/CN=kube-ca" -config ssl/req.cnf
openssl x509 -req -in ssl/tls.csr -CA ssl/ca.crt -CAkey ssl/ca.key -CAcreateserial -out ssl/tls.crt -days 3650 -extensions v3_req -extfile ssl/req.cnf

# Namespace for Dex
kubectl create ns auth-system 
kubectl create ns kubernetes-dashboard
# Secret for Dex
kubectl create secret tls dex --cert=ssl/tls.crt --key=ssl/tls.key -n auth-system
# Secret for Kubernetes Dashboard external TLS Ingress
kubectl create secret tls k8s-dashboard-external-tls --cert=ssl/tls.crt --key=ssl/tls.key -n auth-system
# Secret for Kubernetes Dashboard TLS Ingress
kubectl create secret tls k8s-dashboard-tls --cert=ssl/tls.crt --key=ssl/tls.key -n kubernetes-dashboard
