# Airflow helm chart (KubernetesExecutor)

Run Airflow on Kubernetes using the KubernetesExecutor. 
With this executor, Airflow creates a new worker pod for each task. 
Workers pod are removed as soon as their task is completed. 
The deployment is a bit simpler compared to the CeleryExecutor, because no third-party components are needed.
In this way, the full potential of Kubernetes is leveraged.

Since the release of Airflow 1.10.2, the KubernetesExecutor has become stable enough to be used in production. 
This repository contains a helm chart to deploy Airflow on Kubernetes with the new executor. 
The core structure has been borrowed from [momoshu/kube-airflow](https://github.com/mumoshu/kube-airflow) and
Airflow's [CI scripts](https://github.com/apache/airflow/tree/master/scripts/ci/kubernetes).
Check out the examples for a couple of working deployments both on Minikube and Kubernetes.


## Prerequisites

Before you can run the scripts you need to install 
[Helm](https://docs.helm.sh/using_helm/#installing-helm), 
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and 
[Docker](https://docs.docker.com/install/). 
If you're installing Docker on Ubuntu, then follow the 
[post-installation steps](https://docs.docker.com/install/linux/linux-postinstall/)
to be able to run Docker without sudo.


## Deploy

Deployment details are described in the examples. 
Two sets of examples are provided: for Minikube and hosted Kubernetes.
The examples on Minikube are a bit easier to start with.
On a hosted Kubernetes cluster, you will need an NFS volume for the logs, because
each pod needs write access to the volume. 
Here is a summary of the available deployments.

* Minikube: Recommended to test your deployment locally and to play around with the parameters.

  * git-sync: The scheduler and webserver have a side-car container that continuously pulls the dags from a git repository.
  On the worker pods, the repository is pulled in an init container before the pod starts.
  The main advantage is that the dags are always up-to-date. 
  Adding or updating dags is as easy as pushing your changes to git. 
  However, this approach also comes with two disadvantages. 
  The definition of a dag can change while it is executing. 
  This might lead to unexpected behaviour. 
  You can overcome this issue by versioning the dags. 
  The second drawback is that worker pods take a longer time to start because the repository needs to be pulled
  each time before the pod starts. So make sure that the repository remains as small as possible.
  
  * dags-volume: The dags are stored on a persistent volume instead. 
  Before the webserver starts, a custom script gets executed that loads the dags onto the volume.
  You can provide such a script in the values.yaml file. 
  The dags don't get updated as long as the webserver remains alive. 
  To update the dags, you should restart the webserver and scheduler.
  
* Hosted Kubernetes: A bit more complicated because the pods can run on multiple nodes.
The tricky part are the persistent volumes that need to be read and written on pods.
This is a requirement for the logs volume, which gets updated from the scheduler, webserver and worker pods.
Using ReadWriteOnce only works when all the pods are scheduled on the same node.
The examples provide a possible solution: an NFS server.
An NFS volume allows ReadWriteMany access to the volumes, which is sufficient to solve our problem.

  * git-sync-readwritemany: Similar to Minikube example, but uses NFS volume for the logs.
  
  * dags-volume-readwritemany: Similar to Minikube example, but uses NFS volume for both logs and dags.
  

## Additional reading

The Docker image is based on the great work of [puckel/docker-airflow](https://github.com/puckel/docker-airflow).
Please refer to this repository if you need to make changes to the docker image. 

The Helm chart was based on the [battle-tested chart](https://github.com/mumoshu/kube-airflow) for the CeleryExecutor by momoshu.
I also took a lot of ideas from the [Airflow CI scripts](https://github.com/apache/airflow/tree/master/scripts/ci/kubernetes/kube).

The KubernetesExecutor is explained in greater detail in the [docs](https://airflow.apache.org/kubernetes.html?highlight=kubernetes%20executor)
and Airflow's [confluence page](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=71013666).

Make sure that you also get familiar with the KubernetesPodOperator, which runs any script on any docker image
as a pod on the Kubernetes cluster. This solves a lot of issues with dependencies and resources.
Check out this [blog post by Kubernetes](https://kubernetes.io/blog/2018/06/28/airflow-on-kubernetes-part-1-a-different-kind-of-operator/)
and this [insightful post](https://medium.com/bluecore-engineering/were-all-using-airflow-wrong-and-how-to-fix-it-a56f14cb0753) by Bluecore
on how we're all using Airflow wrong and how to fix it.


## Contributing

Issues, comments and improvements are always welcome. Fork and PR if you want to contribute :)
