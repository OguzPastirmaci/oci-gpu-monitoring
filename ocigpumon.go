package main

import (
	"fmt"
	"log"

	"github.com/NVIDIA/gpu-monitoring-tools/bindings/go/nvml"
)

var temp uint
var gpuUtilization uint
var memoryUtilization uint

type Metrics []struct {
	Namespace     string `json:"namespace"`
	CompartmentID string `json:"compartmentId"`
	ResourceGroup string `json:"resourceGroup"`
	Name          string `json:"name"`
	Dimensions    struct {
		ResourceID   string `json:"resourceId"`
		InstanceName string `json:"instanceName"`
	} `json:"dimensions"`
	Metadata struct {
		Unit        string `json:"unit"`
		DisplayName string `json:"displayName"`
	} `json:"metadata"`
	Datapoints []struct {
		Timestamp string `json:"timestamp"`
		Value     string `json:"value"`
	} `json:"datapoints"`
}

func main() {
	nvml.Init()
	defer nvml.Shutdown()

	count, err := nvml.GetDeviceCount()
	if err != nil {
		log.Panicln("Error getting device count:", err)
	}

	var devices []*nvml.Device
	for i := uint(0); i < count; i++ {
		device, err := nvml.NewDevice(i)
		if err != nil {
			log.Panicf("Error getting device %d: %v\n", i, err)
		}
		devices = append(devices, device)
	}

	for i, device := range devices {
		st, err := device.Status()
		if err != nil {
			log.Panicf("Error getting device %d status: %v\n", i, err)
		}
		temp += *st.Temperature
		gpuUtilization += *st.Utilization.GPU
		memoryUtilization += *st.Utilization.Memory

	}

	fmt.Printf("Average temperature: %d\n", temp/count)
	fmt.Printf("Average GPU utilization: %d\n", gpuUtilization/count)
	fmt.Printf("Average memory utilization: %d\n", memoryUtilization/count)

}
