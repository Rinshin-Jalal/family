# 🚀 Family+ Complete Deployment Guide

## 🎯 Choose Your Launch Path

| Feature | **TestFlight Beta** ⚡ | **App Store Public** 🌎 |
|---------|----------------------|----------------------|
| **Time to Launch** | 1-2 hours | 3-5 days |
| **Review Required** | None (internal) / 1-2 days (external) | 1-3 days (strict) |
| **Max Users** | 10,000 testers | Unlimited |
| **Screenshots** | 1 per device (optional) | 3-10 per device (required) |
| **Metadata** | Minimal | Complete everything |
| **Privacy Disclosures** | Basic | Detailed questionnaire |
| **Updates** | Same day possible | 1-3 days per update |
| **Expiration** | 90 days per build | Never |
| **Best For** | Beta testing, feedback, iteration | Public launch |

**🎓 Recommended Strategy**:
1. **Week 1**: Internal TestFlight (your team) → Fix bugs
2. **Week 2-3**: External TestFlight (beta users) → Gather feedback
3. **Week 4**: App Store launch (if ready)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRODUCTION ENVIRONMENT                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐      ┌──────────────────┐      ┌──────────────┐ │
│  │   iOS App    │ ───▶ │  Cloudflare      │ ───▶ │   Supabase   │ │
│  │ (App Store)  │      │  Workers (Hono)  │      │  PostgreSQL  │ │
│  └──────────────┘      └──────────────────┘      └──────────────┘ │
│                                │                                   │
│                                ▼                                   │
│                         ┌──────────────┐                           │
│                         │  Trigger.dev │                           │
│                         │   v3 Jobs    │                           │
│                         └──────────────┘                           │
│                                                                      │
│  External Services:                                                  │
│  - AWS Bedrock (AI)                                                  │
│  - Cartesia (Transcription)                                          │
│  - OpenAI (Embeddings)                                               │
│  - Twilio (SMS/Calls)                                                │
│  - Cloudflare R2 (Audio Storage)                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] Create Cloudflare account
- [ ] Create Supabase project
- [ ] Create Trigger.dev account
- [ ] Get Apple Developer account
- [ ] Get AWS Bedrock access
- [ ] Get Cartesia API key
- [ ] Get OpenAI API key
- [ ] (Optional) Get Twilio account

### Infrastructure
- [ ] Create R2 bucket (`family-plus-audio`)
- [ ] Configure Supabase database
- [ ] Run database migrations
- [ ] Set up Supabase storage

### Backend
- [ ] Configure Cloudflare Workers secrets
- [ ] Deploy Cloudflare Worker
- [ ] Configure Trigger.dev environment
- [ ] Deploy Trigger.dev tasks
- [ ] Test API endpoints
- [ ] Verify background tasks

### iOS App
- [ ] Configure code signing
- [ ] Add iOS capabilities
- [ ] Update API base URL
- [ ] Configure Supabase credentials
- [ ] **Launch on TestFlight** (⚡ FAST - see below)
- [ ] Gather beta feedback
- [ ] Iterate and fix bugs
- [ ] *Then* submit to App Store (optional)

**⚡ RECOMMENDED**: Start with **TestFlight launch** (hours, not days)!
**📖 See**: `familyplus/TESTFLIGHT_DEPLOYMENT.md` for rapid beta testing.

---

## 🎯 Quick Start Deployment

### Step 1: Deploy Infrastructure (15 min)

```bash
# 1. Create R2 bucket
wrangler r2 bucket create family-plus-audio

# 2. Setup Supabase
cd supabase
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase db reset  # Seed initial data

# 3. Verify database
supabase db diff
```

### Step 2: Deploy Backend (10 min)

```bash
cd backend

# Set secrets (interactive)
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_KEY
wrangler secret put AWS_BEARER_TOKEN_BEDROCK
wrangler secret put AWS_REGION
wrangler secret put CARTESIA_API_KEY
wrangler secret put OPENAI_API_KEY

# Deploy worker
npm run deploy

# Verify deployment
curl https://family-plus-backend.YOUR_SUBDOMAIN.workers.dev/
```

### Step 3: Deploy Background Tasks (5 min)

```bash
cd backend

# Configure Trigger.dev environment variables
# Visit: https://cloud.trigger.dev → Settings → Environment Variables

# Deploy tasks
npx trigger.dev@latest deploy

# Verify tasks
npx trigger.dev@latest tasks
```

### Step 4: Deploy iOS App to TestFlight (1 hour)

```bash
cd familyplus

# Update API base URL
# Edit: Services/APIService.swift line 33
# Set: private let API_BASE_URL = "https://your-worker-url.workers.dev"

# Update Supabase credentials
# Edit: Services/SupabaseService.swift
# Set: supabaseURL and supabaseKey

# Open in Xcode
open familyplus.xcodeproj

# In Xcode:
# 1. Select target: familyplus
# 2. Signing & Capabilities → Select team
# 3. Add capabilities:
#    - Background Modes (Audio, Processing)
#    - Microrone Usage Description
#    - Photo Library Usage Description
#    - Camera Usage Description
# 4. Set version to 0.1.0 (beta < 1.0)
# 5. Product → Archive
# 6. Distribute App → TestFlight
# 7. Upload build
```

**Then in App Store Connect**:
1. Create app (minimal info only)
2. Add internal testers (no review required!)
3. Testers install via TestFlight app

**📖 Full TestFlight Guide**: `familyplus/TESTFLIGHT_DEPLOYMENT.md`

---

## 🔗 Service Configuration

### Cloudflare Workers

```bash
# Worker URL
https://family-plus-backend.YOUR_SUBDOMAIN.workers.dev

# Environment variables (wrangler secret put)
- SUPABASE_URL
- SUPABASE_KEY
- AWS_BEARER_TOKEN_BEDROCK
- AWS_REGION
- CARTESIA_API_KEY
- OPENAI_API_KEY
- twilio_account_sid (optional)
- twilio_auth_token (optional)

# R2 Bucket
family-plus-audio
```

### Trigger.dev

```bash
# Dashboard
https://cloud.trigger.dev

# Project ID
proj_vdbanaagzxesesgrgmgvuz

# Environment variables (set in dashboard)
- SUPABASE_URL
- SUPABASE_KEY
- AWS_BEARER_TOKEN_BEDROCK
- AWS_REGION
- CARTESIA_API_KEY
- OPENAI_API_KEY
```

### Supabase

```bash
# Project URL
https://YOUR_PROJECT_REF.supabase.co

# Required keys
- Service Role Key (for backend)
- Anon Key (for iOS app)

# Database
- PostgreSQL (managed by Supabase)
- Migrations in supabase/migrations/
- Seed data in supabase/seed.sql

# Storage
- Audio files: R2 (not Supabase Storage)
- Images: Supabase Storage (optional)
```

### iOS App

```bash
# Bundle ID
com.yourcompany.familyplus

# Configuration files
- familyplus/Services/APIService.swift
- familyplus/Services/SupabaseService.swift

# Build settings
- Minimum iOS: 16.0
- Swift Language Version: 5.0
- Optimization: -O (release)
```

---

## 🧪 Testing Checklist

### Backend API Tests

```bash
# Health check
curl https://your-worker.workers.dev/

# Create family
curl -X POST https://your-worker.workers.dev/families \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Family"}'

# Get stories
curl https://your-worker.workers.dev/stories?family_id=YOUR_FAMILY_ID

# Create response
curl -X POST https://your-worker.workers.dev/responses \
  -H "Content-Type: application/json" \
  -d '{
    "familyId": "YOUR_FAMILY_ID",
    "promptId": "YOUR_PROMPT_ID",
    "content": "Test story",
    "mediaType": "text"
  }'
```

### Trigger.dev Task Tests

```bash
# Verify tasks are registered
npx trigger.dev@latest tasks

# Monitor task runs
npx trigger.dev@latest runs

# Test specific task
curl -X POST https://your-worker.workers.dev/test/trigger \
  -d '{"task": "process-text-response"}'
```

### iOS App Tests

```bash
# In Xcode:
# 1. Run on simulator
# 2. Run on physical device
# 3. Test authentication flow
# 4. Test story capture
# 5. Test audio recording
# 6. Test photo upload
# 7. Test playback
# 8. Test settings
```

---

## 📊 Monitoring & Observability

### Cloudflare Workers

```bash
# Dashboard
https://dash.cloudflare.com → Workers

# Metrics to monitor
- Request count
- Error rate
- Response time
- CPU usage
- Memory usage

# Logs
# Real-time logs in dashboard
# Export to logpush for long-term storage
```

### Trigger.dev

```bash
# Dashboard
https://cloud.trigger.dev

# Metrics to monitor
- Task execution time
- Success rate
- Failure rate
- Queue depth

# Alerts
# Configure email alerts for failures
# Set up webhook notifications
```

### Supabase

```bash
# Dashboard
https://supabase.com/dashboard

# Metrics to monitor
- Database connections
- Query performance
- Storage usage
- API requests

# Logs
# Database query logs
# API request logs
# Auth events
```

### iOS App

```bash
# App Store Connect
https://appstoreconnect.apple.com

# Metrics to monitor
- Crash reports
- Analytics
- Ratings and reviews
- Usage metrics

# Tools
- Firebase Crashlytics
- TestFlight beta testing
- App Analytics
```

---

## 🔄 CI/CD Pipeline

### Backend Deployment

```bash
# .github/workflows/deploy-backend.yml
name: Deploy Backend

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm test
      - run: npm run deploy
```

### Trigger.dev Deployment

```bash
# .github/workflows/deploy-trigger.yml
name: Deploy Trigger Tasks

on:
  push:
    paths:
      - 'backend/trigger/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npx trigger.dev@latest deploy
```

### iOS App Deployment

```bash
# Use Xcode Cloud or fastlane
# Fastfile:

lane beta do
  build_app(scheme: "familyplus")
  upload_to_testflight
end

lane release do
  build_app(scheme: "familyplus")
  upload_to_app_store
end
```

---

## 🚨 Rollback Procedures

### Backend Rollback

```bash
# List deployments
wrangler deployments list

# Rollback to previous
wrangler rollback

# Or deploy specific version
wrangler deploy --compatibility-date 2025-12-20
```

### Trigger.dev Rollback

```bash
# Redeploy previous version
git checkout PREVIOUS_COMMIT
npx trigger.dev@latest deploy
```

### iOS App Rollback

```bash
# App Store doesn't support rollback
# Must submit new version with hotfix
# Request expedited review if critical
```

---

## 🔐 Security Checklist

### Secrets Management
- [ ] Never commit `.dev.vars`
- [ ] Use Cloudflare secrets for production
- [ ] Rotate API keys regularly
- [ ] Use different keys for dev/prod
- [ ] Monitor for secret leaks

### API Security
- [ ] Implement rate limiting
- [ ] Add CORS headers
- [ ] Validate all inputs
- [ ] Use HTTPS only
- [ ] Implement auth middleware

### Database Security
- [ ] Use Supabase RLS policies
- [ ] Enable row-level security
- [ ] Use service role keys only server-side
- [ ] Regular backups enabled
- [ ] Audit logging enabled

### iOS App Security
- [ ] Store keys in secure enclave
- [ ] Use Keychain for sensitive data
- [ ] Enable App Transport Security
- [ ] Disable jailbreak detection bypasses
- [ ] Obfuscate sensitive code

---

## 📚 Documentation Links

### 🚀 Quick Start Guides
- **[TestFlight Launch Guide](./familyplus/TESTFLIGHT_DEPLOYMENT.md)** - ⚡ START HERE (beta in hours!)
- [Backend Deployment](./backend/DEPLOYMENT.md) - Cloudflare Workers setup
- [Trigger.dev Deployment](./backend/TRIGGER_DEPLOYMENT.md) - Background tasks

### 📱 iOS App Guides
- **[TestFlight Deployment](./familyplus/TESTFLIGHT_DEPLOYMENT.md)** - Rapid beta testing
- [iOS App Deployment](./familyplus/DEPLOYMENT.md) - Xcode build & archive
- [App Store Connect Guide](./familyplus/APP_STORE_CONNECT_GUIDE.md) - Full public launch

### 📋 Planning & Reference
- [Complete Deployment Guide](./DEPLOYMENT_GUIDE.md) - This file
- [Production Launch Plan](./familyplus/PRODUCTION_LAUNCH_PLAN.md) - Feature checklist
- [Backend README](./backend/README.md) - API documentation
- [Supabase Setup](./backend/AWS_BEDROCK_SETUP.md) - Database setup

---

## 🆘 Support & Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Worker fails to start | Check secrets, verify wrangler.toml |
| Tasks not running | Check Trigger.dev environment variables |
| Database errors | Verify Supabase connection, check migrations |
| iOS build fails | Check code signing, verify bundle ID |
| Audio upload fails | Check R2 bucket permissions |

### Emergency Contacts

- Cloudflare Support: https://support.cloudflare.com
- Trigger.dev Support: https://trigger.dev/docs/support
- Supabase Support: https://supabase.com/support
- Apple Developer Support: https://developer.apple.com/support

---

## ✅ Success Criteria

Deployment is successful when:

1. ✅ Backend API responds to health check
2. ✅ All database migrations applied
3. ✅ R2 bucket is accessible
4. ✅ Trigger.dev tasks are registered
5. ✅ Test story can be created and retrieved
6. ✅ Background tasks complete successfully
7. ✅ iOS app can authenticate
8. ✅ iOS app can upload stories
9. ✅ Audio playback works
10. ✅ All monitoring is configured

---

**Last Updated**: 2026-01-12
**Status**: 🟢 Ready for Deployment
**Next Review**: After production deployment
