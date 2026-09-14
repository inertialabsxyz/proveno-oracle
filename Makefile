.PHONY: help check lint test fix build run prove

# The Noir circuit lives in the proveno-zk repository. Point this at a checkout
# of it to use --prove; the orchestrator links proveno-noir as a library, so
# only the circuit directory itself has to be on disk.
CIRCUIT_DIR ?= ../proveno-zk/noir

help:
	@echo "proveno-oracle — the programmable-oracle application (TLS provenance,"
	@echo "                 LLM orchestrator, demo server)"
	@echo
	@echo "  check          CI gate: lint + test"
	@echo "  lint           cargo fmt --check + cargo clippy -D warnings"
	@echo "  test           all tests"
	@echo "  fix            auto-format + apply safe clippy fixes"
	@echo "  build          cargo build --workspace"
	@echo "  run TASK=...   run the orchestrator on a natural-language task"
	@echo "  prove TASK=... same, but generate a Noir proof"
	@echo
	@echo "  Core runtime tests are in proveno-core; the proving pipelines"
	@echo "  (test-prove, prove-openvm, prove-examples) are in proveno-zk."
	@echo
	@echo "  prove needs a proveno-zk checkout for the circuit:"
	@echo "    make prove TASK=\"...\" CIRCUIT_DIR=../proveno-zk/noir"
	@echo "  Both need ANTHROPIC_API_KEY."

check: lint test

lint:
	cargo fmt --check
	cargo clippy --workspace -- -D warnings

test:
	cargo test --workspace

fix:
	cargo fmt --all
	cargo clippy --workspace --fix --allow-dirty --allow-staged

build:
	cargo build --workspace

run:
	@test -n "$(TASK)" || { echo 'usage: make run TASK="<task>"'; exit 2; }
	cargo run -p proveno-orchestrator -- "$(TASK)"

prove:
	@test -n "$(TASK)" || { echo 'usage: make prove TASK="<task>"'; exit 2; }
	@test -d "$(CIRCUIT_DIR)" || { \
	  echo "circuit not found at $(CIRCUIT_DIR)"; \
	  echo "clone proveno-zk alongside this repo, or set CIRCUIT_DIR"; exit 2; }
	cargo run -p proveno-orchestrator -- "$(TASK)" --prove --circuit-dir "$(CIRCUIT_DIR)"
