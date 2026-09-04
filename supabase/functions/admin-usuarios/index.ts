// ============================================================
//  Edge Function: admin-usuarios
//  Gestion de cuentas del Inventario Normativo SERFOR.
//
//  Crear y eliminar cuentas exige la clave service_role, que NUNCA puede
//  estar en el navegador. Por eso vive aqui: la funcion comprueba que quien
//  llama tenga sesion iniciada y rol 'admin', y recien entonces opera.
//
//  Despliegue (ver LEEME.md):
//    Supabase -> Edge Functions -> Create a new function -> nombre: admin-usuarios
//    Pegar este archivo -> Deploy.  No necesita secretos: SUPABASE_URL,
//    SUPABASE_ANON_KEY y SUPABASE_SERVICE_ROLE_KEY ya estan disponibles.
// ============================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (obj: unknown, status = 200) =>
  new Response(JSON.stringify(obj), { status, headers: { ...cors, "content-type": "application/json" } });

const ROLES = ["admin", "especialista"];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // 1) Quien llama debe tener sesion iniciada
    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: authHeader } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "No autenticado." }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_KEY);

    // 2) ...y debe ser administrador. Se comprueba con service role para que
    //    no dependa de lo que el navegador diga tener.
    const { data: yo } = await admin.from("profiles").select("role").eq("id", user.id).single();
    if (!yo || yo.role !== "admin") return json({ error: "Se requiere rol de administrador." }, 403);

    const { accion, id, email, nombre, clave, rol } = await req.json();

    // Cuantos administradores quedan: impide quedarse sin ninguno
    const contarAdmins = async () => {
      const { count } = await admin.from("profiles").select("id", { count: "exact", head: true }).eq("role", "admin");
      return count ?? 0;
    };

    switch (accion) {
      // ---------- Listar cuentas ----------
      case "listar": {
        const { data: perfiles, error } = await admin
          .from("profiles").select("id, email, nombre, role, debe_cambiar_clave, created_at");
        if (error) return json({ error: error.message }, 500);

        // El ultimo acceso solo esta en auth.users
        const { data: lista } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
        const accesos = new Map((lista?.users ?? []).map((u) => [u.id, u.last_sign_in_at]));

        const usuarios = (perfiles ?? []).map((p) => ({
          ...p,
          ultimo_acceso: accesos.get(p.id) ?? null,
          soy_yo: p.id === user.id,
        })).sort((a, b) => (a.email ?? "").localeCompare(b.email ?? "", "es"));

        return json({ usuarios });
      }

      // ---------- Crear cuenta ----------
      case "crear": {
        if (!email || !clave) return json({ error: "Faltan el correo o la clave inicial." }, 400);
        if (clave.length < 8) return json({ error: "La clave inicial debe tener al menos 8 caracteres." }, 400);
        const rolNuevo = ROLES.includes(rol) ? rol : "especialista";

        const { data: creado, error: errCrear } = await admin.auth.admin.createUser({
          email, password: clave, email_confirm: true,
        });
        if (errCrear) {
          const msg = /already been registered|already exists/i.test(errCrear.message)
            ? "Ya existe una cuenta con ese correo."
            : errCrear.message;
          return json({ error: msg }, 400);
        }

        // El disparador on_auth_user_created ya creo el perfil; se completa aqui.
        const { error: errPerfil } = await admin.from("profiles").update({
          email, nombre: nombre ?? null, role: rolNuevo, debe_cambiar_clave: true,
        }).eq("id", creado.user.id);
        if (errPerfil) {
          await admin.auth.admin.deleteUser(creado.user.id);   // no dejar cuenta a medias
          return json({ error: "No se pudo registrar el perfil: " + errPerfil.message }, 500);
        }

        return json({ ok: true, id: creado.user.id });
      }

      // ---------- Eliminar cuenta ----------
      case "eliminar": {
        if (!id) return json({ error: "Falta el identificador." }, 400);
        if (id === user.id) return json({ error: "No puedes eliminar tu propia cuenta." }, 400);

        const { data: destino } = await admin.from("profiles").select("role").eq("id", id).single();
        if (destino?.role === "admin" && (await contarAdmins()) <= 1) {
          return json({ error: "Es el unico administrador: la aplicacion quedaria sin acceso." }, 400);
        }

        const { error } = await admin.auth.admin.deleteUser(id);
        if (error) return json({ error: error.message }, 500);
        return json({ ok: true });
      }

      // ---------- Cambiar rol ----------
      case "cambiar_rol": {
        if (!id || !ROLES.includes(rol)) return json({ error: "Rol no valido." }, 400);
        if (id === user.id && rol !== "admin") {
          return json({ error: "No puedes quitarte a ti mismo el rol de administrador." }, 400);
        }
        const { data: destino } = await admin.from("profiles").select("role").eq("id", id).single();
        if (destino?.role === "admin" && rol !== "admin" && (await contarAdmins()) <= 1) {
          return json({ error: "Es el unico administrador: la aplicacion quedaria sin acceso." }, 400);
        }
        const { error } = await admin.from("profiles").update({ role: rol }).eq("id", id);
        if (error) return json({ error: error.message }, 500);
        return json({ ok: true });
      }

      // ---------- Restablecer clave ----------
      case "resetear_clave": {
        if (!id || !clave) return json({ error: "Falta la clave." }, 400);
        if (clave.length < 8) return json({ error: "La clave debe tener al menos 8 caracteres." }, 400);
        const { error } = await admin.auth.admin.updateUserById(id, { password: clave });
        if (error) return json({ error: error.message }, 500);
        // Al entrar con esta clave, se le vuelve a exigir que la cambie
        await admin.from("profiles").update({ debe_cambiar_clave: true }).eq("id", id);
        return json({ ok: true });
      }

      default:
        return json({ error: "Accion no reconocida: " + accion }, 400);
    }
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
