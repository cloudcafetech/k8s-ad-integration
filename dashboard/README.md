## 1) Deploy the Dashboard UI

```
wget https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ui.yaml
kubectl apply -f dashboard-ui.yaml
```

## 2) Creating the Service Account and ClusterRoleBinding

```
wget https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ac.yaml
kubectl apply -f dashboard-ac.yaml
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

```
wget https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ing.yaml
kubectl create -f dashboard-ing.yaml
```

## 5) Login to dashboard

Go to `https://dashboard.172.30.2.2.nip.io` and insert the previous created token into `Enter token` field.
