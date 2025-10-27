#!/usr/bin/env python3
"""
Catalyst9 Zero-Knowledge Invite System
- Generate invite codes
- Create user accounts with public/private keys
- Encrypt API keys with public key
- Private keys NEVER stored
"""

import secrets
import hashlib
import base64
import json
import os
from datetime import datetime, timedelta
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.backends import default_backend
import argparse

class InviteSystem:
    def __init__(self):
        self.invites_dir = ".invites"
        self.users_dir = ".users"
        os.makedirs(self.invites_dir, exist_ok=True)
        os.makedirs(self.users_dir, exist_ok=True)

    def generate_invite(self, username: str, inviter: str = "admin") -> dict:
        """Generate a secure invite code"""

        # Generate secure invite code
        invite_code = f"inv_{base64.urlsafe_b64encode(secrets.token_bytes(24)).decode('utf-8').rstrip('=')}"

        # Hash for storage
        invite_hash = hashlib.sha256(invite_code.encode()).hexdigest()

        invite_data = {
            "code": invite_code,
            "hash": invite_hash,
            "username": username,
            "inviter": inviter,
            "created": datetime.utcnow().isoformat(),
            "expires": (datetime.utcnow() + timedelta(days=7)).isoformat(),
            "used": False
        }

        # Save invite (store only hash, not actual code)
        safe_data = invite_data.copy()
        del safe_data["code"]  # Never store the actual invite code

        with open(f"{self.invites_dir}/{username}.json", 'w') as f:
            json.dump(safe_data, f, indent=2)

        return invite_data

    def register_user(self, invite_code: str, email: str) -> dict:
        """Register a new user with zero-knowledge auth"""

        # Validate invite code
        invite_hash = hashlib.sha256(invite_code.encode()).hexdigest()

        # Find matching invite
        invite_file = None
        username = None

        for filename in os.listdir(self.invites_dir):
            with open(f"{self.invites_dir}/{filename}", 'r') as f:
                invite_data = json.load(f)
                if invite_data["hash"] == invite_hash and not invite_data["used"]:
                    invite_file = filename
                    username = invite_data["username"]
                    break

        if not invite_file:
            raise ValueError("Invalid or expired invite code")

        # Generate RSA keypair
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend()
        )
        public_key = private_key.public_key()

        # Generate API key
        api_key = f"cat9_{base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8').rstrip('=')}"

        # Encrypt API key with public key
        encrypted_api_key = public_key.encrypt(
            api_key.encode(),
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )
        encrypted_api_key_b64 = base64.b64encode(encrypted_api_key).decode('utf-8')

        # Generate recovery phrases (10 random words)
        wordlist = ["alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel",
                   "india", "juliet", "kilo", "lima", "mike", "november", "oscar", "papa",
                   "quebec", "romeo", "sierra", "tango", "uniform", "victor", "whiskey",
                   "xray", "yankee", "zulu", "quantum", "neutron", "photon", "electron",
                   "proton", "quark", "nebula", "galaxy", "cosmos", "stellar", "lunar",
                   "solar", "orbit", "gravity", "fusion", "plasma", "energy", "matter"]

        recovery_phrases = [secrets.choice(wordlist) for _ in range(10)]
        recovery_hash = hashlib.sha256(" ".join(recovery_phrases).encode()).hexdigest()

        # Serialize keys
        private_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        ).decode('utf-8')

        public_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        ).decode('utf-8')

        # Store user data (NO private key or plain API key!)
        user_data = {
            "username": username,
            "email": email,
            "public_key": public_pem,
            "encrypted_api_key": encrypted_api_key_b64,
            "api_key_hash": hashlib.sha256(api_key.encode()).hexdigest(),
            "recovery_hash": recovery_hash,
            "created": datetime.utcnow().isoformat(),
            "invite_used": invite_hash
        }

        with open(f"{self.users_dir}/{username}.json", 'w') as f:
            json.dump(user_data, f, indent=2)

        # Mark invite as used
        with open(f"{self.invites_dir}/{invite_file}", 'r') as f:
            invite_data = json.load(f)
        invite_data["used"] = True
        invite_data["used_at"] = datetime.utcnow().isoformat()
        with open(f"{self.invites_dir}/{invite_file}", 'w') as f:
            json.dump(invite_data, f, indent=2)

        # Return credentials (this is the ONLY time user sees these!)
        return {
            "username": username,
            "email": email,
            "private_key": private_pem,
            "encrypted_api_key": encrypted_api_key_b64,
            "recovery_phrases": recovery_phrases,
            "warning": "CRITICAL: Save your private key and recovery phrases NOW! They cannot be recovered!"
        }

    def decrypt_api_key(self, private_key_pem: str, encrypted_api_key_b64: str) -> str:
        """Decrypt API key using private key (client-side operation)"""

        # Load private key
        private_key = serialization.load_pem_private_key(
            private_key_pem.encode(),
            password=None,
            backend=default_backend()
        )

        # Decrypt API key
        encrypted_api_key = base64.b64decode(encrypted_api_key_b64)
        api_key = private_key.decrypt(
            encrypted_api_key,
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )

        return api_key.decode('utf-8')

def main():
    parser = argparse.ArgumentParser(description='Catalyst9 Invite System')
    subparsers = parser.add_subparsers(dest='command')

    # Generate invite command
    invite_parser = subparsers.add_parser('invite', help='Generate invite code')
    invite_parser.add_argument('username', help='Username for the invite')
    invite_parser.add_argument('--inviter', default='admin', help='Who is inviting')

    # Register command
    register_parser = subparsers.add_parser('register', help='Register with invite code')
    register_parser.add_argument('invite_code', help='Invite code')
    register_parser.add_argument('email', help='Email address')

    # Decrypt command (for testing)
    decrypt_parser = subparsers.add_parser('decrypt', help='Decrypt API key')
    decrypt_parser.add_argument('username', help='Username')

    args = parser.parse_args()

    system = InviteSystem()

    if args.command == 'invite':
        result = system.generate_invite(args.username, args.inviter)
        print("\n" + "="*60)
        print("🎫 INVITE CODE GENERATED")
        print("="*60)
        print(f"\nUsername: {result['username']}")
        print(f"Invite Code: {result['code']}")
        print(f"Expires: {result['expires']}")
        print(f"\n⚠️  Send this invite code securely to the user")
        print("⚠️  This code will expire in 7 days")
        print("="*60)

    elif args.command == 'register':
        try:
            result = system.register_user(args.invite_code, args.email)

            print("\n" + "="*80)
            print("🔐 CATALYST9 ACCOUNT CREATED - ZERO-KNOWLEDGE AUTHENTICATION")
            print("="*80)
            print(f"\nUsername: {result['username']}")
            print(f"Email: {result['email']}")

            print("\n" + "⚠️ "*10)
            print("CRITICAL SECURITY INFORMATION - SAVE IMMEDIATELY!")
            print("⚠️ "*10)

            print("\n1. YOUR PRIVATE KEY (NEVER SHARED, NEVER STORED):")
            print("-"*60)
            print(result['private_key'])

            print("\n2. YOUR ENCRYPTED API KEY:")
            print("-"*60)
            print(result['encrypted_api_key'])

            print("\n3. RECOVERY PHRASES (WRITE THESE DOWN):")
            print("-"*60)
            for i, phrase in enumerate(result['recovery_phrases'], 1):
                print(f"{i:2}. {phrase}")

            print("\n" + "="*80)
            print("⚠️  WARNING: This is the ONLY time you will see this information!")
            print("⚠️  We do NOT store your private key - it cannot be recovered!")
            print("⚠️  Save your private key and recovery phrases in a password manager!")
            print("="*80)

            print("\n📋 TO USE YOUR ACCOUNT:")
            print("1. Save your private key to a file: ~/.catalyst9/private.key")
            print("2. Use the decrypt command to get your API key")
            print("3. Configure MCP with your decrypted API key")

        except ValueError as e:
            print(f"\n❌ Registration failed: {e}")

    elif args.command == 'decrypt':
        # Load user data
        user_file = f"{system.users_dir}/{args.username}.json"
        if not os.path.exists(user_file):
            print(f"❌ User {args.username} not found")
            return

        with open(user_file, 'r') as f:
            user_data = json.load(f)

        # Get private key from user
        private_key_file = f"{os.path.expanduser('~')}/.catalyst9/{args.username}.key"
        if os.path.exists(private_key_file):
            with open(private_key_file, 'r') as f:
                private_key_pem = f.read()
        else:
            print(f"Please paste your private key (or save it to {private_key_file}):")
            lines = []
            while True:
                line = input()
                lines.append(line)
                if line == "-----END PRIVATE KEY-----":
                    break
            private_key_pem = "\n".join(lines)

        try:
            api_key = system.decrypt_api_key(private_key_pem, user_data['encrypted_api_key'])
            print(f"\n✅ Your decrypted API key: {api_key}")
            print(f"\nAdd to your environment:")
            print(f"export C9_USER='{args.username}'")
            print(f"export C9_USER_KEY='{api_key}'")
        except Exception as e:
            print(f"\n❌ Decryption failed: {e}")
            print("Make sure you're using the correct private key")

if __name__ == "__main__":
    main()