# Example: KubernetesExecutor with git-sync in ReadWriteMany mode

__Important__

- This guide is for educational purposes only. 
The configurations are not suitable for production.
- When using git-sync, airflow will pick up and apply changes in dags even if a dag is still running. 
This can lead to unexpected behaviour.
- Only the logs are written to a ReadWriteMany volume.

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
./nfs/create_nfs_logs.sh
```

This will deploy an NFS server in namespace `airflow`. 
Change the `NAMESPACE` constant in the script to use your own namespace.

## Install using helm

Make sure to use the values in this directory, not the default values of the repository.

```bash
helm upgrade --install airflow airflow/ --namespace airflow --values examples/kube/git-sync-readwritemany/values.yaml
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

The dags are stored in an `EmptyDir` volume in the scheduler, webserver and worker pods. 
In contrast to storing dags in a volume, the dags are nog synced across the scheduler, webserver and workers.
Every pod syncs the dags from a git repository individually. 
Dag changes are pulled continuously during the lifetime of the pods for the scheduler and webserver.
On worker pods they are only synced when the pod gets spawned.
The wait time between syncs can be set using `airflow.dags.git.wait`.
Keep the wait time small enough to limit issues with dags that are out of sync across pods.

It is possible that the flow of a dag changes during its execution. 
Beware to not push dag changes while they are being executed.

An NFS server is used to allow ReadWriteMany access from all the pods to the logs volume.
The volume is created upfront and is used in the deployment through `airflow.logs.persistence.existingClaim` in the values.yaml file.
