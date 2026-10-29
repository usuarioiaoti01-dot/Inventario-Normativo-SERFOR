// ============================================================
//  Edge Function: preguntar
//  Responde preguntas sobre UN documento normativo usando Claude (Anthropic).
//  La clave ANTHROPIC_API_KEY vive aquí como secreto — NUNCA en el frontend.
//
//  EL PDF NO PASA POR AQUI. Se le entrega a Anthropic una URL firmada y lo
//  descarga el. Antes se bajaba el archivo, se convertia a base64 (que en
//  JavaScript ocupa el DOBLE, por ser texto) y se copiaba otra vez al
//  serializar la peticion: un escaneado de 12 MB llegaba a ~100 MB y el
//  proceso moria con WORKER_RESOURCE_LIMIT. Ademas se analizaba el PDF con
//  unpdf solo para contar paginas, que era el gasto de CPU mas caro.
//
//  Los PDF escaneados se leen igual: Claude procesa cada pagina tambien como
//  imagen, de modo que el OCR ya viene incluido y no hace falta anadirlo.
//
//  Despliegue (ver LEEME.md):
//    1) Guardar el secreto:  ANTHROPIC_API_KEY = sk-ant-...
//    2) Desplegar la función: preguntar
// ============================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

    // 2) Leer la peticion. 'archivo' es OPCIONAL: sin el, el asistente solo
    //    busca en el catalogo; con el, ademas lee ese documento.
    const { archivo, pregunta } = await req.json();
    if (!pregunta) return json({ error: "Falta 'pregunta'." }, 400);

    // 3) El catalogo que puede ver QUIEN PREGUNTA.
    //    Se consulta con el cliente del usuario, no con service role: asi lo
    //    filtra RLS y el asistente nunca revela documentos de un conjunto
    //    al que esa persona no tiene acceso.
    const campos = "id, titulo, tipo, entidad, anio, fecha, estado, carpeta, parte, archivo";
    const [rOti, rOpr] = await Promise.all([
      userClient.from("documentos").select(campos),
      userClient.from("normativos_opr").select(campos),
    ]);
    const catalogo = [
      ...(rOti.data ?? []).map((d) => ({ ...d, tabla: "documentos" })),
      ...(rOpr.data ?? []).map((d) => ({ ...d, tabla: "normativos_opr" })),
    ];

    //  Una linea por documento, compacta: el modelo la lee bien y ocupa poco.
    const limpio = (v: unknown) => String(v ?? "").replace(/[|\n\r]/g, " ").trim();
    const listado = catalogo
      .map((d) => [
        `${d.tabla}:${d.id}`, limpio(d.titulo), limpio(d.tipo), limpio(d.entidad),
        limpio(d.fecha) || limpio(d.anio), limpio(d.estado),
        limpio(d.carpeta), limpio(d.parte),
      ].join(" | "))
      .join("\n");

    // 4) El PDF abierto, si lo hay. NO se descarga: se firma una URL temporal
    //    y Anthropic la busca por su cuenta.
    const admin = createClient(SUPABASE_URL, SERVICE_KEY);
    let urlPdf: string | null = null;
    if (archivo) {
      //  La firma se hace con service role, que salta RLS, asi que el permiso
      //  hay que comprobarlo AQUI: ese archivo debe estar en el catalogo que
      //  RLS dejo ver a esta persona. Sin esto, conociendo la ruta se podria
      //  preguntar por un documento de otro conjunto.
      if (!catalogo.some((d) => d.archivo === archivo)) {
        return json({ error: "No tienes acceso a ese documento." }, 403);
      }
      //  5 minutos: suficiente para que Anthropic lo descargue y poco para
      //  que la URL sirva de algo si se filtra. Es el mismo mecanismo que ya
      //  usa el visor de la aplicacion.
      const { data: firma, error: errFirma } = await admin.storage
        .from("documentos").createSignedUrl(archivo, 300);
      if (errFirma || !firma?.signedUrl) {
        return json({ error: "No se pudo preparar el documento: " + (errFirma?.message ?? "") }, 404);
      }
      urlPdf = firma.signedUrl;
    }

    // Mensaje para documentos que superan el límite del asistente
    const BIG_MSG = "DOCUMENTO DEMASIADO EXTENSO - PUEDO LEER HASTA 600 PAGINAS POR DOCUMENTO";

    const system = [
      "Eres el asistente del Inventario Normativo del SERFOR (Peru). Responde SIEMPRE en espanol,",
      "de forma clara, precisa y breve. Haces DOS cosas:",
      "",
      "1) ENCONTRAR DOCUMENTOS. Al final de este mensaje tienes el catalogo completo de lo que",
      "   esta persona puede consultar, una linea por documento con este formato:",
      "       clave | titulo | tipo | entidad | fecha | estado | carpeta | parte",
      "   Cuando pidan localizar documentos (por tema, numero, tipo, entidad, ano, fecha, estado,",
      "   o cualquier otro criterio), busca en ese catalogo y responde con los que coincidan.",
      "   MUY IMPORTANTE: por cada documento que menciones, escribe su marca [[doc:clave]]",
      "   justo despues del titulo. Ejemplo:",
      "       Encontre 2 directivas sobre ecoeficiencia:",
      "       - RGG N 024-2026-MIDAGRI-SERFOR-GG [[doc:normativos_opr:123]]",
      "       - Directiva General N 003-2024 [[doc:documentos:45]]",
      "   La marca es obligatoria: sin ella la persona no puede abrir el documento.",
      "   Si no hay coincidencias, dilo con claridad y sugiere como reformular.",
      "   No inventes documentos: solo puedes nombrar los que estan en el catalogo.",
      "",
      "2) CONSULTAR CONTENIDO. Si se adjunta un PDF, responde sobre el basandote UNICAMENTE en su",
      "   texto, citando articulo, numeral o seccion. Si la respuesta no esta ahi, dilo en vez de",
      "   inventar. No uses marcas [[doc:...]] al responder sobre el documento adjunto.",
      "",
      "Decide tu cual de las dos cosas te piden. Ante la duda, responde sobre el documento adjunto",
      "si lo hay y ofrece buscar en el inventario.",
      "",
      "",
      "CATALOGO (" + catalogo.length + " documentos):",
      listado,
    ].join("\n");

    const content: unknown[] = [];
    if (urlPdf) {
      //  'url': Anthropic descarga el PDF. Los escaneados se leen igual,
      //  porque cada pagina se procesa tambien como imagen.
      content.push({ type: "document", source: { type: "url", url: urlPdf }, citations: { enabled: true } });
    }
    content.push({ type: "text", text: pregunta });

    // 4) Preguntar a Claude (Haiku 4.5)
    //  Haiku 5.5 en vez de 4.5 por dos motivos concretos:
    //    - contexto de 1M en lugar de 200K, y el limite de paginas por PDF
    //      depende de eso: 600 con 1M, solo 100 por debajo.
    //    - cuesta la decima parte, lo que importa porque ahora cada pregunta
    //      lleva el catalogo entero.
    //  2048 porque una lista de coincidencias ocupa mas que una respuesta suelta.
    const body = { model: "claude-haiku-5-5", max_tokens: 2048, system, messages: [{ role: "user", content }] };

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
      //  Ya no se cuentan paginas aqui: el limite lo aplica Claude y se
      //  traduce su error. Cubre tambien el tope de 32 MB por documento.
      if (resp.status === 400 && /PDF pages|exceeds the maximum|too large|prompt is too long/i.test(t)) {
        return json({ respuesta: BIG_MSG, grande: true });
      }
      //  Si Anthropic no pudo descargar el archivo, decirlo con claridad
      if (/unable to (fetch|download)|failed to fetch|url.*not.*accessible/i.test(t)) {
        return json({ error: "Anthropic no pudo descargar el documento desde el almacén. Vuelve a intentarlo." }, 502);
      }
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

    //  Las marcas [[doc:tabla:id]] se convierten en una lista de documentos y
    //  se quitan del texto: en pantalla se ven como fichas, no como codigo.
    const vistos = new Set<string>();
    const encontrados: unknown[] = [];
    for (const m of texto.matchAll(/\[\[doc:([a-z_]+):(\d+)\]\]/g)) {
      const clave = `${m[1]}:${m[2]}`;
      if (vistos.has(clave)) continue;
      const d = catalogo.find((x) => `${x.tabla}:${x.id}` === clave);
      if (!d) continue;             // el modelo invento una clave: se descarta
      vistos.add(clave);
      encontrados.push({ clave, titulo: d.titulo, tipo: d.tipo, entidad: d.entidad,
                         fecha: d.fecha, anio: d.anio, estado: d.estado, parte: d.parte });
    }
    const limpioTexto = texto.replace(/\s*\[\[doc:[a-z_]+:\d+\]\]/g, "").trim();

    return json({
      respuesta: limpioTexto,
      documentos: encontrados,
      paginas: [...paginas].sort((a, b) => a - b),
      catalogo: catalogo.length,
      uso: data.usage,
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
