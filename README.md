# vectorchord-cnpg

CloudNativePG's PostgreSQL 17 image with the [VectorChord](https://github.com/supervc-stack/VectorChord)
extension, the database image behind a self-hosted Immich.

Published as `ghcr.io/prob3/cloudnative-vectorchord:<postgres>-<vectorchord>`, for example
`17.12-1.1.1`. The tag scheme is the same as
[tensorchord/cloudnative-vectorchord](https://github.com/tensorchord/cloudnative-vectorchord), and
so is the recipe. This repository exists because that one stopped publishing: PostgreSQL 17.12
fixed 47 CVEs on 2026-11-12, and no 17.12 image appeared upstream
([tensorchord/cloudnative-vectorchord#114](https://github.com/tensorchord/cloudnative-vectorchord/pull/114)).
If upstream starts publishing again, switching back is a one-line change in the consumer.

## What differs from upstream

- The CNPG base image is pinned by digest, so every rebuild arrives as a Renovate PR.
- The VectorChord `.deb` is pinned by checksum.
- amd64 only, and PostgreSQL 17 only.
- The image is pushed only after `test.sh` passes. The script starts PostgreSQL with `vchord`
  preloaded, checks the version, and builds and uses a `vchordrq` index.

## Updating

- **PostgreSQL patch releases and base rebuilds**: Renovate updates the `FROM` line, and the
  PR merges itself when the build is green.
- **VectorChord**: by hand. Change the version in both places in the URL and replace the
  checksum with the asset's digest:
  `gh api repos/supervc-stack/VectorChord/releases/tags/<version> --jq '.assets[] | [.name, .digest]'`.
  Check Immich's supported range first.
- **Never move the base from bookworm to trixie as a routine update.** A data directory
  initialised on bookworm's glibc needs its text indexes rebuilt after the glibc change.
