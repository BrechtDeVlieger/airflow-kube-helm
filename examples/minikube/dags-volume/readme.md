# Example: KubernetesExecutor with dags in persistent volume

__Important__

- This guide is for educational purposes only. 
The configurations are not suitable for production.
- There are many ways to add dags to the volume.
In this example we'll use the init container to pull dags from the airflow repo and copy them into the volume.
- This example uses a slightly adapted version of [docker-airflow](https://github.com/puckel/docker-airflow).
I take no credit for his great work, I only made some minor changes.

## Start minikube

Make sure that you have installed minikube before continuing

```bash
minikube start
```

Confirm that minikube is started by opening the dashboard.

```bash
minikube dashboard
```

Don't forget to install tiller on the cluster.

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

This script starts from the [puckel git repo](https://github.com/puckel/docker-airflow) to rebuild
the `puckel/docker-airflow` image for kubernetes. 
As soon as the script has finished the docker image will be available in kubernetes as `airflow:latest`.

## Install using helm

Make sure to use the values in this directory, not the default values of the repository.

```bash
helm upgrade --install airflow airflow/ --namespace airflow --values examples/minikube/dags-volume/values.yaml
```

When everything is set up correctly, you should be able to access the airflow webserver.
Have a look at the node port to see on which port the webserver is exposed:

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

## Deployment details

Airflow uses a Kubernetes volume to store the dags on if you set `airflow.dags.persistence.enabled=true` in values.yaml.
A ReadOnlyMany volume is created so that the dags can be accessed from the scheduler, webserver and worker pods.
The volume is populated in the init container of the webserver.
In this example, the airflow git repository is cloned first and then the dags are copied into the volume.
Add your own bash commands to `airflow.dags.persistence.init_dags` to alter the initialization for your application.

You could also use an existing volume by setting `airflow.dags.existingClaim` in the values.yaml file.
Make sure that the claim is configured as `ReadOnlyMany`.
