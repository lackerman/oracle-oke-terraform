# Terraform Kubernetes cluster on Oracle Cloud

The repository contains the necessary Terraform configuration for creating a
multi-node Kubernetes cluster on Oracle Cloud. 

The repo is based on [this][free_oracle_tf] article by [Arnold Galovic][arnold].

## Setup in a nutshell

1. Get the following data from your Oracle Cloud account
    * User OCID
    * Tenancy OCID
    * Compartment OCID
   > You can get these automatically, based on your OCI configuration, and export them as
   > environment variables for Terraform to consume, using `source scripts/oci_env.sh`
2. Initialise the Terraform working directory
   ```shell
   terraform init
   ```
3. Execute a `terraform apply`
   ```shell
   terraform apply
   ```
4. Once done, run `source scripts/oci_env.sh` to expose a few convenience bash wrapper functions.
   These functions are wrappers around `oci` commands, including generating kube config or
   create a bastion forwarding session.
5. Create the kube config using `oci_cluster_kubeconfig`
   > This command with generate a kubeconfig using the cluster APIs private IP and then
   > replace it with `127.0.0.1` / `localhost` so that port-forwarding can be used.
6. Run `export ~/.kube/ociconfig` to set the kube config to the generated config
7. Run `oci_bastion_session_kube_api -v` to create a bastion session (if one doesn't exist)
   and establish a port-forwarding session.
   > I have noticed that if you create the session, the first ssh connection fails. Just re-run
   > the script to connect.
8. To verify cluster access, do a `kubectl get nodes`
9. Enjoy

## Useful queries

There are some useful oci wrapper commands in the [scripts](./scripts) directory.
You can run `source scripts/oci_env.sh` to expose a few convenience bash wrapper functions
in the terminal.

## References

- [Free Oracle Cloud Kubernetes cluster with Terraform][free_oracle_tf]
- [Kubernetes API Basics - Resources, Kinds, and Objects][api_terms]

[arnold]: https://arnoldgalovics.com/author/arnoldgalovics/
[free_oracle_tf]: https://arnoldgalovics.com/oracle-cloud-kubernetes-terraform/
[api_terms]: https://iximiuz.com/en/posts/kubernetes-api-structure-and-terminology/