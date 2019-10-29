#!/bin/bash

# Write logs to /tmp/gpuMetrics.log
exec 3>&1 1>>/tmp/gpuMetrics.log 2>&1

# Getting instance metadata. For more information, check this link: https://docs.cloud.oracle.com/iaas/Content/Compute/Tasks/gettingmetadata.htm
# By default, metrics are published to the same compartment with the instance being monitored. You may change the following variables if you want to use different values.
compartmentId=$(curl -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.compartmentId')
metricNamespace="gpu_monitoring"
metricResourceGroup="gpu_monitoring_rg"
instanceName=$(curl -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.displayName')
instanceId=$(curl -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.id')
endpointRegion=$(curl -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.canonicalRegionName')

# Getting data from nvidia-smi and converting them to OCI monitoring compliant values. This script publishes GPU Temperature, GPU Utilization, and GPU Memory Utilization.
# Here's the list of available queries with nvidia-smi: https://nvidia.custhelp.com/app/answers/detail/a_id/3751/~/useful-nvidia-smi-queries
getMetrics=$(nvidia-smi --query-gpu=timestamp,temperature.gpu,utilization.gpu,utilization.memory --format=csv,noheader,nounits)
gpuTimestamp=$(echo $getMetrics | awk -F, '{print $1}' | sed -e 's/\.[^.]*$//' -e 's/ /T/' -e 's/\//-/g' -e 's/$/Z/')
gpuTemperature=$(echo $getMetrics | awk -F, '{print $2}' | xargs)
gpuUtilization=$(echo $getMetrics | awk -F, '{print $3}' | xargs)
gpuMemoryUtilization=$(echo $getMetrics | awk -F, '{print $4}' | xargs)

metricsJson=$(cat << EOF > /tmp/metrics.json
[
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
]
EOF
)

oci monitoring metric-data post --metric-data file:///tmp/metrics.json --endpoint https://telemetry-ingestion.$endpointRegion.oraclecloud.com
