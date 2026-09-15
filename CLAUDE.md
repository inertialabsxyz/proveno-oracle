# CLAUDE.md

Guidance for Claude Code working in **proveno-agent**.

## What this repository is

The agent layer: how a task becomes a verifiable execution. An LLM orchestrator
takes a natural-language task, has a model write a Lua program for it, runs that
program on the core runtime, and can prove the result. Plus a demo server and a
TLS provenance provider.

| Repository | Scope |
|---|---|
| [proveno-core](https://github.com/inertialabsxyz/proveno-core) | Runtime: parser, compiler, bytecode, vm, host, isa, record/replay |
| [proveno-zk](https://github.com/inertialabsxyz/proveno-zk) | Policy, commitments, Noir circuit, OpenVM guest, contracts |
| **proveno-agent** (here) | LLM orchestrator, demo server, TLS provenance |
| [proveno](https://github.com/inertialabsxyz/proveno) | Umbrella: project overview, architecture, trust model |

Core and the proving layer arrive as git dependencies pinned to tags. The
[architecture document](https://github.com/inertialabsxyz/proveno/blob/main/docs/architecture.md)
in the umbrella is the tie-breaker when documents disagree.

**On the name.** This was `proveno-oracle` until September 2026. Proveno is
deliberately *not* an oracle — "oracle" promises data provenance, which is a
provider's job — and the oracle machinery proper (execution policy, the circuit,
the on-chain consumer) is in proveno-zk. Two thirds of this repository is the
agent loop, so the name follows the code.

## Quality Gate

```bash
make check      # lint + test
```

Must pass before every commit.

There is no `test-prove` here. If a change affects what gets proved — the
program hash, canonical serialization, the oracle tape — run `make test-prove`
in a proveno-zk checkout before opening a PR.

## Layout

| Path | Role |
|---|---|
| `src/tls/` | TLS attestation producer: cert-chain verification, and `to_attestation_bytes` |
| `proveno-orchestrator/` | The agent loop. `pipeline.rs` compile/execute/retry, `llm.rs` backends, `prompt.rs` the system prompt and tool catalogue, `tools.rs` the live host, `prove.rs` artifact building |
| `proveno-demo/` | axum server streaming each stage over SSE, with on-chain submission via alloy |
| `examples/` | Task programs and the LangChain comparison scripts |
| `bench/` | Token-count benchmark against OpenAI function calling |
| `policies/` | `OraclePolicy` documents |

## Common Commands

```bash
make run   TASK="<task>"                 # generate a program and run it
make prove TASK="<task>" CIRCUIT_DIR=../proveno-zk/noir
cargo run -p proveno-orchestrator -- "<task>" --prove --backend openvm --openvm-level app
cargo run -p proveno-demo                # the demo server
```

Needs `ANTHROPIC_API_KEY`. An exported-but-empty value shadows `.env`, because
dotenv does not override variables already set; the orchestrator detects this
and says so rather than failing with a 401.

`--backend` is `noir` (default) or `openvm`; `--openvm-level` is `app` or
`stark`. A policy violation surfaces as a runtime error inside the retry loop,
so the model gets a chance to regenerate a compliant program.

**`--prove` needs the Noir circuit, which lives in proveno-zk.** The orchestrator
links `proveno-noir` as a library, so only the circuit directory has to be on
disk; pass it with `--circuit-dir`.

## Available tools

Programs invoke tools via `tool.call(name, args)`:

| Tool | Description |
|---|---|
| `http_get` | GET a URL → `{status, body}` |
| `http_post` | POST JSON to a URL → `{status, body}` |
| `kv_get` / `kv_set` | In-memory key-value store, per process, not persistent |
| `llm_query` | Sub-query the LLM for fuzzy reasoning |
| `time_now` | Current Unix timestamp |

The tool list is **hardcoded twice**: `live_tool_descriptions()` in `tools.rs`
builds what the prompt tells the model, and a `match` in
`impl HostInterface for LiveHost` dispatches. They must be kept in sync by hand;
the only guard is the `live_descriptions_have_all_tools` test.
`ToolCatalogue` in `prompt.rs` is the unwired seam for making this dynamic.

## Provenance

`src/tls/` is a provenance *provider*, one of potentially several. It captures
and verifies certificate chains, then encodes a record into the opaque
attestation blob the runtime carries via `HostInterface::take_attestation`.

The rest of the stack treats attestations as bytes and never interprets them, so
this module is the piece most likely to move to a repository of its own if more
providers land. Keep the boundary honest: **the circuit binds these blobs, it
does not authenticate them.**

No production host currently implements `take_attestation`, so attestations are
empty in practice.

## Known rough edges

- **`demo-*.sh` are not runnable.** They shell out to `proveno-compiler`,
  `proveno-witness` and `proveno-noir` binaries that are now in other
  repositories, and they carried two defects from before the split: a crate
  named `proveno-proveno-orchestrator`, and `demo-noir-e2e.sh` asking for
  `--bin proveno-prover`, which has never existed.
- **`LiveHost` truncates HTTP bodies by byte index** at 1 MiB
  (`body[..MAX_HTTP_BODY]`), which panics if the boundary lands mid-codepoint.
- **The retry loop grows monotonically.** Failed attempts are appended to the
  conversation with no truncation.
