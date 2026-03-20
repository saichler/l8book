# <div align="center"> Web Server

There is no shortage of web servers in the industry. So why build another one?

**Because Layer 8 requires absolute coherence and zero external dependency.**

Traditional web servers are designed around static endpoints, predefined routes, and tight 
coupling between transport, security, and application logic. They assume APIs are known in advance 
and wired manually.

Layer 8 makes a different assumption.

In Layer 8, services are defined by intent, not by endpoints. APIs are discovered, enforced, 
and exposed dynamically at runtime.

The Layer 8 Web Server is therefore not a generic HTTP engine. It is a first-class architectural component.

It integrates directly with the Security Provider and the AAA system,
allowing services to expose their APIs dynamically, without pre-hardcoded routes, without manual wiring,
and without leaking transport concerns into service design.

Endpoints are not configured. **They emerge.**

The web server becomes an execution surface for service contracts, not a place where application 
logic is embedded.

This preserves coherence across the platform, keeps services decoupled from transport mechanics, 
and ensures that security, identity, and authorization are enforced consistently—by design, 
not by convention.

---
## What the Web Server No Longer Owns

In Layer 8, the Web Server is intentionally constrained.

It does not own responsibilities that traditionally accumulate inside web frameworks and HTTP gateways.

Specifically, the Web Server no longer owns:

- Routing logic
- Application behavior
- API design decisions
- Model semantics
- Security policy
- Session state and concurrency ownership
- Startup ordering and dependency coordination

By removing these responsibilities, the Web Server is reduced to what it must be:  
- **an execution surface for declared contracts.**

---
## Statelessness and Scaling

Because the Web Server owns no application state, no session context, and no service guarantees,
**it is stateless by design.**

All stateful behavior, identity, session continuity, concurrency enforcement, and lifecycle guarantees; 
is owned by the **Security Provider** and the service runtime, as declared in the **Service SLA**.

As a result, scaling the Web Server is purely mechanical. Instances can be added or removed at any time 
without coordination, rebalancing, or warm-up logic.

High availability is achieved through replication, not configuration. Every Web Server instance is 
interchangeable, because nothing inside it needs to be remembered.

---
## Web API in the SLA

In Chapter 10, the Service SLA was introduced as the contract that defines behavior, concurrency, and guarantees.

One aspect was intentionally deferred: how a service exposes its capabilities to the outside world 
through a Web API.

In Layer 8, a service’s internal API and its external Web API are not the same thing.

There is no one-to-one mapping between them.

For that reason, each Service SLA includes a dedicated section that declares the Web APIs the service exposes.

Each Web API entry defines:
- the input model
- the HTTP method
- the response model

An entry represents an externally visible contract, not an implementation detail.

---
## UI Concerns vs Service Guarantees

A Web API is a delivery mechanism, not the source of guarantees.

UI and transport concerns include request formatting, timeouts, retries, pagination, caching, 
and HTTP status conventions.

Service guarantees are defined exclusively by the Service SLA:
- concurrency rules, lifecycle correctness,
- authorization boundaries,
- and observable behavior under load and failure.

The Web Server does not define guarantees. It translates between HTTP and the service runtime. 
Any guarantee a client relies on must originate from the Service SLA and the service itself.

---
## Internal API Service Manager

The Layer 8 Web Server includes an Internal API Service Manager responsible for bridging service contracts 
and web exposure.

Its role is simple and deliberate: to collect the Web API declarations defined in each Service SLA 
and wire them into the web server at runtime.

Services do not register endpoints manually. They publish their Web API declarations when activated.

Likewise, the web server does not assume services already exist. 
**Discovery is symmetric and deterministic.**

**Web APIs are not configured. They are discovered.**

---
## From Request to Service

Request execution in Layer 8 is deliberately uneventful.

- The Web Server validates identity through the Security Provider,
- deserializes JSON into the declared input protobuf,
- translates the HTTP method into a Layer 8 action,
- and forwards the request to the target service.

The service executes under its SLA-defined rules.

- The response is returned as Elements,
- serialized into JSON,
- and delivered to the caller.

Nothing in this flow is application-specific.

**Execution follows contracts. Transport remains an implementation detail.**