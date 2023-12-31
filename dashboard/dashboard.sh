#!/bin/bash
showtoken=1
cmd="kubectl proxy"
count=`pgrep -cf "$cmd"`
#dashboard_yaml="https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"
dashboard_yaml="https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ui.yaml"
readonly_yaml="https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-read-only.yaml"
admin_yaml="https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-admin.yaml"
ing_yaml="https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ing.yaml"
msgstarted="-e Kubernetes Dashboard started"
msgstopped="Kubernetes Dashboard stopped"

case $1 in
start)
   wget -q $dashboard_yaml
   wget -q $readonly_yaml
   wget -q $admin_yaml  
   wget -q $ing_yaml     
   kubectl apply -f $dashboard_yaml >/dev/null 2>&1
   kubectl apply -f $readonly_yaml >/dev/null 2>&1
   kubectl apply -f $admin_yaml >/dev/null 2>&1
   kubectl apply -f $ing_yaml >/dev/null 2>&1   

   if [ $count = 0 ]; then
      nohup $cmd >/dev/null 2>&1 &
      echo $msgstarted
   else
      echo "Kubernetes Dashboard already running"
   fi
   ;;

stop)
   showtoken=0
   if [ $count -gt 0 ]; then
      kill -9 $(pgrep -f "$cmd")
   fi
   kubectl delete -f $dashboard_yaml >/dev/null 2>&1
   kubectl delete -f $readonly_yaml >/dev/null 2>&1
   kubectl delete -f $admin_yaml >/dev/null 2>&1
   kubectl delete -f $ing_yaml >/dev/null 2>&1      
   echo $msgstopped
   ;;

status)
   found=`kubectl get serviceaccount admin-user -n kubernetes-dashboard 2>/dev/null`
   if [[ $count = 0 ]] || [[ $found = "" ]]; then
      showtoken=0
      echo $msgstopped
   else
      found=`kubectl get clusterrolebinding admin-user -n kubernetes-dashboard 2>/dev/null`
      if [[ $found = "" ]]; then
         nopermission=" but user has no permissions."
         echo $msgstarted$nopermission
         echo 'Run "dashboard start" to fix it.'
      else
         echo $msgstarted
      fi
   fi
   ;;
esac

# Show full command line # ps -wfC "$cmd"
if [ $showtoken -gt 0 ]; then
   # Show token
   echo "Admin token:"
   kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d   
   echo

   echo "User read-only token:"
   kubectl get secret read-only-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
   echo
fi
