# Example: KubernetesExecutor with git-sync in ReadWriteMany mode

__Important__

- This guide is for educational purposes only. 
The configurations are not suitable for production.
- Both the logs and dags are written to a ReadWriteMany volume. 
It seems to be almost impossible to write the dags from one pod and then read them from the other pods.
Since we have the NFS volume already available anyway, it's much easier to mount the dags as ReadWriteMany as well.

## Initialize helm on Kubernetes

This guide assumes that Kubernetes is already running and that kubectl is already authenticated to the right cluster.

```bash
kubectl apply -f airflow/tiller.yaml
helm init --service-account tiller
```

## Build the docker image

Every time minikube is started, the docker image needs to be rebuilt.
The build script builds the image on the minikube VM directly,
but these images are not persistent across restarts.

```bash
./examples/kube/docker/build-docker.sh <YOUR/IMAGE/URL> <TAG>
```

This script uses the [puckel git repo](https://github.com/puckel/docker-airflow) to rebuild
the `puckel/docker-airflow` image for kubernetes. 
Now push the docker image to the repository.

```bash
docker push <YOUR/IMAGE/URL>:<TAG>
```

Replace the image url and tag in `examples/kube/git-sync-readwritemany/values.yaml`.

## Create the NFS volume

Cloud providers have no default provisioning for ReadWriteMany volumes. 
NFS (network file system) provides one of the most straightforward ways to such volumes. 
You can find all the deployment details [here](https://github.com/kubernetes/examples/tree/master/staging/volumes/nfs).
To speed things up a little bit, you can use the script in this repository to create an NFS server and volume for the logs.

```bash
./nfs/create_nfs_logs_and_dags.sh
```

This will deploy an NFS server in namespace `airflow`. 
Change the `NAMESPACE` constant in the script to use your own namespace.

## Install using helm

Make sure to use the values in this directory, not the default values of the repository.

```bash
helm upgrade --install airflow airflow/ --namespace airflow --values examples/kube/dags-volume-readwritemany/values.yaml
```

You can access the webserver using portforwarding. 
The webserver will be available at `localhost:8080`.

```bash
kubectl port-forward --namespace airflow $(kubectl get pod --namespace airflow --selector="app=airflow-web,release=airflow" --output jsonpath='{.items[0].metadata.name}') 8080:8080
```

It can take a while before you can access the webserver. 
The scheduler and webserver usually try to connect to postgres before the database is ready,
which results in connection timeouts. 
You can close the webserver and scheduler pods when the database is available to speed up the
first deployment.

## What you should see

The webserver should be up and running on `localhost:8080`.
Try to run the example_bash_operator simply by unpausing it. 
If all went well the dag should be scheduled twice now.
Make sure that all the tasks complete successfully and that the logs are available.
Once the tasks are completed, the pods should be removed from Kubernetes automatically.

# Deployment details

The dags are stored in a ReadWriteMany NFS volume that is available from the scheduler, webserver and worker pods.
This approach ensures that the dags are always in sync across the components. 
It is inherently more safe, but less flexible since the dags are only loaded when the webserver is started.
The NFS server is also used to allow ReadWriteMany access from all the pods to the logs volume.
The volumes are created upfront and are used in the deployment through `airflow.logs.persistence.existingClaim` and `airflow.dags.persistence.existingClaim` in the values.yaml file.
