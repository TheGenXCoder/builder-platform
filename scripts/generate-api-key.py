#!/usr/bin/env python3
"""
Generate cryptographically secure API keys for Catalyst9
"""

import secrets
import hashlib
import base64
import sys
import json
from datetime import datetime

def generate_api_key(username: str) -> dict:
    """Generate a secure API key for a user"""

    # Generate 32 bytes of random data (256 bits)
    random_bytes = secrets.token_bytes(32)

    # Add user context (but not predictably)
    context = f"{username}:{datetime.utcnow().isoformat()}:{secrets.token_hex(8)}"
    context_hash = hashlib.sha256(context.encode()).digest()

    # Combine for final key material
    key_material = hashlib.sha256(random_bytes + context_hash).digest()

    # Create the API key (URL-safe base64)
    api_key = base64.urlsafe_b64encode(key_material).decode('utf-8').rstrip('=')

    # Create a key hash for database storage (never store plain keys!)
    key_hash = hashlib.sha256(api_key.encode()).hexdigest()

    return {
        "username": username,
        "api_key": f"cat9_{api_key[:48]}",  # Prefix for identification
        "key_hash": key_hash,  # Store this in DB, not the key
        "created": datetime.utcnow().isoformat(),
        "note": "SAVE THIS KEY - it cannot be recovered!"
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: python generate-api-key.py <username>")
        sys.exit(1)

    username = sys.argv[1]
    key_data = generate_api_key(username)

    print("\n" + "="*60)
    print(f"API Key Generated for: {username}")
    print("="*60)
    print(f"\nAPI Key: {key_data['api_key']}")
    print(f"\nDatabase Hash: {key_data['key_hash']}")
    print(f"\nCreated: {key_data['created']}")
    print(f"\n⚠️  {key_data['note']}")
    print("="*60)

    # Also save to a secure file
    filename = f".credentials/catalyst9-{username}-{datetime.now().strftime('%Y%m%d')}.json"
    print(f"\nSaving to: {filename}")

    import os
    os.makedirs(".credentials", exist_ok=True)
    with open(filename, 'w') as f:
        json.dump(key_data, f, indent=2)

    print("✅ Done")

if __name__ == "__main__":
    main()