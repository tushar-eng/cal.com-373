# 🚀 Quick Cal.com Deployment on EasyPanel

## ✅ Fixed Build Issue

The build failure has been resolved! The issue was missing environment variables during the Next.js build process. The updated `infra/docker/web/Dockerfile` now includes the necessary build-time environment variables.

## 🏗️ What Was Fixed

Added build-time environment variables to the Dockerfile:
- `NEXTAUTH_SECRET` - Authentication secret
- `CALENDSO_ENCRYPTION_KEY` - Encryption key for sensitive data
- `DATABASE_URL` - Database connection (placeholder for build)
- `NEXT_PUBLIC_WEBAPP_URL` - Public app URL
- `NEXTAUTH_URL` - NextAuth callback URL
- `EMAIL_FROM` - Default email sender

## 🚀 Deploy Now

### Step 1: Database Setup
1. In EasyPanel: **Services** → **Add Service** → **PostgreSQL**
2. Configure:
   - Name: `calcom-db`
   - Database: `calcom`
   - Username: `calcom`
   - Generate strong password

### Step 2: Deploy Cal.com
1. **Apps** → **Add App** → **Deploy from Git**
2. **Configuration:**
   - Repository: Your GitHub repo URL
   - Branch: Your current branch
   - **Dockerfile path**: `infra/docker/web/Dockerfile`
   - Build context: `/` (root)
   - Port: `80`
   - Public: ✅ Enabled

### Step 3: Set Environment Variables

**⚠️ IMPORTANT: Generate Proper Security Keys**

The build failed because NEXTAUTH_SECRET was too short. NextAuth requires at least 32 characters.

**Generate Security Keys:**
```bash
# Generate NEXTAUTH_SECRET (32+ characters)
openssl rand -base64 32

# Generate CALENDSO_ENCRYPTION_KEY (64 hex characters)
openssl rand -hex 32
```

**Required Environment Variables:**
```bash
DATABASE_URL=postgresql://calcom:YOUR_PASSWORD@postgres-service:5432/calcom?schema=public
NEXTAUTH_SECRET=your-generated-32-plus-char-secret
CALENDSO_ENCRYPTION_KEY=your-generated-64-char-hex-key
NEXT_PUBLIC_WEBAPP_URL=https://your-app-name.easypanel.host
NEXTAUTH_URL=https://your-app-name.easypanel.host/api/auth
EMAIL_FROM=Cal.com <no-reply@yourdomain.com>
NODE_OPTIONS=--max-old-space-size=6144
NEXT_TELEMETRY_DISABLED=1
```

**Alternative: Use Simple Dockerfile**

If you continue having build issues, try using the simpler Dockerfile:
- **Dockerfile path**: `infra/docker/web/Dockerfile.simple`

This version has more robust build handling and better error recovery.

### Step 4: Deploy & Access

1. Click **Deploy** in EasyPanel
2. Wait 5-10 minutes for build to complete
3. Access your Cal.com at: `https://your-app-name.easypanel.host`

## ✨ What You Get

- **Complete Cal.com web application**
- **Built-in API endpoints** at `/api/*`
- **Automatic database migrations** on startup
- **App store seeded** with available integrations
- **Optimized for production** with proper memory limits

## 🔧 Optional Integrations

Add these environment variables for enhanced functionality:

**Email (SendGrid):**
```bash
SENDGRID_API_KEY=your-sendgrid-api-key
SENDGRID_EMAIL=verified-sender@yourdomain.com
```

**SMS (Twilio):**
```bash
TWILIO_SID=your-account-sid
TWILIO_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890
```

**Google Calendar:**
```bash
GOOGLE_API_CREDENTIALS={"web":{"client_id":"...","client_secret":"...","redirect_uris":["https://your-domain/api/integrations/googlecalendar/callback"]}}
```

**Zoom:**
```bash
ZOOM_CLIENT_ID=your-zoom-client-id
ZOOM_CLIENT_SECRET=your-zoom-client-secret
```

## 🎉 Success!

Your Cal.com instance should now be running successfully. You can:

1. **Create your admin account** - Visit your URL and sign up
2. **Set up availability** - Configure your working hours
3. **Create event types** - Define your bookable services
4. **Share booking links** - Start accepting appointments
5. **Add integrations** - Connect calendars and video platforms

## 🆘 Troubleshooting

**Build still fails?**
- Check that all required environment variables are set
- Verify database connection string format
- Ensure PostgreSQL service is running

**Can't access the app?**
- Check EasyPanel app logs for errors
- Verify port 80 is exposed and public is enabled
- Ensure environment variables match your domain

**Database issues?**
- Verify DATABASE_URL format: `postgresql://user:pass@host:port/db?schema=public`
- Check PostgreSQL service is healthy
- Ensure database and user exist

Need help? Check the detailed deployment guide in `EASYPANEL_DEPLOYMENT.md` or the Cal.com GitHub repository.
