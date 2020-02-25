# Example: KubernetesExecutor with git-sync

__Important__

- This guide is for educational purposes only. 
The configurations are not suitable for production.
- Airflow will pick up and apply changes in dags even if a dag is still running. 
This can lead to unexpected behaviour.

## Start minikube

Make sure that you have installed minikube before continuing

```bash
minikube start
```

Confirm that minikube is started by opening the dashboard.

```bash
minikube dashboard
```

Don't forget to install tiller on the cluster. Ignore this step

```bash
kubectl apply -f airflow/tiller.yaml
helm init --service-account tiller
```

## Build the docker image

Every time minikube is started, the docker image needs to be rebuilt.
The build script builds the image on the minikube VM directly,
but these images are not persistent across restarts.

```bash
./examples/minikube/docker/build-docker.sh
```

This script uses the [puckel git repo](https://github.com/puckel/docker-airflow) to rebuild
the `puckel/docker-airflow` image for kubernetes. 
As soon as the script has finished the docker image will be available in kubernetes as `airflow:latest`.

## Install using helm

Make sure to use the values in this directory, not the default values of the repository.

```bash
helm upgrade --install airflow airflow/ --namespace airflow --values examples/minikube/git-sync/values.yaml
```

When everything is set up correctly, you should be able to access the airflow webserver.
Have a look at the node port to see on which port the webserver is exposed: don't neeed to do this!

```bash
echo 192.168.99.100:`kubectl describe service airflow-web --namespace=airflow | grep NodePort | sed -n 's/.*web  \([0-9]\+\)\/TCP/\1/p' `
```

It can take a while before you can access the webserver. 
The scheduler and webserver usually try to connect to postgres before the database is ready,
which results in connection timeouts. 
You can close the webserver and scheduler pods when the database is available to speed up the
first deployment.

## What you should see

The webserver should be up and running on the address mentioned above.
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
