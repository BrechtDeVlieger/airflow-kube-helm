#!/bin/bash

IMAGE=${1:-airflow}
TAG=${2:-b}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "$IMAGE:$TAG dir=$DIR"

ENVCONFIG=$(minikube docker-env)
if [ $? -eq 0 ]; then
  eval $ENVCONFIG
fi

rm -rf .tmp/

mkdir -p .tmp && cd .tmp
mkdir docker-airflow
mkdir docker-airflow/script
mkdir docker-airflow/config
cp $DIR/../../../script/entrypoint.sh docker-airflow/script/entrypoint.sh
cp $DIR/../../../config/airflow.cfg docker-airflow/config/airflow.cfg
cp $DIR/../../../test_dag.py docker-airflow/test_dag.py
cp $DIR/Dockerfile docker-airflow/Dockerfile
cd docker-airflow

docker build --build-arg PYTHON_DEPS="Flask-OAuthlib" --build-arg AIRFLOW_DEPS="kubernetes" --tag=${IMAGE}:${TAG} .

cd ../..
rm -rf .tmp/
