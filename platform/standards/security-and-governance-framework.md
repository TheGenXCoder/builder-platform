# Security and Governance Framework

**The Builder Platform - Comprehensive Security, Privacy, and Compliance Standards**

**Last Updated:** October 7, 2024
**Status:** Core Platform Standard
**Applies To:** All code, infrastructure, vendor selection, and operational procedures
**Review Frequency:** Quarterly + After major incidents or regulatory changes

---

## Executive Summary

**"Security by design. Privacy by default. Compliance from day one."**

This framework establishes security and governance standards for The Builder Platform across multiple regulatory and industry frameworks:

- **NIST 800-53** (Federal security controls)
- **GDPR** (EU General Data Protection Regulation)
- **CCPA** (California Consumer Privacy Act)
- **SOC 2** (Service Organization Controls)
- **OWASP Top 10** (Web application security)
- **Extensible** (pluggable framework adapters for future standards)

**Why this matters:**
- ProductHunt launch → Global audience → Must comply with GDPR/CCPA
- Enterprise customers → Require SOC 2 audit
- Security breaches → Platform credibility destroyed
- Regulatory fines → €20M or 4% revenue (GDPR), $7,500/violation (CCPA)
- **Prevention costs < reaction costs**

---

## Core Philosophy

### Security by Design

**Not:** Bolt-on security after features built
**But:** Security requirements drive architecture

**Examples:**
- Passkeys from day 1 (not "we'll add MFA later")
- Encryption at rest (not "we'll encrypt later")
- Audit logging built-in (not "we'll add monitoring later")

### Privacy by Default

**Not:** "Opt-in to privacy" or "buried in settings"
**But:** Maximum privacy as default configuration

**Examples:**
- Minimal data collection (ask for email, not phone + address + birthday)
- No analytics tracking without consent
- Data deletion on request (not "30-day retention minimum")
- Portable data exports (JSON, not proprietary format)

### Compliance from Day One

**Not:** "We'll get compliant when we have customers"
**But:** Compliance before ProductHunt launch

**Why:** Retrofitting compliance = massive technical debt. Building compliant = marginal cost.

---

## Regulatory Framework Mapping

### NIST 800-53 (Federal Security Controls)

**Applicability:** US federal contracts, government customers, defense industry

**Key Control Families:**
- **AC (Access Control):** Role-based access, least privilege, session management
- **AU (Audit and Accountability):** Logging, monitoring, audit trails
- **CM (Configuration Management):** Change control, baseline configurations
- **IA (Identification and Authentication):** Passkeys, MFA, session security
- **SC (System and Communications Protection):** Encryption in transit/rest, TLS 1.3
- **SI (System and Information Integrity):** Input validation, vulnerability scanning

**Builder Platform Implementation:**
- See NIST 800-53 control mapping (Section below)

**Certification Path:**
- FedRAMP (Federal Risk and Authorization Management Program) - IF pursuing government customers
- Required controls: ~325 of 945 total (Moderate baseline)

---

### GDPR (General Data Protection Regulation)

**Applicability:** ANY user from EU (even 1 user = full compliance required)

**Key Principles:**
1. **Lawfulness, Fairness, Transparency:** Clear consent, honest data usage
2. **Purpose Limitation:** Collect data for specific purposes only
3. **Data Minimization:** Collect only what's necessary
4. **Accuracy:** Keep data up-to-date, allow user corrections
5. **Storage Limitation:** Delete data when no longer needed
6. **Integrity and Confidentiality:** Security measures (encryption, access control)
7. **Accountability:** Demonstrate compliance

**User Rights:**
- **Right to Access:** Download all their data
- **Right to Rectification:** Correct inaccurate data
- **Right to Erasure ("Right to be Forgotten"):** Delete their data
- **Right to Data Portability:** Export in machine-readable format
- **Right to Object:** Stop processing their data
- **Right to Withdraw Consent:** Opt-out anytime

**Builder Platform Implementation:**
- See GDPR compliance checklist (Section below)

**Penalties:** Up to €20M or 4% of annual global turnover (whichever is higher)

---

### CCPA (California Consumer Privacy Act)

**Applicability:** Businesses with California users that meet thresholds:
- Gross revenue >$25M, OR
- Data of 50,000+ CA residents, OR
- 50%+ revenue from selling personal data

**Key Rights:**
1. **Right to Know:** What data collected, how used, who shared with
2. **Right to Delete:** Request deletion of personal data
3. **Right to Opt-Out:** Stop sale of personal data
4. **Right to Non-Discrimination:** Same service/price regardless of privacy choices

**Builder Platform Implementation:**
- See CCPA compliance checklist (Section below)

**Penalties:** Up to $7,500 per intentional violation, $2,500 per unintentional

---

### SOC 2 (Service Organization Controls)

**Applicability:** B2B SaaS selling to enterprises

**Trust Service Criteria:**
1. **Security:** Protection against unauthorized access
2. **Availability:** System uptime and performance
3. **Processing Integrity:** Complete, accurate, timely processing
4. **Confidentiality:** Protection of confidential data
5. **Privacy:** Personal information handled per commitments

**SOC 2 Type I vs Type II:**
- Type I: Controls designed appropriately (point-in-time audit)
- Type II: Controls operating effectively (6-12 month audit)

**Builder Platform Implementation:**
- See SOC 2 control mapping (Section below)

**Certification Timeline:**
- Month 6: Begin documentation
- Month 12: Type I audit
- Month 18: Type II audit (after 6 months of evidence)

---

### OWASP Top 10 (Web Application Security)

**Applicability:** ALL web applications

**2021 Top 10:**
1. Broken Access Control
2. Cryptographic Failures
3. Injection
4. Insecure Design
5. Security Misconfiguration
6. Vulnerable and Outdated Components
7. Identification and Authentication Failures
8. Software and Data Integrity Failures
9. Security Logging and Monitoring Failures
10. Server-Side Request Forgery (SSRF)

**Builder Platform Implementation:**
- See OWASP mitigation strategies (Section below)

---

## Data Classification

### Data Categories

**1. Identity Data (PII - Personally Identifiable Information)**
- Email address
- User ID
- IP address (optional, security only)
- Device information (optional, user-provided names)

**GDPR Article 4:** PII = "any information relating to an identified or identifiable natural person"

**Protection Level:** HIGH
- Encrypted at rest (AES-256)
- Encrypted in transit (TLS 1.3)
- Access logged (audit trail)
- Deletion on request (30-day max)

---

**2. Content Data (User-Generated Content)**
- Research specs
- Verified facts
- Content drafts
- Conversation logs
- Tags and metadata

**Ownership:** User owns 100% of content data

**Protection Level:** HIGH
- Encrypted at rest
- Encrypted in transit
- User can export (JSON, Markdown)
- User can delete (cascade delete)
- **Never used for AI training without explicit consent**

---

**3. Knowledge Graph Data**
- Fact relationships
- Entity connections
- Cross-domain patterns
- Verification metadata

**Sensitivity:** MEDIUM (derived from user content, but may reveal patterns)

**Protection Level:** MEDIUM-HIGH
- Encrypted at rest
- Access control (users see only their graph)
- Aggregated analytics OK (privacy-preserving)
- Individual graph data = user-owned

---

**4. Analytics Data (Optional, Consent-Based)**
- Feature usage (which buttons clicked)
- Performance metrics (page load times)
- Error logs (crash reports)
- A/B test assignments

**Collection:** ONLY with explicit consent (GDPR/CCPA compliant)

**Protection Level:** MEDIUM
- Anonymized where possible
- Aggregate reporting only
- No sale to third parties
- User can opt-out anytime

---

**5. Authentication Data**
- Passkey public keys
- Credential IDs
- Session tokens
- Recovery attempt logs

**Protection Level:** CRITICAL
- Encrypted at rest (never store biometrics - handled by device)
- Access logged (all auth events)
- Rate limiting (prevent brute force)
- Audit trail (security monitoring)

---

## Technical Security Controls

### 1. Encryption

**At Rest (Database):**
```typescript
// PostgreSQL encryption
// Option A: Database-level encryption (transparent)
// Option B: Application-level encryption (field-level)

// Field-level encryption for sensitive fields
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto'

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY // 32-byte key
const ALGORITHM = 'aes-256-gcm'

export function encrypt(plaintext: string): { encrypted: string; iv: string; tag: string } {
  const iv = randomBytes(16)
  const cipher = createCipheriv(ALGORITHM, Buffer.from(ENCRYPTION_KEY, 'hex'), iv)

  let encrypted = cipher.update(plaintext, 'utf8', 'hex')
  encrypted += cipher.final('hex')

  const tag = cipher.getAuthTag()

  return {
    encrypted,
    iv: iv.toString('hex'),
    tag: tag.toString('hex'),
  }
}

export function decrypt(encrypted: string, iv: string, tag: string): string {
  const decipher = createDecipheriv(
    ALGORITHM,
    Buffer.from(ENCRYPTION_KEY, 'hex'),
    Buffer.from(iv, 'hex')
  )

  decipher.setAuthTag(Buffer.from(tag, 'hex'))

  let decrypted = decipher.update(encrypted, 'hex', 'utf8')
  decrypted += decipher.final('utf8')

  return decrypted
}

// Usage in Prisma middleware
prisma.$use(async (params, next) => {
  // Encrypt sensitive fields before write
  if (params.action === 'create' || params.action === 'update') {
    if (params.model === 'User' && params.args.data.email) {
      // Email is searchable, so hash for indexing + encrypt for storage
      const { encrypted, iv, tag } = encrypt(params.args.data.email)
      params.args.data.emailEncrypted = encrypted
      params.args.data.emailIv = iv
      params.args.data.emailTag = tag
    }
  }

  // Decrypt on read
  const result = await next(params)

  if (params.action === 'findUnique' || params.action === 'findMany') {
    // Decrypt fields
    if (result && result.emailEncrypted) {
      result.email = decrypt(result.emailEncrypted, result.emailIv, result.emailTag)
    }
  }

  return result
})
```

**In Transit (Network):**
- TLS 1.3 minimum (HTTPS everywhere)
- HSTS (HTTP Strict Transport Security) enabled
- Certificate pinning (API clients)

**Configuration:**
```typescript
// next.config.ts
export default {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload',
          },
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
        ],
      },
    ]
  },
}
```

---

### 2. Access Control

**Principle of Least Privilege:**
- Users see only their data
- Admins have separate elevated role (require re-auth for sensitive actions)
- Service accounts (background jobs) have minimal permissions

**Role-Based Access Control (RBAC):**
```prisma
enum Role {
  USER          // Normal user
  ADMIN         // Platform admin
  SUPPORT       // Customer support (read-only access to help users)
  AUDITOR       // Compliance auditor (read-only logs)
}

model User {
  id     String @id
  email  String @unique
  role   Role   @default(USER)
  // ...
}
```

**Row-Level Security (RLS) Pattern:**
```typescript
// Middleware: Ensure users only access their data
export async function enforceUserAccess(userId: string, resourceUserId: string) {
  if (userId !== resourceUserId) {
    throw new Error('Unauthorized: Access denied')
  }
}

// Usage in API route
export async function GET(request: Request) {
  const session = await getSession(request)
  const { projectId } = await request.json()

  const project = await prisma.project.findUnique({ where: { id: projectId } })

  // Enforce access control
  enforceUserAccess(session.userId, project.userId)

  return NextResponse.json(project)
}
```

---

### 3. Input Validation & Sanitization

**Prevent Injection Attacks (SQL, XSS, Command Injection):**

```typescript
// Zod for runtime type validation
import { z } from 'zod'

const CreateProjectSchema = z.object({
  name: z.string().min(1).max(100).regex(/^[a-zA-Z0-9\s\-_]+$/),
  description: z.string().max(500).optional(),
  domain: z.enum(['AUTOMOTIVE', 'CULINARY', 'WOODWORKING', 'CUSTOM']),
})

export async function POST(request: Request) {
  const body = await request.json()

  // Validate input
  const validatedData = CreateProjectSchema.parse(body) // Throws if invalid

  // Prisma prevents SQL injection (parameterized queries)
  const project = await prisma.project.create({ data: validatedData })

  return NextResponse.json(project)
}
```

**XSS Prevention:**
- React escapes by default (JSX)
- Use `dangerouslySetInnerHTML` ONLY with sanitized HTML (DOMPurify library)
- Content Security Policy (CSP) header

```typescript
// CSP header
headers: [
  {
    key: 'Content-Security-Policy',
    value: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';",
  },
]
```

---

### 4. Rate Limiting

**Prevent Brute Force & DDoS:**

```typescript
// Rate limiting with Upstash Redis + @upstash/ratelimit
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_URL!,
  token: process.env.UPSTASH_REDIS_TOKEN!,
})

const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '10 s'), // 10 requests per 10 seconds
  analytics: true,
})

export async function POST(request: Request) {
  const ip = request.headers.get('x-forwarded-for') || 'unknown'

  const { success, limit, reset, remaining } = await ratelimit.limit(ip)

  if (!success) {
    return NextResponse.json(
      { error: 'Too many requests' },
      {
        status: 429,
        headers: {
          'X-RateLimit-Limit': limit.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
          'X-RateLimit-Reset': reset.toString(),
        },
      }
    )
  }

  // Process request
}
```

**Rate Limit Tiers:**
- Authentication: 5 attempts per 15 minutes (per IP)
- Account recovery: 3 attempts per 15 minutes (per email)
- API endpoints: 100 requests per minute (per user)
- Public pages: 1000 requests per minute (per IP)

---

### 5. Audit Logging

**Log All Security-Relevant Events:**

```prisma
model AuditLog {
  id        String   @id @default(cuid())
  userId    String?  // Null for unauthenticated events
  action    String   // LOGIN_SUCCESS, PASSKEY_REMOVED, DATA_EXPORTED, etc.
  resource  String?  // e.g., "User:abc123", "Project:xyz789"
  ipAddress String?
  userAgent String?
  metadata  Json?    // Additional context
  createdAt DateTime @default(now())

  @@index([userId])
  @@index([action])
  @@index([createdAt])
  @@map("audit_logs")
}
```

**What to Log:**
- ✅ Authentication events (login, logout, passkey changes)
- ✅ Authorization failures (denied access attempts)
- ✅ Data access (who viewed what, when)
- ✅ Data modifications (create, update, delete)
- ✅ Data exports (GDPR requests)
- ✅ Configuration changes (settings, permissions)
- ❌ Sensitive data values (passwords, keys, user content)

**Log Retention:**
- 90 days (standard)
- 1 year (compliance requirement for SOC 2)
- Anonymize after retention period (preserve stats, remove PII)

---

### 6. Dependency Management

**Prevent Supply Chain Attacks:**

```bash
# Audit dependencies for vulnerabilities
bun audit

# Update dependencies regularly (monthly sprint)
bun update

# Lock file integrity (Bun lock file)
git add bun.lock
```

**Automated Scanning:**
- GitHub Dependabot (vulnerability alerts)
- Snyk or Socket.dev (continuous monitoring)
- CI/CD pipeline: Fail build on critical vulnerabilities

**Package Selection Criteria:**
- ✅ Active maintenance (commits within 6 months)
- ✅ Security track record (no major breaches)
- ✅ TypeScript support (type safety)
- ✅ MIT/Apache license (compatible with platform)
- ⚠️ Minimize dependencies (each dep = attack surface)

---

### 7. Secrets Management

**Never Commit Secrets:**

```bash
# .env (gitignored)
DATABASE_URL="postgresql://..."
ENCRYPTION_KEY="64-char-hex-key"
SESSION_SECRET="random-secret-key"

# CI/CD: Use environment secrets (GitHub Actions, Vercel env vars)
```

**Secret Rotation:**
- Database passwords: Quarterly
- API keys: Annually or on breach
- Encryption keys: Never (would lose encrypted data - use versioning instead)
- Session secrets: Quarterly

**Secret Storage:**
- Development: `.env` (gitignored)
- Staging/Production: Vercel environment variables or HashiCorp Vault
- Never: Hardcoded in source code, committed to git

---

## Privacy Controls

### 1. Consent Management

**GDPR/CCPA Requirement:** Explicit opt-in consent for non-essential data processing.

**Implementation:**
```typescript
// Consent types
enum ConsentType {
  ESSENTIAL          // Required for service (authentication, security)
  ANALYTICS          // Optional usage analytics
  MARKETING          // Optional marketing emails
  THIRD_PARTY_SHARE  // Optional data sharing with partners
}

model UserConsent {
  id           String      @id @default(cuid())
  userId       String
  user         User        @relation(fields: [userId], references: [id])
  consentType  ConsentType
  granted      Boolean     @default(false)
  grantedAt    DateTime?
  revokedAt    DateTime?
  ipAddress    String?     // Proof of consent (GDPR requirement)
  createdAt    DateTime    @default(now())
  updatedAt    DateTime    @updatedAt

  @@unique([userId, consentType])
  @@map("user_consents")
}
```

**UI:**
```tsx
// Consent banner (first visit)
<ConsentBanner>
  <p>We use cookies for essential functionality (authentication, security).</p>
  <p>Optional: Help us improve with usage analytics.</p>

  <Button onClick={() => grantConsent('ANALYTICS')}>Accept All</Button>
  <Button onClick={() => grantConsent('ESSENTIAL')}>Essential Only</Button>
  <Link href="/privacy">Privacy Policy</Link>
</ConsentBanner>

// Settings → Privacy
<ConsentSettings>
  <Toggle checked={consents.ANALYTICS} onChange={handleAnalytics}>
    📊 Usage Analytics - Help us improve the platform
  </Toggle>
  <Toggle checked={consents.MARKETING} onChange={handleMarketing}>
    📧 Marketing Emails - Updates and tips
  </Toggle>
</ConsentSettings>
```

---

### 2. Data Minimization

**Collect Only What's Necessary:**

**What We Ask For:**
- ✅ Email (authentication, account recovery)
- ✅ Domain preference (UX personalization)

**What We DON'T Ask For:**
- ❌ Phone number (not needed for core service)
- ❌ Full name (email sufficient for identification)
- ❌ Birthdate (not relevant to platform)
- ❌ Physical address (SaaS doesn't need it)
- ❌ Payment info until subscription (if using Stripe, they handle PCI)

**Progressive Data Collection:**
- MVP: Email only
- Profile: Optional display name
- Billing: Only when user subscribes (handled by Stripe - PCI compliant)

---

### 3. Data Retention

**How Long We Keep Data:**

**Active Users:**
- Account data: Until user deletes account
- Content data: Until user deletes content
- Session data: 30 days after last activity
- Audit logs: 90 days (1 year for compliance)

**Deleted Accounts:**
- Soft delete: 30 days (recovery window)
- Hard delete: After 30 days (permanent, cascading)
- Audit logs: Anonymize user ID (preserve stats)

**Implementation:**
```typescript
// Soft delete (set deletedAt timestamp)
await prisma.user.update({
  where: { id: userId },
  data: { deletedAt: new Date() },
})

// Scheduled job: Permanent deletion after 30 days
async function permanentlyDeleteAccounts() {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)

  const accountsToDelete = await prisma.user.findMany({
    where: {
      deletedAt: { lte: thirtyDaysAgo },
    },
  })

  for (const user of accountsToDelete) {
    // Cascade delete (Prisma handles relations)
    await prisma.user.delete({ where: { id: user.id } })

    // Anonymize audit logs
    await prisma.auditLog.updateMany({
      where: { userId: user.id },
      data: { userId: `DELETED_${user.id}` }, // Preserve stats, remove PII link
    })
  }
}
```

---

### 4. Data Portability

**GDPR Right to Data Portability:**

**Export Format:** JSON (machine-readable) + Markdown (human-readable)

**Implementation:**
```typescript
// API route: /api/user/export
export async function GET(request: Request) {
  const session = await getSession(request)

  // Gather all user data
  const userData = await prisma.user.findUnique({
    where: { id: session.userId },
    include: {
      projects: {
        include: {
          facts: true,
          content: true,
          researchSpecs: true,
        },
      },
      credentials: true,
      logs: true,
    },
  })

  // Remove sensitive fields (credential public keys OK, but remove internal IDs)
  const exportData = {
    user: {
      email: userData.email,
      domain: userData.domain,
      createdAt: userData.createdAt,
    },
    projects: userData.projects.map(p => ({
      name: p.name,
      domain: p.domain,
      facts: p.facts.map(f => ({
        claim: f.claim,
        confidence: f.confidence,
        tier: f.tier,
        source: f.source,
      })),
      content: p.content.map(c => ({
        title: c.title,
        body: c.body,
        confidence: c.confidence,
      })),
    })),
    credentials: userData.credentials.map(c => ({
      deviceName: c.deviceName,
      createdAt: c.createdAt,
      lastUsedAt: c.lastUsedAt,
    })),
  }

  // Return as downloadable JSON
  return new NextResponse(JSON.stringify(exportData, null, 2), {
    headers: {
      'Content-Type': 'application/json',
      'Content-Disposition': `attachment; filename="builder-platform-export-${Date.now()}.json"`,
    },
  })
}
```

**UI:**
```tsx
<Card>
  <CardHeader>
    <CardTitle>Export Your Data</CardTitle>
    <CardDescription>
      Download all your data in JSON format (GDPR Article 20)
    </CardDescription>
  </CardHeader>
  <CardContent>
    <Button onClick={handleExport}>
      📥 Download My Data
    </Button>
  </CardContent>
</Card>
```

---

### 5. Right to Deletion

**GDPR Right to Erasure ("Right to be Forgotten"):**

**Implementation:**
```tsx
<Card>
  <CardHeader>
    <CardTitle>Delete Your Account</CardTitle>
    <CardDescription>
      Permanently delete your account and all data (GDPR Article 17)
    </CardDescription>
  </CardHeader>
  <CardContent>
    <Alert variant="destructive">
      <AlertTitle>⚠️ This action cannot be undone</AlertTitle>
      <AlertDescription>
        All your projects, research, and content will be permanently deleted after 30 days.
      </AlertDescription>
    </Alert>

    <Button variant="destructive" onClick={handleDelete}>
      Delete My Account
    </Button>
  </CardContent>
</Card>
```

**Exceptions (When deletion isn't required):**
- Legal obligation (tax records, court orders)
- Fraud prevention (if user was banned for abuse)
- **But:** Anonymize data (remove PII, keep fraud detection signals)

---

## Framework-Specific Compliance Checklists

### NIST 800-53 Control Mapping

**Access Control (AC) Family:**
- [ ] AC-2: Account Management (user provisioning/deprovisioning)
- [ ] AC-3: Access Enforcement (RBAC implemented)
- [ ] AC-7: Unsuccessful Login Attempts (rate limiting on auth)
- [ ] AC-11: Session Lock (automatic logout after inactivity)
- [ ] AC-17: Remote Access (TLS 1.3 for all connections)

**Audit and Accountability (AU) Family:**
- [ ] AU-2: Audit Events (all auth, data access logged)
- [ ] AU-3: Content of Audit Records (who, what, when, where)
- [ ] AU-6: Audit Review (automated anomaly detection)
- [ ] AU-9: Protection of Audit Information (logs immutable, encrypted)
- [ ] AU-11: Audit Retention (90 days standard, 1 year compliance)

**Identification and Authentication (IA) Family:**
- [ ] IA-2: Identification and Authentication (passkeys implemented)
- [ ] IA-5: Authenticator Management (multi-passkey support)
- [ ] IA-8: Identification and Authentication (device tracking)

**System and Communications Protection (SC) Family:**
- [ ] SC-8: Transmission Confidentiality (TLS 1.3)
- [ ] SC-12: Cryptographic Key Establishment (proper key management)
- [ ] SC-13: Cryptographic Protection (AES-256 for data at rest)
- [ ] SC-28: Protection of Information at Rest (database encryption)

**Full checklist:** 325 controls for FedRAMP Moderate. Document in separate compliance matrix if pursuing government customers.

---

### GDPR Compliance Checklist

**Lawful Basis (Article 6):**
- [ ] Consent obtained for optional data processing (analytics)
- [ ] Legitimate interest documented (fraud prevention)
- [ ] Contract basis clear (service delivery requires email)

**User Rights:**
- [ ] Right to Access (Settings → Download My Data)
- [ ] Right to Rectification (Settings → Edit Profile)
- [ ] Right to Erasure (Settings → Delete Account)
- [ ] Right to Data Portability (JSON export)
- [ ] Right to Object (Opt-out of analytics)
- [ ] Right to Restrict Processing (Pause account, don't delete)

**Data Protection by Design (Article 25):**
- [ ] Encryption at rest and in transit
- [ ] Pseudonymization where possible (user IDs, not emails in logs)
- [ ] Data minimization (only collect necessary data)
- [ ] Privacy by default (opt-in for non-essential)

**Data Breach Notification (Article 33-34):**
- [ ] Incident response plan documented
- [ ] 72-hour notification to supervisory authority (if breach)
- [ ] User notification if high risk

**Data Protection Officer (DPO):**
- [ ] Not required until >250 employees OR large-scale sensitive data processing
- [ ] Designate contact for privacy inquiries (privacy@builder-platform.com)

**Data Processing Agreements (DPA):**
- [ ] Signed DPA with all vendors (Vercel, Railway, etc.)
- [ ] GDPR-compliant data processing terms

**Privacy Policy:**
- [ ] Published at /privacy
- [ ] Clear, plain language (not legalese)
- [ ] Updated within 30 days of material changes

---

### CCPA Compliance Checklist

**Applicability Check:**
- [ ] Annual gross revenue > $25M? (NOT YET - track when approaching)
- [ ] Data of 50,000+ CA residents? (NOT YET - track user count)
- [ ] 50%+ revenue from selling personal data? (NO - we don't sell data)

**If applicable:**

**Consumer Rights:**
- [ ] Right to Know (what data collected, how used)
- [ ] Right to Delete (same as GDPR)
- [ ] Right to Opt-Out of Sale (we don't sell, but must offer)
- [ ] Right to Non-Discrimination (no different pricing for privacy choices)

**"Do Not Sell My Personal Information" Link:**
- [ ] Required in footer (even if not selling)
- [ ] Clarify "We do not sell your personal information"

**Notice at Collection:**
- [ ] Privacy policy lists data categories collected
- [ ] Purposes for collection documented

**Authorized Agent Requests:**
- [ ] Process for users to designate agent to request deletion

---

### SOC 2 Control Mapping

**Security:**
- [ ] CC6.1: Logical and physical access restricted
- [ ] CC6.2: Transmission protected (TLS 1.3)
- [ ] CC6.3: Data at rest protected (encryption)
- [ ] CC6.6: Vulnerability management (dependency scanning)
- [ ] CC6.7: System monitoring (audit logs, anomaly detection)
- [ ] CC6.8: Malware protection (WAF, rate limiting)

**Availability:**
- [ ] CC7.1: System availability monitored
- [ ] CC7.2: Recovery procedures documented (backup/restore)

**Processing Integrity:**
- [ ] CC8.1: Processing complete and accurate (input validation)

**Confidentiality:**
- [ ] CC9.1: Confidential data identified (data classification)
- [ ] CC9.2: Confidential data disposed securely (deletion process)

**Privacy:**
- [ ] CC10.1: Notice provided (privacy policy)
- [ ] CC10.2: Choice and consent obtained
- [ ] CC10.3: Collection limited (data minimization)
- [ ] CC10.4: Data use limited to stated purposes
- [ ] CC10.5: Data access provided to users (export)
- [ ] CC10.6: Data disclosed per commitments (no unexpected sharing)
- [ ] CC10.7: Data quality maintained (accuracy)
- [ ] CC10.8: Data monitoring and enforcement (audit logs)

**SOC 2 Audit Timeline:**
- Month 1-6: Document policies and procedures
- Month 7-12: Operate controls, collect evidence
- Month 12: Type I audit (design effectiveness)
- Month 18: Type II audit (operating effectiveness over 6 months)

---

### OWASP Top 10 Mitigation Strategies

**A01: Broken Access Control**
- ✅ Implement RBAC (Role-Based Access Control)
- ✅ Enforce principle of least privilege
- ✅ Server-side access checks (never trust client)
- ✅ Row-level security (users see only their data)

**A02: Cryptographic Failures**
- ✅ TLS 1.3 for all connections
- ✅ AES-256 for data at rest
- ✅ Proper key management (no hardcoded keys)
- ✅ HSTS enabled (force HTTPS)

**A03: Injection**
- ✅ Prisma ORM (parameterized queries prevent SQL injection)
- ✅ Input validation with Zod (runtime type checking)
- ✅ React escapes by default (prevents XSS)
- ✅ CSP header (Content Security Policy)

**A04: Insecure Design**
- ✅ Threat modeling (identify attack vectors)
- ✅ Security requirements in design phase
- ✅ Passkeys from day 1 (not bolted on later)

**A05: Security Misconfiguration**
- ✅ No default passwords or keys
- ✅ Error handling (no stack traces in production)
- ✅ Security headers enabled (X-Frame-Options, etc.)
- ✅ Minimal permissions (least privilege)

**A06: Vulnerable and Outdated Components**
- ✅ Dependency scanning (bun audit, Snyk)
- ✅ Monthly dependency updates
- ✅ Automated vulnerability alerts (Dependabot)

**A07: Identification and Authentication Failures**
- ✅ Passkeys (phishing-resistant)
- ✅ Session management (secure cookies, expiration)
- ✅ Rate limiting (prevent brute force)
- ✅ Multi-passkey support (device redundancy)

**A08: Software and Data Integrity Failures**
- ✅ Dependency lock files (bun.lock)
- ✅ Code signing (Git commit signatures)
- ✅ CI/CD pipeline integrity (GitHub Actions OIDC)

**A09: Security Logging and Monitoring Failures**
- ✅ Comprehensive audit logging
- ✅ Log retention (90 days)
- ✅ Anomaly detection (failed login patterns)
- ✅ Incident alerting (Sentry, email alerts)

**A10: Server-Side Request Forgery (SSRF)**
- ✅ Input validation for URLs
- ✅ Whitelist allowed domains
- ✅ Network segmentation (API can't access internal services)

---

## Extensible Framework Adapter Pattern

### Pluggable Compliance Modules

**Goal:** Add new frameworks (HIPAA, PCI-DSS, ISO 27001) without rewriting entire security system.

**Pattern:**
```typescript
// lib/compliance/framework-adapter.ts
interface ComplianceFramework {
  name: string
  version: string
  controls: Control[]

  checkCompliance(): Promise<ComplianceReport>
  generateAuditReport(): Promise<AuditReport>
  documentEvidence(controlId: string, evidence: Evidence): Promise<void>
}

// Implement per framework
class GDPRAdapter implements ComplianceFramework {
  name = 'GDPR'
  version = '2018'
  controls = [
    { id: 'ART6', name: 'Lawful Basis', status: 'COMPLIANT' },
    { id: 'ART15', name: 'Right to Access', status: 'COMPLIANT' },
    // ...
  ]

  async checkCompliance() {
    // Query systems to verify GDPR compliance
    const hasPrivacyPolicy = await checkPrivacyPolicyExists()
    const hasConsentMechanism = await checkConsentImplemented()
    const hasDataExport = await checkExportFunctionality()

    return {
      framework: 'GDPR',
      overallStatus: hasPrivacyPolicy && hasConsentMechanism && hasDataExport ? 'COMPLIANT' : 'NON_COMPLIANT',
      controls: this.controls,
      lastChecked: new Date(),
    }
  }

  async generateAuditReport() {
    // Collect evidence for auditor
  }
}

class SOC2Adapter implements ComplianceFramework {
  name = 'SOC 2'
  version = '2017'
  controls = [
    { id: 'CC6.1', name: 'Logical Access', status: 'IN_PROGRESS' },
    // ...
  ]

  // Same interface, different implementation
}

// Registry of frameworks
const complianceRegistry = {
  gdpr: new GDPRAdapter(),
  soc2: new SOC2Adapter(),
  ccpa: new CCPAAdapter(),
  // Add future frameworks here
}

// Usage
export async function checkAllCompliance() {
  const reports = await Promise.all(
    Object.values(complianceRegistry).map(framework => framework.checkCompliance())
  )

  return reports
}
```

**Benefits:**
- ✅ Add HIPAA compliance without touching GDPR code
- ✅ Generate framework-specific audit reports
- ✅ Automate compliance checks (CI/CD integration)
- ✅ Dashboard shows compliance status across all frameworks

**Dashboard Example:**
```tsx
<ComplianceDashboard>
  <FrameworkCard framework="GDPR" status="COMPLIANT" lastChecked="2024-10-07" />
  <FrameworkCard framework="SOC 2" status="IN_PROGRESS" lastChecked="2024-10-07" />
  <FrameworkCard framework="CCPA" status="NOT_APPLICABLE" lastChecked="2024-10-07" />
  <FrameworkCard framework="HIPAA" status="NOT_IMPLEMENTED" />
</ComplianceDashboard>
```

---

## Incident Response Plan

### Detection

**How We Detect Security Incidents:**
- Automated alerting (Sentry error tracking)
- Audit log anomalies (unusual login patterns, mass data access)
- User reports (security@builder-platform.com)
- Vulnerability disclosures (security researchers)

---

### Response Procedure

**1. Identification (0-1 hour)**
- [ ] Confirm incident is real (not false positive)
- [ ] Assess severity (Critical, High, Medium, Low)
- [ ] Notify incident response team

**Severity Criteria:**
- **Critical:** Data breach, authentication bypass, active exploit
- **High:** Vulnerability with no known exploit (but high risk)
- **Medium:** Vulnerability with low exploitability
- **Low:** Theoretical vulnerability, no user impact

**2. Containment (1-4 hours)**
- [ ] Isolate affected systems (disable compromised accounts, revoke tokens)
- [ ] Preserve evidence (logs, database snapshots)
- [ ] Prevent further damage (patch vulnerability, block IPs)

**3. Eradication (4-24 hours)**
- [ ] Remove threat (patch code, remove malware, revoke compromised credentials)
- [ ] Verify systems clean (scan for backdoors, check audit logs)

**4. Recovery (24-72 hours)**
- [ ] Restore services (bring systems back online)
- [ ] Monitor for reinfection (heightened alerting)
- [ ] Verify functionality (test critical paths)

**5. Lessons Learned (Within 1 week)**
- [ ] Document incident timeline
- [ ] Identify root cause
- [ ] Update procedures (prevent recurrence)
- [ ] Train team (if process gaps identified)

---

### Breach Notification Requirements

**GDPR (Article 33-34):**
- Notify supervisory authority within 72 hours
- Notify users if "high risk" to rights and freedoms

**CCPA:**
- Notify California Attorney General if >500 CA residents affected
- Notify affected users

**SOC 2:**
- Notify customers (per contract terms)
- Document in audit report

**Template:**
```
Subject: Security Incident Notification - The Builder Platform

Dear [User],

We are writing to inform you of a security incident that may have affected your account.

What Happened:
On [DATE], we discovered [BRIEF DESCRIPTION]. We immediately took action to [CONTAINMENT STEPS].

What Information Was Involved:
[LIST DATA TYPES - e.g., "Email addresses and account creation dates. No content data, passkeys, or financial information was affected."]

What We Are Doing:
- [ERADICATION STEPS]
- [PREVENTIVE MEASURES]

What You Can Do:
- [RECOMMENDED USER ACTIONS - e.g., "Register a new passkey if you haven't already"]
- Monitor your account for unusual activity

We take your security seriously and sincerely apologize for this incident.

Contact: security@builder-platform.com

Sincerely,
The Builder Platform Team
```

---

## Vendor Management

### Third-Party Security Requirements

**Before Selecting Vendor:**
- [ ] Review privacy policy (GDPR/CCPA compliant?)
- [ ] Check security certifications (SOC 2, ISO 27001?)
- [ ] Sign Data Processing Agreement (DPA)
- [ ] Verify data encryption (at rest and in transit)
- [ ] Confirm data location (EU servers for EU users?)
- [ ] Review breach notification terms

**Current Vendors:**
- **Vercel:** Hosting (SOC 2 Type II, GDPR compliant)
- **Railway/Render:** Database hosting (SOC 2, GDPR compliant)
- **Prisma:** ORM (open source, no data collection)
- **SimpleWebAuthn:** Passkey library (open source, no vendor)
- **Sentry:** Error tracking (optional, consent-based)

**Vendor Review:** Annually or when contract renews

---

## Development Lifecycle Integration

### Secure SDLC (Software Development Lifecycle)

**Phase 1: Design**
- [ ] Threat modeling (identify attack vectors)
- [ ] Security requirements documented
- [ ] Privacy impact assessment (new data collection?)

**Phase 2: Development**
- [ ] Code review (security-focused)
- [ ] Static analysis (ESLint security rules, TypeScript strict mode)
- [ ] Dependency scanning (bun audit)

**Phase 3: Testing**
- [ ] Unit tests (security functions)
- [ ] Integration tests (access control, auth flows)
- [ ] Penetration testing (manual or automated)

**Phase 4: Deployment**
- [ ] Secrets management (no hardcoded keys)
- [ ] Environment separation (dev/staging/prod)
- [ ] Rollback plan (if deployment issues)

**Phase 5: Monitoring**
- [ ] Error tracking (Sentry)
- [ ] Performance monitoring (Vercel Analytics)
- [ ] Security alerting (anomaly detection)

---

## Audit & Certification Roadmap

### Timeline

**Month 1-3 (Foundation):**
- Implement core security controls
- Document policies and procedures
- Privacy policy published
- GDPR/CCPA compliance achieved

**Month 4-6 (Pre-Audit):**
- Internal security audit (self-assessment)
- Penetration testing (external firm)
- Remediate findings
- Document evidence collection

**Month 7-12 (SOC 2 Type I Preparation):**
- Operate controls consistently
- Collect audit evidence
- Employee training (security awareness)
- Vendor DPAs signed

**Month 12 (SOC 2 Type I Audit):**
- Engage auditor (Big 4 or specialized firm)
- Provide evidence (logs, policies, code samples)
- Receive Type I report (design effectiveness)

**Month 13-18 (SOC 2 Type II Preparation):**
- Continue operating controls
- 6-month evidence period
- Quarterly internal audits

**Month 18 (SOC 2 Type II Audit):**
- Type II audit (operating effectiveness)
- Receive final report
- Publish SOC 2 badge (marketing)

---

## Continuous Improvement

### Security Review Cadence

**Weekly:**
- Dependency updates (critical vulnerabilities only)
- Incident review (if any occurred)

**Monthly:**
- Dependency updates (all outdated packages)
- Security metrics review (failed logins, rate limit triggers)
- New vulnerability research (OWASP, CVE databases)

**Quarterly:**
- Compliance framework review (update checklists)
- Vendor security review (still compliant?)
- Policy updates (reflect new regulations)
- Team security training (new threats, best practices)

**Annually:**
- External penetration test
- SOC 2 audit (Type II)
- Comprehensive policy review
- Incident response drill (tabletop exercise)

---

## Tag Index

#security #governance #compliance #gdpr #ccpa #soc2 #nist-800-53 #owasp #encryption #access-control #audit-logging #incident-response #privacy #data-protection #vendor-management #secure-sdlc #penetration-testing #compliance-frameworks #extensible-architecture #2-way-door

---

**Status:** Living document. Update as regulations change, incidents occur, or new frameworks adopted.

**Next Review:** January 7, 2025 (Quarterly)

**Owner:** Platform Security Team (initially: Founder)

**Contact:** security@builder-platform.com
