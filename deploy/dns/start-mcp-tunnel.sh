#!/bin/bash

# SSH tunnel script for MCP to access remote Knowledge Graph database
echo "Starting SSH tunnel for MCP access to catalyst9.ai..."

# Kill any existing tunnel on port 5433
lsof -ti:5433 | xargs kill -9 2>/dev/null

# Start SSH tunnel (local port 5433 -> remote PostgreSQL 5432)
ssh -N -L 5433:localhost:5432 catalyst@75.163.222.167 &
TUNNEL_PID=$!

echo "SSH tunnel started (PID: $TUNNEL_PID)"
echo "PostgreSQL available at localhost:5433"
echo ""
echo "To stop the tunnel: kill $TUNNEL_PID"
echo "Tunnel PID saved to: ~/.mcp-tunnel.pid"
echo $TUNNEL_PID > ~/.mcp-tunnel.pid

# Keep the script running
echo "Press Ctrl+C to stop the tunnel..."
wait $TUNNEL_PID