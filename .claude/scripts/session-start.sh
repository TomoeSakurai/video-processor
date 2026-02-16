#!/bin/bash
# Session start hook for Claude Code web sessions
# Sets up local development environment automatically

set -e

echo "=== video-processor session start ==="

# 1. Install dependencies if needed
if [ ! -d "node_modules/.pnpm" ]; then
  echo "[1/4] Installing dependencies..."
  pnpm install --frozen-lockfile 2>&1 | tail -5
else
  echo "[1/4] Dependencies already installed"
fi

# 2. Start PostgreSQL if not running
if ! pg_isready -q 2>/dev/null; then
  echo "[2/4] Starting PostgreSQL..."
  sudo pg_ctlcluster 16 main start 2>/dev/null || true
  sleep 1
  if pg_isready -q 2>/dev/null; then
    echo "  PostgreSQL started"
  else
    echo "  WARNING: PostgreSQL failed to start"
  fi
else
  echo "[2/4] PostgreSQL already running"
fi

# 3. Set up backend .env if missing
if [ ! -f "apps/backend/.env" ]; then
  echo "[3/4] Creating backend .env for local development..."
  cat > apps/backend/.env << 'ENVEOF'
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/video_processor"
NODE_ENV=development
PORT=8080
CORS_ORIGIN=*
TEMP_STORAGE_TYPE=local
LOCAL_TEMP_STORAGE_DIR=/tmp/video-processor-cache
BACKEND_URL=http://localhost:8080
ENVEOF
else
  echo "[3/4] Backend .env already exists"
fi

# 4. Create database and apply schema if PostgreSQL is running
if pg_isready -q 2>/dev/null; then
  # Create database if it doesn't exist
  sudo -u postgres psql -lqt 2>/dev/null | grep -q video_processor || {
    echo "[4/4] Creating database..."
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';" 2>/dev/null
    sudo -u postgres psql -c "CREATE DATABASE video_processor;" 2>/dev/null
  }
  echo "[4/4] Applying database schema..."
  pnpm --filter backend db:push 2>&1 | tail -3
else
  echo "[4/4] Skipping database setup (PostgreSQL not available)"
fi

echo "=== Setup complete ==="
echo ""
echo "Available commands:"
echo "  pnpm dev              - Start frontend + backend"
echo "  pnpm lint             - Run linter"
echo "  pnpm typecheck        - Run type checker"
echo "  pnpm test             - Run unit tests"
echo "  pnpm test:integration - Run integration tests"
