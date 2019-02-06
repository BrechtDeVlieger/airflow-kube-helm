#!/usr/bin/env bash

set -e

NAMESPACE=airflow
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WAIT_SECONDS=3

function server_ip()
{
    echo "$(kubectl describe service nfs-server --namespace ${NAMESPACE} | grep IP: | tr -s ' ' | cut -d ' ' -f2)"
}

NFS_SERVER_IP=$(server_ip)

while [[ -z "${NFS_SERVER_IP}" ]]; do
    echo "Waiting ${WAIT_SECONDS} seconds to check if NFS server is ready..."
    sleep ${WAIT_SECONDS}
    echo "Checking if NFS server is ready..."
    NFS_SERVER_IP=$(server_ip)
done

echo "NFS server IP: ${NFS_SERVER_IP}"

sed -e "s/NFS_SERVER_POD_IP_ADDRESS/${NFS_SERVER_IP}/" ${DIR}/volumes_logs.yaml > ${DIR}/volumes_logs_complete.yaml
sed -e "s/NFS_SERVER_POD_IP_ADDRESS/${NFS_SERVER_IP}/" ${DIR}/volumes_dags.yaml > ${DIR}/volumes_dags_complete.yaml

kubectl delete -f ${DIR}/volumes_logs_complete.yaml --namespace=${NAMESPACE}
rm ${DIR}/volumes_logs_complete.yaml

kubectl delete -f ${DIR}/volumes_dags_complete.yaml --namespace=${NAMESPACE}
rm ${DIR}/volumes_dags_complete.yaml
kubectl delete -f ${DIR}/nfs_server.yaml --namespace=${NAMESPACE}
