# <div align="center"> Practice: Making Architecture Explicit

At this point, you have a set of Protocol Buffer messages and have already identified the 
**Prime Objects** in your model.

Using the example from the previous chapter, the following snippet shows a simplified view of the 
generated protobuf definitions:

```proto
message EmployeeList {
  repeated Employee list = 1;
  l8api.L8MetaData metadata = 2;
}

// Prime Object
message Employee {
  string id = 1;
  string name = 2;
  repeated Addr addresses = 3;
}

message AddressList {
  repeated Employee list = 1;
  l8api.L8MetaData metadata = 2;
}

// Prime Object
message Addr {
  string line1 = 1;
  string line2 = 2;
  int32 zip = 3;
}
```

At this stage, the important observation is not the syntax of the messages, but the 
**explicit identification of Prime Objects**. Prime Objects define lifecycle ownership, 
concurrency boundaries, and service responsibility in Layer 8.

> **Note**
> Layer 8 includes a script that simplifies the generation of Protocol Buffer bindings for AI-assisted workflows.
> This script will be covered in the next chapter.

---
## Defining and Activating an SLA

In this example, we use a **distributed cache service**. Using a persistable service follows the same 
pattern, with the only difference being the injection of a persistence-layer implementation.

Below is the activation method for the `Employee` service. This is where architecture becomes explicit.

```go
package employees

import (
	"github.com/saichler/l8-ai-template/go/types/example"
	"github.com/saichler/l8services/go/services/base"
	"github.com/saichler/l8types/go/ifs"
	"github.com/saichler/l8types/go/types/l8api"
	"github.com/saichler/l8types/go/types/l8web"
	"github.com/saichler/l8utils/go/utils/web"
)

func ActivateEmployees(vnic ifs.IVNic) {
	// Logical service name used by other services to reference this service
	serviceName := "Employee"

	// Service area enables vertical scaling (e.g., multiple isolated caches in the same process)
	serviceArea := byte(0)

	sla := ifs.NewServiceLevelAgreement(
		&base.BaseService{},      // Layer 8 base service implementation
		serviceName, serviceArea, // Logical service identity
		true, // Stateful service (in-memory cache)
		nil,  // Optional callback for validation or pre-processing
	)

	// Define the Prime Object and its collection
	sla.SetServiceItem(&example.Employee{})
	sla.SetServiceItemList(&example.EmployeeList{})

	// Define the primary key that uniquely identifies the Prime Object
	sla.SetPrimaryKeys("EmployeeId")

	// Select the concurrency model
	sla.SetTransactional(true) // Transactional vs best-effort concurrency

	// Disable replication; all instances maintain identical state
	sla.SetReplication(false)

	// Define the Web API surface for this service
	ws := web.New(serviceName, serviceArea, 0)

	// CRUD-style endpoints mapped to Prime Object semantics
	ws.AddEndpoint(&example.Employee{}, ifs.POST, &l8web.L8Empty{})
	ws.AddEndpoint(&example.EmployeeList{}, ifs.POST, &l8web.L8Empty{})
	ws.AddEndpoint(&example.Employee{}, ifs.PUT, &l8web.L8Empty{})
	ws.AddEndpoint(&example.Employee{}, ifs.PATCH, &l8web.L8Empty{})
	ws.AddEndpoint(&l8api.L8Query{}, ifs.DELETE, &l8web.L8Empty{})
	ws.AddEndpoint(&l8api.L8Query{}, ifs.GET, &example.EmployeeList{})

	sla.SetWebService(ws)

	// Activate the service within the virtual network context
	vnic.Resources().Services().Activate(sla, vnic)
}
```

What matters here is not the API mechanics, but the **architectural declaration**:

- The Prime Object is explicit
- The concurrency model is explicit
- The service lifecycle is explicit
- The API surface is derived from the model, not hand-coded logic

At this point, the system no longer relies on implicit conventions.
The architecture is declared, enforced, and observable.

---
## Creating the Resources

`Resources` encapsulate the ecosystem services required by a Layer 8–based system.
They form the runtime foundation on which networking, security, service management,
and observability are built.

In most projects, resource creation is centralized in a single static or bootstrap
method, similar to the example below. This method is typically invoked once during
process initialization.

```go
// CreateResources initializes and wires all core ecosystem services
// required by this project.
func CreateResources(alias string) ifs.IResources {
	// Create and configure the logger
	log := logger.NewLoggerImpl(&logger.FmtLogMethod{})
	log.SetLogLevel(ifs.Info_Level)

	// Instantiate the Resources container
	res := resources.NewResources(log)

	// Register the service registry
	res.Set(registry.NewRegistry())

	// Load and initialize the security provider
	sec, err := ifs.LoadSecurityProvider(res)
	if err != nil {
		// Delay to allow logs to flush before crashing
		time.Sleep(time.Second * 10)
		panic(err.Error())
	}
	res.Set(sec)

	// Configure networking using default values
	conf := &l8sysconfig.L8SysConfig{
		MaxDataSize:               resources.DEFAULT_MAX_DATA_SIZE,
		RxQueueSize:               resources.DEFAULT_QUEUE_SIZE,
		TxQueueSize:               resources.DEFAULT_QUEUE_SIZE,
		LocalAlias:                alias,        // Pod or process identifier for observability
		VnetPort:                  uint32(20201), // Virtual network port
		KeepAliveIntervalSeconds:  30,            // Heartbeat interval to the vNet
	}
	res.Set(conf)

	// Enable runtime introspection
	res.Set(introspecting.NewIntrospect(res.Registry()))

	// Initialize the service manager
	res.Set(manager.NewServices(res))

	return res
}
```

---
## Containing Process

A **containing process** is responsible for instantiating a virtual network interface (vNic)
and activating services within that runtime context.

From the application’s perspective, this process follows a small and deterministic sequence:
initialize resources, establish networking, activate services, and wait.

```go
func main() {
	// Create and initialize all ecosystem resources
	res := CreateResources("pod name / process name / container name")

	// Select the networking mode.
	// When running under Kubernetes, this enables native integration.
	// If Kubernetes is not present, the framework automatically
	// falls back to container-level and then process-level networking.
	ifs.SetNetworkMode(ifs.NETWORK_K8s)

	// Instantiate the virtual network interface (vNic)
	nic := vnic.NewVirtualNetworkInterface(res, nil)

	// Start the vNic and its underlying networking stack
	nic.Start()

	// Block until the vNic is connected and ready
	nic.WaitForConnection()

	// Activate services within this network context
	employees.ActivateEmployees(nic)

	// Block until a termination signal is received
	// (e.g., SIGTERM, SIGINT). Cleanup is handled by the framework.
	common.WaitForSignal(res)
}
```

---
## Starting a Web Server

Starting a web server to expose the Web API, including authentication endpoints, is 
intentionally as simple as activating any other service.

It follows the **exact same architectural pattern**:  
a Service Level Agreement is defined, activated, and bound to the virtual network context, 
with a small number of web-specific configuration steps.

The following example can be used **instead of** calling `employees.ActivateEmployees(nic)` 
when the process is responsible for serving HTTP endpoints.

```go
func startWebServer(nic ifs.IVNic, httpPort int, cert string) {
	// Configure the REST server
	serverConfig := &server.RestServerConfig{
		Host:           ipsegment.MachineIP, // Detect the machine IP and bind to it
		Port:           httpPort,            // HTTP/HTTPS listening port
		Authentication: true,                // Enable secure communication
		CertName:       cert,                // TLS certificate identifier
		Prefix:         "/myApp/",            // Application URL prefix
	}

	// Create the REST server instance
	svr, err := server.NewRestServer(serverConfig)
	if err != nil {
		panic(err)
	}

	// Register built-in health service endpoints
	hs, ok := nic.Resources().Services().ServiceHandler(health.ServiceName, 0)
	if ok {
		ws := hs.WebService()
		svr.RegisterWebService(ws, nic)
	}

	// Activate the web service as a first-class Layer 8 service
	sla := ifs.NewServiceLevelAgreement(
		&server.WebService{},
		ifs.WebService,
		0,
		false,
		nil,
	)
	sla.SetArgs(svr)

	nic.Resources().Services().Activate(sla, nic)

	nic.Resources().Logger().Info("Web server started")

	// Start accepting HTTP requests
	svr.Start()
}
```

>That’s it. If it feels simple, it’s because the complexity was moved where it belongs, **into the architecture.**