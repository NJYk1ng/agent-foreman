# agent-foreman

**A senior lead who thinks. A cheap crew that works.**

English · [简体中文](README.md)

Agent skills that turn **Codex** into a tech lead — planning, reviewing, unblocking — and
**Claude Code** into the crew that writes the code, behind whatever model endpoint you choose.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Harnesses](https://img.shields.io/badge/harnesses-Claude%20Code%20%C2%B7%20Codex-orange.svg)](#requirements)
[![Status](https://img.shields.io/badge/status-pre--alpha-red.svg)](#status)

---

## Why

### The harness and the model provider are separable

Claude Code's value is mostly in its **harness** — skills, hooks, subagents, MCP, the terminal
UX. The harness talks to any Anthropic-compatible endpoint. **You can keep the harness and change
the model behind it.**

That decoupling matters because model providers are *not* interchangeable on two axes: **price**
and **availability**.

- **Price.** Frontier subscriptions cost 10–50× a cheap API endpoint per token. Long agent
  sessions are the expensive kind of usage — see below.
- **Availability.** In some jurisdictions, individual providers enforce account terms more
  strictly than others. If your entire workflow is welded to a single provider, that provider's
  availability becomes *your* availability. A workflow you can't run is worth nothing.

### Long sessions cost quadratically, and subscriptions have quota ceilings

Both harnesses are **stateless over HTTP**: every turn resends the entire conversation. A
session's total cost therefore grows with the *square* of its length. In a real session we
measured, `cache_read` accounted for **99%** of all tokens billed — the bulk of the cost is
re-sending context you already sent.

At the same time, subscription plans cap you by **quota** (a rolling window plus a weekly cap),
not by dollars. Once the quota is gone the workflow stops dead — mid-task, at the worst moment.

### So: split the roles by what they need, not by who is smarter

| | Needs | Put your… |
|---|---|---|
| **The lead** | judgment, and a **small** context | safest, strongest **subscription** |
| **The crew** | endurance, and a **large** context | cheapest **endpoint** |

This is also how real engineering teams work. A good tech lead does not write most of the code.
They set direction, decompose the work, review the result — and personally write the 10% that is
genuinely hard.

**agent-foreman** installs that structure into two agents.

---

## How it works

```
                          you
                           │  requirements
                           ▼
              ┌────────────────────────────┐
              │  LEAD  ·  Codex            │
              │  plan · review · unblock   │
              │  small context, quota-safe │
              └─────────────┬──────────────┘
                            │  .foreman/PLAN.md    what to build, with acceptance checks
                            │  .foreman/REVIEW.md  what is wrong, by severity
                            ▼
              ┌────────────────────────────┐
              │  CREW  ·  Claude Code      │
              │  implement · self-test     │
              │  cheap endpoint, long ctx  │
              └─────────────┬──────────────┘
                            │  .foreman/STATUS.md  proof, one line per acceptance check
                            │  .foreman/BLOCKED.md what was tried, what is needed
                            └──────────────►  back to the lead
```

The two agents never share a conversation. They share **files**, in a directory both can read and
write. That is the whole protocol — and it is deliberately boring, because a protocol you can
`cat` is a protocol you can debug.

**Why not real-time chat between agents?** Because both are *turn-based*, not daemons. An agent
mid-turn is not listening. "Real-time" would mean "at the next turn boundary" at best — and every
message you push into a context gets re-sent on every subsequent turn. High-frequency chatter
between two agents inflates cost faster than it produces work. Teams synchronize at **handoff
points**, not continuously.

---

## Related work

**[sno-station-skills](https://github.com/sno-ai/sno-station-skills)** (Apache-2.0) covers
adjacent ground and does it well: cross-vendor peer review, work orders with a written definition
of done, handoff when an agent exhausts its quota. If you run **two premium subscriptions** —
Claude Code *and* Codex, both on paid plans — read it first; it may already be what you want.

agent-foreman is built for a different constraint:

| | sno-station-skills | agent-foreman |
|---|---|---|
| **Cost profile** | assumes two premium subscriptions | **one subscription + a cheap endpoint** |
| **Roles** | interchangeable; either vendor can lead | **fixed and asymmetric**: Codex leads |
| **Quota policy** | automatic handoff when quota runs out | **explicit budget + a human gate** |
| **Footprint** | 31 skills, a CLI installer, a companion app | **4 skills, zero dependencies** |
| **Who writes the hard 10%** | not specified | **the lead, by rule** |

If your situation is "I have one subscription I can rely on, and one cheap API" — that is the gap
this fills.

### Honest limitations

- The claim that Claude Code's harness works *well* with non-Anthropic models is, so far,
  **our own experience**, not a benchmark. Publishing measurements is on the [roadmap](#status).
- The lead role assumes a Codex subscription. The design works with an API key, but the quota
  discipline in `docs/architecture.md` assumes a ceiling rather than a bill.

---

## Requirements

| Requirement | Version | Why |
|---|---|---|
| **Claude Code** | ≥ 2.1 | needs `SKILL.md` support and hooks |
| **Codex CLI** | current (`@openai/codex`) | the lead |
| **Node.js** | ≥ 18.18 | required by the Codex↔Claude Code bridge |
| **git** | any | the contract directory is committed — it is the audit trail |
| A **crew endpoint** | any Anthropic-compatible | DeepSeek, a relay, Anthropic itself, … |

**Accounts** — either works:
- a **ChatGPT subscription** (the bridge works on the free tier too; paid tiers have far larger
  limits), or
- an **OpenAI API key**.

**Optional but recommended:** [`openai/codex-plugin-cc`](https://github.com/openai/codex-plugin-cc)
— the official bridge that lets Claude Code invoke Codex directly. agent-foreman does not require
it (the file contract works without any bridge at all), but it removes a copy-paste step.

---

## Install

Pre-alpha: the layout is still moving. Until `install.sh` lands, install by hand.

```bash
git clone https://github.com/<you>/agent-foreman
cd agent-foreman

# Shared skill — both harnesses read it, so both must have an identical copy
cp -r skills/agent-contract ~/.claude/skills/
cp -r skills/agent-contract ~/.codex/skills/

# The lead's skills
cp -r skills/tech-lead     ~/.codex/skills/
cp -r skills/cross-review  ~/.codex/skills/

# The crew's skill
cp -r skills/execute-plan  ~/.claude/skills/
```

Point your crew harness at a cheap endpoint — in `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://your-endpoint.example.com",
    "ANTHROPIC_AUTH_TOKEN": "<your key>",
    "ANTHROPIC_MODEL": "<your model>"
  }
}
```

> ⚠️ Never commit that file. The token is stored in plaintext.

---

## Quick start

In your project repository:

```bash
mkdir -p .foreman
git add .foreman && git commit -m "chore: init agent-foreman contract"
```

**1 · The lead plans.** In Codex:

```
$tech-lead  <describe what you want, in your own words>
```

It writes `.foreman/PLAN.md` — a task list where **every task carries falsifiable acceptance
checks** (a command, an observable fact, or an on-site step with its pass criterion written out),
and where the hard tasks are marked for the lead to write personally.

**2 · The crew builds.** In Claude Code:

```
/execute-plan
```

It reads `PLAN.md`, implements, **runs every acceptance check and pastes the real output** into
`.foreman/STATUS.md`, and stops where the plan stops.

**3 · The lead reviews.** Back in Codex:

```
$cross-review  .foreman/STATUS.md
```

It checks the diff against the acceptance checks and writes `.foreman/REVIEW.md` with findings
graded P0–P3. Nothing counts as done because an agent said so.

**4 · If the crew gets stuck**, it writes `.foreman/BLOCKED.md` — what it tried, what it needs. You
decide whether to spend lead quota on it. That decision is deliberate: see
[Quota discipline](docs/architecture.md#quota-discipline).

---

## Design

Four skills, one contract:

| Skill | Installed in | Role |
|---|---|---|
| `agent-contract` | **both** | defines the file contract below — the only thing that must be byte-identical on both sides |
| `tech-lead` | Codex | requirements → `PLAN.md` |
| `cross-review` | Codex | diff → `REVIEW.md` |
| `execute-plan` | Claude Code | `PLAN.md` → code + `STATUS.md` |

The contract files, in `.foreman/`:

| File | Written by | Contains |
|---|---|---|
| `PLAN.md` | lead | tasks with goal, owner, dependencies, **acceptance checks**, and boundaries |
| `STATUS.md` | crew | per-check results **with the real command output**, and the commit |
| `BLOCKED.md` | crew | the blocker, what was already tried, the specific decision needed |
| `REVIEW.md` | lead | findings graded P0–P3, plus a check-by-check verdict against `PLAN.md` |

Full specification: [`docs/contract.md`](docs/contract.md).
Design rationale and the quota model: [`docs/architecture.md`](docs/architecture.md).

---

## Status

**Pre-alpha.** Phase 1 (contract + the four skills) is being written now. Phase 2 adds hooks so
that inbound messages surface automatically at turn boundaries — with a human gate on anything
that spends lead quota.

- [x] Contract design
- [ ] `agent-contract`, `tech-lead`, `cross-review`, `execute-plan`
- [ ] `install.sh`
- [ ] Hooks (Claude Code `UserPromptSubmit` / `Stop`; Codex `userPromptSubmit` / `stop`)
- [ ] Measured comparison: same tasks, lead-led vs. single-agent, on cost and defect escape rate

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). The most useful
thing you can send right now is a **failure case**: a task where the division of labor made
things worse.

## License

Apache-2.0 — see [LICENSE](LICENSE).
