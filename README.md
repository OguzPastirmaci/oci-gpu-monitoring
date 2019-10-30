# Publishing GPU metrics to Oracle Cloud Infrastructure (OCI) Monitoring service

Currently, the Oracle Cloud Infrastructure (OCI) [Monitoring service](https://docs.cloud.oracle.com/iaas/Content/Monitoring/Concepts/monitoringoverview.htm) does not have built-in support for collecting GPU metrics from GPU instances.

However, it's possible to publish custom metrics to OCI Monitoring service. This repo has the necessary information and the script for publishing GPU temperature, GPU utilization, and GPU memory utilization from GPU instances to OCI Monitoring service.

## Prerequisites

#### IAM Policy
The script publishes the metrics to the same compartment as the GPU instance being monitored by default. You probably have the necessary IAM policy already configured for your user.

If you plan to use a separate compartment for publishing the metrics, or if you get a message that you don’t have permission or are unauthorized, check with your administrator.

You can find more info in [this link](https://docs.cloud.oracle.com/iaas/Content/Identity/Concepts/commonpolicies.htm#metrics-publish).


#### OCI CLI
The script uses OCI CLI for uploading the metrics to OCI Monitoring service, so the CLI must be installed in the GPU instance that you want to monitor.

You can install the OCI CLI by running the following command:

```zsh
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```
IMPORTANT: If you change the default installation location of the CLI, make sure you update the `cliLocation` variable in the shell script.

```zsh
# OCI CLI binary location
# Default installation location for Oracle Linux and CentOS is /home/opc/bin/oci
# Default installation location for Ubuntu is /home/ubuntu/bin/oci
cliLocation="/home/opc/bin/oci"
```

You should also configure the CLI so that it can authenticate with your 
You can find more information on OCI CLI in [this link](https://docs.cloud.oracle.com/iaas/Content/API/Concepts/cliconcepts.htm).

