# <div align="center"> Service as a Contract, Enforced by Concurrency

> The phrase "As a Service" is widely used and rarely understood.

For most software engineers and architects, serviceability is not a first-class design 
concern. It is not taught as part of computer science curricula, nor is it emphasized 
during professional growth.

**As a result, systems are often designed without an explicit serviceability mindset.**

---
## The Serviceability Mindset

A **serviceability mindset** is an architectural approach that treats operational 
behavior, correctness under concurrency, failure handling, recovery, and evolution; 
as part of the service contract, not as an afterthought.

Rather than assuming services will be managed externally through tooling and procedures,
a serviceability mindset requires that services declare their guarantees up front
and relies on the platform to enforce them.

In this model, correctness, predictability, and diagnosability
are properties of the architecture itself,
not responsibilities deferred to operators or runtime intervention.

With the rise of microservices, this gap became more visible.
While systems are broken into services, Service Level Agreements (SLAs)
are rarely defined, modeled, or enforced at design time.

This leads to a design failure on day one.

Without SLAs, services are merely distributed components. They expose APIs, 
**but they do not provide guarantees.**

In Layer 8, serviceability is foundational.

An SLA is not documentation.
It is not an operational afterthought.
It is a core architectural contract.

Layer 8 treats SLA as a first-class concept,
enforced by the platform and used to drive radical simplicity in system design.

---
## What is a Service?

One of the most common misconceptions in modern software architecture
is the belief that a service is a process, a container, or a pod.

**It is not.**

Whatever runs inside a process is not the service. Treating runtime artifacts 
as services is a primary source of accidental complexity. 

***It forces architects to solve problems that should not exist in the first place.***

This misconception leads directly to:

- unnecessary coupling,
- fragile scaling strategies,
- and lifecycle confusion.

Layer 8 uses a different definition.

In Layer 8, a Service encapsulates the lifecycle of a **Prime Object**.

### Prime Object
> A Prime Object is the root of a nested model with an independent lifecycle 
> and support for creating, reading, updating, and deleting state, and it defines 
> the unit of concurrency ownership that allows Layer 8 to enforce concurrency 
> at the architectural level rather than in application code.

If an object can be created, updated, queried, and deleted independently,
it qualifies as a Prime Object and therefore defines a service boundary.

Layer 8 adopts the commonly understood RESTful semantics and uses
POST, PUT, PATCH, DELETE, and GET as the basic interaction interface
between other services and its Prime Object.

**It is important to note:** This service interface is not exposed to the outside world. It is used only for service-to-service 
interaction within the same Virtual Network.

### Logical Services vs Runtime Artifacts

In Layer 8, a service is a logical construct, not a runtime artifact.

A logical service is defined by its ownership of a Prime Object, its identity model,
and its declared Service Level Agreement. It represents a contract: how the system behaves under 
concurrency, failure, and evolution.

Processes, containers, and pods are runtime artifacts. They are execution units created to host 
service logic, but they are not the service itself. They can be restarted, replaced, rescheduled, 
or scaled without changing the service’s identity or guarantees.

Confusing runtime artifacts with services forces architects to solve lifecycle, scaling, and 
concurrency problems at the infrastructure level. Layer 8 avoids this by treating runtime artifacts
as interchangeable participants in a single logical service, whose behavior is defined by 
**contract rather than deployment.**

### Example: Single Service

In the following example, there is only one service: Employee.

The Address does not have an independent lifecycle. It does not exist outside the Employee model
and therefore does not define its own service.

```
message Employee {
  string id = 1;
  Address addr = 2;
}

message Address {
  string line1 = 1;
  string line2 = 2;
  string line3 = 3;
}
```

### Example: Two Services

In the next example, Address has its own lifecycle.
It can be created, updated, and deleted independently.

As a result, it becomes its own service.

```
message Employee {
  string id = 1;
  string addrId = 2;
}

message Address {
  string addrId = 1;
  string line1 = 2;
  string line2 = 3;
  string line3 = 4;
}
```

This method of identifying services based on lifecycle ownership
has proven to be a major architectural enabler.

It allows Layer 8 to provide generic support for:

- concurrency,
- redundancy,
- high availability,
- and horizontal scaling,

without introducing service-specific logic, while allowing a single service to span multiple 
processes and present itself as a single logical service.

These properties emerge naturally from the service definition
and will be explored further in the rest of this chapter.

---
## Concurrency and Transactions

A crucial step in designing a service is defining its **Service Level Agreement (SLA)**.

If this step is skipped, postponed, or treated as an afterthought,
failure is almost guaranteed.

An SLA is a business contract. If expectations are not defined up front,
consumers will define them instead, and those expectations will usually grow without bounds.

**To prevent this, Layer 8 enforces SLA awareness.**

An SLA is not optional. It is a required input for service activation.

A service cannot start without declaring how it behaves.

### Stateless or Stateful

The first decision a service must make is whether it is stateless or stateful. Assume there are three 
instances of a service running in three different processes.

If one instance crashes and restarts, ask the following question:

>Can the restarted instance immediately serve requests
without synchronizing with the other two
and without breaking correctness?

If the answer is yes, the service is **stateless**.  
If the answer is no, the service is **stateful**.

This decision directly impacts concurrency, recovery, and transaction semantics.

### Service Item

We established earlier that a service encapsulates a **Prime Object**.

The next question is: what uniquely identifies an instance of that Prime Object?

>Within the Prime Object, one or more attributes must define identity.

These attributes form the Service Item key.

Concurrency, routing, and transactional guarantees are all applied
relative to this identity.

### Stateful Concurrency Methods

>For stateful services, the SLA must define the concurrency model.

Layer 8 supports the following patterns.

#### Best Effort

Multiple instances may receive requests.

When an instance processes a request, it acknowledges completion to the caller
and makes a best effort to propagate the update to its peers.

This model favors availability and low latency, but allows temporary inconsistency.

#### Transactional

A single instance is elected as the leader.

All requests are routed through the leader, which coordinates updates
with its followers.

When the leader acknowledges completion, all peers are already synchronized.

This model favors consistency over availability.

#### Replication Count X

A single instance is elected as the leader.

Requests are routed to the leader, which coordinates updates
with a defined number of followers.

Completion is acknowledged only after X peers have successfully synchronized the data.

This model allows precise control over the balance between:

- consistency,
- availability,
- and latency.

### SLA Choices and Observable Behavior

The following table summarizes how SLA declarations in Layer 8
translate directly into observable system behavior.

| SLA Choice | Declaration | Observable Behavior |
|-----------|-------------|---------------------|
| Service Type | Stateless | Any instance can serve requests immediately after restart; no synchronization required |
| Service Type | Stateful | Instances must coordinate state; restart may require synchronization |
| Concurrency Model | Best Effort | Requests complete quickly; temporary inconsistency between instances is possible |
| Concurrency Model | Transactional | Requests are acknowledged only after all peers are synchronized; strong consistency |
| Concurrency Model | Replication Count X | Requests complete after X replicas acknowledge; tunable consistency vs latency |
| Leadership | None | Requests may be handled by any instance |
| Leadership | Elected Leader | All writes are routed through the leader; leadership may change transparently |
| Replication | Disabled | Single authoritative instance per Service Item |
| Replication | Enabled | Multiple replicas exist; placement and count are enforced by the platform |
| Failure Handling | Instance Failure | Instance is replaced without changing service identity |
| Failure Handling | Leader Failure | New leader is elected without client-visible disruption |
| Acknowledgement | Immediate | Caller may observe stale reads briefly |
| Acknowledgement | Post-Sync | Caller observes only committed, synchronized state |

---
## Concurrency as a Service

>In Layer 8, concurrency is not implemented by application logic.  
It is not reinvented per service.  
It is not guessed at runtime.

Concurrency is declared as part of the SLA and enforced by the platform.

The service expresses intent. Layer 8 applies the contract.

**Concurrency is served, not invented.**

### What Application Code No Longer Implements

Because service behavior in Layer 8 is declared through the SLA and enforced by the platform,
application code is no longer responsible for implementing core operational concerns.

Specifically, application code does not implement:

- concurrency control or locking semantics,
- leader election or leadership failover,
- replication coordination or quorum handling,
- state synchronization between instances,
- cache coherence or defensive copying,
- retry logic to compensate for partial failure,
- idempotency guards for repeated requests,
- instance discovery or peer awareness,
- lifecycle reconciliation after restarts or crashes.

Application code is limited to expressing domain behavior against a single logical service abstraction.

Operational correctness is guaranteed by the platform, not reimplemented by each service.
As a result, service implementations remain small, deterministic, and independent of 
deployment topology.

---
## Base Service

As Layer 8 evolved, and more infrastructure services were built using the same design guidelines,
a pattern began to emerge.

Service implementations were repeating themselves.

Further coherence analysis revealed that, across services, most of the implementation code
was effectively identical.

Only the declared intent and the SLA varied from one service to another.

Through repeated cycles of:

- coherence analysis,
- refactoring,
- and revalidation,

the Layer 8 Base Service emerged.

The Base Service captures common behavior in a single, generic,
well-tested implementation.

As a result, implementing a service no longer requires writing service logic.

A service is defined by declaring its SLA.

The platform provides the rest.

### Distributed Cache

At the core of the Base Service is a Distributed Cache designed for correctness
under concurrency.

The cache guarantees both thread safety and safe concurrent modification
by combining two techniques:

- mutex-based synchronization,
- and defensive cloning.

A read-write mutex allows multiple goroutines to read concurrently,
while ensuring that write operations have exclusive access.

However, mutexes alone are not sufficient.

Even with proper locking, a caller could modify an object after retrieving it from the cache,
silently corrupting shared state.

To prevent this, the cache clones every value:

- once when storing it,
- and again when retrieving it.

Callers always interact with independent copies. They never receive direct references to cached data.

This design guarantees that:

- changes made by one goroutine never affect others,
- shared state cannot be corrupted accidentally,
- and callers do not need to manage synchronization themselves.

The result is complete isolation with minimal cognitive overhead.

The Base Service embodies the core philosophy of Layer 8:
- declare intent,
- enforce guarantees,
- and eliminate accidental complexity.

---
## Service Manager

>The Service Manager is responsible for the lifecycle of a service.

It orchestrates service activation, coordination, and termination, and acts as the control plane
that binds together the core Layer 8 subsystems.

Specifically, the Service Manager coordinates between:

- the Secure Virtual Network Overlay,
- the security guidelines and policies,
- and the declared concurrency model defined by the service SLA.

The Service Manager maintains the Service Participant Peer Registry,
tracking all active instances participating in a service.

When required by the SLA, it performs leader election and manages leadership transitions
transparently.

Leadership is treated as a role, not as an identity, and can move
without changing the service facade.

Through this mechanism,
services remain:

- logically singular,
- operationally distributed,
- and compliant with their declared guarantees.

The Service Manager ensures that service behavior follows intent, **not deployment artifacts**.

---
## Replication Index Service

When a service declares sharding or a replication count as part of its SLA, Layer 8 provides 
a built-in Replication Index Service.

This service tracks and coordinates replication according to the guarantees defined by the SLA.

When replication is enabled, the Replication Index Service is activated automatically.

It maintains a consistent view of:

- which service instances hold replicas,
- how many replicas exist for each Service Item,
- and how replication responsibilities are distributed.

The Replication Index Service works in coordination with:

- the Service Manager,
- the declared concurrency model,
- and the Secure Virtual Network Overlay.

Replication state is not inferred. It is explicitly tracked and enforced.

By externalizing replication coordination into a dedicated service,
Layer 8 avoids embedding replication logic into application code.

Replication is declared.  
The index is maintained.  
Consistency follows the contract.