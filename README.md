# Kubernetes Dashboard Active Directory Integration

## Setup LDAP Server

#### Run LDAP Server
```
apt install ldap-utils -y
HIP=`ip -o -4 addr list enp1s0 | awk '{print $4}' | cut -d/ -f1`

docker run --name ldap-server -p 389:389 -p 636:636 \
--env LDAP_TLS_VERIFY_CLIENT=try \
--env LDAP_ORGANISATION="Cloudcafe Org" \
--env LDAP_DOMAIN="cloudcafe.org" \
--env LDAP_ADMIN_PASSWORD="StrongAdminPassw0rd" \
--detach osixia/openldap:latest
```

#### Check LDAP Server UP & running

```
until [ $(docker inspect -f "{{json .State.Status }}" $(docker ps -a | grep ldap-server | awk '{print $1}')) == '"running"' ]; do echo "Waiting for LDAP to UP..." && sleep 1; done
```

#### Add LDAP User & Group 
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/ldap-records.ldif
ldapadd -x -H ldap://$HIP -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -f ldap-records.ldif
```

#### LDAP query (test)
```
ldapsearch -x -H ldap://$HIP -D "cn=admin,dc=cloudcafe,dc=org" -b "dc=cloudcafe,dc=org" -w "StrongAdminPassw0rd"
```

## Create K8S Cluster

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
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dex-ldap-cm.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dex.yaml
kubectl create -f dex-ldap-cm.yaml
kubectl create -f dex.yaml
```

#### You can check if Dex is deployed properly by browsing 
```
curl https://auth.172.30.2.2.nip.io:30443/.well-known/openid-configuration  --cacert ssl/ca.crt
curl https://auth.172.30.2.2.nip.io:30443/auth --cacert ssl/ca.crt
```

### Modify API Server manifest
Copy Certificate & edit the Kubernetes API configuration. Add the OIDC parameters and modify the issuer URL accordingly.

```
cp ssl/ca.crt /etc/kubernetes/pki/dex-ca.crt
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

**As follows**
##### (ENSURE THE WILDCARD CERTIFICATES ARE PRESENT IN THIS FILE PATH IN ALL MASTER NODES)

```
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=172.30.1.2
    - --allow-privileged=true
#ADD THE FOLLOWING LINES:
... 
    - --oidc-issuer-url=https://auth.172.30.2.2.nip.io:30443/
    - --oidc-client-id=oidc-auth-client
    - --oidc-ca-file=/etc/kubernetes/pki/dex-ca.crt
    - --oidc-username-claim=email
    - --oidc-groups-claim=groups
...
```

### Install Oauth2 Proxy [Authentication using Providers (LDAP,AD etc)]
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/oauth-proxy.yaml
kubectl create -f oauth-proxy.yaml
```

### Install Dashboard
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard.sh
chmod 755 dashboard.sh
./dashboard.sh
```

### Create the role binding for different users
```
kubectl create rolebinding pkar-admin --clusterrole=admin --user=pkar
kubectl create rolebinding mkar-view-default --clusterrole=view --user=mkar -n default
kubectl create rolebinding read-only-user-view --clusterrole=view --user=read-only-user
```

### Testing
```
kubectl auth can-i get pods             
kubectl auth can-i get deployments      
kubectl auth can-i create deployments  
```

[Ref#1](https://discuss.kubernetes.io/t/configure-oidc-with-dex-for-a-microk8s-cluster/18339)
[Ref#2](https://computingforgeeks.com/kubernetes-and-active-directory-integration/)
