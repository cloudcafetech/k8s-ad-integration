#!/usr/bin/env bash
# AD integration with Kubernetes
# Make sure Ingress setup with hostNetwork=true

PUBIPM=31.128.11.45
PUBIPN=21.20.11.46
LDAPIP=172.168.1.1
MASTERIP=`ip -o -4 addr list ens4 | awk '{print $4}' | cut -d/ -f1`

### AD Integration ###

# Certificate Generate
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/certgen.sh
sed -i -e "s|172.30.2.2|$PUBIPM|g" certgen.sh
sed -i -e "s|172.30.1.2|$PUBIPN|g" certgen.sh
sed -i -e "s|oauth-proxy.172.30.1.2.nip.io|oauth-proxy.$MASTERIP.nip.io|g" certgen.sh
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
sed -i -e "s|master-ip|$MASTERIP|g" dex.yaml
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

# Create the role binding for different users
#kubectl create rolebinding mkar-view-default --clusterrole=view --user=mkar -n default
kubectl create clusterrolebinding debrupkar-view --user=debrupkar@cloudcafe.org --clusterrole=view
kubectl create clusterrolebinding prasenkar-admin --user=prasenkar@cloudcafe.org --clusterrole=admin

# Copy Certificate & edit the Kubernetes API configuration
cp ssl/ca.crt /etc/kubernetes/pki/dex-ca.crt

echo "Follow URL - https://github.com/cloudcafetech/k8s-ad-integration/tree/main#modify-api-server-manifest-in-all-master-nodes"
