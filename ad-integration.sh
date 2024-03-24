#!/usr/bin/env bash
# AD integration with Kubernetes
# Make sure Ingress setup with hostNetwork=true

PUBIPM=31.128.11.45
PUBIPN=21.20.11.46
LDAPIP=172.168.1.1
MASTERIP=`ip -o -4 addr list ens4 | awk '{print $4}' | cut -d/ -f1`
#CLUSTYPE=rke2

### AD Integration ###

# Certificate Generate
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/certgen.sh
sed -i -e "s|172.30.2.2|$PUBIPM|g" certgen.sh
sed -i -e "s|172.30.1.2|$PUBIPN|g" certgen.sh
chmod 755 certgen.sh
./certgen.sh

# Setup K8s Dashboard
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ui.yaml
kubectl apply -f dashboard-ui.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ing.yaml
sed -i -e "s|172.30.2.2|$PUBIPM|g" dashboard-ing.yaml
kubectl create -f dashboard-ing.yaml

# Dex Deployment
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dex-ldap-cm.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dex.yaml
sed -i -e "s|172.30.2.2|$PUBIPM|g" dex-ldap-cm.yaml
sed -i -e "s|172.30.1.2|$LDAPIP|g" dex-ldap-cm.yaml
sed -i -e "s|:30443||g" dex-ldap-cm.yaml
sed -i -e "s|172.30.2.2|$PUBIPM|g" dex.yaml
kubectl create -f dex-ldap-cm.yaml
kubectl create -f dex.yaml

# Check for Dex POD UP
echo "Waiting for Dex POD ready .."
DEXPOD=$(kubectl get pod -n auth-system | grep dex | awk '{print $1}')
kubectl wait pods/$DEXPOD --for=condition=Ready --timeout=5m -n auth-system

# Oauth Deployment
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/oauth-proxy.yaml
sed -i -e "s|:30443||g" oauth-proxy.yaml
sed -i -e "s|172.30.2.2|$PUBIPM|g" oauth-proxy.yaml
sed -i -e "s|172.30.1.2|$PUBIPN|g" oauth-proxy.yaml
kubectl create -f oauth-proxy.yaml

# Check for OAuth POD UP
echo "Waiting for OAuth POD ready .."
OAPOD=$(kubectl get pod -n auth-system | grep oauth | awk '{print $1}')
kubectl wait pods/$OAPOD --for=condition=Ready --timeout=5m -n auth-system

# Gangway Deployment
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/gangway.yaml
sed -i -e "s|10.182.0.13|$MASTERIP|g" gangway.yaml
sed -i -e "s|172.30.1.2|$PUBIPM|g" gangway.yaml
kubectl create -f gangway.yaml

# Check for Gangway POD UP
echo "Waiting for Gangway POD ready .."
GWPOD=$(kubectl get pod -n auth-system | grep gangway | awk '{print $1}')
kubectl wait pods/$GWPOD --for=condition=Ready --timeout=5m -n auth-system

# Download LDAP new user ldif file
#wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/new-add-user.ldif

# Create the role binding for different users
#kubectl create rolebinding titli-view-default --clusterrole=view --user=titlikar@cloudcafe.org -n default
#kubectl create rolebinding rajat-admin-default --clusterrole=admin --user=rajatkar@cloudcafe.org -n default
kubectl create clusterrolebinding debrupkar-view --clusterrole=view --user=debrupkar@cloudcafe.org 
kubectl create clusterrolebinding prasenkar-admin --clusterrole=admin --user=prasenkar@cloudcafe.org

# Status
kubectl get po -n ingress-nginx 
kubectl get po -n kubernetes-dashboard
kubectl get po -n auth-system

if [[ "$CLUSTYPE" == "rke2" ]]; then
  # Copy Certificate & edit the Kubernetes API configuration for RKE2
  cp ssl/ca.crt /var/lib/rancher/rke2/server/tls/dex-ca.crt
  wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/add-line-rke2.txt
  sed -i -e "s|172.30.1.2|$PUBIPM|g" add-line-rke2.txt
  sed -i '/rke2-metrics-server/r add-line-rke2.txt' /etc/rancher/rke2/config.yaml
  systemctl restart rke2-server.service  
  sleep 45
else
  # Copy Certificate & edit the Kubernetes API configuration for Kubeadm
  cp ssl/ca.crt /etc/kubernetes/pki/dex-ca.crt
  wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/add-line.txt
  sed -i -e "s|172.30.1.2|$PUBIPM|g" add-line.txt
  sed -i '/--allow-privileged=true/r add-line.txt' /etc/kubernetes/manifests/kube-apiserver.yaml  
  sleep 45
fi

# Check for API server POD UP & Running without error
echo "Waiting for API server POD UP & Running without Error .."
APIPOD=$(kubectl get pod -n kube-system | grep kube-apiserver | awk '{print $1}')
kubectl wait pods/$APIPOD --for=condition=Ready --timeout=5m -n kube-system
kubectl logs $APIPOD -n kube-system

# Monitoring login (LDAP) enablement
echo "Make sure monitoring is installed .."
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/ldap.toml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/grafana-ldap.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/kubemon-ingress.yaml
sed -i -e "s|172.30.1.2|$PUBIPM|g" kubemon-ingress.yaml
sed -i -e "s|172.30.1.2|$LDAPIP|g" ldap.toml
kubectl delete ing prom alert -n monitoring
kubectl create -f kubemon-ingress.yaml
kubectl delete deployment.apps/grafana -n monitoring
kubectl delete cm grafana-ini -n monitoring
kubectl create secret generic grafana-ldap-toml --from-file=ldap.toml=./ldap.toml -n monitoring
kubectl create -f grafana-ldap.yaml -n monitoring

# Check for Grafana POD UP & Running
echo "Waiting for  Grafana POD UP & Running without Error .."
GFPOD=$(kubectl get pod -n monitoring | grep grafana | awk '{print $1}')
kubectl wait pods/$GFPOD --for=condition=Ready --timeout=2m -n monitoring

# Minio integration
kubectl create ns minio-store
kubectl create cm dex-cert --from-file=ssl/ca.crt -n minio-store
kubectl create secret tls minio --cert=ssl/tls.crt --key=ssl/tls.key -n minio-store
kubectl create -f minio.yaml
sleep 15
kubectl wait pods/minio-0 --for=condition=Ready --timeout=2m -n minio-store
mc config host add k8sminio http://minio-api."$MASTERIP".nip.io minioadmin admin@2675 --insecure
mc mb k8sminio/lokik8sminio --insecure

kubectl get ing -A

# New users insert script in LDAP
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/new-user-ldap.sh
sed -i -e "s|172.168.1.1|$LDAPIP|g" new-user-ldap.sh
chmod 755 new-user-ldap.sh
#./new-user-ldap.sh

#echo "Follow URL - https://github.com/cloudcafetech/k8s-ad-integration/tree/main#modify-api-server-manifest-in-all-master-nodes"
