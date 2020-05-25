# Deployments

![Deployment](images/deployment.png)

- A Deployment object exists to **reliably rollout** new software versions.
- You can also easily rollback to any of the previous versions.
- A Deployment spec contains a **strategy** field, this dictates **how old pods are replaced by new ones when a rollout is triggered**.
- The Deployment **triggers a rollout** when its **pod template is changed** (scaling a Deployment does NOT trigger a rollout).

## Deployment Strategies

- Recreate strategy - kills and recreates Pods.
  - Deployment updates its ReplicaSet to use the new image.
  - Deployment kills all existing Pods.
  - ReplicaSet (detecting Pod number is below threshold) recreates new Pods with the new version of the image.
  - This rollout results in some **service downtime**.
- RollingUpdate (default).
  - Deployment can **update** the **running application** while it's **still receiving traffic** with **zero downtime**.
  - Instead of kill all and recreate it works by **incrementally updating** existing Pod instances with new ones.
    - So, create new Pods with updated software.
    - Ensure they are healthy and then remove some old Pods - The Deployment controller uses **readiness checks** to determine if **new Pods are healthy**.
    - Continue until all existing Pods have been replaced with new ones.
  - NOTE during rolling update both **old and new software versions will be running concurrently**. These differing versions must be **version compatible** for the rolling update to work.
  - Rolling updates are **versioned** and **enables a deployment rollback**.
    - Deployment keeps its rollout history.
    - Allowing for a Deployment update to be reverted to a previous stable version.