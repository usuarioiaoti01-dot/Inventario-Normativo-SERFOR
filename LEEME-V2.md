# Versión 2.0 — Observaciones de OPR

Rama `version-2.0`, publicada en `/v.02/`. La versión 1.0 (`main`, `/v.01/`)
sigue funcionando sin cambios: **ambas usan la misma base de datos**, pero la
2.0 lee columnas que la 1.0 ignora, de modo que conviven sin estorbarse.

Origen: `OBS_PROTOTIPO (Recomendaciones OPR) - 150926.pptx`, 27 observaciones
en 10 diapositivas.

## Antes de usarla

Ejecutar **`supabase-v2-observaciones-opr.sql`** en el SQL Editor. Añade
columnas y corrige datos; no quita nada, así que la 1.0 no se ve afectada.

## Hecho

| Diap. | Observación | Cómo quedó |
|---|---|---|
| 1 | «Inventario OPR» → «Inventario» | Rótulo fijo |
| 1 | Filtro de fecha por rango | Campos *Desde* y *hasta*; un rango al revés se corrige solo |
| 1, 2, 7 | Órgano / UO Proponente | Columna, filtro, campo en el alta y en la carga masiva. Visible en la cabecera de cada norma |
| 2 | Orden del más reciente al más antiguo | Por **fecha de publicación**. Antes era solo por año, así que dentro de un año el orden era arbitrario |
| 2 | Nombre formal de la resolución | Las ~101 resoluciones toman el número formal, que ya estaba guardado en `carpeta` |
| 3 | Todos los documentos igual | Todo se presenta desplegable, también lo que es un solo archivo: «1 documento» |
| 3 | Los 25 «expedientes» | Título compuesto, agrupados como el resto |
| 4 | Descarga en PDF y Word | Botones separados. El de Word solo aparece si el documento lo tiene |
| 5 | «Año» → fecha completa | Campo de fecha; el año se deriva de ella |
| 5 | ¿Para qué sirve «Colección»? | Explicado con ejemplos en el propio formulario |
| 6 | Reducir los tipos | Lista corta **solo en Normativos OPR**. Normas OTI conserva la larga |
| 7 | «Modificada» → «Modificación» | Renombrado, y aparece el campo *Modifica a* al elegirlo |
| 8 | «¿Existen otros tipos de guardar?» | El selector se oculta cuando solo hay un destino |
| 8 | ¿Cómo se enlaza cada archivo? | Explicado en la ventana del formato, con ejemplos de una norma repartida en tres archivos |
| 9 | Adecuar la carga masiva | Plantilla nueva: `fecha`, `organo`, `modifica_a`; fuera `anio` |
| 10 | Se vuelve a la lista al cambiar de pestaña | Corregido: `TOKEN_REFRESHED` ya no reinicia la pantalla |
| 10 | Anexos | Admitidos como parte, con su propio orden |

## Pendiente de datos, no de programación

La capacidad está construida; falta el dato.

| Qué falta | Cuánto | Quién |
|---|---|---|
| Archivos **Word** | 354 documentos, ninguno tiene .docx | OPR |
| **Órgano proponente** de los que no se deducen | 239 de 354 | OPR |
| **Título formal** de los documentos normativos | ~87 (parte `Documento`) | Extraer del PDF y revisar |
| **Separar los expedientes** en resolución + documento | 25 | OPR, si decide hacerlo |

Sobre el órgano: el relleno automático usa el prefijo de la resolución
(RGG → Gerencia General, RDE → Dirección Ejecutiva, RSG → Secretaría General).
Eso da el órgano que **emite**, que no siempre es el que **propone**. El campo
es editable para corregirlo.

## Sin resolver, requiere respuesta de OPR

1. **Diapositiva 1** — «Agregar Perfiles para que puedan acceder a los nuevos
   registros»: ¿un menú visible de perfiles, o que más perfiles puedan cargar?
   Lo segundo ya está hecho. Si piden que un no administrador gestione cuentas,
   es un cambio de seguridad que conviene decidir explícitamente.
2. **Diapositiva 10** — «la vista de documentos será una sola pestaña»:
   ¿unificar Normas OTI y Normativos OPR en un solo listado? Chocaría con el
   esquema de perfiles.
3. **Diapositiva 10** — «si un documento normativo está derogado no constituye
   que se encuentre en la plataforma»: ¿los derogados se ocultan, se archivan o
   se quitan? Hoy se muestran con etiqueta.

## Otros puntos de la diapositiva 10

- **Capacidad**: 630 MB de 1 GB ocupados, unos 220 documentos más de margen en
  el plan gratuito. Con los Word sube un 30-40 %. Si SERFOR va a seguir
  generando normas, hace falta plan de pago o despliegue propio.
- **Manual de usuario**: pendiente. Conviene escribirlo cuando OPR valide esta
  versión, no antes.
