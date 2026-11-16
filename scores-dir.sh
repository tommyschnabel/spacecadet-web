#!/bin/sh
# /scores holds the shared high score table; nginx workers write it.
mkdir -p /scores
chown nginx:nginx /scores
[ -f /scores/scores.json ] && chown nginx:nginx /scores/scores.json
exit 0
