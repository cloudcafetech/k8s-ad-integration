# Auth setup RKE2

### Download and deploy

```
mkdir auth
cd auth

wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/refs/heads/main/dex-ldap-cm.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/refs/heads/main/dex.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/refs/heads/main/gangway.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/refs/heads/main/k8s-ocp-web-console.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/refs/heads/main/new-add-user.ldif

ORGS=cloudcafe
ED=tech
DOMAIN=172.27.2.220.nip.io
sed -i "s/apps.k8s.cloudcafe.tech/$DOMAIN/g" *.yaml

sed -i "s/ghcr.io/registry.$DOMAIN/g" *.yaml
sed -i "s/gcr.io/registry.$DOMAIN/g" *.yaml
sed -i "s/docker.io/registry.$DOMAIN/g" *.yaml
sed -i "s/quay.io/registry.$DOMAIN/g" *.yaml

sed -i "s/cloudcafe.org/$ORGS.$ED/g" openldap-k8s.yaml
sed -i "s/cloudcafe/$ORGS/g" openldap-k8s.yaml
sed -i "s/cloudcafe/$ORGS/g" new-add-user.ldif
sed -i "s/dc=org/dc=$ED/g" new-add-user.ldif

kubectl create ns auth-system
kubectl create -f *.yaml -n auth-system
```

### Load used in LDAP

```
ldapadd -x -H ldap://<worker node ip>:30389 -D "cn=admin,dc=$ORGS,dc=$ED" -w StrongAdminPassw0rd -f ldap-records.ldif
ldapsearch -x -H ldap://<worker node ip>:30389 -D "cn=admin,dc=$ORGS,dc=$ED" -b "dc=$ORGS,dc=$ED" -w "StrongAdminPassw0rd"
```

### Run from each Master Node

- Get certificate from secret

```
kubectl get secret dex -n auth-system -o json -o=jsonpath="{.data.tls\.crt}" | base64 -d > dex-ca.crt
cp dex-ca.crt /var/lib/rancher/rke2/server/tls/dex-ca.crt
```

- Add below txt in RKE2 config file

```
kube-apiserver-arg:
  - --oidc-issuer-url=https://auth.DOMAIN/
  - --oidc-client-id=oidc-auth-client
  - --oidc-ca-file=/var/lib/rancher/rke2/server/tls/dex-ca.crt
  - --oidc-username-claim=email
  - --oidc-groups-claim=groups
```

- Restart service

```systemctl restart rke2-server```
