#!/bin/bash
# NOMAD GitHub Backup Script
# Usage: ./github-push.sh GITHUB_USERNAME PERSONAL_ACCESS_TOKEN

set -e

USER=$1
TOKEN=$2
REPO_NAME=${3:-"nomad-ai-travel-planner"}

if [ -z "$USER" ] || [ -z "$TOKEN" ]; then
    echo "Usage: $0 <github_username> <personal_access_token> [repo_name]"
    echo ""
    echo "How to get token:"
    echo "1. Go to https://github.com/settings/tokens"
    echo "2. Click 'Generate new token (classic)'"
    echo "3. Select 'repo' scope"
    echo "4. Copy token and run this script"
    exit 1
fi

echo "Creating GitHub repository: $REPO_NAME..."

# Create repo via API
curl -s -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "{\"name\":\"$REPO_NAME\",\"private\":true,\"description\":\"NOMAD AI Travel Planner - Full stack Flutter + Node.js project\"}" \
  https://api.github.com/user/repos

echo ""
echo "Repository created. Pushing code..."

# Add remote and push
cd /root/.openclaw/workspace
git remote remove origin 2>/dev/null || true
git remote add origin "https://$USER:$TOKEN@github.com/$USER/$REPO_NAME.git"
git branch -M main
git push -u origin main

echo ""
echo "Done! Repository pushed to:"
echo "https://github.com/$USER/$REPO_NAME"
echo ""
echo "Next agent can clone with:"
echo "git clone https://github.com/$USER/$REPO_NAME.git"
