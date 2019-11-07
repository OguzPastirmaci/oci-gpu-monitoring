Get-Date

# OCI CLI binary location
# Default installation location is "C:\Users\opc\bin"
$cliLocation = "C:\Users\opc\bin"

# nvidia-smi binary location
# Default installation location is "C:\Program Files\NVIDIA Corporation\NVSMI"
$nvidiaSmiLocation = "C:\Program Files\NVIDIA Corporation\NVSMI"

# Check if oci.exe and nvidia-smi.exe are in the path and add them if needed. This is not a persistent add.
if ((Get-Command "oci.exe" -ErrorAction SilentlyContinue) -eq $null) { 
   $env:Path = $env:Path + ";" + "$cliLocation"
}

if ((Get-Command "nvidia-smi.exe" -ErrorAction SilentlyContinue) -eq $null) { 
   $env:Path = $env:Path + ";" + "$nvidiaSmiLocation"
} 

# Getting instance metadata. For more information, check this link: https://docs.cloud.oracle.com/iaas/Content/Compute/Tasks/gettingmetadata.htm
# By default, metrics are published to the same compartment with the instance being monitored. You may change the following variables if you want to use different values.
$getMetadata = (curl -s -L http://169.254.169.254/opc/v1/instance/) | ConvertFrom-Json
$compartmentId = $getMetadata.compartmentId
$metricNamespace = "gpu_monitoring"
$metricResourceGroup = "gpu_monitoring_rg"
$instanceName = $getMetadata.displayName
$instanceId = $getMetadata.id
$endpointRegion = $getMetadata.canonicalRegionName

# Getting data from nvidia-smi and converting them to OCI monitoring compliant values. This script publishes GPU Temperature, GPU Utilization, and GPU Memory Utilization.
# Run "nvidia-smi --help-query-gpu" to get the list of available metrics.
$nvidiaTimestamp = (nvidia-smi.exe --query-gpu=timestamp --format=csv, noheader, nounits)
$gpuTimestamp = ($nvidiaTimestamp.Replace(" ", "T").Replace("/", "-")).Substring(0, $nvidiaTimestamp.IndexOf('.')) + "Z"
$gpuTemperature = (nvidia-smi.exe --query-gpu=temperature.gpu --format=csv, noheader, nounits)
$gpuUtilization = (nvidia-smi.exe --query-gpu=utilization.gpu --format=csv, noheader, nounits)
$gpuMemoryUtilization = (nvidia-smi.exe --query-gpu=utilization.memory --format=csv, noheader, nounits)

$metricsJson = @"
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
"@

$metricsJson | Out-File $env:TEMP\metrics.json -Encoding ASCII

oci monitoring metric-data post --metric-data file://$env:TEMP\metrics.json --endpoint https://telemetry-ingestion.$endpointRegion.oraclecloud.com
