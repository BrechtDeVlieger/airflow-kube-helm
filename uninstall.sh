#!/bin/bash

NAMESPACE=$1
: "${NAMESPACE:="default"}"

##############################################################
# Function to remove airflow from kubernetes cluster
##############################################################
uninstall_airflow() {

  # Remove port forwarding
  PORT_FORWARD_PROCESS=`ps -ef | grep "kubectl port-forward " | grep -v "grep" | awk '{ print $2 }'`
  if [ -z "$PORT_FORWARD_PROCESS" ]; then
    echo "No port-forward process running"
  else
    echo "Killing process ${PORT_FORWARD_PROCESS} to end port-forwarding"
    kill ${PORT_FORWARD_PROCESS}
  fi

  # Uninstall airflow via helm
  helm delete --purge airflow
  echo "Waiting 10 seconds for services to shut down"
  sleep 10

  # Remove pods that refuse to go away
  export AIRFLOW_TO_PURGE=`kubectl get pods | grep airflow | cut -f1 -d' '`
  for i in "${AIRFLOW_TO_PURGE[@]}"
  do
    echo "Purging: ${i}"
    kubectl delete pods $i --grace-period=0 --force
  done

  # Delete airflow service account
  kubectl --namespace=${NAMESPACE} delete clusterrolebinding airflow
  kubectl --namespace=${NAMESPACE} delete serviceaccount airflow --namespace=${NAMESPACE}

  # Delete secrets
  kubectl --namespace=${NAMESPACE} delete secret invoice-processing-env
  kubectl --namespace=${NAMESPACE} delete secret invoice-processing-google-app-cred
  kubectl --namespace=${NAMESPACE} delete secret invoice-processing-invoice-processing-ocr-creds
  kubectl --namespace=${NAMESPACE} delete secret invoice-processing-ocr-compress

  # Remove the logging service
  ./nfs/delete_nfs.sh ${NAMESPACE}

  #kubectl delete -n ${NAMESPACE} deployment nfs-server
  #kubectl --namespace ${NAMESPACE} delete service nfs-server
}


uninstall_airflow
