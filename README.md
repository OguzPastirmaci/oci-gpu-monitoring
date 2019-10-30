# Publishing GPU metrics to Oracle Cloud Infrastructure (OCI) Monitoring service

Currently, the Oracle Cloud Infrastructure (OCI) [Monitoring service](https://docs.cloud.oracle.com/iaas/Content/Monitoring/Concepts/monitoringoverview.htm) does not have built-in support for collecting GPU metrics from GPU instances.

However, it's possible to publish custom metrics to OCI Monitoring service. This repo has the necessary information and the script for publishing GPU temperature, GPU utilization, and GPU memory utilization from GPU instances to OCI Monitoring service.

## Prerequisites

### IAM Policy
The script publishes the metrics to the same compartment as the GPU instance being monitored by default. You probably have the necessary IAM policy already configured for your user.

If you plan to use a separate compartment for publishing the metrics, or if you get a message that you don’t have permission or are unauthorized, check with your administrator.

You can find more info in [this link](https://docs.cloud.oracle.com/iaas/Content/Identity/Concepts/commonpolicies.htm#metrics-publish).


### OCI CLI
The script uses OCI CLI for uploading the metrics to OCI Monitoring service, so the CLI must be installed in the GPU instance that you want to monitor.

You can install the OCI CLI by running the following command:

```sh
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```
**IMPORTANT:** If you change the default installation location of the CLI, or use Ubuntu as the OS, make sure you update the `cliLocation` variable in the shell script.

```sh
# OCI CLI binary location
# Default installation location for Oracle Linux and CentOS is /home/opc/bin/oci
# Default installation location for Ubuntu is /home/ubuntu/bin/oci
cliLocation="/home/opc/bin/oci"
```

To have the CLI walk you through the first-time setup process, use the `oci setup config` command. The command prompts you for the information required for the config file and the API public/private keys. The setup dialog generates an API key pair and creates the config file.


You can find more information on OCI CLI in [this link](https://docs.cloud.oracle.com/iaas/Content/API/Concepts/cliconcepts.htm).

### NVIDIA System Management Interface (nvidia-smi)
The script uses `nvidia-smi` command line utility to gather metrics data from the GPUs in the instance. If you are already using your GPU instances you should already have  the appropriate NVIDIA drivers installed. The script also checks if it's installed but you may SSH into your GPU instance and run `nvidia-smi` in the command line. You should see an output like this:

```console
[opc@gputest ~]$ nvidia-smi

Wed Oct 30 18:29:24 2019
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 418.67       Driver Version: 418.67       CUDA Version: 10.1     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla V100-SXM2...  Off  | 00000000:00:04.0 Off |                    0 |
| N/A   38C    P0    39W / 300W |      0MiB / 16130MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+

+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

## Steps for publishing GPU metrics to OCI Monitoring service

1- Install git
```sh
sudo yum install git
```

2- Clone the repository
```sh
git clone https://github.com/OguzPastirmaci/oci-gpu-monitoring.git
```

3- Change to the repo directory
```sh
cd oci-gpu-monitoring
```

4- We will create a Cron job to run the script every minute, but before that let's run the script manually to check we don't get any errors.

```sh
sh ./publishGPUMetrics.sh
```

5- By default, the scripts writes logs to `/tmp/gpuMetrics.log`. Let's check the logs to see if there were any errors.

```sh

