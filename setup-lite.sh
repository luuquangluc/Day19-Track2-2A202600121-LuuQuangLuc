#!/usr/bin/env bash
# Lite path: pure Python, in-process Qdrant, SQLite Feast online store.
# No Docker, no GPU, no external services. ~60s on a clean machine.

set -euo pipefail

echo "[lite] Day 19 lightweight setup"
echo "[lite] Stack: fastembed + qdrant-client[memory] + rank-bm25 + feast(sqlite) + FastAPI"
echo

# ── 1. Python ───────────────────────────────────────────────────────────
if command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
  PYTHON_CMD=python3
elif command -v python >/dev/null 2>&1 && python --version >/dev/null 2>&1; then
  PYTHON_CMD=python
else
  echo "[lite] Python 3 not found. Install Python 3.10+."
  exit 1
fi

PY_VER=$($PYTHON_CMD -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "[lite] Python $PY_VER detected using $PYTHON_CMD"

# ── 2. venv ─────────────────────────────────────────────────────────────
if [ ! -d ".venv" ]; then
  if command -v uv >/dev/null 2>&1; then
    echo "[lite] Creating venv with uv (faster)"
    uv venv .venv
  else
    echo "[lite] Creating venv with python -m venv"
    $PYTHON_CMD -m venv .venv
  fi
fi
# shellcheck source=/dev/null
if [ -f ".venv/Scripts/activate" ]; then
  source .venv/Scripts/activate
else
  source .venv/bin/activate
fi

# ── 3. Install deps ─────────────────────────────────────────────────────
if command -v uv >/dev/null 2>&1; then
  uv pip install -r requirements.txt
else
  python -m pip install -U pip
  python -m pip install -r requirements.txt
fi

# ── 4. Convert Jupytext sources to .ipynb ───────────────────────────────
jupytext --to notebook --update notebooks/*.py || jupytext --to notebook notebooks/*.py

# ── 5. .env scaffold ────────────────────────────────────────────────────
[ -f .env ] || cp .env.example .env

# ── 6. Seed corpus + golden set ─────────────────────────────────────────
python scripts/seed_corpus.py

# ── 7. Smoke test ───────────────────────────────────────────────────────
python scripts/verify_lite.py

cat <<EOF

[lite] Done. Activate the venv and continue:

    source .venv/$(if [ "$OS" = "Windows_NT" ]; then echo "Scripts"; else echo "bin"; fi)/activate
    make api       # start FastAPI on :8000
    make lab       # open Jupyter on :8888
    make benchmark # Precision@10 + latency table

Tip: read VIBE-CODING.md before starting NB1 — it tells you what to delegate
to your AI assistant and what to think through yourself.
EOF
