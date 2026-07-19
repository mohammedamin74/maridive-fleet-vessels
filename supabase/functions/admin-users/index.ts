// Supabase Edge Function: admin-users
// Lets an authenticated ADMIN create, delete, or reset the password of other
// fleet accounts. Runs server-side with the service-role key (never exposed to
// the app). The caller's admin status is verified against the profiles table
// before any action is taken.
//
// Deploy: Supabase Dashboard → Edge Functions → Deploy a new function named
// "admin-users" and paste this file. No extra secrets needed — SUPABASE_URL,
// SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are provided automatically.

import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DOMAIN = "@maridive.app";

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...cors },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const authHeader = req.headers.get("Authorization") ?? "";

    // 1) Identify the caller from their JWT.
    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData } = await caller.auth.getUser();
    const callerId = userData?.user?.id;
    if (!callerId) return json(401, { error: "notAuthenticated" });

    // 2) Verify the caller is an admin (service client bypasses RLS).
    const admin = createClient(url, serviceKey);
    const { data: prof } = await admin
      .from("profiles")
      .select("is_admin")
      .eq("id", callerId)
      .maybeSingle();
    if (!prof?.is_admin) return json(403, { error: "notAdmin" });

    const body = await req.json();
    const action = String(body.action ?? "");
    const username = String(body.username ?? "").trim().toLowerCase();

    if (action === "create") {
      if (!username || !body.password) return json(400, { error: "required" });
      const { error } = await admin.auth.admin.createUser({
        email: username + DOMAIN,
        password: String(body.password),
        email_confirm: true,
        user_metadata: {
          username,
          display_name: String(body.displayName ?? ""),
          is_admin: body.isAdmin === true,
        },
      });
      if (error) {
        const m = String(error.message).toLowerCase();
        if (m.includes("already") || m.includes("exists")) {
          return json(409, { error: "userExists" });
        }
        return json(400, { error: error.message });
      }
      return json(200, { ok: true });
    }

    if (action === "update") {
      if (username === "admin") return json(400, { error: "protectedUser" });
      const { data: target } = await admin
        .from("profiles")
        .select("id")
        .eq("username", username)
        .maybeSingle();
      if (!target) return json(404, { error: "notFound" });

      const newUsername = body.newUsername
        ? String(body.newUsername).trim().toLowerCase()
        : username;
      if (!newUsername) return json(400, { error: "required" });

      const authUpdate: Record<string, unknown> = {};
      if (newUsername !== username) {
        authUpdate.email = newUsername + DOMAIN;
        authUpdate.email_confirm = true;
      }
      if (body.password) authUpdate.password = String(body.password);
      if (Object.keys(authUpdate).length > 0) {
        const { error } = await admin.auth.admin.updateUserById(
          target.id,
          authUpdate,
        );
        if (error) {
          const m = String(error.message).toLowerCase();
          if (m.includes("already") || m.includes("exists")) {
            return json(409, { error: "userExists" });
          }
          return json(400, { error: error.message });
        }
      }

      const profileUpdate: Record<string, unknown> = {};
      if (newUsername !== username) profileUpdate.username = newUsername;
      if (body.displayName !== undefined) {
        profileUpdate.display_name = String(body.displayName).trim();
      }
      if (Object.keys(profileUpdate).length > 0) {
        const { error } = await admin
          .from("profiles")
          .update(profileUpdate)
          .eq("id", target.id);
        if (error) return json(400, { error: error.message });
      }
      return json(200, { ok: true });
    }

    if (action === "delete" || action === "reset") {
      if (username === "admin") return json(400, { error: "protectedUser" });
      const { data: target } = await admin
        .from("profiles")
        .select("id")
        .eq("username", username)
        .maybeSingle();
      if (!target) return json(404, { error: "notFound" });

      if (action === "delete") {
        const { error } = await admin.auth.admin.deleteUser(target.id);
        if (error) return json(400, { error: error.message });
      } else {
        if (!body.password) return json(400, { error: "required" });
        const { error } = await admin.auth.admin.updateUserById(target.id, {
          password: String(body.password),
        });
        if (error) return json(400, { error: error.message });
      }
      return json(200, { ok: true });
    }

    return json(400, { error: "unknownAction" });
  } catch (e) {
    return json(500, { error: String(e) });
  }
});
