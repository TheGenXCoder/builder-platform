# Catalyst9 Zero-Knowledge Authentication

## Overview

Catalyst9 uses a **zero-knowledge authentication system** where:
- We NEVER store or see your private keys
- API keys are encrypted and only you can decrypt them
- Account recovery uses secure phrases (not passwords)
- Complete privacy - even we can't access your data

## How It Works

### 1. Invitation Phase
```bash
# Admin generates invite code
python3 scripts/invite-system.py invite john --inviter bert

# Output:
# Invite Code: inv_ObNKRSQfDEEJgK7mzaP8EnvHHTla-5ki
```

We store: SHA256 hash of invite code (not the code itself)

### 2. Registration Phase
```bash
# User registers with invite code
python3 scripts/invite-system.py register [invite-code] john@example.com
```

What happens:
1. Generate 2048-bit RSA keypair
2. Generate secure API key
3. Encrypt API key with public key
4. Generate 10 recovery phrases
5. Show ALL credentials (only time!)

We store:
- ✅ Public key
- ✅ Encrypted API key (useless without private key)
- ✅ Hash of recovery phrases
- ❌ Private key (NEVER stored)
- ❌ Plain API key (NEVER stored)

### 3. Using Your Account

```bash
# Save your private key
echo "[private-key]" > ~/.catalyst9/john.key

# Decrypt your API key when needed
python3 scripts/invite-system.py decrypt john

# Configure MCP
export C9_USER='john'
export C9_USER_KEY='[decrypted-api-key]'
```

## Security Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   You Have   │     │  We Store    │     │  We Never    │
│              │     │              │     │    Have      │
├──────────────┤     ├──────────────┤     ├──────────────┤
│ Private Key  │     │ Public Key   │     │ Private Key  │
│ API Key      │     │ Encrypted    │     │ Plain API    │
│ Recovery     │     │   API Key    │     │   Key        │
│   Phrases    │     │ Recovery     │     │ Recovery     │
│              │     │   Hash       │     │   Phrases    │
└──────────────┘     └──────────────┘     └──────────────┘
```

## What This Prevents

### ❌ Database Breach
If our database is stolen, attackers get:
- Encrypted API keys (useless without private keys)
- Public keys (can't decrypt anything)
- Hashes (can't reverse to get original data)

### ❌ Inside Access
Even Catalyst9 admins cannot:
- See your API key
- Decrypt your data
- Recover your account
- Access your private information

### ❌ Password Attacks
No passwords means:
- No password to guess
- No password to phish
- No password to leak
- No password fatigue

## Recovery Process

If you lose your API key but have your private key:
```bash
# Get encrypted API key from us
curl https://catalyst9.ai/api/v1/recovery/encrypted-key \
  -d "username=john"

# Decrypt locally with your private key
python3 scripts/invite-system.py decrypt john
```

If you lose everything but have recovery phrases:
- Contact admin with recovery phrases
- We verify hash matches
- Generate new invite for account reset
- You create new keys

## For Developers

### Generate Invite (Admin Only)
```python
from scripts.invite_system import InviteSystem

system = InviteSystem()
invite = system.generate_invite("newuser", "admin")
print(invite['code'])  # Send securely to user
```

### Register User
```python
result = system.register_user(invite_code, email)
# Returns: private_key, encrypted_api_key, recovery_phrases
# SAVE IMMEDIATELY - shown only once!
```

### Decrypt API Key (Client-Side)
```python
api_key = system.decrypt_api_key(private_key_pem, encrypted_api_key_b64)
```

## Database Schema

```sql
-- Users table (zero-knowledge fields)
users:
  - public_key TEXT          -- RSA public key
  - encrypted_api_key TEXT   -- Encrypted with public key
  - recovery_hash VARCHAR    -- SHA256 of phrases
  - registration_method      -- 'zero-knowledge' or 'legacy'

-- Invites table (no plain codes stored)
invites:
  - invite_hash VARCHAR      -- SHA256 of invite code
  - username VARCHAR         -- Reserved username
  - expires_at TIMESTAMP     -- Auto-expires in 7 days
```

## Web Registration

Users can register at: `https://catalyst9.ai/register`

1. Enter invite code
2. Enter email
3. Get credentials displayed ONCE
4. Save everything immediately

## Command-Line Tools

```bash
# Generate invite
./scripts/invite-system.py invite [username]

# Register account
./scripts/invite-system.py register [code] [email]

# Decrypt API key
./scripts/invite-system.py decrypt [username]
```

## Best Practices

### For Users
1. **Save private key** in password manager immediately
2. **Write down recovery phrases** on paper
3. **Never share private key** with anyone (including us!)
4. **Store securely** - treat like Bitcoin wallet

### For Admins
1. **Send invites securely** - use Signal, encrypted email
2. **Set expiry** - invites expire in 7 days
3. **Monitor attempts** - check recovery_attempts table
4. **Rotate regularly** - encourage key rotation

## FAQ

**Q: What if I lose my private key?**
A: Your account becomes inaccessible. We cannot recover it. Use recovery phrases to reset.

**Q: Why can't you reset my password?**
A: There are no passwords. Your private key IS your authentication.

**Q: Is this like Bitcoin?**
A: Similar concept - you own your keys, we can't access your funds (data).

**Q: What about compliance/legal requests?**
A: We can provide encrypted data, but without your private key, it's meaningless.

**Q: Can I change my keys?**
A: Yes, request a new invite to re-register with new keys.

## Summary

- **You control your keys** - True data ownership
- **We can't see your data** - Zero-knowledge proof
- **No passwords** - Cryptographic authentication
- **Unrecoverable** - With great power comes great responsibility

---

*"Not your keys, not your data"* - Catalyst9 Philosophy