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

// Los perfiles ya no estan escritos aqui: se leen de la tabla "perfiles"
// (ver supabase-perfiles-editables.sql). Crear un perfil desde la pantalla
// basta para poder asignarlo, sin volver a desplegar esta funcion.
//
// Se conserva la tolerancia a como se escribio el rol a mano ('Admin',
// 'Administrador', con espacios): comparar contra la clave exacta dejaba
// fuera a administradores reales, que la interfaz si reconocia.
const ALIAS: Record<string, string> = {
  administrador: "admin", administrator: "admin",
  profesional: "especialista", oti: "normas_oti",
};
const claveRol = (r: unknown, validas: Set<string>) => {
  const v = String(r ?? "").trim().normalize("NFD").replace(/[̀-ͯ]/g, "")
              .toLowerCase().replace(/\s+/g, "_");
  if (validas.has(v)) return v;
  const a = ALIAS[v];
  return (a && validas.has(a)) ? a : null;
};

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

    // 2) Los perfiles vigentes, tal como estan en la base. De aqui sale tanto
    //    que roles son validos como cual de ellos gestiona cuentas.
    const { data: perfiles, error: errPerf } = await admin
      .from("perfiles").select("clave, nombre, gestiona_cuentas");
    if (errPerf || !perfiles || !perfiles.length) {
      return json({ error: "No se pudo leer la tabla de perfiles. Ejecuta supabase-perfiles-editables.sql." }, 500);
    }
    const VALIDAS = new Set(perfiles.map((x) => x.clave as string));
    const MANDAN = new Set(perfiles.filter((x) => x.gestiona_cuentas).map((x) => x.clave as string));
    const normalizarRol = (r: unknown) => claveRol(r, VALIDAS);
    const gestiona = (r: unknown) => { const c = normalizarRol(r); return !!c && MANDAN.has(c); };

    // 3) Quien llama debe tener un perfil que gestione cuentas. Se comprueba con
    //    service role para que no dependa de lo que el navegador diga tener.
    const { data: yo } = await admin.from("profiles").select("role").eq("id", user.id).single();
    if (!yo) return json({ error: "Tu cuenta no tiene perfil en la tabla profiles." }, 403);
    if (!gestiona(yo.role)) {
      return json({ error: `Tu perfil (${JSON.stringify(yo.role)}) no tiene permiso para gestionar cuentas.` }, 403);
    }

    const { accion, id, email, nombre, clave, rol } = await req.json();

    // Cuantas cuentas pueden administrar: impide quedarse sin ninguna. Se
    // cuenta por PERMISO, no por el nombre del perfil, porque ahora puede
    // haber varios perfiles que gestionen cuentas.
    const contarAdmins = async () => {
      const { count } = await admin.from("profiles")
        .select("id", { count: "exact", head: true }).in("role", [...MANDAN]);
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
        // Antes, un rol no reconocido caia en silencio a "especialista" y la
        // cuenta quedaba con permisos distintos a los pedidos. Ahora se rechaza.
        const rolNuevo = normalizarRol(rol);
        if (!rolNuevo) {
          return json({ error: `El perfil ${JSON.stringify(rol)} no existe. Perfiles validos: ${[...VALIDAS].join(", ")}.` }, 400);
        }

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
        if (gestiona(destino?.role) && (await contarAdmins()) <= 1) {
          return json({ error: "Es la unica cuenta que puede administrar: la aplicacion quedaria sin acceso." }, 400);
        }

        const { error } = await admin.auth.admin.deleteUser(id);
        if (error) return json({ error: error.message }, 500);
        return json({ ok: true });
      }

      // ---------- Cambiar rol ----------
      case "cambiar_rol": {
        const rolPedido = normalizarRol(rol);
        if (!id || !rolPedido) {
          return json({ error: `Perfil no valido: ${JSON.stringify(rol)}. Validos: ${[...VALIDAS].join(", ")}.` }, 400);
        }
        if (id === user.id && !gestiona(rolPedido)) {
          return json({ error: "No puedes quitarte a ti mismo el permiso de gestionar cuentas." }, 400);
        }
        const { data: destino } = await admin.from("profiles").select("role").eq("id", id).single();
        if (gestiona(destino?.role) && !gestiona(rolPedido) && (await contarAdmins()) <= 1) {
          return json({ error: "Es la unica cuenta que puede administrar: la aplicacion quedaria sin acceso." }, 400);
        }
        const { error } = await admin.from("profiles").update({ role: rolPedido }).eq("id", id);
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
