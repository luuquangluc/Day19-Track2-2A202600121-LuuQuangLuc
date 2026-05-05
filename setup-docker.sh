#!/usr/bin/env bash
# Full Docker path: Qdrant server + Redis online store + Postgres offline store.
# Same Python venv as lite + the docker extras. ~3-5 min on first run (image pulls).

set -euo pipefail

echo "[docker] Day 19 full Docker setup"
echo "[docker] Stack: Qdrant (server) + Redis + Postgres + bge-m3 embeddings"
echo

# ── 1. Python ───────────────────────────────────────────────────────────
if command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
  PYTHON_CMD=python3
elif command -v python >/dev/null 2>&1 && python --version >/dev/null 2>&1; then
  PYTHON_CMD=python
else
  echo "[docker] Python 3 not found. Install Python 3.10+."
  exit 1
fi

# ── 1. Docker preflight ─────────────────────────────────────────────────
command -v docker >/dev/null 2>&1 || { echo "[docker] Docker not found. Install Docker Desktop first."; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "[docker] Need Docker Compose v2 (bundled with Desktop ≥ 4.x)."; exit 1; }

# ── 2. Bring up services ────────────────────────────────────────────────
docker compose up -d

echo "[docker] Waiting up to 30s for services to become healthy..."
for i in $(seq 1 30); do
  if docker compose ps --format json | grep -q '"Health":"healthy"'; then
    break
  fi
  sleep 1
done

# ── 3. Python venv (same as lite) ───────────────────────────────────────
if [ ! -d ".venv" ]; then
  if command -v uv >/dev/null 2>&1; then
    uv venv .venv
  else
    $PYTHON_CMD -m venv .venv
  fi
fi
# shellcheck source=/dev/null
if [ -f ".venv/Scripts/activate" ]; then
  source .venv/Scripts/activate
else
  source .venv/bin/activate
fi

# ── 4. Install lite + docker extras ─────────────────────────────────────
if command -v uv >/dev/null 2>&1; then
  uv pip install -r requirements.txt -r requirements-full.txt
else
  python -m pip install -U pip
  python -m pip install -r requirements.txt -r requirements-full.txt
fi

jupytext --to notebook --update notebooks/*.py 2>/dev/null || jupytext --to notebook notebooks/*.py

# ── 5. .env for docker mode ─────────────────────────────────────────────
if [ ! -f .env ]; then
  cp .env.example .env
  # Flip the lite defaults to docker — the user can edit afterward.
  sed -i.bak \
    -e 's/^QDRANT_MODE=memory/QDRANT_MODE=server/' \
    -e 's/^EMBEDDING_BACKEND=fastembed/EMBEDDING_BACKEND=bge-m3/' \
    -e 's/^FEAST_ONLINE_STORE=sqlite/FEAST_ONLINE_STORE=redis/' \
    -e 's/^FEAST_OFFLINE_STORE=file/FEAST_OFFLINE_STORE=postgres/' \
    .env
  rm -f .env.bak
fi

# ── 6. Seed corpus + smoke test ─────────────────────────────────────────
python scripts/seed_corpus.py
python scripts/verify_docker.py

cat <<EOF

[docker] Done. Services running:

  Qdrant   → http://localhost:6333  (dashboard)
  Redis    → redis://localhost:6379
  Postgres → postgresql://feast:feast@localhost:5432/feast_offline

Activate the venv and continue:

    source .venv/$(if [ "$OS" = "Windows_NT" ]; then echo "Scripts"; else echo "bin"; fi)/activate
    make api       # start FastAPI on :8000
    make lab       # open Jupyter on :8888

Stop the stack later: docker compose down (state persists)
                  or  docker compose down -v (full reset)
EOF
