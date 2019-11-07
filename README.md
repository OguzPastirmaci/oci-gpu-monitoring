# Publishing GPU metrics to Oracle Cloud Infrastructure (OCI) Monitoring service

Currently, the Oracle Cloud Infrastructure (OCI) [Monitoring service](https://docs.cloud.oracle.com/iaas/Content/Monitoring/Concepts/monitoringoverview.htm) does not have built-in support for collecting GPU metrics from GPU instances.

However, it's possible to [publish custom metrics](https://docs.cloud.oracle.com/iaas/Content/Monitoring/Tasks/publishingcustommetrics.htm) to OCI Monitoring service. This repo has the necessary information and the shell script for publishing **GPU temperature, GPU utilization, and GPU memory utilization** from GPU instances to OCI Monitoring service.

If you encounter any problems when following this guide, feel free to create an [issue](https://github.com/OguzPastirmaci/oci-gpu-monitoring/issues).

# [Step by step instructions for Linux](../master/docs/linux.md)

# [Step by step instructions for Windows](../master/docs/windows.md)


