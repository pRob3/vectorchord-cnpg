# CloudNativePG's PostgreSQL 17 with the VectorChord extension, for Immich.
#
# The recipe is tensorchord/cloudnative-vectorchord's, unchanged in substance:
# CNPG's system image plus VectorChord's own .deb. It is rebuilt here because
# tensorchord stopped publishing: PostgreSQL 17.12 shipped on 2026-11-12 with 47
# security fixes and no 17.12 image appeared upstream (tensorchord PR #114).
#
# Three deliberate differences from upstream:
#   - the base is pinned by digest, so every rebuild arrives as a Renovate PR;
#   - the .deb is pinned by checksum, so a replaced release asset fails the build;
#   - amd64 only, which is all the cluster runs.
#
# Stay on bookworm. The running cluster's data directory was initialised on
# bookworm's glibc, and trixie's glibc sorts text differently: moving the base
# would silently invalidate every text index until a REINDEX. That is a planned
# operation, never a patch release.
FROM ghcr.io/cloudnative-pg/postgresql:17.12-system-bookworm@sha256:e33b1b2b10564e7fb29f7e77e58e3e28338fdc81d2c6c78925bdf24ca47a6cd0

# VectorChord is bumped by hand: the version appears twice in the URL, and the
# checksum is the release asset's digest as GitHub reports it,
#   gh api repos/supervc-stack/VectorChord/releases/tags/<version> --jq '.assets[] | [.name, .digest]'
# The workflow reads the version from this URL to name the image tag.
USER root
ADD --checksum=sha256:a48132c8d616c0d52a9811b32f12f88a8f6cc8542d7cc0180c8d0986bfbd03c5 \
    https://github.com/supervc-stack/VectorChord/releases/download/1.1.1/postgresql-17-vchord_1.1.1-1_amd64.deb \
    /tmp/vchord.deb
RUN apt-get install -y --no-install-recommends /tmp/vchord.deb \
 && rm -f /tmp/vchord.deb

USER 26
