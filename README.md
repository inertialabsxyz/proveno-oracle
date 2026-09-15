# proveno-agent

The agent layer for [proveno](https://github.com/inertialabsxyz/proveno): an LLM
orchestrator that writes Lua for a natural-language task, runs it on the core
runtime and can prove the result, plus a demo server and a TLS provenance
provider.

Depends on [proveno-core](https://github.com/inertialabsxyz/proveno-core) and
[proveno-zk](https://github.com/inertialabsxyz/proveno-zk) by git tag.

```bash
export ANTHROPIC_API_KEY=...
make run   TASK="what is the current ETH price in USD"
make prove TASK="..." CIRCUIT_DIR=../proveno-zk/noir
make check
```

## On the name

This repository was `proveno-oracle` until September 2026. Proveno is
deliberately **not** an oracle: "oracle" promises data provenance, which is a
provider's job, not proveno's. The oracle machinery proper — the execution
policy, the Noir circuit, the on-chain consumer — lives in proveno-zk. Two
thirds of this repository is the agent loop, so the name follows the code.

## Caveat

The `demo-*.sh` scripts are **not** currently runnable: they shell out to
binaries that now live in other repositories, and carried two defects from
before the split. See [CLAUDE.md](CLAUDE.md).

## Licence

See [LICENSE](LICENSE).
