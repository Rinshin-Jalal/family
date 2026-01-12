# Backend Deployment Guide - Family+

## Prerequisites

- Cloudflare account with Workers enabled
- Supabase project created
- AWS Bedrock access (or OpenAI API key)
- Twilio account (for elder phone features)

---

## Phase 1: Infrastructure Setup

### 1.1 Create R2 Bucket for Audio Storage

```bash
# Install Wrangler CLI
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Create R2 bucket
wrangler r2 bucket create family-plus-audio

# Verify bucket creation
wrangler r2 bucket list
```

### 1.2 Configure Supabase

```bash
# Navigate to supabase directory
cd ../supabase

# Link to your Supabase project
supabase link --project-ref YOUR_PROJECT_REF

# Push database schema
supabase db push

# Seed initial data (optional)
supabase db reset
```

### 1.3 Set Environment Secrets

```bash
cd ../backend

# Set production secrets
wrangler secret put SUPABASE_URL
# Enter: https://your-project.supabase.co

wrangler secret put SUPABASE_KEY
# Enter: your-service-role-key

wrangler secret put AWS_BEARER_TOKEN_BEDROCK
# Enter: your-aws-bearer-token

wrangler secret put AWS_REGION
# Enter: us-west-2

wrangler secret put CARTESIA_API_KEY
# Enter: your-cartesia-api-key

wrangler secret put OPENAI_API_KEY
# Enter: your-openai-api-key (for story synthesis)

wrangler secret put twilio_account_sid
# Enter: your-twilio-sid

wrangler secret put twilio_auth_token
# Enter: your-twilio-token
```

---

## Phase 2: Deploy Cloudflare Worker

### 2.1 Build and Deploy

```bash
# Deploy to Cloudflare Workers
npm run deploy

# Verify deployment
curl https://family-plus-backend.YOUR_SUBDOMAIN.workers.dev/health
```

### 2.2 Configure Custom Domain (Optional)

```bash
# Add custom domain
wrangler domains add api.yourdomain.com

# Update DNS records
# CNAME api.yourdomain.com -> family-plus-backend.YOUR_SUBDOMAIN.workers.dev
```

---

## Phase 3: Trigger.dev Deployment

### 3.1 Deploy Background Tasks

```bash
# Deploy trigger tasks
npx trigger.dev@latest deploy

# Verify tasks are registered
npx trigger.dev@latest tasks
```

### 3.2 Configure Trigger.dev Environment

1. Go to https://cloud.trigger.dev
2. Select your project: `proj_vdbanaagzxesesgrgmgvuz`
3. Navigate to **Settings** → **Environment Variables**
4. Add the following:
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
   - `AWS_BEARER_TOKEN_BEDROCK`
   - `AWS_REGION`
   - `CARTESIA_API_KEY`
   - `OPENAI_API_KEY`

---

## Phase 4: Verification

### 4.1 Test API Endpoints

```bash
# Test health check
curl https://your-worker-url.workers.dev/

# Test stories endpoint
curl https://your-worker-url.workers.dev/stories?family_id=YOUR_FAMILY_ID

# Test prompts endpoint
curl https://your-worker-url.workers.dev/prompts?family_id=YOUR_FAMILY_ID
```

### 4.2 Monitor Background Tasks

- Visit Trigger.dev dashboard
- Check for successful task runs
- Verify error rates

---

## Phase 5: Monitoring & Logging

### 5.1 Cloudflare Analytics

- Go to Cloudflare Dashboard → Workers
- View request metrics, error rates, latency

### 5.2 Trigger.dev Monitoring

- Real-time task execution logs
- Failure notifications
- Performance metrics

---

## Rollback Plan

```bash
# List deployments
wrangler deployments list

# Rollback to previous version
wrangler rollback

# Or deploy specific version
wrangler deploy --compatibility-date 2025-12-20
```

---

## Troubleshooting

### Worker fails to start
- Check wrangler.toml compatibility_date
- Verify all secrets are set
- Check Cloudflare dashboard for error logs

### Trigger tasks not running
- Verify environment variables in Trigger.dev dashboard
- Check task logs in Trigger.dev
- Ensure `npx trigger.dev deploy` succeeded

### Database connection errors
- Verify SUPABASE_URL and SUPABASE_KEY
- Check Supabase project status
- Test connection: `psql $DATABASE_URL`

### R2 upload failures
- Verify bucket exists: `wrangler r2 bucket list`
- Check R2 permissions in wrangler.toml
- Enable CORS for R2 bucket if needed
