# Portfolio email setup

The portfolio uses a Netlify Function to send email through Gmail SMTP. Supabase continues to store visitor messages and the admin reply history. The Gmail App Password is a private server-side secret: never put it in browser code, this file, or GitHub.

## 1. Prepare Gmail

1. Sign in to the Google account `sangbethuel938@gmail.com`.
2. Ensure 2-Step Verification is enabled.
3. Create an App Password for the portfolio if you have not already done so.
4. Keep the App Password private. Enter it only in Netlify environment variables.

## 2. Add these environment variables in Netlify

Open your Netlify site → **Project configuration** → **Environment variables** → **Add a variable**. Add each variable:

| Name | Value |
|---|---|
| `GMAIL_USER` | `sangbethuel938@gmail.com` |
| `GMAIL_APP_PASSWORD` | Your Google App Password (secret; enter directly in Netlify) |
| `NOTIFICATION_EMAIL` | `sangbethuel938@gmail.com` |
| `SITE_ORIGIN` | `https://sangbethuel.netlify.app` |
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase publishable/anon key |

Set the variables so they are available to **Functions**. Do not add the App Password to GitHub or share it in chat. If Google displays spaces in the App Password, enter it without spaces.

## 3. Redeploy

After adding the variables, trigger a new production deploy in Netlify. The repository includes Nodemailer as a dependency for Gmail SMTP.

## 4. Test

1. Submit a test message through the public contact form using an email address you can access.
2. Confirm the message is saved and the notification arrives at `sangbethuel938@gmail.com`.
3. Sign in to the portfolio admin using the owner account, open that message, write a reply and click **Send email reply**.
4. Confirm the visitor receives the reply and the sent reply appears in the dashboard history.

If an email fails, check the Netlify Function logs. Gmail may block SMTP access if account security or sending limits are reached. Email delivery is not confirmed until both tests succeed.
