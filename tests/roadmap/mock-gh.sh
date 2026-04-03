#!/bin/bash
# Mock gh CLI for roadmap skill testing.
# Passes prerequisite checks and returns empty data for queries.

case "$*" in
    *--version*)
        echo "gh version 2.60.0 (mock)"
        ;;
    *"auth status"*)
        echo "github.com"
        echo "  ✓ Logged in to github.com account testuser (mock)"
        ;;
    *"issue list"*)
        echo "[]"
        ;;
    *"api"*"milestones"*)
        echo "[]"
        ;;
    *)
        echo "[]"
        ;;
esac
exit 0
