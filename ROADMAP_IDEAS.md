# Flipper: Product Opportunities

_Research-backed ideas for what to build next, grounded in the 2025–2026 competitive landscape and the resiliency tooling gaps around Ruby/Rails. Compiled 2026-07._

## Context / TLDR

The feature-flag category converged hard in 2025–2026:

- **Typed/JSON flag values** and **MCP servers** are now universal — Flipper is the only notable tool without either.
- **Metric-guarded rollouts with auto-rollback** became the commercial differentiator (LaunchDarkly Release Guardian, Datadog Feature Flags).
- **Three of seven commercial vendors were acquired by AI/observability companies** in a 9-month window: Statsig → OpenAI ($1.1B), Eppo → Datadog, DevCycle → Dynatrace. The market decided flags + observability is one product.

On the resiliency side, the strongest signal is that teams already hand-build ops tooling **on top of Flipper** (GitLab runbooks, PlanetScale's Sidekiq kill-switch middleware), while the Ruby OSS in that space is largely abandonware.

Because the owner is already building an APM, several items below rank higher than they otherwise would — the APM is the health signal that makes guarded rollouts and auto-tripping kill switches possible natively.

---

## List 1 — Gaps vs other flag platforms (ranked)

### 1. Typed / JSON flag values (multivariate)
The keystone gap. Every competitor — all 7 commercial, all 5 OSS — supports string/number/JSON values; GrowthBook's comparison content explicitly calls Flipper out as the only tool without it. Dynamic config, AI/prompt config, and experimentation all sit downstream of "a flag can return a value, not just a boolean." Biggest lift on the list, but everything else worth wanting in 2027 depends on it. Splits naturally across tiers: typed values in OSS, editing/targeting UI in Pro/Cloud.

### 2. Guarded rollouts with auto-rollback (APM synergy)
**The** frontier feature: LaunchDarkly Release Guardian, Datadog's Feature Flags GA headline (auto-rollback on APM/RUM/SLO signals), Harness Release Monitoring. No Rails-native version exists at any price. Uniquely well-positioned here because the hard part is the health signal — the APM being built produces exactly that. Percentage rollout ramps automatically, the APM watches error rate/latency for the new cohort, and the flag halts or reverts itself on regression. This is what makes flags + APM one product, and it's why Datadog and Dynatrace bought their way into flags.

### 3. Official MCP server
All 12 researched competitors shipped one in ~6 months — novel to table stakes inside 2025. Cheap here: the Cloud API already exists; wrap it with role-scoped tools (list/check/enable-for-actor, guarded by permissions). A local OSS variant that talks to the app's own adapter is the dev-loop version. Low effort, high "Flipper is current" signal, increasingly a checklist item in tool selection.

### 4. OpenFeature provider (+ optional OFREP on Cloud)
OpenFeature is now the category's interop layer — providers exist for essentially everyone but Flipper; Datadog built its product on it; Cloudflare's new flag service is OpenFeature-native. A Ruby provider is a thin gem. Bigger strategic move: an **OFREP-compliant evaluation endpoint** on Cloud makes any OpenFeature SDK in any language a Flipper client — the cheapest answer to "Flipper is Ruby-only" without maintaining 15 SDKs.

### 5. Release orchestration: approvals, change requests, scheduled changes in the UI
LaunchDarkly, Statsig, Harness, and Datadog all have approval workflows; Flipper has none, and it's a hard requirement for regulated buyers. Scheduled changes partially exist via 1.4.0 time-based expressions, but there's no UI affordance ("enable at 9am Tuesday, ramp to 100% by Friday"). Natural Gold/enterprise material.

### 6. SSO/SAML and 2FA on Cloud
Unsexy, but the classic enterprise deal-blocker — docs show neither. Pure sales unblocking for the tier where the money is.

### 7. AI-generated flag-cleanup PRs
Pro already has call sites; Cloud has stale detection — two-thirds of the way to what became the new bar in 2025 (LaunchDarkly Vega, Datadog Bits AI, Statsig). Closing the loop (stale flag + known call sites → behavior-preserving removal PR) is a smaller step here than it was for them.

### 8. Experimentation (deliberately last)
The stats arms race (CUPED, sequential testing, warehouse-native) is a different company, and GrowthBook gives a full stats engine away free — no margin in chasing it. Honest play: lightweight "impact" views on telemetry already collected, plus a documented GrowthBook/PostHog integration path for teams that outgrow that.

---

## List 2 — One step to the side: resiliency tooling (ranked)

Ranked partly by how much each compounds with flags + APM.

### 1. The APM (already being built)
Independently validated as #1 by the flag research: observability became the moat (LaunchDarkly acquired Highlight, Datadog acquired Eppo, Dynatrace acquired DevCycle). Flags wired to health signals is where the category is going.

### 2. Dynamic runtime config
The most validated adjacency — every major flag vendor's second act (Statsig Dynamic Config, LaunchDarkly JSON flags, ConfigCat, Firebase). Ruby incumbent is `rails-settings-cached`: 1,000+ dependents (incl. Mastodon), but no UI, no audit, no targeting, no environments, barely moving. Devs hand-roll Redis singletons for the exact resiliency knobs you'd turn mid-incident because deploying an ENV change takes ~15 minutes. This is List 1 #1 in different clothes: `Flipper.setting(:page_size).value`, per-actor/per-tenant overrides (unserved multi-tenant pain), audit + rollback included. One investment, two product stories.

### 3. Background job control plane
Strongest evidence of unmet demand in the whole study: GitLab runbooks and PlanetScale's published middleware both already implement kill/defer/throttle for Sidekiq jobs **using Flipper**. Queue pausing is paywalled in Sidekiq Pro (~$229/mo), limiters in Enterprise (~$749/mo); OSS gap-fillers (sidekiq-limit_fetch et al.) are unmaintained; Solid Queue explicitly declined rate limiting; no dashboard spans Sidekiq + Solid Queue + GoodJob. Productize what GitLab hand-rolled — per-job-class/per-tenant kill, defer, throttle, gradual re-enable via percentage gates, audit — through ActiveJob/Sidekiq middleware. Wedge: the huge OSS-Sidekiq base that won't pay $749/mo.

### 4. Operational toggles / kill switches as a first-class type
Kill switches are already the top non-release use of flags; the productizable delta is what plain flags lack: auto-trip on error thresholds (APM again), TTL/auto-expiring switches, fail-safe direction + runbook links, and percentage gates as brownout dials ("serve cached homepage to 40% of anonymous traffic"). Unleash is coining "FeatureOps" to claim this; nothing Ruby-native does it. Cheap relative to its story value; reframes Flipper from "release tool" to "production control panel."

### 5. Deploy safety / Kamal integration
Kamal has no canary workflow — kamal-proxy has percentage-rollout code implemented-but-hidden for ~2 years — and 37signals' stated position is that canarying belongs in feature flags (effectively an invitation). Deploy markers + a post-deploy flag guard ("after `kamal deploy`, watch these metrics, auto-halt the rollout flag") largely falls out of List 1 #2 with a Kamal on-ramp.

### 6. Runtime-adjustable rate limiting
Algorithm layer is commoditized (Rails 8 `rate_limit`, rack-attack, Cloudflare), but nobody owns the control plane: per-plan/per-tenant limits adjustable from a dashboard mid-incident, with audit and observability. "Flipper for limits" — and the in-process-gem-plus-sync architecture answers the latency objection that kills hosted rate-limit APIs on HN. Real but narrower than 2–5.

### 7. Circuit breaker visibility (integrate, don't rebuild)
Ruby's breaker gems are mediocre-to-dead (circuitbox stalled since 2023; Semian is powerful but config-driven with no dashboard; Evil Martians wrote in 2025 the category "lacks monitoring and real-time management," with fresh demand from flaky LLM APIs). Nobody offers a hosted breaker control plane. But total market attention is modest — do it as an integration (surface Semian/Stoplight state, alert on open circuits, "when breaker opens, flip flag X"), not a product.

### 8. Maintenance / read-only mode
Incumbent gem (turnout) died in 2018; Kamal now handles the static-page tier. App-aware maintenance — read-only mode, admins-through, scheduled windows — is still hand-rolled, and every DIY version is literally a flag in middleware. Ship `Flipper::Maintenance` as a packaged feature for retention/marketing; a prior hosted-maintenance-mode startup died, so don't make it a product.

### Avoid
- **Chaos engineering for Ruby** — two company-backed gems already died; commercial players deliberately stay at the infra layer.
- **On-call/paging** — crowded, commoditizing, SMS reliability is a different company's problem. (Worth stealing only the small "which flags changed during this incident" view.)

---

## The through-line

List 2 items 2–6 plus guarded rollouts from List 1 converge on one story no Ruby incumbent owns: **the production control panel for Rails** — flags, config, jobs, limits, and deploys, all watched by the APM and all able to react to it. The market decided in 2025 that flags + observability is one product; Flipper is one of very few positioned to build that natively for Rails instead of bolting it on via acquisition.

---

## Appendix: what Flipper Cloud/Pro already ship (so as not to duplicate)

**Pro (self-hosted, early access):** self-hosted dashboard, expressions UI, feature owners, call sites (code scanning w/ editor deep links), audit log (+ Slack), multi-database support, dynamic/large actor sets.

**Cloud (hosted):** environments (production + personal + custom, prod mirroring), 3-level RBAC + trusted domains, longevity/owners/tags, audit history + one-click rollback, telemetry (evaluation metrics, stale detection via telemetry summary), webhooks (HMAC-signed, instant sync), Slack integration, super search (⌘K), REST API, local-sync model.

**Recently shipped (2025–2026):** time-based expressions (1.4.0), smarter ⌘K, Slack integration, extended telemetry timeframes, expressions in Cloud UI, tag picker.

**Confirmed gaps in all tiers:** no SAML/SSO or 2FA, no A/B testing, no UI scheduled/guarded rollouts, no approval workflows, no non-Ruby server SDKs (JS adapter only), no OpenFeature provider, no MCP server, no typed/JSON flag values.
