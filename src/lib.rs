//! The programmable-oracle application layer for proveno.
//!
//! Currently one module: [`tls`], a provenance provider that captures and
//! verifies TLS certificate chains and encodes them into the opaque attestation
//! blobs the runtime carries.
// The TLS module was written inside a `no_std`-capable crate and still uses
// `alloc::` paths. Keep them working rather than churning the source.
extern crate alloc;

pub mod tls;
