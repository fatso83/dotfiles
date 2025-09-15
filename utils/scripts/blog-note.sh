#!/bin/bash

set -e

ELEVENTY_DIR="$HOME/dev/11ty-blog"
POSTS="${ELEVENTY_DIR}/src/site/notes"

DATE=$(date +"%Y-%m-%d";)

TOPIC="$*"
SLUGIFIED_TOPIC=$(npx --yes slug "$TOPIC")
FILE="$POSTS/$DATE-$SLUGIFIED_TOPIC.md"

cat > "$FILE" << EOF
---
date: $DATE
tags:
    - notes
title: "$TOPIC"
---

my text here
EOF

"${EDITOR:-nano}" "$FILE"

cd "$ELEVENTY_DIR"
git add "$FILE"
git commit -m "Added note on \"$TOPIC\""
git status
echo "Push? (y/N)"
read YESNO
if [[ "$YESNO" =~ [yY] ]]; then
    git push
fi

