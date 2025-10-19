# Firestore Security Rules & Indexes Deployment Guide

**Version:** 1.0 **Date:** 2025-10-19 **Task:** 13.2 - Implement Tenant-Aware
Firestore Security Rules

---

## 📋 Overview

This document provides deployment instructions for Firestore Security Rules and
Indexes for the multi-tenant Adyela platform.

**Files:**

- `firestore.rules` - 462 lines of HIPAA-compliant security rules
- `firestore.indexes.json` - 14 composite indexes for optimal query performance

---

## 🚀 Deployment Commands

### Prerequisites

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Verify project
firebase projects:list
```

### Deploy to Staging

```bash
# Set project
firebase use adyela-staging

# Deploy rules only
firebase deploy --only firestore:rules

# Deploy indexes only
firebase deploy --only firestore:indexes

# Deploy both
firebase deploy --only firestore

# Estimated time: 2-5 minutes
```

### Deploy to Production

```bash
# Set project
firebase use adyela-production

# Deploy both rules and indexes
firebase deploy --only firestore

# IMPORTANT: Monitor for errors after deployment
```

---

## ✅ Validation & Testing

### Test Rules Locally (Emulator)

```bash
# Start Firestore emulator
firebase emulators:start --only firestore

# In another terminal, run integration tests
cd tests/firestore
npm test

# Rules will be loaded from firestore.rules automatically
```

### Manual Testing Checklist

**Tenant Isolation:**

- [ ] User in tenant A cannot read tenant B appointments
- [ ] User cannot create appointment in tenant they don't belong to
- [ ] User cannot modify tenant_id of existing appointment

**PHI Protection:**

- [ ] Patient can only read their own prescriptions
- [ ] Only prescribing practitioner can update prescription (within 24h)
- [ ] Medical records cannot be deleted by anyone except admins

**RBAC:**

- [ ] Only tenant owner can update tenant settings
- [ ] Only practitioners can create prescriptions
- [ ] Only admins can read audit logs

---

## 📊 Post-Deployment Verification

### Check Rules Status

```bash
firebase firestore:indexes

# Should show all 14 indexes
# Status should be "READY" (may take 5-10 minutes to build)
```

### Monitor Logs

```bash
# Check for security rule violations
gcloud logging read "resource.type=cloud_firestore_database AND severity=ERROR" --limit 50 --format json

# Look for:
# - Permission denied errors
# - Index not found errors
```

### Performance Check

Run these queries and verify they use indexes (not full scans):

```python
# Query 1: Patient appointments
db.collection("tenants").document(tenant_id)\\
  .collection("appointments")\\
  .where("patient_id", "==", patient_id)\\
  .order_by("start_time", "desc")\\
  .limit(20).get()

# Query 2: Practitioner appointments by status
db.collection("tenants").document(tenant_id)\\
  .collection("appointments")\\
  .where("practitioner_id", "==", practitioner_id)\\
  .where("status", "==", "confirmed")\\
  .order_by("start_time", "asc").get()
```

---

## 🔄 Rollback Procedure

If issues are detected after deployment:

```bash
# Option 1: Revert to previous rules
git checkout HEAD~1 firestore.rules
firebase deploy --only firestore:rules

# Option 2: Deploy permissive rules temporarily
# (NOT recommended for production)
```

---

## 📝 Testing Strategy

### Unit Tests (Firestore Rules Test Framework)

Create `tests/firestore/security-rules.test.js`:

```javascript
const testing = require('@firebase/rules-unit-testing');

describe('Multi-Tenant Security Rules', () => {
  it('allows user to read appointments in their tenant', async () => {
    const db = await testing.initializeTestEnvironment({
      projectId: 'test-project',
      firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
    });

    // Test implementation
  });

  it('denies cross-tenant data access', async () => {
    // Test that user in tenant A cannot read tenant B data
  });
});
```

### Integration Tests

```bash
# Run full test suite
npm run test:firestore

# Expected: All tests pass
# Coverage: Tenant isolation, RBAC, PHI protection
```

---

## 📈 Index Build Time Estimates

| Collection    | Documents | Build Time |
| ------------- | --------- | ---------- |
| appointments  | < 10K     | 2-5 min    |
| appointments  | 10K-100K  | 5-15 min   |
| appointments  | > 100K    | 15-60 min  |
| prescriptions | Any       | 2-10 min   |
| audit_logs    | Any       | 5-15 min   |

**Note:** Index building happens in background. Queries will work but may be
slower until indexes are READY.

---

## 🔧 Troubleshooting

### Issue: "Index not found" error

**Solution:**

```bash
# Check index status
firebase firestore:indexes

# If status is "CREATING", wait 5-10 minutes
# If status is "ERROR", redeploy indexes
firebase deploy --only firestore:indexes
```

### Issue: "Permission denied" errors

**Solution:**

1. Check user authentication status
2. Verify user belongs to tenant (check `/users/{uid}/tenants/{tenantId}`
   exists)
3. Check user role in `

/users/{uid}`document 4. Review rules logic in`firestore.rules`

### Issue: Slow queries after deployment

**Solution:**

```bash
# Verify indexes are READY
firebase firestore:indexes

# Check query patterns match index definitions
# Add missing indexes to firestore.indexes.json and redeploy
```

---

## 📚 Related Documentation

- [Firestore Multi-Tenant Schema Design](/docs/architecture/firestore-multitenant-schema-design.md)
- [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Index Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)

---

**Status:** ✅ Ready for Deployment **Owner:** Backend Team **Review:** Security
Team (before production deployment)
