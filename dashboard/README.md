## 1) Deploy the Dashboard UI

```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ui.yaml
kubectl apply -f dashboard-ui.yaml
```

## 2) Creating the Service Account and ClusterRoleBinding

```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-admin.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-read-only.yaml
kubectl apply -f dashboard-admin.yaml
kubectl apply -f dashboard-read-only.yaml
```

## 3) Get a Bearer Token

Now we need to find token we can use to log in. Execute following command:

**Admin Token:**

```kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d ```

**Read only User Token:**

```kubectl get secret read-only-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d```

It should print the data with line like:

```
token: <YOUR TOKEN HERE>
```

Now save it. You need to use it whe login the dashboard.


## 4) Create the ingress controller

```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ing.yaml
kubectl create -f dashboard-ing.yaml
```

## 5) Login to dashboard

Go to `https://dashboard.172.30.2.2.nip.io` and insert the previous created token into `Enter token` field.

### Use Script

```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard.sh
chmod 755 dashboard.sh
./dashboard.sh
```

