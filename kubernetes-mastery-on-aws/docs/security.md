# Security

## Authentication

- All **authentication** in Kubernetes is done at the **API server**
- Kubernetes clusters have 2 categories of user accounts:
  - Normal User Accounts
    - Normal users are managed by an independent service **outside** k8s
  - Service Accounts
    - Service accounts are synthetic users managed by the k8s API of **kind: ServiceAccount**

How are **normal users** managed outside of k8s?

- For small clusters:
  - Distribute private keys
  - Distribute bearer tokens
  - Use a static username/password in a CSV file
- For large clusters:
  - Integrate with an external store e.g. LDAP
  - Manage users centrally and provide single sign-on (SSO) capability
  - Subdivide users into groups and control resource access

And what is the purpose of **service accounts**?

- Service accounts create identities for **processes running in pods**
- Service accounts are bound to specific namespaces
- Service account credentials are stored as **secrets**
  - Secrets are objects in k8s for storing sensitive data e.g. passwords, OAuth tokens, access keys
- The API server automatically creates service accounts for pods
  - If a pod does not have a service account, its value is set to **default**
- You can also manually create service accounts