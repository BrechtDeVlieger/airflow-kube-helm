#!/usr/bin/env bash

set -e

NAMESPACE=airflow
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

${DIR}/create_nfs_logs.sh

function server_ip()
{
    echo "$(kubectl describe service nfs-server --namespace ${NAMESPACE} | grep IP: | tr -s ' ' | cut -d ' ' -f2)"
}

NFS_SERVER_IP=$(server_ip)

sed -e "s/NFS_SERVER_POD_IP_ADDRESS/${NFS_SERVER_IP}/" ${DIR}/volumes_dags.yaml > ${DIR}/volumes_dags_complete.yaml
kubectl apply -f ${DIR}/volumes_dags_complete.yaml --namespace=${NAMESPACE}
