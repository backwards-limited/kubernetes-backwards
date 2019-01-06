# Kubernetes

## Without Kubernetes

Before Kubernetes, we deployed 4 containers onto AWS Elastic Beanstalk:

> ![Before Kubernetes on AWS](images/containers-on-aws-without-kubernetes.png)

The **worker** calculates Fibonacci and with more users we would eventually need to scale up this service:

> ![Scale up eb](images/scale-up-eb.png)

E.g. 3 users could now submit their requests and each is handled by a different **worker**.

However, Elastic Beanstalk will scale up everything, not just the **worker**:

> ![EB way of scaling](images/eb-scaling.png)

## Kubernetes Approach

Kubernetes approach to solving the above issue:

> ![Kubernetes approach](images/kubernetes-approach.png)

And so, what is and why use Kubernetes?

> ![Kubernetes what and why](images/what-is-kubernetes.png)

## Working with Kubernetes

> ![Working with Kubernetes](images/working-with-kubernetes.png)

> ![Local Kubernetes](images/local-kubernetes.png)