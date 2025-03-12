#!/bin/bash

# Array of branches to process
branches=(
  "feature/node-clock-issues"
  "feature/node-filesystem-almost-out-of-files"
  "feature/node-filesystem-almost-out-of-space"
  "feature/node-filesystem-files-filling-up"
  "feature/node-filesystem-space-filling-up"
  "feature/node-high-conntrack-entries"
  "feature/node-network-errors"
  "feature/node-raid-issues"
  "feature/node-exporter-owners"
  "feature/node-exporter-runbooks"
)

# OWNERS file content
OWNERS_CONTENT="# Node Exporter Alert Runbooks Maintainers

reviewers:
- monitoring-team
- node-team

approvers:
- monitoring-team
- node-team"

# Process each branch
for branch in "${branches[@]}"; do
  echo "Processing branch: $branch"
  
  # Checkout the branch
  git checkout "$branch"
  
  # If this is the owners branch, just push it
  if [ "$branch" == "feature/node-exporter-owners" ]; then
    echo "Pushing branch $branch without adding OWNERS file"
    git push -u origin "$branch"
    continue
  fi
  
  # Check if OWNERS file exists
  if [ ! -f alerts/node-exporter/OWNERS ]; then
    echo "Adding OWNERS file to $branch"
    mkdir -p alerts/node-exporter
    echo "$OWNERS_CONTENT" > alerts/node-exporter/OWNERS
    git add alerts/node-exporter/OWNERS
    git commit -m "Add OWNERS file for node-exporter directory"
  else
    echo "OWNERS file already exists in $branch"
  fi
  
  # Push the branch
  echo "Pushing branch $branch"
  git push -u origin "$branch"
done

echo "All branches processed and pushed" 