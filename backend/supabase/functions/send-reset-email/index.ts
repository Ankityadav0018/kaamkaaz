// @ts-nocheck
// Deno Edge Function — runs on Supabase, not Node.js
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const sendEmail = async (resendApiKey: string, to: string, subject: string, html: string) => {
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${resendApiKey}`
    },
    body: JSON.stringify({
      from: 'Kaamkaaz <noreply@kaamkaaz.org>',
      to,
      subject,
      html
    })
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Resend Error: ${err}`)
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    if (!resendApiKey) {
      throw new Error("RESEND_API_KEY is not set in Edge Function secrets")
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { email } = await req.json()

    if (!email) {
      return new Response(
        JSON.stringify({ error: 'Email is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      )
    }

    // 1. Try to generate a Supabase recovery link
    const { data, error } = await supabaseAdmin.auth.admin.generateLink({
      type: 'recovery',
      email: email,
      options: {
        redirectTo: 'io.supabase.kaamkaaz://reset-callback'
      }
    })

    if (error || !data?.properties?.action_link) {
      // User NOT found in Supabase — return explicit 404 error
      return new Response(
        JSON.stringify({ error: 'This email is not registered. Please sign up first.' }),
        { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      )
    }

    // 2. User found — send the real reset link
    const actionLink = data.properties.action_link

    await sendEmail(
      resendApiKey,
      email,
      'Reset your Kaamkaaz password',
      `
        <div style="font-family:Arial,sans-serif;max-width:500px;margin:auto;padding:24px;">
          <h2 style="color:#1a1a2e;">Password Reset Request</h2>
          <p>Hello,</p>
          <p>We received a request to reset the password for your Kaamkaaz account.</p>
          <p>Click the button below to create a new password:</p>
          <p>
            <a href="${actionLink}"
              style="display:inline-block;padding:12px 24px;background-color:#007bff;
                     color:#ffffff;text-decoration:none;border-radius:8px;font-weight:bold;">
              Reset Password
            </a>
          </p>
          <p>This link will expire in 1 hour. If you didn't request this, you can safely ignore this email.</p>
          <br/>
          <p style="color:#888;font-size:12px;">— The Kaamkaaz Team</p>
        </div>
      `
    )

    return new Response(
      JSON.stringify({ message: 'Password reset email sent successfully.' }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders }, status: 500 }
    )
  }
})
