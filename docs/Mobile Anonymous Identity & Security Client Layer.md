## Product: MedVerify Mobile App (Flutter)

## Status: Draft v1

---

# 1. Purpose

Implement client-side anonymous identity generation and secure communication with backend services while minimizing onboarding friction.

The mobile application must:

- Create anonymous identities
    
- Store secrets securely
    
- Sign requests
    
- Refresh sessions automatically
    
- Secure uploads
    

---

# 2. Goals

Primary goals:

- Zero-login onboarding
    
- Persistent device identity
    
- Secure local secret storage
    
- Automatic authentication management
    

Non-goals:

- User accounts
    
- Password management
    
- Manual authentication flows
    

---

# 3. Responsibilities

Flutter app owns:

- Device identity generation
    
- Secret storage
    
- Request signing
    
- Token storage
    
- Token refresh
    
- Upload execution
    

---

# 4. First Launch Flow

Application startup:

```text
Launch App
   ↓
Check Existing Identity
   ↓
If Missing:
Generate Identity
   ↓
Register Device
   ↓
Store Tokens
```

---

# 5. Device Identity Requirements

Generate:

```text
device_public_id → UUID

device_secret → 256-bit random
```

Requirements:

- Generated once
    
- Persist across app sessions
    
- Regenerated only after reinstall/reset
    

---

# 6. Secure Storage Requirements

Store using:

Android:

```text
Android Keystore
```

iOS:

```text
Keychain
```

Store:

- Device secret
    
- Tokens
    
- Device ID
    

Never store:

- Plain secrets in shared preferences
    
- Secrets in local files
    

---

# 7. API Request Requirements

Every protected request includes:

```text
Authorization: Bearer token

X-Device-ID: id

X-Timestamp: unix time

X-Signature: signature
```

---

# 8. Request Signing

Algorithm:

```text
signature =
HMAC_SHA256(
 device_secret,
 method +
 path +
 timestamp +
 body_hash
)
```

Requirements:

- Automatic signing
    
- Centralized interceptor
    
- Retry-safe
    

---

# 9. Token Management

Requirements:

- Automatic refresh
    
- Refresh before expiry
    
- Silent renewal
    

Failure flow:

```text
Expired Token
   ↓
Refresh
   ↓
Retry Request
```

---

# 10. Upload Workflow

Flow:

```text
Get Upload Permission
    ↓
Receive Upload URL
    ↓
Upload File
    ↓
Notify Backend
```

Requirements:

- Retry uploads
    
- Track progress
    
- Validate file locally first
    

---

# 11. Failure Handling

Handle:

- Invalid signatures
    
- Expired tokens
    
- Blocked device
    
- Upload failures
    
- Connectivity loss
    

---

# 12. Analytics Events

Track:

- Registration success
    
- Registration failures
    
- Upload failures
    
- Signature failures
    
- Token refresh events
    

---

# 13. Success Metrics

- <5 second onboarding
    
- > 99% successful registrations
    
- <1% failed refresh attempts
    
- <2% upload failures