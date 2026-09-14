# proveno-oracle

The programmable-oracle application built on proveno: a TLS provenance
provider, an LLM orchestrator that writes and runs Lua programs, and a demo
server.

Split out of the proveno monorepo. Depends on
[proveno-core](https://github.com/inertialabsxyz/proveno-core) for the runtime
and [proveno-zk](https://github.com/inertialabsxyz/proveno-zk) for proving,
both by git tag.

```bash
make check                      # lint + test
make run   TASK="<task>"        # generate a Lua program and run it
make prove TASK="<task>"        # same, plus a Noir proof
```

Both need `ANTHROPIC_API_KEY`. An exported-but-empty value shadows `.env`,
because dotenv does not override variables already set; the orchestrator
detects this and says so rather than failing with a 401.

## Cross-repo notes

`make prove` needs the Noir circuit, which lives in proveno-zk. The
orchestrator links `proveno-noir` as a library, so only the circuit directory
has to be on disk:

```bash
git clone https://github.com/inertialabsxyz/proveno-zk.git ../proveno-zk
make prove TASK="..." CIRCUIT_DIR=../proveno-zk/noir
```

The `demo-*.sh` scripts are **not** currently runnable. They shell out to
`proveno-compiler`, `proveno-witness` and `proveno-noir` binaries, which now
live in other repositories, and they carried two defects from before the split:
they invoke a crate named `proveno-proveno-orchestrator`, and
`demo-noir-e2e.sh` asks for `--bin proveno-prover`, which has never existed.
Rewriting them against installed binaries is outstanding work.

The core runtime's tests are in proveno-core (`make check`); the proving
pipelines (`test-prove`, `prove-openvm`, `prove-examples`) are in proveno-zk.
