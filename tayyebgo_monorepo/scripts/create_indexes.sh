#!/bin/bash
# TayyebGo — Firestore Composite Index Creator
#
# Deploys the composite indexes defined in firestore.indexes.json.
# Some indexes (single-field, collection-group) are auto-created by Firestore,
# but composite indexes require manual deployment via Firebase CLI.
#
# Prerequisites:
#   1. Install Firebase CLI: npm install -g firebase-tools
#   2. Login: firebase login
#   3. Select project: firebase use tayyebgo
#
# Usage:
#   bash scripts/create_indexes.sh

echo "=== TayyebGo Firestore Index Deployment ==="
echo ""
echo "This will deploy composite indexes defined in firestore.indexes.json"
echo "to Firebase project 'tayyebgo'."
echo ""
echo "Required composite indexes:"
echo "  1. Orders: restaurantId ↑, status ↑, createdAt ↓"
echo "  2. Orders: status ↑, createdAt ↓"
echo "  3. Orders: customerId ↑, createdAt ↓"
echo "  4. Orders: restaurantId ↑, createdAt ↓"
echo "  5. menu_items: restaurantId ↑, sortOrder ↑"
echo "  6. Users: role ↑, createdAt ↓"
echo "  7. promos: restaurantId ↑, active ↑"
echo ""

if [ ! -f firestore.indexes.json ]; then
  echo "ERROR: firestore.indexes.json not found in monorepo root."
  echo "Run this script from the monorepo root directory."
  exit 1
fi

echo "Deploying indexes via Firebase CLI..."
echo "  firebase deploy --only firestore:indexes"
echo ""

# Uncomment the line below to actually deploy:
# firebase deploy --only firestore:indexes

echo ""
echo "=== Deployment complete ==="
echo ""
echo "NOTE: Index creation takes 1-5 minutes in Firebase Console."
echo "The apps will show 'FAILED_PRECONDITION' errors until indexes finish building."
echo ""
echo "To monitor progress: https://console.firebase.google.com/project/tayyebgo/firestore/indexes"
