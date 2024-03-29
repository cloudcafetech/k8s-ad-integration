# Kubernetes Dashboard Active Directory Integration

## Setup LDAP Server

#### By Script
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/run-ldap.sh
chmod 755 run-ldap.sh
./run-ldap.sh
```

**OR**

#### Run LDAP Server
```
apt install ldap-utils -y
HIP=`ip -o -4 addr list enp1s0 | awk '{print $4}' | cut -d/ -f1`

docker run --restart=always --name ldap-server -p 389:389 -p 636:636 \
--env LDAP_TLS_VERIFY_CLIENT=try \
--env LDAP_ORGANISATION="Cloudcafe Org" \
--env LDAP_DOMAIN="cloudcafe.org" \
--env LDAP_ADMIN_PASSWORD="StrongAdminPassw0rd" \
--detach osixia/openldap:latest
```

#### Check LDAP Server UP & Running

```
until [ $(docker inspect -f {{.State.Running}} ldap-server)"=="true ]; do echo "Waiting for LDAP to UP..." && sleep 1; done;
```

#### Add LDAP User & Group 
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/ldap-records.ldif
ldapadd -x -H ldap://$HIP -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -f ldap-records.ldif
```

#### LDAP query 

- Verify (All records)
```
ldapsearch -x -H ldap://$HIP -D "cn=admin,dc=cloudcafe,dc=org" -b "dc=cloudcafe,dc=org" -w "StrongAdminPassw0rd"
```

- User search
```
ldapsearch -x -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -b "cn=debrup,ou=people,dc=cloudcafe,dc=org" -H ldap://$HIP
ldapsearch -x -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -b "cn=prasen,ou=people,dc=cloudcafe,dc=org" -H ldap://$HIP
```

- Group search
```
ldapsearch -x -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -b "cn=developers,ou=groups,dc=cloudcafe,dc=org" -H ldap://$HIP
ldapsearch -x -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -b "cn=admins,ou=groups,dc=cloudcafe,dc=org" -H ldap://$HIP
```

## Create K8S Cluster

https://killercoda.com/playgrounds/scenario/kubernetes

**OR**

- KUBEADM
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/k8s-setup.sh
chmod 755 k8s-setup.sh
./k8s-setup.sh
```
- RKE2
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/k8s-setup-rke2.sh
chmod 755 k8s-setup-rke2.sh
```

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

echo "Waiting for Dex POD ready .."
DEXPOD=$(kubectl get pod -n auth-system | grep dex | awk '{print $1}')
kubectl wait pods/$DEXPOD --for=condition=Ready --timeout=5m -n auth-system
```

#### You can check if Dex is deployed properly by browsing 
```
curl https://auth.172.30.2.2.nip.io:30443/.well-known/openid-configuration  --cacert ssl/ca.crt
curl https://auth.172.30.2.2.nip.io:30443/auth --cacert ssl/ca.crt
```

### Modify API Server manifest (IN ALL MASTER NODES)
Copy Certificate & edit the Kubernetes API configuration. Add the OIDC parameters and modify the issuer URL accordingly.

**NOTE: After edit kube-apiserver.yaml, the API Server POD automatically restart**  

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

### Check if APIServer POD Up & Running without Error

```
kubectl wait pods/kube-apiserver-controlplane --for=condition=Ready --timeout=2m -n kube-system
kubectl logs pods/kube-apiserver-controlplane -n kube-system
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
kubectl create rolebinding titli-view-default --clusterrole=view --user=titlikar@cloudcafe.org -n default
kubectl create rolebinding rajat-admin-default --clusterrole=admin --user=rajatkar@cloudcafe.org -n default
kubectl create clusterrolebinding debrupkar-view --clusterrole=view --user=debrupkar@cloudcafe.org 
kubectl create clusterrolebinding prasenkar-admin --clusterrole=admin --user=prasenkar@cloudcafe.org
```

### Testing

Using Dashboard UI install below yaml with different User Login
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

** OR ** 

```
touch .kube/config-debrup 
export KUBECONFIG=$HOME/.kube/config-debrup
```

In browser run ```https://kubectl.172.30.2.2.nip.io``` first authenticate then copy certificate and kubectl command then execute. 

```
more $HOME/.kube/config-debrup

kubectl auth can-i get pods

kubectl auth can-i get pods -n default --as=debrupkar@cloudcafe.org   
  
kubectl auth can-i get deployments -n default --as=debrupkar@cloudcafe.org

kubectl auth can-i get deployments --as=prasenkar@cloudcafe.org

kubectl auth can-i create deployments -n default --as=debrupkar@cloudcafe.org

kubectl auth can-i create deployments --as=prasenkar@cloudcafe.org
```

[Ref#1](https://discuss.kubernetes.io/t/configure-oidc-with-dex-for-a-microk8s-cluster/18339)
[Ref#2](https://computingforgeeks.com/kubernetes-and-active-directory-integration/)
