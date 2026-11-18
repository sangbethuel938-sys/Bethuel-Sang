# Portfolio email setup

The portfolio now uses a Netlify Function as a private server-side bridge to Resend. The Resend API key must never be placed in `config.js`, browser JavaScript, or GitHub.

## 1. Create a Resend account and verify a sending domain

1. Open https://resend.com/ and create an account.
2. In Resend, open **Domains** and add a domain you own.
3. Add the DNS records Resend provides at your domain registrar.
4. Wait until Resend shows the domain as **Verified**.
5. Create an API key with email-sending permission.

A Netlify subdomain such as `sangbethuel.netlify.app` is not a domain you control for DNS verification. Use a domain you own. Resend's shared testing sender is for testing, not normal visitor replies.

## 2. Add these environment variables in Netlify

Open your Netlify site → **Project configuration** → **Environment variables** → **Add a variable**. Add:

| Name | Value |
|---|---|
| `RESEND_API_KEY` | Your Resend API key (starts with `re_`) |
| `RESEND_FROM_EMAIL` | A sender on your verified domain, e.g. `Bethuel Sang <hello@yourdomain.com>` |
| `NOTIFICATION_EMAIL` | `sangbethuel938@gmail.com` |
| `SITE_ORIGIN` | `https://sangbethuel.netlify.app` |
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase publishable/anon key |

Set the variables so they are available to **Functions**. Do not put secret values in this file or commit them to GitHub.

## 3. Redeploy

After adding the variables, trigger a new production deploy in Netlify. Netlify Functions read environment variables at runtime, and a new deploy applies changed values.

## 4. Test

1. Submit a test message through the public contact form using an email address you can access.
2. Confirm the message appears in Supabase **Authentication is not needed for public form submissions** and in the portfolio admin Messages tab.
3. Confirm the notification arrives at `sangbethuel938@gmail.com`.
4. Sign in to the portfolio admin using the owner account, open that message, write a reply and click **Send email reply**.
5. Confirm the visitor receives the reply and the sent reply appears in the dashboard history.

If an email fails, check the Netlify Function logs and the Resend Logs page. The email API key is private; never share it in chat or GitHub.
