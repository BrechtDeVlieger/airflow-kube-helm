#!/bin/bash

export PODS_TO_DELETE=`kubectl get pods | grep -e Completed -e Error -e ImagePullBackOff | awk '{print $1}'`
for i in "${PODS_TO_DELETE[@]}"
do
  kubectl delete pods $i
done
