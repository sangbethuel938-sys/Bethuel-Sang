const nodemailer = require("nodemailer");

const ADMIN_EMAIL = "sangbethuel938@gmail.com";

const json = (statusCode, payload) => ({
  statusCode,
  headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  body: JSON.stringify(payload)
});

const cleanText = (value, max) => typeof value === "string" ? value.trim().slice(0, max) : "";
const escapeHtml = (value) => String(value).replace(/[&<>"']/g, (c) => ({
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
}[c]));

exports.handler = async (event) => {
  if (event.httpMethod !== "POST") return json(405, { error: "Method not allowed." });

  const allowedOrigins = (process.env.SITE_ORIGIN || "https://sangbethuel.netlify.app")
    .split(",").map((value) => value.trim()).filter(Boolean);
  const origin = event.headers.origin || event.headers.Origin || "";
  if (!origin || !allowedOrigins.includes(origin)) {
    return json(403, { error: "This website is not allowed to use the email service." });
  }

  let input;
  try {
    input = JSON.parse(event.body || "{}");
  } catch {
    return json(400, { error: "Invalid request." });
  }

  const action = input.action;
  const name = cleanText(input.name, 160);
  const body = cleanText(input.body || input.message, 5000);
  const email = cleanText(input.email, 320);
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!process.env.GMAIL_USER || !process.env.GMAIL_APP_PASSWORD) {
    return json(503, { error: "Email service is not configured yet. Please contact the site owner." });
  }

  let to;
  let subject;
  let textBody;
  let htmlBody;
  let replyTo;

  if (action === "contact") {
    if (!name || !emailPattern.test(email) || !body) {
      return json(400, { error: "Please provide your name, a valid email address and a message." });
    }
    to = process.env.NOTIFICATION_EMAIL || ADMIN_EMAIL;
    subject = "Portfolio message from " + name;
    textBody = "New message from " + name + " (" + email + ")\n\n" + body;
    htmlBody = "<h2>New portfolio message</h2><p><strong>From:</strong> " +
      escapeHtml(name) + " (" + escapeHtml(email) + ")</p><p>" +
      escapeHtml(body).replace(/\n/g, "<br>") + "</p>";
    replyTo = email;
  } else if (action === "reply") {
    const recipient = cleanText(input.to, 320);
    if (!emailPattern.test(recipient) || !body) {
      return json(400, { error: "A valid visitor email and reply text are required." });
    }

    const tokenHeader = event.headers.authorization || event.headers.Authorization || "";
    const token = tokenHeader.startsWith("Bearer ") ? tokenHeader.slice(7) : "";
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_ANON_KEY;
    if (!token || !supabaseUrl || !supabaseKey) {
      return json(401, { error: "Please sign in again. Admin email verification is unavailable." });
    }

    let authResponse;
    try {
      authResponse = await fetch(supabaseUrl.replace(/\/$/, "") + "/auth/v1/user", {
        headers: { apikey: supabaseKey, Authorization: "Bearer " + token }
      });
    } catch {
      return json(502, { error: "Could not verify your admin session." });
    }
    const user = await authResponse.json().catch(() => null);
    if (!authResponse.ok || !user || String(user.email || "").toLowerCase() !== ADMIN_EMAIL) {
      return json(403, { error: "Only the portfolio owner can send replies." });
    }

    to = recipient;
    subject = "Re: Your message to Bethuel Sang";
    textBody = "Hello " + (name || "there") + ",\n\n" + body + "\n\nRegards,\nBethuel Sang";
    htmlBody = "<p>Hello " + escapeHtml(name || "there") + ",</p><p>" +
      escapeHtml(body).replace(/\n/g, "<br>") + "</p><p>Regards,<br>Bethuel Sang</p>";
    replyTo = ADMIN_EMAIL;
  } else {
    return json(400, { error: "Unknown email action." });
  }

  try {
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.GMAIL_USER,
        pass: process.env.GMAIL_APP_PASSWORD
      }
    });

    const result = await transporter.sendMail({
      from: "Bethuel Sang <" + process.env.GMAIL_USER + ">",
      to,
      replyTo,
      subject,
      text: textBody,
      html: htmlBody
    });

    return json(200, { success: true, id: result.messageId || null });
  } catch (error) {
    console.error("Gmail SMTP delivery error:", error && error.message ? error.message : "Unknown error");
    return json(502, { error: "Gmail could not send the email. Please check the email settings and try again." });
  }
};
