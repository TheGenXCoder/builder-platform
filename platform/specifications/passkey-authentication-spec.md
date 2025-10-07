# Passkey Authentication Implementation Specification

**The Builder Platform - Passwordless Authentication via WebAuthn/FIDO2**

**Last Updated:** October 7, 2024
**Status:** Implementation Ready
**Dependencies:** Architectural Decision Principles (2-way door framework)
**Target Users:** Sophisticated experts comfortable with modern authentication

---

## Philosophy

**"No passwords. No exceptions."**

Passwords are inherently insecure:
- Phishable (fake login pages)
- Reusable (credential stuffing attacks)
- Guessable (dictionary attacks, social engineering)
- Leakable (database breaches, keyloggers)

**Passkeys solve all of these:**
- ✅ Phishing-resistant (public key cryptography, domain-bound)
- ✅ Unique per service (no credential reuse)
- ✅ Unguessable (cryptographic keys, not user-chosen strings)
- ✅ Unleakable (private key never leaves device/authenticator)

**Trade-off:** Slightly higher initial friction for massive long-term security gain. Our users are experts building knowledge platforms - they understand this trade-off.

---

## Core Requirements

### Must-Have (MVP)

1. **Passkey Registration**
   - User can create account with passkey (no password option)
   - Email as account identifier
   - Multi-passkey support (register multiple devices/authenticators)
   - Device/authenticator naming ("iPhone 13", "YubiKey 5C")

2. **Passkey Authentication**
   - Login with passkey (biometric or hardware key)
   - Automatic user identification (resident keys preferred)
   - Cross-origin support (webauthn.io compliance)
   - Remember device preference

3. **Passkey Management**
   - View all registered passkeys
   - Add new passkey to existing account
   - Remove/revoke passkeys
   - Track last used timestamp
   - Require at least 1 passkey always (can't remove last one)

4. **Account Recovery**
   - Email-based recovery flow (send magic link)
   - Time-limited recovery links (15-minute expiry)
   - Must register new passkey during recovery
   - Recovery attempt logging (security audit trail)

5. **Session Management**
   - Session tokens (JWT or encrypted cookies)
   - Refresh token rotation
   - Device tracking (optional, privacy-first)
   - Logout from all devices

### Nice-to-Have (Post-MVP)

6. **Backup Codes**
   - Generate one-time recovery codes (8-10 codes)
   - Store hashed (bcrypt/argon2)
   - Use once and delete
   - User downloads and stores securely

7. **Enterprise Features**
   - Hardware key requirement option (security-conscious orgs)
   - Attestation verification (require specific authenticator types)
   - Login policy enforcement (e.g., re-auth every 24 hours)

8. **Analytics & Monitoring**
   - Passkey registration success rate
   - Authentication failure reasons
   - Browser/platform support metrics
   - Recovery flow usage

---

## Technical Architecture

### WebAuthn Standard (FIDO2)

**What is WebAuthn:**
- W3C standard for public key authentication
- Supported by all modern browsers (Safari, Chrome, Firefox, Edge)
- Works with platform authenticators (FaceID, TouchID, Windows Hello)
- Works with hardware keys (YubiKey, Titan Key, Feitian)

**How it works:**
1. **Registration:** Browser generates key pair, stores private key in secure enclave, sends public key to server
2. **Authentication:** Server sends challenge, browser signs with private key, server verifies signature with stored public key
3. **No password ever touches server or network**

### 2-Way Door Architecture

**Abstraction Layer: Credential Provider Interface**

```typescript
// lib/auth/credential-provider.ts
interface CredentialProvider {
  // Registration
  createRegistrationChallenge(email: string): Promise<RegistrationChallenge>
  verifyRegistrationResponse(response: RegistrationResponse): Promise<Credential>

  // Authentication
  createAuthenticationChallenge(email?: string): Promise<AuthenticationChallenge>
  verifyAuthenticationResponse(response: AuthenticationResponse): Promise<User>

  // Management
  listCredentials(userId: string): Promise<Credential[]>
  addCredential(userId: string, response: RegistrationResponse): Promise<Credential>
  removeCredential(credentialId: string): Promise<void>
  updateCredential(credentialId: string, updates: Partial<Credential>): Promise<Credential>
}

// Pluggable implementations
class WebAuthnProvider implements CredentialProvider { ... }
class PasskeyLibraryAdapter implements CredentialProvider { ... }
class ClerkPasskeyAdapter implements CredentialProvider { ... }
```

**Why this is a 2-way door:**
- Can swap WebAuthn libraries (SimpleWebAuthn, @github/webauthn-json, Hanko Passkey)
- Can integrate with Clerk Passkeys or Auth0 Passkeys later
- Can add password fallback (though we won't) without touching app code
- Testable (mock CredentialProvider for unit tests)

---

## Database Schema

### Additions to Prisma Schema

```prisma
// User model (already exists, add relation)
model User {
  id            String       @id @default(cuid())
  email         String       @unique
  // ... existing fields

  // Passkey relations
  credentials   Credential[]
  recoveryAttempts RecoveryAttempt[]

  @@map("users")
}

// Passkey credentials
model Credential {
  id                String   @id @default(cuid())
  credentialId      String   @unique // Base64URL encoded credential ID from WebAuthn
  publicKey         Bytes    // Public key from authenticator
  counter           BigInt   @default(0) // Signature counter (replay attack prevention)
  deviceName        String?  // User-provided name ("iPhone 13")
  aaguid            String?  // Authenticator AAGUID (device identification)
  transports        Json?    // Supported transports: ["usb", "nfc", "ble", "internal"]
  backedUp          Boolean  @default(false) // Is this credential synced across devices?
  lastUsedAt        DateTime?
  createdAt         DateTime @default(now())

  // User who owns this credential
  userId            String
  user              User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@map("credentials")
}

// Account recovery attempts (audit trail)
model RecoveryAttempt {
  id            String   @id @default(cuid())
  email         String
  token         String   @unique // Hashed recovery token
  expiresAt     DateTime
  usedAt        DateTime?
  ipAddress     String?
  userAgent     String?
  success       Boolean  @default(false)
  createdAt     DateTime @default(now())

  // User (if recovery successful)
  userId        String?
  user          User?    @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([email])
  @@index([token])
  @@index([expiresAt])
  @@map("recovery_attempts")
}

// Optional: Backup codes (post-MVP)
model BackupCode {
  id            String   @id @default(cuid())
  codeHash      String   // Bcrypt/Argon2 hash of code
  usedAt        DateTime?
  createdAt     DateTime @default(now())

  userId        String
  user          User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@map("backup_codes")
}
```

**Key Design Decisions:**

1. **Credential ID as unique:** Prevents duplicate registration of same authenticator
2. **Counter field:** Detects cloned authenticators (replay attacks)
3. **Transports stored:** Helps UI show appropriate icons (fingerprint vs USB key)
4. **backedUp flag:** Indicates if passkey syncs across user's devices (iCloud Keychain, Google Password Manager)
5. **Recovery audit trail:** Security monitoring, detect abuse patterns

---

## User Flows

### Flow 1: New User Registration (Happy Path)

**Step 1: Email Collection**
```
User visits /signup
Enter email → "Continue with Passkey"
```

**Step 2: Passkey Creation**
```
Browser prompts:
  "Create a passkey for builder-platform.com"
  [Use Touch ID] [Use iPhone] [Use Security Key]

User authenticates (FaceID, fingerprint, PIN)
Passkey created ✅
```

**Step 3: Device Naming (Optional)**
```
"Name this passkey (optional)"
[iPhone 13 Pro] [Save]

Registered passkeys:
  • iPhone 13 Pro (this device) - Just now
```

**Step 4: Onboarding**
```
Domain selection → Project setup
(Same as Week 3-4 spec)
```

**Total time:** 30-45 seconds (faster than password + email verify!)

---

### Flow 2: Returning User Login (Happy Path)

**Step 1: Email Entry (Optional with Resident Keys)**
```
User visits /login

Option A (Resident Key):
  "Sign in with Passkey" button
  → Browser lists available passkeys
  → Select user@email.com
  → Authenticate (FaceID)
  → Logged in ✅

Option B (Non-Resident Key):
  Enter email → "Continue"
  → Browser prompts for passkey
  → Authenticate
  → Logged in ✅
```

**Total time:** 5-10 seconds (2 taps!)

---

### Flow 3: Adding Second Passkey (Multi-Device)

**Scenario:** User has passkey on iPhone, wants to add laptop.

**Step 1: Navigate to Settings**
```
User logged in on iPhone
Settings → Security → Passkeys

Current passkeys:
  • iPhone 13 Pro - Last used 2 min ago

[+ Add Another Passkey]
```

**Step 2: Add Passkey (on new device)**
```
User opens laptop, visits builder-platform.com
Settings → Security → Passkeys → [+ Add Another Passkey]

Browser prompts (laptop):
  "Create a passkey for builder-platform.com"
  [Use Touch ID]

User authenticates with MacBook Touch ID
```

**Step 3: Confirmation**
```
Current passkeys:
  • iPhone 13 Pro - Last used 5 min ago
  • MacBook Pro M2 - Just now ✅
```

**Result:** User can now log in from either device with their passkey.

---

### Flow 4: Account Recovery (Lost All Devices)

**Scenario:** User lost phone, got new device, needs access.

**Step 1: Recovery Initiation**
```
User visits /login
Enter email → "Continue"
Browser: "No passkey found"

[Lost access? Recover your account]
```

**Step 2: Email Verification**
```
"We'll send a recovery link to user@email.com"
[Send Recovery Link]

Email sent ✅
  Subject: "Account Recovery - The Builder Platform"
  Body: "Click this link to recover your account: [Recover Account]
         This link expires in 15 minutes."
```

**Step 3: Recovery Flow**
```
User clicks link
  → Verify token valid (not expired, not used)
  → "Create a new passkey for your account"
  → Browser prompts for passkey creation
  → User authenticates with new device
  → Passkey registered ✅

Recovery successful! You can now sign in with your new passkey.

Action taken:
  - New passkey registered: "iPhone 15 Pro"
  - Recovery link invalidated
  - Email sent: "Account recovery completed"
```

**Step 4: Security Review (Optional)**
```
Settings → Security → Recent Activity

Recovery attempt:
  • Oct 7, 2024 9:45 PM
  • IP: 192.168.1.174 (San Francisco, CA)
  • New passkey registered: "iPhone 15 Pro"

[This was me] [This wasn't me - Secure my account]
```

---

### Flow 5: Passkey Management (Revocation)

**Scenario:** User sold old laptop, wants to remove its passkey.

**Step 1: View Passkeys**
```
Settings → Security → Passkeys

Current passkeys (3):
  • iPhone 13 Pro - Last used 2 min ago
  • MacBook Pro M2 - Last used 1 hour ago
  • Old MacBook Air - Last used 3 months ago ⚠️
```

**Step 2: Remove Passkey**
```
Click "Old MacBook Air" → [Remove]

⚠️ Are you sure?
Removing this passkey will prevent sign-in from that device.
You'll need to create a new passkey to use that device again.

[Cancel] [Remove Passkey]
```

**Step 3: Confirmation**
```
Passkey removed ✅

Current passkeys (2):
  • iPhone 13 Pro - Last used 2 min ago
  • MacBook Pro M2 - Last used 1 hour ago

Security log:
  • Passkey "Old MacBook Air" removed - Just now
  • Email sent: "Passkey removed from your account"
```

---

## Implementation Details

### Library Selection

**Recommended: SimpleWebAuthn**
```bash
bun add @simplewebauthn/server @simplewebauthn/browser
```

**Why SimpleWebAuthn:**
- ✅ TypeScript-first (full type safety)
- ✅ Handles WebAuthn complexity (attestation, assertion, COSE key parsing)
- ✅ Works with NextAuth.js or standalone
- ✅ Well-documented, actively maintained
- ✅ Used in production by Auth0, Clerk, others
- ✅ MIT license (no vendor lock-in)

**Alternatives (2-way door):**
- `@github/webauthn-json` (GitHub's library, simpler but less feature-rich)
- `hanko/passkeys` (Hanko's library, more opinionated)
- Clerk Passkeys (managed service, requires Clerk account)

---

### Server-Side Implementation

**API Routes:**

```typescript
// app/api/auth/passkey/register/challenge/route.ts
export async function POST(request: Request) {
  const { email } = await request.json()

  // Check if user exists (disallow duplicate emails)
  const existingUser = await prisma.user.findUnique({ where: { email } })
  if (existingUser) {
    return NextResponse.json({ error: 'Email already registered' }, { status: 400 })
  }

  // Generate registration challenge
  const challenge = await credentialProvider.createRegistrationChallenge(email)

  // Store challenge in session (short-lived, 2-minute expiry)
  // Use encrypted session cookie or Redis for production

  return NextResponse.json(challenge)
}

// app/api/auth/passkey/register/verify/route.ts
export async function POST(request: Request) {
  const response = await request.json()

  // Verify registration response
  const credential = await credentialProvider.verifyRegistrationResponse(response)

  // Create user + credential in transaction
  const user = await prisma.$transaction(async (tx) => {
    const newUser = await tx.user.create({
      data: {
        email: response.email,
        domain: 'CUSTOM',
      },
    })

    await tx.credential.create({
      data: {
        credentialId: credential.credentialId,
        publicKey: credential.publicKey,
        counter: credential.counter,
        deviceName: response.deviceName || null,
        aaguid: credential.aaguid,
        transports: credential.transports,
        backedUp: credential.backedUp,
        userId: newUser.id,
      },
    })

    return newUser
  })

  // Create session
  const session = await createSession(user.id)

  return NextResponse.json({ user, session })
}

// app/api/auth/passkey/authenticate/challenge/route.ts
export async function POST(request: Request) {
  const { email } = await request.json()

  // Generate authentication challenge
  const challenge = await credentialProvider.createAuthenticationChallenge(email)

  return NextResponse.json(challenge)
}

// app/api/auth/passkey/authenticate/verify/route.ts
export async function POST(request: Request) {
  const response = await request.json()

  // Verify authentication response
  const user = await credentialProvider.verifyAuthenticationResponse(response)

  // Update credential counter and lastUsedAt
  await prisma.credential.update({
    where: { credentialId: response.credentialId },
    data: {
      counter: response.counter,
      lastUsedAt: new Date(),
    },
  })

  // Create session
  const session = await createSession(user.id)

  return NextResponse.json({ user, session })
}

// app/api/auth/passkey/credentials/route.ts (list, add, remove)
// ... similar patterns
```

---

### Client-Side Implementation

**React Component: Passkey Registration**

```typescript
'use client'

import { startRegistration } from '@simplewebauthn/browser'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { toast } from 'sonner'

export function PasskeyRegistration() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleRegister = async () => {
    setLoading(true)

    try {
      // 1. Get registration challenge from server
      const challengeRes = await fetch('/api/auth/passkey/register/challenge', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      })

      if (!challengeRes.ok) {
        throw new Error('Failed to create challenge')
      }

      const challenge = await challengeRes.json()

      // 2. Prompt user to create passkey (browser UI)
      const registrationResponse = await startRegistration(challenge)

      // 3. Send response to server for verification
      const verifyRes = await fetch('/api/auth/passkey/register/verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...registrationResponse,
          email,
        }),
      })

      if (!verifyRes.ok) {
        throw new Error('Failed to verify registration')
      }

      // 4. Registration successful!
      toast.success('Account created! Welcome to Builder Platform.')
      router.push('/dashboard')

    } catch (error) {
      console.error('Registration error:', error)
      toast.error('Failed to create passkey. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <Input
        type="email"
        placeholder="your@email.com"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <Button
        onClick={handleRegister}
        disabled={!email || loading}
        className="w-full"
      >
        {loading ? 'Creating passkey...' : 'Create Account with Passkey'}
      </Button>
    </div>
  )
}
```

**Similar components for:**
- `PasskeyAuthentication` (login)
- `PasskeyManagement` (list/add/remove)
- `AccountRecovery` (email recovery flow)

---

## Non-Trivial Challenges & Solutions

### Challenge 1: Device Loss / Account Recovery

**Problem:** User loses all devices with passkeys → locked out forever.

**Solution:** Email-based recovery flow
- Temporary magic link (15-minute expiry)
- Forces new passkey registration during recovery
- Recovery attempts logged (audit trail)
- Email notification on successful recovery

**Alternative (Post-MVP):** Backup codes
- Generate 8-10 one-time codes
- User downloads and stores securely (password manager, printed paper)
- Each code usable once, then deleted
- Trade-off: Codes are like passwords (can be stolen), but better than permanent lockout

---

### Challenge 2: Cross-Device Sync

**Problem:** User creates passkey on iPhone. Wants to use laptop. Does it sync?

**Solution: Depends on platform**
- **Apple ecosystem:** iCloud Keychain syncs passkeys (iPhone ↔ Mac ↔ iPad)
- **Google ecosystem:** Google Password Manager syncs (Chrome ↔ Android)
- **Cross-platform:** NO sync (iPhone ↔ Windows PC)

**Our approach:**
- **Multi-passkey support:** User registers passkey on each device
- **Detection:** Check `backedUp` flag from WebAuthn response (indicates synced credential)
- **UX:** If user has synced credential, show "✓ Synced across your Apple devices"
- **Guidance:** Encourage registering passkey on each platform (iPhone + Windows PC)

**UI Example:**
```
Your Passkeys:
  • iPhone 13 Pro ☁️ Synced - Last used 2 min ago
  • Windows PC - Last used 1 day ago

☁️ Synced passkeys work across your Apple devices.
Windows PC requires separate passkey registration.

[+ Add Passkey on Another Device]
```

---

### Challenge 3: Browser/Platform Support

**Problem:** Not all browsers support WebAuthn. What's our fallback?

**Solution: Progressive enhancement**
- Check `window.PublicKeyCredential` availability
- If unavailable, show fallback UI

**Fallback options:**
1. **Email magic link (temporary):** "Your browser doesn't support passkeys yet. We'll send you a login link."
2. **Upgrade prompt:** "For the best security, please use Chrome, Safari, Firefox, or Edge."
3. **Hardware key only:** Some users with old browsers can still use USB security keys

**Browser support matrix (2024):**
- ✅ Safari 16+ (macOS, iOS)
- ✅ Chrome 108+ (all platforms)
- ✅ Firefox 119+ (all platforms)
- ✅ Edge 108+ (Windows, macOS)
- ⚠️ Older browsers: Fallback to email magic link

**Detection code:**
```typescript
const isPasskeySupported = () => {
  return window?.PublicKeyCredential !== undefined &&
         typeof window.PublicKeyCredential === 'function'
}
```

---

### Challenge 4: User Education

**Problem:** Many users don't know what passkeys are. Confusing UX = drop-off.

**Solution: Clear communication + inline education**

**Sign-up page:**
```
Sign Up with Passkey

🔐 What's a passkey?
Passkeys use your fingerprint, face, or device PIN to sign in.
No passwords to remember. No passwords to leak.

More secure than passwords. Faster to use.

[Create Account with Passkey]

---
Technical details:
Uses FIDO2/WebAuthn standard. Your private key never leaves your device.
Supported by Apple, Google, Microsoft.
```

**First-time flow:**
```
Step 1/3: Create Your Passkey

When you tap "Continue", your browser will prompt you to:
  • Use Touch ID (fingerprint)
  • Use Face ID (facial recognition)
  • Use Windows Hello (fingerprint or face)
  • Use a security key (YubiKey, etc.)

This creates a secure credential for your account.

[Continue] [Learn more about passkeys →]
```

**Post-registration:**
```
✅ Passkey Created!

You can now sign in with your fingerprint instead of a password.

💡 Tip: Register a passkey on another device so you can sign in from anywhere.

[+ Add Passkey on Another Device] [Skip for now]
```

---

### Challenge 5: Testing & Development

**Problem:** How to test passkey flows without physical devices?

**Solution: Multiple strategies**

**1. Browser DevTools Simulation**
- Chrome DevTools: Settings → Devices → Add virtual authenticator
- Firefox: about:config → security.webauthn.enable_softtoken = true
- Allows testing registration/authentication without hardware

**2. Mock Credential Provider (Unit Tests)**
```typescript
class MockCredentialProvider implements CredentialProvider {
  async createRegistrationChallenge(email: string) {
    return { challenge: 'mock-challenge', /* ... */ }
  }

  async verifyRegistrationResponse(response: RegistrationResponse) {
    return { credentialId: 'mock-cred-id', /* ... */ }
  }

  // ... other methods
}
```

**3. Integration Tests with Playwright**
```typescript
test('passkey registration flow', async ({ page }) => {
  // Set up virtual authenticator
  await page.addVirtualAuthenticator({
    protocol: 'ctap2',
    transport: 'internal',
    hasResidentKey: true,
    isUserVerified: true,
  })

  await page.goto('/signup')
  await page.fill('input[type=email]', 'test@example.com')
  await page.click('button:has-text("Create Account with Passkey")')

  // Virtual authenticator automatically responds
  await expect(page).toHaveURL('/dashboard')
})
```

**4. Hardware Keys for Manual Testing**
- YubiKey 5C (~$50) - USB-C + NFC
- Feitian BioPass (~$40) - Fingerprint sensor
- Test on real devices (iPhone, Android, Windows PC)

---

### Challenge 6: Replay Attack Prevention

**Problem:** Attacker captures authentication response, replays it later.

**Solution: Signature counter**
- Each authenticator maintains a counter (increments with each use)
- Server stores counter, expects it to increase
- If counter doesn't increase → cloned authenticator → reject

**Implementation:**
```typescript
// During authentication verification
const credential = await prisma.credential.findUnique({
  where: { credentialId: response.credentialId }
})

if (response.counter <= credential.counter) {
  // Counter didn't increase → possible cloned authenticator
  await logSecurityEvent({
    type: 'REPLAY_ATTACK_DETECTED',
    credentialId: response.credentialId,
    expected: credential.counter,
    received: response.counter,
  })

  throw new Error('Authentication failed: Invalid counter')
}

// Update counter
await prisma.credential.update({
  where: { credentialId: response.credentialId },
  data: { counter: response.counter },
})
```

---

## Security Considerations

### 1. Challenge Randomness

**Requirement:** Challenges must be cryptographically random (32 bytes minimum).

**Implementation:**
```typescript
import { randomBytes } from 'crypto'

const generateChallenge = () => {
  return Buffer.from(randomBytes(32)).toString('base64url')
}
```

**Storage:** Store challenge in encrypted session cookie or Redis with short expiry (2 minutes).

---

### 2. Origin Verification

**Requirement:** Verify authentication comes from expected origin (prevent phishing).

**Implementation:**
```typescript
// SimpleWebAuthn handles this automatically
const verification = await verifyAuthenticationResponse({
  response: authenticationResponse,
  expectedChallenge: storedChallenge,
  expectedOrigin: 'https://builder-platform.com', // Must match
  expectedRPID: 'builder-platform.com', // Relying Party ID
})
```

**Why this matters:** Even if attacker tricks user into using passkey on fake site, signature won't verify because origin is wrong.

---

### 3. HTTPS Required

**Requirement:** WebAuthn ONLY works over HTTPS (or localhost for development).

**Why:** Prevents man-in-the-middle attacks.

**Development:** `localhost:3000` works without HTTPS (WebAuthn exception).

**Production:** Enforce HTTPS (Next.js on Vercel does this automatically).

---

### 4. Rate Limiting

**Requirement:** Prevent brute-force recovery attempts.

**Implementation:**
```typescript
// Limit recovery emails per IP address
const RECOVERY_RATE_LIMIT = {
  maxAttempts: 5,
  windowMs: 15 * 60 * 1000, // 15 minutes
}

// Check rate limit before sending recovery email
const recentAttempts = await prisma.recoveryAttempt.count({
  where: {
    ipAddress,
    createdAt: { gte: new Date(Date.now() - RECOVERY_RATE_LIMIT.windowMs) },
  },
})

if (recentAttempts >= RECOVERY_RATE_LIMIT.maxAttempts) {
  throw new Error('Too many recovery attempts. Try again in 15 minutes.')
}
```

---

### 5. Audit Logging

**Requirement:** Log all auth events for security monitoring.

**Events to log:**
- Passkey registration (success, failure)
- Authentication (success, failure, device info)
- Passkey removal
- Account recovery attempts
- Counter anomalies (replay attacks)

**Storage:** Separate `AuthLog` table or external logging service (Sentry, Datadog).

**Compliance:** Required for SOC 2, GDPR audit trails.

---

## Privacy Considerations

### 1. Data Minimization

**What we store:**
- ✅ Public key (required for authentication)
- ✅ Credential ID (required for identification)
- ✅ Counter (required for security)
- ✅ Last used timestamp (user convenience)
- ✅ Device name (user-provided, optional)

**What we DON'T store:**
- ❌ Biometric data (stays on device, never sent)
- ❌ Device serial numbers (AAGUID is acceptable, non-identifying)
- ❌ Precise location (IP address optional, for security only)
- ❌ Browsing history, device fingerprints, etc.

---

### 2. GDPR Compliance

**Right to Access:** User can view all registered passkeys.

**Right to Deletion:** User can delete account → cascade deletes all credentials.

**Right to Portability:** User can export credential list (metadata only, not private keys).

**Data Retention:** Recovery attempts auto-delete after 90 days (configurable).

---

### 3. Transparency

**Settings → Security page shows:**
- All registered passkeys (device name, last used)
- Recent authentication history (date, IP address - optional)
- Recovery attempts (success/failure)
- Account security score (e.g., "2 passkeys registered ✓")

**User control:**
- Remove passkeys anytime
- Download security log
- Enable/disable recovery email

---

## Migration Strategy

### Phase 1: Passkey-Only Launch (MVP)

**Target:** Early adopters, technically sophisticated users.

**Approach:**
- No password option
- Passkey required for signup
- Email recovery as fallback
- Clear messaging: "We use passkeys for security. No passwords needed."

**Expected friction:** ~10-15% drop-off (acceptable for MVP, targeting right users).

---

### Phase 2: Broad Adoption (Post-MVP)

**Add if needed (based on user feedback):**
- Magic link login (email-based, password-free alternative)
- Backup codes (for users without email access)
- Enterprise SSO (SAML, OAuth for organizations)

**Never add:**
- Passwords (security downgrade, goes against platform values)

---

### Phase 3: Advanced Features (Year 1+)

**Potential additions:**
- Hardware key requirement (security-conscious users)
- Attestation verification (require specific authenticator types)
- Passkey inheritance (family accounts, organization transfer)
- Cross-platform sync (if standards improve)

---

## Success Metrics

### Registration Funnel

**Track:**
- Email entered → Challenge created (drop-off %)
- Challenge created → Passkey registered (browser prompt acceptance %)
- Passkey registered → Account created (verification success %)

**Target:** >80% completion rate (email → account created).

---

### Authentication Success Rate

**Track:**
- Login initiated → Challenge created
- Challenge created → Passkey authenticated
- Authentication success rate (by browser, platform, authenticator type)

**Target:** >95% success rate.

---

### Recovery Usage

**Track:**
- Recovery emails sent
- Recovery completions
- Time to recovery (user experience)

**Target:** <5% of logins require recovery (indicates good multi-passkey adoption).

---

### Multi-Passkey Adoption

**Track:**
- % users with 1 passkey (risky, single device)
- % users with 2+ passkeys (safer, multiple devices)
- Average passkeys per user

**Target:** 60%+ of users have 2+ passkeys.

---

### Browser/Platform Support

**Track:**
- Passkey support detection (% users with compatible browsers)
- Fallback usage (magic link, etc.)
- Browser/OS distribution

**Insights:** Identify unsupported platforms, prioritize compatibility improvements.

---

## Reusability (2-Way Door Applied)

### This Specification is a Standalone Module

**Goal:** Passkey auth should be extractable and reusable in other projects.

**Architecture:**
```
passkey-auth/
├── lib/
│   ├── credential-provider.ts      # Interface
│   ├── webauthn-provider.ts        # SimpleWebAuthn adapter
│   ├── mock-provider.ts            # Testing adapter
│   └── types.ts                    # Shared types
├── components/
│   ├── passkey-registration.tsx
│   ├── passkey-authentication.tsx
│   ├── passkey-management.tsx
│   └── account-recovery.tsx
├── api/
│   ├── register/challenge/route.ts
│   ├── register/verify/route.ts
│   ├── authenticate/challenge/route.ts
│   ├── authenticate/verify/route.ts
│   └── credentials/route.ts
├── prisma/
│   └── passkey-schema.prisma       # Credential models
├── README.md                        # Implementation guide
└── package.json                     # Dependencies
```

**Extract to separate npm package:**
```bash
npx create-next-app@latest my-new-app
cd my-new-app
bun add @builder-platform/passkey-auth

# Import and use
import { PasskeyRegistration } from '@builder-platform/passkey-auth'
import { setupPasskeyAuth } from '@builder-platform/passkey-auth/setup'
```

**Benefits:**
- ✅ Use in Builder Platform
- ✅ Use in other projects (consulting clients)
- ✅ Open source (if desired)
- ✅ Generates revenue (paid support, enterprise features)

---

## Implementation Timeline

### Week 2 (Sprint 1): Foundation

**Tasks:**
- [ ] Install SimpleWebAuthn (`bun add @simplewebauthn/server @simplewebauthn/browser`)
- [ ] Add Prisma schema (Credential, RecoveryAttempt models)
- [ ] Run migration (`bunx prisma migrate dev`)
- [ ] Build `CredentialProvider` interface (abstraction layer)
- [ ] Implement `WebAuthnProvider` adapter (SimpleWebAuthn wrapper)
- [ ] Create registration API routes (challenge + verify)
- [ ] Create authentication API routes (challenge + verify)
- [ ] Build `PasskeyRegistration` component (signup UI)
- [ ] Build `PasskeyAuthentication` component (login UI)
- [ ] Test flows with virtual authenticator (Chrome DevTools)

**Deliverable:** Working passkey registration + login.

---

### Week 3 (Sprint 1): Polish & Recovery

**Tasks:**
- [ ] Build `PasskeyManagement` component (list/add/remove)
- [ ] Implement email recovery flow (send link → verify → register new passkey)
- [ ] Add session management (JWT or encrypted cookies)
- [ ] Create protected route middleware
- [ ] Add rate limiting (recovery emails, auth attempts)
- [ ] Browser compatibility detection + fallback UI
- [ ] Write integration tests (Playwright + virtual authenticator)

**Deliverable:** Complete auth system with recovery.

---

### Week 4 (Sprint 1): UX & Documentation

**Tasks:**
- [ ] User education tooltips (inline help)
- [ ] Passkey explainer page (/docs/passkeys)
- [ ] Settings → Security page (view passkeys, recent activity)
- [ ] Email templates (welcome, recovery, security alerts)
- [ ] Analytics events (registration, auth, recovery)
- [ ] Admin audit logs (security monitoring)
- [ ] Test on real devices (iPhone, Android, YubiKey)

**Deliverable:** Production-ready passkey auth.

---

## References & Resources

### Standards

- **WebAuthn Spec:** https://www.w3.org/TR/webauthn-2/
- **FIDO Alliance:** https://fidoalliance.org/
- **CTAP (Client to Authenticator Protocol):** https://fidoalliance.org/specs/fido-v2.0-ps-20190130/fido-client-to-authenticator-protocol-v2.0-ps-20190130.html

### Libraries

- **SimpleWebAuthn:** https://simplewebauthn.dev/
- **@github/webauthn-json:** https://github.com/github/webauthn-json
- **Hanko Passkeys:** https://www.hanko.io/

### Testing

- **webauthn.io:** https://webauthn.io/ (test your implementation)
- **Chrome Virtual Authenticator:** DevTools → More Tools → WebAuthn
- **Playwright WebAuthn:** https://playwright.dev/docs/auth#authenticator

### User Education

- **Passkeys.dev:** https://passkeys.dev/ (explain to users)
- **Apple Passkeys Guide:** https://developer.apple.com/passkeys/
- **Google Passkeys:** https://developers.google.com/identity/passkeys

---

## Tag Index

#passkeys #webauthn #fido2 #passwordless #authentication #security #2-way-door #reusable-module #phishing-resistant #biometric-auth #hardware-keys #account-recovery #multi-device #cross-platform #prisma-schema #api-design #ux-flows #user-education #testing-strategy #privacy #gdpr #audit-logging

---

**Status:** Implementation ready. Proceed with Week 2 Sprint 1.

**Next Review:** After MVP launch (validate success metrics, iterate on UX).
