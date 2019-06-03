#!/bin/bash

NAMESPACE=$1
: "${NAMESPACE:="default"}"

set -x

killall kubectl
sleep 1
rm nohup.out

AIRFLOW_POD=`kubectl get pod --namespace ${NAMESPACE} --selector="app=airflow-web,release=airflow" --output jsonpath='{.items[0].metadata.name}'`
AIRFLOW_PORT=8080

nohup kubectl port-forward --namespace ${NAMESPACE} ${AIRFLOW_POD} ${AIRFLOW_PORT}:${AIRFLOW_PORT} &

