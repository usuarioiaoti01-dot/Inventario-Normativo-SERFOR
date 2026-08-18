// ============================================================
//  Edge Function: preguntar
//  Responde preguntas sobre UN documento normativo usando Claude (Anthropic).
//  La clave ANTHROPIC_API_KEY vive aquí como secreto — NUNCA en el frontend.
//
//  Despliegue (ver LEEME.md):
//    1) Guardar el secreto:  ANTHROPIC_API_KEY = sk-ant-...
//    2) Desplegar la función: preguntar
// ============================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { encodeBase64 } from "https://deno.land/std@0.224.0/encoding/base64.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (obj: unknown, status = 200) =>
  new Response(JSON.stringify(obj), { status, headers: { ...cors, "content-type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
    if (!ANTHROPIC_API_KEY) return json({ error: "Falta el secreto ANTHROPIC_API_KEY en la función." }, 500);

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // 1) Verificar que quien llama tiene sesión iniciada
    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: authHeader } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "No autenticado." }, 401);

    // 2) Leer la petición
    const { archivo, pregunta } = await req.json();
    if (!archivo || !pregunta) return json({ error: "Faltan 'archivo' o 'pregunta'." }, 400);

    // 3) Descargar el PDF del Storage privado (con service role)
    const admin = createClient(SUPABASE_URL, SERVICE_KEY);
    const { data: file, error: dlErr } = await admin.storage.from("documentos").download(archivo);
    if (dlErr || !file) return json({ error: "No se pudo leer el documento: " + (dlErr?.message ?? "") }, 404);

    const bytes = new Uint8Array(await file.arrayBuffer());
    // Límite práctico (Claude admite hasta 32 MB por petición; base64 infla ~33%).
    if (bytes.length > 22 * 1024 * 1024) {
      return json({ error: "El documento es muy grande para el asistente (más de ~22 MB). Puedo dividirlo si lo necesitas." }, 413);
    }

    // Claude lee PDF nativo hasta 100 páginas. Para documentos más grandes,
    // extraemos el texto y se lo pasamos como texto (sin límite de páginas).
    let usarTexto = false, textoDoc = "";
    try {
      const { getDocumentProxy, extractText } = await import("https://esm.sh/unpdf@0.12.1");
      const pdf = await getDocumentProxy(bytes);
      if (pdf.numPages > 100) {
        const r = await extractText(pdf, { mergePages: true });
        textoDoc = typeof r.text === "string" ? r.text : (Array.isArray(r.text) ? r.text.join("\n") : "");
        if (textoDoc.trim().length > 0) usarTexto = true;
      }
    } catch (_) { /* si falla la extracción, usamos el PDF nativo */ }

    const MAX_CHARS = 700000; // ~175k tokens, margen para el contexto de Haiku (200K)
    let notaTruncado = "";
    if (usarTexto && textoDoc.length > MAX_CHARS) {
      textoDoc = textoDoc.slice(0, MAX_CHARS);
      notaTruncado = "\n\n[NOTA: documento muy extenso; se analizó solo la primera parte.]";
    }

    const system =
      "Eres el asistente del Inventario Normativo del SERFOR (Perú). Respondes preguntas sobre documentos normativos " +
      "(directivas, reglamentos, leyes, resoluciones). Responde SIEMPRE en español, de forma clara, precisa y breve, " +
      "basándote ÚNICAMENTE en el documento proporcionado. Cita el artículo, numeral o sección cuando corresponda. " +
      "Si la respuesta no está en el documento, dilo explícitamente en lugar de inventar.";

    const content = usarTexto
      ? [{ type: "text", text: `A continuación el TEXTO del documento normativo:\n\n"""\n${textoDoc}${notaTruncado}\n"""\n\nPregunta del usuario: ${pregunta}` }]
      : [
          { type: "document", source: { type: "base64", media_type: "application/pdf", data: encodeBase64(bytes) }, citations: { enabled: true } },
          { type: "text", text: pregunta },
        ];

    // 4) Preguntar a Claude (Haiku 4.5)
    const body = { model: "claude-haiku-4-5", max_tokens: 1024, system, messages: [{ role: "user", content }] };

    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!resp.ok) {
      const t = await resp.text();
      return json({ error: "Error de Claude (" + resp.status + "): " + t }, 502);
    }

    const data = await resp.json();

    // 5) Combinar bloques de texto y recopilar páginas citadas
    let texto = "";
    const paginas = new Set<number>();
    for (const b of data.content ?? []) {
      if (b.type === "text") {
        texto += b.text;
        for (const c of b.citations ?? []) {
          if (c.type === "page_location" && c.start_page_number) paginas.add(c.start_page_number);
        }
      }
    }

    return json({ respuesta: texto.trim(), paginas: [...paginas].sort((a, b) => a - b), uso: data.usage });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
