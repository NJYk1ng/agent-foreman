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

```bash
git clone https://github.com/NJYk1ng/agent-foreman
cd agent-foreman
./install.sh
```

It routes each skill to the side that owns it — `agent-contract` goes to both,
`execute-plan` only to Claude Code, `tech-lead` / `cross-review` only to Codex.

```bash
./install.sh --dry-run     # say what it would do, touch nothing
./install.sh --force       # overwrite existing
./install.sh --uninstall   # remove what this repo installed
```

**`notify-lead` is installed globally too** (into `~/.local/bin`) — it runs from anywhere inside a
project and walks up to find `.foreman/`. So **a new project needs nothing**.

**Optional: give the project its own instructions** (useful when someone clones it without the global install):

```bash
./install.sh --project ~/code/my-project
```

| File | For | What it does |
|---|---|---|
| `AGENTS.md` | Codex | **read automatically at session start** — tells it "you are the lead" and that it must **ask before acting when woken automatically** |
| `CLAUDE.md` | Claude Code | a one-line `@AGENTS.md` forward (**single source of truth — two copies drift**) |

> ⚠️ **It never overwrites or deletes a file it did not put there.** Projects often already have
> their own `AGENTS.md` / `CLAUDE.md` — on a mismatch it refuses and tells you which line to add
> by hand; uninstall only removes files byte-identical to this repo's.

### The three layers of "the agent knows who it is"

| Installed at | File | When it takes effect |
|---|---|---|
| **global** (`install.sh`) | `~/.claude/CLAUDE.md` / `~/.codex/AGENTS.md` | ⭐ **from the first word** — any project, as long as it has `.foreman/` |
| project (`--project`, optional) | `AGENTS.md` / `CLAUDE.md` | makes the project **self-describing** — useful for a clone without the global install |
| **global** (`install.sh`) | `~/.local/bin/notify-lead` | the crew runs it to wake the lead — **a new project needs no setup** |

**Why all three**: the global layer gives the agent its role; the project layer pins the details
into the repo (they travel with git, so anyone who clones gets them); the script layer automates
the handoff. Any two would work, but it drifts more easily.

> ⚠️ **The two harnesses share a skill format, but do not sync automatically.**
> Measured: a skill placed only in `~/.claude/skills/` is invisible to Codex, and vice versa.
> Each skill must be installed on the side that owns it.

### ⭐ Install once, and both sides know who they are

`./install.sh` also writes a role note into **each side's global memory**:

| Written into | Content |
|---|---|
| `~/.claude/CLAUDE.md` | what the crew does — and **what it must not do** |
| `~/.codex/AGENTS.md` | what the lead does — and **what it must not do** |

```
Does:    follow .foreman/PLAN.md, verify each check, write STATUS.md
Doesn't: ❌ write PLAN/REVIEW
         ❌ mark a [现场] check ✅ (you cannot verify it)
         ❌ write UNVERIFIED as DONE
         ❌ substitute a caveat for a verification
```

**It does not replace those files — it inserts between a pair of markers**, leaving everything you
already had **untouched** (backed up first; `--uninstall` restores byte-for-byte). The block opens
with "look for `.foreman/` at the project root; if it is not there, ignore this entirely", so
**your other projects are unaffected**.

> 📌 **This layer is the point.** Skills fire only when something matches them; a project-level
> `AGENTS.md` must be placed in every project. **Only global memory makes an agent know its role
> and its limits from the first word.**

> ⚠️ Paths: Claude Code reads `~/.claude/CLAUDE.md`; Codex reads
> `` ${CODEX_HOME:-~/.codex}/AGENTS.md `` (that is the file behind Codex's own
> `Failed to read global AGENTS.md instructions from ...` message).

**Alternative: install with [cc-switch](https://github.com/farion1231/cc-switch).** Its skill table
carries `enabled_claude` / `enabled_codex` columns and does the same routing, plus content hashes
and an update channel. If you already use cc-switch, add this repo as a skill source and tick the
sides you want — no `install.sh` needed.

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

In your project repository, **open two terminals** (one `codex`, one `claude`), both at the repo root.

**1 · The lead plans.** In Codex:

```
$tech-lead  <describe what you want, in your own words>
```

It writes `.foreman/PLAN.md` — a task list where **every task carries falsifiable acceptance
checks** (a command, an observable fact, or an on-site step with its pass criterion written out),
and where the hard tasks are marked for the lead to write personally.

> ⚠️ **Commit only after this step** — `.foreman/` needs a file in it first:
> ```bash
> git add .foreman && git commit -m "chore: init agent-foreman contract"
> ```
> (Git does not track empty directories, so `mkdir` followed by `git add` does not work.)

**2 · The crew builds.** In Claude Code:

```
/execute-plan
```

It reads `PLAN.md`, implements, **runs every acceptance check and pastes the real output** into
`.foreman/STATUS.md`, and stops where the plan stops.

**3 · ⭐ The crew wakes the lead — you paste nothing.**

When the crew finishes `STATUS.md` it runs `notify-lead`, which **pushes "your turn" into the
running Codex session**. Codex wakes up — you never walk over and type a prompt.

Its **first act is not to work; it is to ask you**:

```
The crew handed in .foreman/STATUS.md: T1 is UNVERIFIED, AC1 passed, AC2–AC4 await your on-site check.
Shall I review now?
```

It only starts once you say yes. **That is the "anything that spends lead quota goes through a
human" gate** — moved from *you launch it* to *it comes and asks you*. The gate is unchanged;
your hands are free.

> 📌 How: Codex has no "file changed → start a turn" facility (its inotify watches config files
> only, and its hook events include no file-change event). But it does have `codex queue` —
> **you can push a message into a running session from outside.** `notify-lead` wraps it.
> Measured: queueing a message into an idle TUI starts a turn.
> See the comments in [`scripts/notify-lead.sh`](scripts/notify-lead.sh).

**4 · The lead reviews.** Once you say yes, it checks the diff against the acceptance checks and
writes `.foreman/REVIEW.md` with findings graded P0–P3. Nothing counts as done because an agent
said so.

**5 · Nudge the crew.** When the lead finishes reviewing, the crew is parked. Switch to the
crew's terminal and **press ↑ then Enter**.

**Why you nudge here instead of it waking itself**: see
[Why we did not use hooks](#-why-we-did-not-use-hooks) — every mechanism that auto-wakes Claude
Code is either **silently self-disabling** or requires **reverse-engineering an internal
protocol**. The nudge costs two seconds and buys you a workflow that **never quietly breaks.**

(The crew needs no briefing on what the lead said — its global memory says "when you are called,
read `.foreman/` first"; it works out from `REVIEW.md` whether it was bounced or approved.)

**6 · If the crew gets stuck**, it writes `.foreman/BLOCKED.md` — what it tried, what it needs. You
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

**Pre-alpha.** The contract, the four skills, and "the crew wakes the lead when it is done" all work.

- [x] Contract design — [`docs/contract.md`](docs/contract.md)
- [x] All four skills: `agent-contract` (both) + `execute-plan` (crew) + `tech-lead`, `cross-review` (lead)
- [x] `install.sh` — routes each skill to its side; **writes both global memories (install once, both know who they are)**; `--project` drops the collaboration files into a project
- [x] **The crew wakes the lead automatically** — `notify-lead.sh` (via `codex queue`) + `AGENTS.md`/`CLAUDE.md` templates
- [x] ~~The lead wakes the crew~~ — **two routes evaluated, both dropped**: file watching has a silent `cd` bug, the socket needs an internal protocol reversed. **Replaced by "nudge the crew"** — see below
- [ ] Measured comparison: same tasks, lead-led vs. single-agent, on cost and defect escape rate

### ⚠️ Why we did not use hooks

The original plan was hooks for automatic handoff (Claude Code's `Stop`, Codex's `stop`).
**We measured, then dropped it.** Recorded here so nobody has to walk the same path:

1. **Codex project hooks sit behind two trust gates** — project trust plus a **per-hook hash
   trust**. An unreviewed hook is **skipped silently, with no message**
   ([#48715](https://github.com/openai/codex/issues/48715)). User-level hooks skip that gate but
   then apply globally.
2. **`codex exec` does not run hooks at all** — only the interactive TUI does.
3. **Claude Code's `FileChanged` + `asyncRewake` really can start a turn** — measured on
   v2.1.301: the hook fires, the project-level `.claude/settings.json` is loaded, and both the
   `matcher` (a filename in the current directory) and absolute `watchPaths` from `SessionStart`
   work. ⚠️ **But it has a fatal bug, reproduced here**: the watch is **silently disarmed after any
   `cd`** ([#95440](https://github.com/anthropics/claude-code/issues/95440)).

   Measured side by side (same settings, same watched file):

   | Session | Ran a `cd`? | Hook fired |
   |---|---|---|
   | A | no | ✅ 3 times |
   | B | yes (marker file proves it) | ❌ **not once** |

   And every step an agent takes runs a `cd` ⇒ **dead the moment work starts, with no message.**

4. **We also tried a cleaner route**: each Claude Code session has a unix socket
   (`/run/user/<uid>/cc-socks/<pid>.sock`; `claude agents --json` lists sessions and their pids),
   which in principle allows pushing a message in from outside, symmetric to `codex queue`.
   **But its protocol is internal and undocumented** (custom headers like `from="…"` plus a 32-hex
   token), and anything reverse-engineered from it **can silently break on the next update.**
   ⇒ Not worth it for a feature that might quietly stop working. **Dropped.**
4. Working around it by having the hook `sleep` until it is your turn does work, but the cost is a
   terminal that **looks frozen**, where a stuck state and a dead one are hard to tell apart.

⇒ Instead: **the crew runs one command that pushes a message into the lead's session**
(`codex queue`, measured to wake an idle TUI). No daemon, no hooks, no extra trust step.
**The gate is still there — it just asks you now.**

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). The most useful
thing you can send right now is a **failure case**: a task where the division of labor made
things worse.

## License

Apache-2.0 — see [LICENSE](LICENSE).
