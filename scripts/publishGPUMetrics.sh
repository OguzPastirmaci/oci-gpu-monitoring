#!/bin/bash


# Write logs to /tmp/gpuMetrics.log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>/tmp/gpuMetrics.log 2>&1
date


# OCI CLI binary location
# Default installation location for Oracle Linux 7 is /home/opc/bin/oci
# Default installation location for Ubuntu 18.04 and Ubuntu 16.04 is /home/ubuntu/bin/oci
cliLocation="/home/opc/bin/oci"

# Check if OCI CLI, nvidia-smi, jq, and curl is installed
if ! [ -x "$(command -v $cliLocation)" ]; then
  echo 'Error: OCI CLI is not installed. Please follow the instructions in this link: https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm' >&2
  exit 1
fi

if ! [ -x "$(command -v nvidia-smi)" ]; then
  echo 'Error: nvidia-smi is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v curl)" ]; then
  echo 'Error: curl is not installed.' >&2
  exit 1
fi

# Getting instance metadata. For more information, check this link: https://docs.cloud.oracle.com/iaas/Content/Compute/Tasks/gettingmetadata.htm
# By default, metrics are published to the same compartment with the instance being monitored. You may change the following variables if you want to use different values.
compartmentId=$(curl -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.compartmentId')
metricNamespace="gpu_monitoring"
instanceName=$(curl -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.displayName')
instanceId=$(curl -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.id')
endpointRegion=$(curl -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.canonicalRegionName')

# Getting data from nvidia-smi and converting them to OCI monitoring compliant values. This script publishes GPU Temperature, GPU Utilization, and GPU Memory Utilization.
# Run "nvidia-smi --help-query-gpu" to get the list of available metrics
readarray -t getMetrics < <(nvidia-smi --query-gpu=timestamp,temperature.gpu,utilization.gpu,utilization.memory --format=csv,noheader,nounits)

metricsJson=$(cat << EOF > /tmp/metrics.json
[
EOF
)

# loop through each GPU returned from nvidia-sli. Use the metricResourceGroup as a unique identifier for each GPU
for ((i = 0; i < ${#getMetrics[@]}; i++))
do
	metricResourceGroup="gpu_${i}_monitoring"
	gpuTimestamp=$(echo ${getMetrics[$i]} | awk -F, '{print $1}' | sed -e 's/\.[^.]*$//' -e 's/ /T/' -e 's/\//-/g' -e 's/$/Z/')
	gpuTemperature=$(echo ${getMetrics[$i]} | awk -F, '{print $2}' | xargs)
	gpuUtilization=$(echo ${getMetrics[$i]} | awk -F, '{print $3}' | xargs)
	gpuMemoryUtilization=$(echo ${getMetrics[$i]} | awk -F, '{print $4}' | xargs)

metricsJson=$(cat << EOF >> /tmp/metrics.json
   {
      "namespace":"$metricNamespace",
      "compartmentId":"$compartmentId",
      "resourceGroup":"$metricResourceGroup",
      "name":"gpuTemperature",
      "dimensions":{
         "resourceId":"$instanceId",
         "instanceName":"$instanceName"
      },
      "metadata":{
         "unit":"degrees Celcius",
         "displayName":"GPU Temperature"
      },
      "datapoints":[
         {
            "timestamp":"$gpuTimestamp",
            "value":$gpuTemperature
         }
      ]
   },
   {
      "namespace":"$metricNamespace",
      "compartmentId":"$compartmentId",
      "resourceGroup":"$metricResourceGroup",
      "name":"gpuUtilization",
      "dimensions":{
         "resourceId":"$instanceId",
         "instanceName":"$instanceName"
      },
      "metadata":{
         "unit":"percent",
         "displayName":"GPU Utilization"
      },
      "datapoints":[
         {
            "timestamp":"$gpuTimestamp",
            "value":$gpuUtilization
         }
      ]
   },
{
      "namespace":"$metricNamespace",
      "compartmentId":"$compartmentId",
      "resourceGroup":"$metricResourceGroup",
      "name":"gpuMemoryUtilization",
      "dimensions":{
         "resourceId":"$instanceId",
         "instanceName":"$instanceName"
      },
      "metadata":{
         "unit":"percent",
         "displayName":"GPU Memory Utilization"
      },
      "datapoints":[
         {
            "timestamp":"$gpuTimestamp",
            "value":$gpuMemoryUtilization
         }
      ]
   }
EOF
)

# if there is going to be another iteration in the loop, we need a comma to keep this as valid JSON
if [ $((i+1)) -lt ${#getMetrics[@]} ]
then
metricsJson=$(cat << EOF >> /tmp/metrics.json
,
EOF
)
fi
	
done


metricsJson=$(cat << EOF >> /tmp/metrics.json
]
EOF
)


$cliLocation monitoring metric-data post --metric-data file:///tmp/metrics.json --endpoint https://telemetry-ingestion.$endpointRegion.oraclecloud.com

