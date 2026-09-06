# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
#
# Multi-stage build on Chainguard's Wolfi Node images — continuously rebuilt to
# zero known CVEs, minimal (no shell / package managers in the runtime), and
# non-root by default. This is the secure base every service on the paved road
# shares; keep the shape (multi-stage, lockfile install, non-root, exec-form CMD)
# even if the app grows.
#
# Pinned to the :latest / :latest-dev tag AND its digest (Chainguard's free tier
# is :latest-only): the tag lets Renovate track the stream, the digest gives
# reproducibility. Renovate keeps the digest fresh automatically (renovate.json)
# — each bump is a PR the Trivy scan gates, so the base never silently rots.
# The `# hadolint ignore=DL3007` lines are deliberate: pinning a mutable tag is
# safe precisely because the digest is pinned alongside it.

# --- build: install production deps from the committed lockfile (build once).
# hadolint ignore=DL3007
FROM cgr.dev/chainguard/node:latest-dev@sha256:87c646948c4ee39b8b2abcb6e6e77008bedc1cbfec41a0c75ddca1a74ec3b691 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# --- runtime: minimal Chainguard node, non-root (uid 65532), no shell / package managers.
# hadolint ignore=DL3007
FROM cgr.dev/chainguard/node:latest@sha256:3cf2a28e10607bd6758a4e56fbd5580ab9d041f2126e4e79ae50af29f9317f54
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY src ./src
USER 65532
EXPOSE 3000
# The Chainguard node image's ENTRYPOINT is `node`; CMD is the script it runs.
CMD ["/app/src/server.js"]
