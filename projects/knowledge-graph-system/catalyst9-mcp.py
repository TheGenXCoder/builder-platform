#!/usr/bin/env python3
"""
Catalyst9 MCP Client - Universal Access
Connect from any machine with proper credentials
"""

import json
import sys
import os
import requests
from typing import Dict, Any, Optional
from datetime import datetime

# Configuration from environment
API_URL = os.environ.get("CATALYST9_API_URL", "https://catalyst9.ai")
USER = os.environ.get("CATALYST9_USER", "anonymous")
API_KEY = os.environ.get("CATALYST9_API_KEY", "")

class Catalyst9MCP:
    def __init__(self):
        self.api_url = API_URL
        self.user = USER
        self.api_key = API_KEY
        self.session = requests.Session()

        # Set authentication header if API key provided
        if self.api_key:
            self.session.headers.update({
                "Authorization": f"Bearer {self.api_key}",
                "X-Catalyst9-User": self.user
            })

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
        """Initialize the MCP server with user info"""
        # Verify authentication if API key provided
        auth_status = "authenticated" if self.api_key else "anonymous"

        return {
            "protocolVersion": "2024-11-05",
            "capabilities": {
                "tools": {},
                "resources": {}
            },
            "serverInfo": {
                "name": "catalyst9-knowledge-graph",
                "version": "1.0.0",
                "user": self.user,
                "authStatus": auth_status
            }
        }

    def list_tools(self) -> Dict[str, Any]:
        """List available tools"""
        tools = [
            {
                "name": "search_knowledge",
                "description": f"Search {self.user}'s knowledge graph",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "Search query"
                        },
                        "scope": {
                            "type": "string",
                            "enum": ["personal", "org", "team", "project", "all"],
                            "description": "Search scope (personal, org, team, project, or all)",
                            "default": "all"
                        },
                        "org": {
                            "type": "string",
                            "description": "Organization to search (e.g., 'uta')",
                            "default": None
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
                "description": f"Add knowledge to {self.user}'s graph",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "content": {
                            "type": "string",
                            "description": "Knowledge content"
                        },
                        "tags": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Tags for categorization"
                        },
                        "visibility": {
                            "type": "string",
                            "enum": ["private", "org", "team", "public"],
                            "description": "Visibility level",
                            "default": "private"
                        },
                        "org": {
                            "type": "string",
                            "description": "Organization slug (e.g., 'uta')",
                            "default": None
                        }
                    },
                    "required": ["content"]
                }
            },
            {
                "name": "list_recent",
                "description": f"List {self.user}'s recent knowledge blocks",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "limit": {
                            "type": "integer",
                            "description": "Number of items",
                            "default": 5
                        }
                    }
                }
            },
            {
                "name": "get_stats",
                "description": f"Get {self.user}'s knowledge graph statistics",
                "inputSchema": {
                    "type": "object",
                    "properties": {}
                }
            }
        ]

        # Add admin tools for specific users
        if self.user in ["bert", "admin"]:
            tools.append({
                "name": "admin_stats",
                "description": "Get system-wide statistics (admin only)",
                "inputSchema": {
                    "type": "object",
                    "properties": {}
                }
            })

        return {"tools": tools}

    def call_tool(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Call a tool"""
        tool_name = params.get("name")
        args = params.get("arguments", {})

        if tool_name == "search_knowledge":
            return self.search_knowledge(args)
        elif tool_name == "add_knowledge":
            return self.add_knowledge(args)
        elif tool_name == "list_recent":
            return self.list_recent(args)
        elif tool_name == "get_stats":
            return self.get_stats(args)
        elif tool_name == "admin_stats" and self.user in ["bert", "admin"]:
            return self.admin_stats(args)
        else:
            raise ValueError(f"Unknown tool: {tool_name}")

    def search_knowledge(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Search knowledge with user context"""
        query = args.get("query", "")
        scope = args.get("scope", "all")
        org = args.get("org", None)
        limit = args.get("limit", 10)

        # Add user context to search
        search_params = {
            "query": query,
            "limit": limit,
            "user": self.user,
            "scope": scope,
            "org": org
        }

        response = self.session.post(
            f"{self.api_url}/api/v1/search",
            json=search_params
        )

        if response.status_code == 200:
            data = response.json()
            scope_desc = f"{org} org" if org else scope
            result_text = f"Search results for '{query}' (scope: {scope_desc}):\n\n"

            if data.get("results"):
                for i, result in enumerate(data["results"], 1):
                    result_text += f"{i}. {result.get('content', 'No content')}\n"
                    if result.get('tags'):
                        result_text += f"   Tags: {', '.join(result['tags'])}\n"
                    result_text += "\n"
            else:
                result_text += "No results found."

            return {
                "content": [
                    {
                        "type": "text",
                        "text": result_text
                    }
                ]
            }
        elif response.status_code == 401:
            raise Exception("Authentication required. Please set CATALYST9_API_KEY")
        else:
            raise Exception(f"API error: {response.status_code}")

    def add_knowledge(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Add knowledge with visibility control"""
        content = args.get("content", "")
        tags = args.get("tags", [])
        visibility = args.get("visibility", "private")
        org = args.get("org", None)

        knowledge_data = {
            "content": content,
            "tags": tags,
            "user": self.user,
            "visibility": visibility,
            "org": org,
            "timestamp": datetime.utcnow().isoformat()
        }

        response = self.session.post(
            f"{self.api_url}/api/v1/knowledge/add",
            json=knowledge_data
        )

        if response.status_code == 200:
            if visibility == "org" and org:
                location = f"{org} organization"
            elif visibility == "team":
                location = "team"
            elif visibility == "public":
                location = "public knowledge base"
            else:
                location = f"{self.user}'s private space"

            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"Knowledge added to {location}.\nVisibility: {visibility}\nTags: {', '.join(tags) if tags else 'none'}"
                    }
                ]
            }
        elif response.status_code == 401:
            raise Exception("Authentication required. Please set CATALYST9_API_KEY")
        else:
            raise Exception(f"API error: {response.status_code}")

    def list_recent(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """List user's recent knowledge blocks"""
        limit = args.get("limit", 5)

        response = self.session.get(
            f"{self.api_url}/api/v1/knowledge/recent",
            params={"limit": limit, "user": self.user}
        )

        if response.status_code == 200:
            data = response.json()
            result_text = f"Recent knowledge for {self.user}:\n\n"

            for i, item in enumerate(data.get("items", []), 1):
                result_text += f"{i}. {item.get('content', '')[:100]}...\n"
                result_text += f"   Added: {item.get('timestamp', 'unknown')}\n\n"

            return {
                "content": [
                    {
                        "type": "text",
                        "text": result_text
                    }
                ]
            }
        else:
            # Fallback for endpoints not yet implemented
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"Recent items for {self.user} (feature coming soon)"
                    }
                ]
            }

    def get_stats(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Get user statistics"""
        response = self.session.get(
            f"{self.api_url}/api/v1/stats/user/{self.user}"
        )

        if response.status_code == 200:
            stats = response.json()
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"""Knowledge Graph Statistics for {self.user}:

Total Blocks: {stats.get('total_blocks', 0)}
Personal: {stats.get('personal_blocks', 0)}
Shared: {stats.get('shared_blocks', 0)}
Tags Used: {stats.get('unique_tags', 0)}
Last Activity: {stats.get('last_activity', 'N/A')}
"""
                    }
                ]
            }
        else:
            # Fallback stats
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"Statistics for {self.user}:\n- Connected to Catalyst9\n- Authentication: {'Yes' if self.api_key else 'No'}"
                    }
                ]
            }

    def admin_stats(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Get admin statistics (restricted)"""
        response = self.session.get(f"{self.api_url}/api/v1/admin/stats")

        if response.status_code == 200:
            stats = response.json()
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"""System Statistics (Admin View):

Total Users: {stats.get('total_users', 0)}
Total Blocks: {stats.get('total_blocks', 0)}
Active Today: {stats.get('active_today', 0)}
Storage Used: {stats.get('storage_gb', 0)} GB
API Calls (24h): {stats.get('api_calls_24h', 0)}
"""
                    }
                ]
            }
        else:
            return {
                "content": [
                    {
                        "type": "text",
                        "text": "Admin statistics require proper authentication"
                    }
                ]
            }

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

    # Show startup info
    if not API_KEY:
        print(f"# Catalyst9 MCP: Running as '{USER}' (no authentication)", file=sys.stderr)
        print("# Set CATALYST9_API_KEY for authenticated access", file=sys.stderr)
    else:
        print(f"# Catalyst9 MCP: Authenticated as '{USER}'", file=sys.stderr)

    client = Catalyst9MCP()

    # Read from stdin, write to stdout (MCP protocol)
    for line in sys.stdin:
        try:
            request = json.loads(line)
            response = client.handle_request(request)
            print(json.dumps(response))
            sys.stdout.flush()
        except json.JSONDecodeError:
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