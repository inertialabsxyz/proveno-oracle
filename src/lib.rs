//! The agent layer for proveno: turning a task into a verifiable execution.
//!
//! The bulk of this repository is the orchestrator, which takes a
//! natural-language task, has an LLM write a Lua program for it, runs that
//! program on the core runtime, and can prove the result.
//!
//! This crate itself currently holds one module: [`tls`], a provenance
//! provider that captures and verifies TLS certificate chains and encodes them
//! into the opaque attestation blobs the runtime carries. Provenance is a
//! pluggable boundary (`HostInterface::take_attestation`), so if more providers
//! land this is the piece most likely to move to a repository of its own.
// The TLS module was written inside a `no_std`-capable crate and still uses
// `alloc::` paths. Keep them working rather than churning the source.
extern crate alloc;

pub mod tls;
