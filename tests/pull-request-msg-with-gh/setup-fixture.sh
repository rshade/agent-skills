#!/bin/bash
set -euo pipefail

# ── Setup Git Fixture for PR Message Skill ───────────────────────────
#
# Creates a git repo with a feature branch and meaningful commits,
# simulating completed feature work for the PR message skill to
# summarize.

cd /workspace

# Configure git (test-skill.sh may have already done this, but be safe)
git config --global user.email "test@test.local"
git config --global user.name "Test User"
git config --global init.defaultBranch main

# Re-initialize with a clean main branch and initial commit
rm -rf .git
git init
git checkout -b main

# Create initial project files on main
cat > README.md << 'EOF'
# Auth Service

A lightweight authentication service.
EOF

cat > auth.py << 'EOF'
"""Authentication module."""


def validate_token(token: str) -> bool:
    """Check if a token is valid."""
    return token.startswith("Bearer ")
EOF

git add README.md auth.py
git commit -m "feat: initial auth service scaffold"

# Create feature branch with work
git checkout -b feat/add-user-auth

cat > auth.py << 'EOF'
"""Authentication module with user login support."""


def validate_token(token: str) -> bool:
    """Check if a token is valid."""
    return token.startswith("Bearer ")


def authenticate(username: str, password: str) -> dict:
    """Authenticate a user and return session info."""
    if not username or not password:
        raise ValueError("credentials required")
    return {"user": username, "token": "jwt-token-here", "expires": 3600}


def logout(token: str) -> bool:
    """Invalidate a session token."""
    if not validate_token(token):
        raise ValueError("invalid token format")
    return True
EOF

git add auth.py
git commit -m "feat: add user authentication and logout"

cat > tests.py << 'EOF'
"""Tests for authentication module."""
from auth import authenticate, logout, validate_token


def test_authenticate_success():
    result = authenticate("admin", "secret")
    assert result["user"] == "admin"
    assert "token" in result


def test_authenticate_empty_credentials():
    try:
        authenticate("", "secret")
        assert False, "Should have raised"
    except ValueError:
        pass


def test_logout_valid():
    assert logout("Bearer abc123") is True


def test_validate_token():
    assert validate_token("Bearer xyz") is True
    assert validate_token("invalid") is False
EOF

git add tests.py
git commit -m "test: add unit tests for auth module"

echo "[setup] Git fixture created: main + feat/add-user-auth (2 commits ahead)"
git log --oneline --all
