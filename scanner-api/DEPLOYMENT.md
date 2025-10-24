# TPC Ops Scanner API - Deployment Guide

Complete guide for deploying the Scanner API to various platforms.

## Prerequisites

1. Supabase project with bulk ticket tables set up
2. PostgreSQL function `verify_and_use_ticket` installed (see `database/verify_and_use_ticket.sql`)
3. QR_SECRET_KEY from main ticket generation system
4. Scanner API keys generated

---

## Option 1: Vercel (Recommended for Serverless)

### Step 1: Install Vercel CLI

```bash
npm install -g vercel
```

### Step 2: Configure Environment Variables

In your Vercel dashboard (or via CLI), set:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
QR_SECRET_KEY=your_secret_key_here
SCANNER_API_KEY=scanner_api_key_12345
ADMIN_API_KEY=admin_api_key_67890
NODE_ENV=production
```

### Step 3: Deploy

```bash
# Login to Vercel
vercel login

# Deploy to production
vercel --prod
```

### Step 4: Test Deployment

```bash
curl https://your-app.vercel.app/health
```

**Pros:**
- Automatic scaling
- Zero server maintenance
- Free SSL certificates
- Global CDN

**Cons:**
- 10-second function timeout
- Cold starts (mitigated by keeping functions warm)

---

## Option 2: Railway

### Step 1: Install Railway CLI

```bash
npm install -g @railway/cli
```

### Step 2: Initialize Project

```bash
railway login
railway init
```

### Step 3: Add Environment Variables

```bash
railway variables set VITE_SUPABASE_URL=https://your-project.supabase.co
railway variables set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
railway variables set QR_SECRET_KEY=your_secret_key
railway variables set SCANNER_API_KEY=scanner_api_key_12345
railway variables set ADMIN_API_KEY=admin_api_key_67890
railway variables set NODE_ENV=production
```

### Step 4: Deploy

```bash
railway up
```

**Pros:**
- Simple deployment
- Persistent connections
- Automatic HTTPS
- Good free tier

**Cons:**
- Paid plans for production
- Manual scaling

---

## Option 3: Render

### Step 1: Connect Repository

1. Go to [render.com](https://render.com)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository

### Step 2: Configure Service

**Build Command:**
```bash
npm install && npm run build
```

**Start Command:**
```bash
npm start
```

### Step 3: Add Environment Variables

Add all environment variables in Render dashboard:

```
VITE_SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
QR_SECRET_KEY
SCANNER_API_KEY
ADMIN_API_KEY
NODE_ENV=production
PORT=3000
```

### Step 4: Deploy

Render will automatically deploy on push to main branch.

**Pros:**
- Free tier available
- Auto-deploy on push
- Good for small-medium loads

**Cons:**
- Free tier spins down after inactivity
- Limited free hours per month

---

## Option 4: VPS (DigitalOcean, Linode, AWS EC2)

### Step 1: Set Up Server

```bash
# SSH into server
ssh root@your-server-ip

# Update system
apt update && apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install PM2
npm install -g pm2
```

### Step 2: Clone and Configure

```bash
# Clone repository
git clone https://github.com/your-repo/tpc-scanner-api.git
cd tpc-scanner-api

# Install dependencies
npm install

# Create .env file
nano .env
# (Paste your environment variables)

# Build application
npm run build
```

### Step 3: Start with PM2

```bash
# Start application
pm2 start dist/index.js --name tpc-scanner-api

# Save PM2 configuration
pm2 save

# Setup PM2 startup script
pm2 startup
# (Run the command it outputs)

# Monitor logs
pm2 logs tpc-scanner-api
```

### Step 4: Set Up Nginx Reverse Proxy

```bash
# Install Nginx
apt install -y nginx

# Create Nginx config
nano /etc/nginx/sites-available/scanner-api
```

**Nginx Configuration:**

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# Enable site
ln -s /etc/nginx/sites-available/scanner-api /etc/nginx/sites-enabled/

# Test Nginx config
nginx -t

# Restart Nginx
systemctl restart nginx
```

### Step 5: Set Up SSL with Let's Encrypt

```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d api.yourdomain.com

# Auto-renewal is set up automatically
```

**Pros:**
- Full control over server
- No vendor lock-in
- Can handle high loads
- Persistent WebSocket connections

**Cons:**
- More maintenance required
- Manual security updates
- Need DevOps knowledge

---

## Option 5: Docker

### Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY src ./src

# Build application
RUN npm run build

# Expose port
EXPOSE 3000

# Set environment to production
ENV NODE_ENV=production

# Start application
CMD ["node", "dist/index.js"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  scanner-api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - VITE_SUPABASE_URL=${VITE_SUPABASE_URL}
      - SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}
      - QR_SECRET_KEY=${QR_SECRET_KEY}
      - SCANNER_API_KEY=${SCANNER_API_KEY}
      - ADMIN_API_KEY=${ADMIN_API_KEY}
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Deploy

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

**Pros:**
- Consistent environment
- Easy to scale
- Portable across platforms

**Cons:**
- Requires Docker knowledge
- Slightly more overhead

---

## Post-Deployment Checklist

### 1. Database Setup

Run the PostgreSQL function in Supabase SQL editor:

```sql
-- See database/verify_and_use_ticket.sql
```

### 2. Test Endpoints

```bash
# Health check
curl https://your-api-url.com/health

# API info
curl https://your-api-url.com/api

# Test authentication
curl https://your-api-url.com/api/scanner/scan-history \
  -H "Authorization: Bearer YOUR_SCANNER_API_KEY" \
  -H "X-Scanner-ID: test-scanner"
```

### 3. Set Up Monitoring

**Uptime Monitoring:**
- Uptime Robot: Monitor `/health` endpoint
- Better Uptime: Set up status page
- Pingdom: Configure alerts

**Error Tracking:**
- Sentry: Add to `src/index.ts`
- LogRocket: Session replay
- DataDog: APM monitoring

### 4. Load Testing

```bash
# Install Apache Bench
apt install apache2-utils

# Test with 100 concurrent requests
ab -n 1000 -c 100 \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "X-Scanner-ID: test" \
  https://your-api-url.com/health
```

Target: > 100 requests/second with < 500ms response time

### 5. Security Hardening

- [ ] Enable HTTPS only
- [ ] Set up firewall (UFW/iptables)
- [ ] Configure rate limiting
- [ ] Rotate API keys regularly
- [ ] Enable Supabase RLS policies
- [ ] Set up IP whitelisting (if needed)
- [ ] Enable security headers (Helmet.js already configured)

### 6. Backup Strategy

- [ ] Database backups (Supabase auto-backup enabled)
- [ ] Environment variables backed up securely
- [ ] Code in version control
- [ ] Document API keys in secure vault

---

## Scaling Considerations

### Horizontal Scaling

**Load Balancer Setup (Nginx):**

```nginx
upstream scanner_api {
    least_conn;
    server 10.0.0.1:3000;
    server 10.0.0.2:3000;
    server 10.0.0.3:3000;
}

server {
    listen 80;
    location / {
        proxy_pass http://scanner_api;
    }
}
```

### Caching Strategy

For high-traffic events:

- Cache batch details (5 min TTL)
- Use Redis for session data
- CDN for static assets

### Database Optimization

- Connection pooling (already configured in Supabase client)
- Database indexes (already exist)
- Read replicas for heavy read loads

---

## Troubleshooting Production Issues

### Issue: High response times

**Check:**
1. Database connection pool size
2. Supabase region (should match API region)
3. Network latency
4. CPU/memory usage

**Solution:**
- Upgrade server resources
- Add connection pooling
- Use Redis caching

### Issue: Rate limit false positives

**Check:**
1. Scanner behind NAT (same IP for multiple scanners)
2. Rate limit too strict

**Solution:**
- Implement per-scanner-ID rate limiting
- Increase limits for production

### Issue: Duplicate scan entries

**Check:**
1. PostgreSQL function `verify_and_use_ticket` exists
2. Function has proper permissions

**Solution:**
- Re-run database migration
- Check Supabase logs

---

## Maintenance

### Regular Tasks

**Daily:**
- Monitor error logs
- Check response times
- Verify uptime

**Weekly:**
- Review scan statistics
- Check disk space (VPS only)
- Security updates (VPS only)

**Monthly:**
- Rotate API keys
- Review and archive old logs
- Performance optimization review

### Updating the API

```bash
# Pull latest code
git pull origin main

# Install dependencies
npm install

# Build
npm run build

# Restart (PM2)
pm2 restart tpc-scanner-api

# Or (Docker)
docker-compose down && docker-compose up -d --build
```

---

## Support

For deployment issues:

- GitHub Issues: [Repository]
- Email: support@trippechalo.in
- Supabase Docs: https://supabase.com/docs

---

**Good luck with your deployment! 🚀**
