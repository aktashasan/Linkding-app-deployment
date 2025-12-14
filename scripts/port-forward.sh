#!/bin/bash

# Port-forward script for accessing Linkding application

set -e

PORT=${1:-9090}

echo "🔗 Starting port-forward to Linkding service on port $PORT..."
echo ""
echo "Access the application at: http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop the port-forward"
echo ""

kubectl port-forward -n linkding service/linkding ${PORT}:80
