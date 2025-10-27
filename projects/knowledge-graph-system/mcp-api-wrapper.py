#!/usr/bin/env python3
"""
MCP API Wrapper for Catalyst9 Knowledge Graph
Connects to the deployed API at catalyst9.ai instead of direct database
"""

import json
import sys
import os
import requests
from typing import Dict, Any, Optional

API_URL = os.environ.get("KG_API_URL", "https://catalyst9.ai")

class MCPAPIWrapper:
    def __init__(self):
        self.api_url = API_URL
        self.session = requests.Session()

    def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle an MCP JSON-RPC request"""
        method = request.get("method", "")
        params = request.get("params", {})
        request_id = request.get("id")

        try:
            if method == "initialize":
                result = self.initialize()
            elif method == "tools/list":
                result = self.list_tools()
            elif method == "tools/call":
                result = self.call_tool(params)
            elif method == "search":
                result = self.search(params)
            else:
                return self.error_response(request_id, -32601, f"Method not found: {method}")

            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": result
            }
        except Exception as e:
            return self.error_response(request_id, -32603, str(e))

    def initialize(self) -> Dict[str, Any]:
        """Initialize the MCP server"""
        return {
            "protocolVersion": "2024-11-05",
            "capabilities": {
                "tools": {},
                "resources": {}
            },
            "serverInfo": {
                "name": "catalyst9-kg-api",
                "version": "1.0.0"
            }
        }

    def list_tools(self) -> Dict[str, Any]:
        """List available tools"""
        return {
            "tools": [
                {
                    "name": "search_knowledge",
                    "description": "Search the knowledge graph",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "query": {
                                "type": "string",
                                "description": "Search query"
                            },
                            "limit": {
                                "type": "integer",
                                "description": "Maximum results",
                                "default": 10
                            }
                        },
                        "required": ["query"]
                    }
                },
                {
                    "name": "add_knowledge",
                    "description": "Add knowledge to the graph",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "content": {
                                "type": "string",
                                "description": "Knowledge content"
                            },
                            "metadata": {
                                "type": "object",
                                "description": "Optional metadata"
                            }
                        },
                        "required": ["content"]
                    }
                }
            ]
        }

    def call_tool(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Call a tool"""
        tool_name = params.get("name")
        args = params.get("arguments", {})

        if tool_name == "search_knowledge":
            return self.search_knowledge(args)
        elif tool_name == "add_knowledge":
            return self.add_knowledge(args)
        else:
            raise ValueError(f"Unknown tool: {tool_name}")

    def search_knowledge(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Search knowledge via API"""
        query = args.get("query", "")
        limit = args.get("limit", 10)

        response = self.session.post(
            f"{self.api_url}/api/v1/search",
            json={"query": query, "limit": limit}
        )

        if response.status_code == 200:
            data = response.json()
            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(data, indent=2)
                    }
                ]
            }
        else:
            raise Exception(f"API error: {response.status_code}")

    def add_knowledge(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Add knowledge via API"""
        content = args.get("content", "")
        metadata = args.get("metadata", {})

        response = self.session.post(
            f"{self.api_url}/api/v1/knowledge/add",
            json={"content": content, "metadata": metadata}
        )

        if response.status_code == 200:
            return {
                "content": [
                    {
                        "type": "text",
                        "text": "Knowledge added successfully"
                    }
                ]
            }
        else:
            raise Exception(f"API error: {response.status_code}")

    def search(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Direct search method"""
        return self.search_knowledge(params)

    def error_response(self, request_id: Any, code: int, message: str) -> Dict[str, Any]:
        """Create an error response"""
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {
                "code": code,
                "message": message
            }
        }

def main():
    """Main entry point for MCP server"""
    wrapper = MCPAPIWrapper()

    # Read from stdin, write to stdout (MCP protocol)
    for line in sys.stdin:
        try:
            request = json.loads(line)
            response = wrapper.handle_request(request)
            print(json.dumps(response))
            sys.stdout.flush()
        except json.JSONDecodeError:
            # Ignore malformed lines
            continue
        except Exception as e:
            error_response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {
                    "code": -32700,
                    "message": f"Parse error: {e}"
                }
            }
            print(json.dumps(error_response))
            sys.stdout.flush()

if __name__ == "__main__":
    main()