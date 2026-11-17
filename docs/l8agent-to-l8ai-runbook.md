# Runbook: switching a project from l8agent to l8ai

l8ai replaces l8agent's per-user AI chat with a scalable chat for people
(direct messages, groups, presence) in which the AI agent, **Tanto (Layer8)**,
is one more participant. The browser side is the l8ui `l8chat` bubble. LLM
providers and profiles live in l8secure and reach the agent through
`ISecurityProvider.LlmProfile`.

Probler was the first adopter. Every step below is what probler needed, and
the troubleshooting table lists every problem that surfaced on its KIND
cluster. Use probler's commits as the worked example:
`cc73b07`, `158883f`, `905df34`, `f8689f9` (probler `main`).

---

## 0. What you are moving to

| l8agent (old) | l8ai (new) |
|---|---|
| one pod `<project>-agent` with its own postgres (`agentdb`), area 120: `AgntChat`, `AgntConvo`, `AgntMsg`, `AgntPrmpt` | five images, area 81: `chat-orm` (own postgres, `chatdb`), `chat` (instances), `chat-router`, `chat-users`, `chat-agent` (Tanto) |
| LLM from a security **credential** (`Credential(LLMCreds, key)`) | LLM from l8secure **providers and profiles** (`/79/LlmProv`, `/79/LlmProf`), selectable per conversation |
| `L8AgentBubble` / `L8AgentBubbleMobile`, AIA section | `L8ChatBubble` / `L8ChatBubbleMobile` (l8ui `l8chat/`), no section |
| agent ran as its own identity | Tanto runs every tool **as the requesting user** (their aaaId), so ScopeView and deny rules apply |
| the agent saw only its own node's services | the agent learns every model → service from the services' web descriptors (cluster-wide) |

Services and endpoints (all in area **81**, l8ai `go/ai/common/defaults.go`):

| Process | Public (web) | Internal |
|---|---|---|
| chat-router | `ChatMsg`, `ChatConv`, `ChatPeer`, `ChatSync` | `ChatIdx`, `ChatReg` |
| chat (instances) | — | `ChatShMsg`, `ChatShCnv`, `ChatShSync` |
| chat-users | `ChatStat`, `ChatGroup` | — |
| chat-orm | — | `ChatMsgDb`, `ChatCnvDb`, `ChatGrpDb`, `ChatStatDb` |
| chat-agent | — | `ChatAgent` |

**Check first:** area 81 must not be used by another service of your project.

---

## 1. Prerequisites (framework versions)

The project must build against these (all on `main`):

- **l8types:** `ISecurityProvider.LlmProfile` / `UserInfo`, `IVNic.Unicast(..., aaaId)`, `IServiceMessageHandler`.
- **l8services:** dispatch to `IServiceMessageHandler`.
- **l8utils:** `aggregator.NewAggregator(vnic, interval, maxSize, timeout)`. Any project code that calls `NewAggregator` with three arguments must add the size cap, e.g. `NewAggregator(vnic, 5, 0, 30)` (0 = time-only, as before).
- **l8secure:** LLM providers/profiles, `UserInfo`, and `AllowedTypes` with `Nodes(false, true)` (`a6c4cd2`).
- **l8ui:** `l8chat/` (`facdd7d` or later).
- **l8ai:** `main`.

The security provider is a Go plugin: **after moving any framework version, rebuild the security image and every service image** (plugin and services must be built against the same package versions).

---

## 2. l8secure: the project's security config (`go/secure/plugin/<project>/<project>.json`)

1. **LLM provider and default profile.** Add `llmProviders` and `llmProfiles` (they seed the `LlmProv` / `LlmProf` services):
   ```json
   "llmProviders": {
     "testllm": {
       "providerId": "testllm", "name": "TestLLM",
       "kind": "L8_LLM_PROVIDER_KIND_OPENAI_COMPATIBLE",
       "baseUrl": "https://llm.example.dev/v1",
       "apiKey": "<API_KEY>",
       "models": [{ "modelId": "gpt-oss-120b", "displayName": "gpt-oss-120b" }]
     }
   },
   "llmProfiles": {
     "default": { "profileId": "default", "name": "Default", "providerId": "testllm",
                  "modelId": "gpt-oss-120b", "isDefault": true }
   }
   ```
   `kind` is `L8_LLM_PROVIDER_KIND_ANTHROPIC` or `L8_LLM_PROVIDER_KIND_OPENAI_COMPATIBLE`. Exactly one profile is the default; the model must be listed by its provider.
2. **Chat database credential.** Under the `postgres` credentials add `chatdb` (same shape as the old `agentdb`: `aside` = user, `yside` = port 5432, `zside` = password). chat-orm starts its own postgres with it.
3. **Roles.** Users who chat need GET/POST/PATCH on the chat types (`ChatConversation`, `ChatMessage`, `ChatPeer`, `ChatSync`, `ChatUserStatus`, `ChatGroup`) and GET on `L8User` (names) and `L8LlmProfile` (profile selector). A wildcard role (probler's `operator`) already covers them; a view-only role can read but not send, heartbeat or mark as read.
4. **e2e:** add a second **writing** user (probler: `operator2`, "Second Operator", role `operator`) for the two-user chat specs.
5. Rebuild the images: `cd l8secure && ./build-images.sh <project> amd64` (or the project's own `k8s/build-images.sh security`), then tag them under the names the project's Dockerfiles use (probler: `saichler/<project>-security:latest`, `saichler/<project>-postgres:latest`).

---

## 3. Remove l8agent

- `go.mod` / `go.sum` / `vendor`: drop `github.com/saichler/l8agent` (re-vendor).
- The agent binary and its deployment (`go/prob/agent/` in probler) and its image from the build scripts.
- The model registration: the four `RegisterType` calls for `L8AgentConversation`, `L8AgentChatMessage`, `L8AgentChatConversation`, `L8AgentPrompt`.
- The web server's `SetServiceTimeout("AgntChat", 120, …)`.
- **Desktop web:** the `l8agent/*.css` / `*.js` includes, the AIA section (`aia/`, `sections/aia.html`, its nav link, `sections.js` mapping, `initializeAia`, the `nsMap` entry), and `L8AgentBubble.init(...)`.
- **Mobile web:** the `l8agent/m/*` includes, `m/js/aia/*`, the AIA entries in the mobile nav configs, and `L8AgentBubbleMobile.init(...)`.
- **e2e:** the AI-agent specs and the `L8Agent*` / `Aia*` entries in the required-globals lists.

---

## 4. Register the l8ai types

In the project's shared model registration (the function its web server calls; probler: `go/prob/common/models/models.go` `Register`):

```go
import l8aicommon "github.com/saichler/l8ai/go/ai/common"
...
l8aicommon.RegisterTypes(res)
```

Do **not** register the LLM types: the security plugin does. The project never imports l8secure.

---

## 5. The five binaries

Each `main.go` only creates resources and the vnic and calls one `Activate`. Probler's versions (`go/prob/chat-*/main.go`, `go/prob/chat/main.go`) can be copied with the project's own resource helper:

```go
// chat-router
router.ActivateRouter(nil, nic)              // github.com/saichler/l8ai/go/ai/router

// chat (instances): flush and release on SIGTERM
instance := chat.ActivateChat(nil, nic)       // .../go/ai/chat
common.WaitForSignal(res)
instance.Shutdown()

// chat-users
users.ActivateUsers(nil, nic)                 // .../go/ai/users

// chat-orm: start the pod's postgres with the chatdb credential, then
orm.ActivateOrm(creds, "chatdb", nic)         // .../go/ai/orm

// chat-agent (Tanto)
agent.CallRegisterModels(res, models.Register) // before the vnic starts
...
agent.ActivateAgent(agent.AgentConfig{
    RegisterTypes: models.Register,          // the same function the web server uses
    SystemPrompt:  "<domain hints: the project's main models>",
    HelpDocs:      helpDocs,                 // embedded help.md ('@help' prompts)
    WebToolsURL:   "https://tools.example.dev", // optional ('@web' prompts)
    MaskingSecret: "<same on every agent replica>", // optional; random if empty
}, nic)
```

`nil` config = the defaults in `go/ai/common/defaults.go` (`NewChatConfig()`).

**Dockerfiles** (probler's `go/prob/chat-*/Dockerfile`): build from `main.go` (plus `help.md` for the agent); the final stage is `<project>-security` for router, chat, users and agent, and `<project>-postgres` for chat-orm. Add the five images to the project's build scripts (`go/build-all-images.sh`, `k8s/build-images.sh`).

The service Dockerfiles resolve every package except `main.go` from GitHub, so push the project's own packages (e.g. the models package) before building the images.

**Every service Dockerfile needs the "@latest" step** right after `go mod tidy` (probler has it; l8erp did not):
```dockerfile
RUN GOPROXY=direct GOPRIVATE=github.com go mod tidy
RUN GOPROXY=direct GOPRIVATE=github.com go get $(go list -m all | awk '/^github.com\/saichler\// && $1 != "github.com/saichler/build" {print $1"@latest"}')
```
Without it, `go mod tidy` keeps the older l8types / l8utils / l8bus versions that the project's (and other modules') `go.mod` pin next to the new l8ai, and the build fails (`UserInfo undefined`, `too many arguments in call to aggregator.NewAggregator`, `does not implement ifs.IVNic (wrong type for method Unicast)`). It is needed in **all** images, not only the chat ones: the security plugin is built from the latest versions, and every service must match it.

---

## 6. Kubernetes

| Workload | Replicas | Notes |
|---|---|---|
| `<project>-chat-orm` | 1 | StatefulSet with `/data` (its postgres) |
| `<project>-chat` | 3 | `terminationGracePeriodSeconds: 30` (flush + release on SIGTERM) |
| `<project>-chat-router` | 2 | one leader, one standby with a full index copy |
| `<project>-chat-users` | 2 | |
| `<project>-chat-agent` | 1–2 | `hostAliases` for LAN-only LLM / web-tools names, if any |

Every workload carries the `NODE_IP` env like the project's other pods. See probler's five manifests for each mode (KIND and baremetal/sharon StatefulSets, local and GKE Deployments).

**KIND:** load the five images in `kind-start.sh`, add them to the readiness wait, and keep the LLM `hostAliases` only when the machine is on their subnet (probler's `kind-start.sh` strips them otherwise, so the pods use the public names).

---

## 7. Web shells

1. Bump the l8ui submodule to a commit with `l8chat/`.
2. **Desktop `app.html`:** CSS `l8ui/shared/layer8-markdown.css`, `l8ui/l8chat/l8chat.css`; JS after the websocket, popup, file-upload and markdown files:
   ```html
   <!-- JS: Chat (l8chat) -->
   <script src="l8ui/l8chat/l8chat-core-api.js"></script>
   <script src="l8ui/l8chat/l8chat-core-store.js"></script>
   <script src="l8ui/l8chat/l8chat-core-live.js"></script>
   <script src="l8ui/l8chat/l8chat-core-actions.js"></script>
   <script src="l8ui/l8chat/l8chat-core-files.js"></script>
   <script src="l8ui/l8chat/l8chat-status.js"></script>
   <script src="l8ui/l8chat/l8chat-sidebar.js"></script>
   <script src="l8ui/l8chat/l8chat-convlist.js"></script>
   <script src="l8ui/l8chat/l8chat-composer.js"></script>
   <script src="l8ui/l8chat/l8chat-thread.js"></script>
   <script src="l8ui/l8chat/l8chat-group-dialog.js"></script>
   <script src="l8ui/l8chat/l8chat-conv-dialog.js"></script>
   <script src="l8ui/l8chat/l8chat-bubble.js"></script>
   <script src="<project>/<project>-chat-config.js"></script>
   ```
3. **Mobile `m/app.html`:** CSS `l8chat.css` + `l8chat/m/l8chat-m.css`; the same core and view scripts (paths `../l8ui/...`), then `l8chat/m/l8chat-m.js`, `l8chat/m/l8chat-bubble-m.js` and the chat config.
4. **Endpoints file** (one file for both shells; l8chat names no service itself):
   ```js
   window.<PROJECT>_CHAT_ENDPOINTS = {
       msg: '/81/ChatMsg', conv: '/81/ChatConv', peer: '/81/ChatPeer', sync: '/81/ChatSync',
       stat: '/81/ChatStat', group: '/81/ChatGroup', users: '/73/users', llmProf: '/79/LlmProf'
   };
   ```
5. **Mount:** desktop `app.js`: `L8ChatBubble.init({ endpoints: <PROJECT>_CHAT_ENDPOINTS });` before `Layer8DWebSocket.init()`. Mobile `app-core.js`: `L8ChatBubbleMobile.init({ endpoints: <PROJECT>_CHAT_ENDPOINTS });` after `Layer8DWebSocket.init()`. A missing endpoint throws at init.
6. **deps-check** (desktop + mobile): `L8ChatApi`, `L8ChatStore`, `L8ChatLive`, `L8ChatSession`, `L8ChatFiles`, `L8ChatStatus`, `L8ChatSidebar`, `L8ChatConvList`, `L8ChatComposer`, `L8ChatThread`, `L8ChatGroupDialog`, `L8ChatConvDialog`, `Layer8Markdown`, plus `L8ChatBubble` (desktop) or `L8ChatMobile`, `L8ChatBubbleMobile` (mobile).
7. The page must be **https or localhost**: the deterministic conversation IDs use `crypto.subtle`.

---

## 8. e2e (Playwright)

- Seeded sessions must set `sessionStorage.currentUser` (the real login does; l8chat reads it).
- Copy probler's `e2e/pages/Chat.ts`, `tests/desktop/28-chat.spec.ts` and `tests/mobile/07-chat.spec.ts`; set the second writing user and its full name in `fixtures/env.ts`; change the Tanto question's count endpoint to a model of the project.
- Regenerate the shell inventory (`npm run inventory`) after the shell changes.

---

## 9. Verify

1. All five chat pods are Running, and the agent's log lists what it learned:
   `catalog: <Model> is served by <Service>/<area>`; the project's main models must be there.
2. API smoke test (as a writing user):
   ```bash
   # create a conversation, read it, post a message, read the sidebar
   POST /<prefix>/81/ChatConv {"conversationId":"<uuid>","peerKind":1,"peerKey":"<userA>|<userB>","title":"smoke"}
   GET  /<prefix>/81/ChatConv   select * from ChatConversation where conversationId=<uuid>
   POST /<prefix>/81/ChatMsg  {"messageId":"<uuid>","conversationId":"<uuid>","body":"hello"}
   GET  /<prefix>/81/ChatPeer   select * from ChatPeer limit 30 page 0
   ```
   (`peerKey` lists the two user IDs in ascending order.)
3. The router logs `router: cold start assigned N conversations` after a restart (persistence works).
4. The chat e2e specs, then the full suite. Tanto's spec asks a counting question and requires the real number.

---

## 10. Troubleshooting (all seen in probler)

| Symptom | Cause | Fix |
|---|---|---|
| Image builds fail with `not enough arguments in call to aggregator.NewAggregator` | a module still calls the 3-argument form | pass the size cap: `NewAggregator(vnic, interval, 0, timeout)` |
| Image builds fail with `UserInfo undefined`, `too many arguments in call to aggregator.NewAggregator` or `does not implement ifs.IVNic (wrong type for method Unicast)` | the Dockerfile has no "@latest" step, so old framework versions are mixed with the new l8ai | add the step from §5 to every Dockerfile |
| Chat writes time out right after a deploy | the router replicas were still activating | retry after they log `chat router activated` |
| `router: no chat instance is available` | an l8ai build older than `c46d187` (services found through `GetParticipants`, which only knows services the asking node hosts) | rebuild against current l8ai (services found through the health records) |
| `router: cold start: … Cannot find active handler for service ChatCnvDb` | an l8ai build older than `368f9aa` (chat ORM in the shared `L8SG` group, whose leader is another ORM node) | rebuild against current l8ai (own group `ChatOrm`) |
| `security: … Nodes: onlyLeafs and onlyRoots cannot both be true` in the agent | l8secure older than `a6c4cd2` | rebuild the security image and all service images |
| Tanto: `dial tcp <LAN ip>:443: no route to host` | `hostAliases` map the LLM to a LAN address the cluster cannot reach | drop the aliases off that LAN (probler's `kind-start.sh` does it automatically) |
| Tanto: "I don't have access to a … model" | the agent's catalog has no entry for it | check the agent log's `catalog:` lines; the model must be registered on the agent (`CallRegisterModels` with the web server's function) and served by a service with web endpoints |
| Tanto answers nothing for 5 minutes, then "could not answer" | the agent never got the turn or never replied | agent log: `ChatAgent: turn …` errors; the LLM profile (`/79/LlmProf`) and the provider's URL and key |
| The bubble shows no user name / sends as nobody | `sessionStorage.currentUser` missing (custom login or test seeding) | set it at login, as l8ui's login does |
| A view-only user cannot send | its role allows GET only | give chatting users POST/PATCH on the chat types (step 2.3) |

---

## 11. Known limits (see the plan, `plans/l8ai-chat-and-agent.md`)

- Attachments offer **Download** only (N8); mobile file transfer goes through `Layer8FileUpload` without the bearer token (N9). FileStore writes to the web node's local disk, so multi-node web deployments need a shared `/data/l8files` volume (Risk A1).
- One chat-orm instance (N1).
- No per-role scoping of chat or user lookup yet (DR26).
