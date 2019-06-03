#!/bin/bash
##############################################################
# This script installs Airflow with the Kubernetes Executor
# onto a cluster via a Helm Chart
#
# OSX instructions:
# Install docker and enable kubernetes:
#
# https://docs.docker.com/docker-for-mac/install/
#
# enable kubernetes:
# - Top right go Docker -> "Preferences..." -> "Kubernetes"
#   - Check mark "enable kubernetes", "Show system containers"
#   - Select "kubernetes" instead of swarm
#
# Make sure python is install along with cryptography
#   pip3 install cryptography
#
##############################################################

NAMESPACE=$1
: "${NAMESPACE:="default"}"
BUILD_DOCKER="TRUE"

##############################################################
# Build the docker image script
##############################################################
build_docker() {
  ./examples/kube/docker/build-docker.sh dafrenchyman/docker-airflow 1.10.2
  docker push dafrenchyman/docker-airflow:1.10.2
}

##############################################################
# Check everything is up and running
# Install helm if not running
##############################################################
setup () {
  # Check docker is running
  which docker
  if [ $? -eq 0 ]
  then
      echo "Docker installed"
  else
      exit 1
  fi

  # Check node is up
  [[ $(kubectl get nodes | grep Ready) ]] || exit 1

  # Install Helm
  brew list kubernetes-helm || brew install kubernetes-helm

  # Setup namespace
  kubectl create namespace ${NAMESPACE}

  # Setup NFS Log mount
  ./nfs/create_nfs_logs.sh ${NAMESPACE}

  ##########################################
  # Install Tiller on the cluster
  ##########################################
  kubectl apply -f airflow/tiller.yaml
  helm init --service-account tiller

  echo "Waiting for tiller to come up (30 seconds)"
  sleep 30
}

##############################################################
# Function to install airflow via helm
##############################################################
install_airflow () {

  # add a service account within a namespace for airflow
  # This will allow the worker nodes to spawn pods
  kubectl --namespace ${NAMESPACE} create sa airflow
  kubectl --namespace ${NAMESPACE} create sa default

  # Create service accounts
  kubectl create clusterrolebinding ${NAMESPACE}:airflow \
    --clusterrole cluster-admin \
    --serviceaccount=${NAMESPACE}:airflow \
    --namespace=${NAMESPACE}

  kubectl create clusterrolebinding ${NAMESPACE}:default \
    --clusterrole cluster-admin \
    --serviceaccount=${NAMESPACE}:default \
    --namespace=${NAMESPACE}

  # Generate a fernet key
  FERNET_KEY=`python3 -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)"`

  helm upgrade --install airflow airflow/ \
    --namespace ${NAMESPACE} \
    --values ./install/custom_values.yaml \
    --set airflow.fernet_key="$FERNET_KEY"

  # Wait a few seconds
  sleep 5

  # Make sure all services are up (All airflow services return 1 before moving on)
  is_done="FALSE"
  while [ "$is_done" != "TRUE" ]
  do
    airflow_pods_list=`kubectl --namespace ${NAMESPACE} get pods | grep airflow | awk '{ print $3 }'`
    is_done="TRUE"
    while read -r line; do
      if [ "$line" != "Running" ]
      then
        echo "Services are not up yet (waiting 10 seconds)"
        is_done="FALSE"
        break
      fi
    done <<< "$airflow_pods_list"
    sleep 10
  done

  ##############################################################
  # Create Secrets on the cluster
  ##############################################################

  # Google credential secrets as file
  kubectl --namespace ${NAMESPACE} \
    create secret generic invoice-processing-env \
    --from-env-file=./secrets.env
  kubectl --namespace ${NAMESPACE} \
    create secret generic invoice-processing-google-app-cred \
    --from-file=./google_app_creds.json
  kubectl --namespace ${NAMESPACE} \
    create secret generic invoice-processing-invoice-processing-ocr-creds \
    --from-file=./invoice-processing-ocr-creds.json
  kubectl --namespace ${NAMESPACE} \
    create secret generic invoice-processing-ocr-compress \
    --from-file=./ocr-compress.json

  # Google credential secrets for pod ImagePullSecrets (still need to figure this out)
  DOCKER_REG="FALSE"
  if [ "DOCKER_REG" == "TRUE" ]; then
    kubectl create secret docker-registry gcr-json-key \
      --docker-server=http://gcr.io \
      --docker-username=_json_key \
      --docker-password="$(cat google_app_creds.json)" \
      --docker-email=any@validemail.com

    # Attach ImagePullSecrets to pod serviceaccount
    kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "gcr-json-key"}]}'
  fi

  ##############################################################
  # Test connecting to cluster
  ##############################################################
  APISERVER=$(kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " ")
  TOKEN=$(kubectl describe secret $(kubectl get secrets | grep ^default | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d " ")
  curl $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure

  ##############################################################
  # Enable access to the web GUI
  #   Helpful instructions:
  #   https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/
  ##############################################################

  # Get the name of the airflow pod
  ./install/port_forwarding.sh ${NAMESPACE}

  echo "Airflow is now up and running on: http://localhost:8080/"
}

build_docker
setup
install_airflow

##############################################################
# Extras
##############################################################

#
# Enable Kubernetes web GUI
# Info: https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
#
#kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
#kubectl proxy

# Example of how to enter a running container
# kubectl exec -it <POD_NAME> -- /bin/bash