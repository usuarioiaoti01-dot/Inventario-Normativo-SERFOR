# ============================================================
#  Descarga de Documentos Normativos OPR - SERFOR
#  Descarga los PDF (Resolucion, Documento/Lineamiento y Anexo)
#  listados en "LISTA_DOCUMENTOS_NORMATIVOS_OPR_v.01" y los
#  organiza en subcarpetas por Tipo (Lineamiento/Directiva) y
#  Estado (Vigente/No Vigente).
#
#  Requiere conexion a internet en el equipo donde se ejecute.
#  Ejecutar con PowerShell 7 (pwsh), no con powershell.exe 5.1:
#    pwsh -ExecutionPolicy Bypass -File .\descargar_documentos_normativos_opr.ps1
#
#  Puede volver a ejecutarse: si un archivo ya existe con el
#  mismo nombre y tamano mayor a 0, se omite (no se descarga de
#  nuevo), asi que es seguro reintentar si hubo cortes de red.
# ============================================================

$ErrorActionPreference = "Stop"

# Carpeta raiz del proyecto (ajustar si se copia el script a otra ubicacion)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dest = Join-Path $Root "Documentos Normativos OPR"

Write-Output "Carpeta destino: $Dest"

# ------------------------------------------------------------
#  Listado de documentos (generado desde el Excel origen)
# ------------------------------------------------------------
$Documentos = @(
  [pscustomobject]@{
    Item        = 1
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000213-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-09-06'
    Denominacion= 'Disponen modificación de los Lineamientos para el ejercicio de la potestad sancionadora y desarrollo del procedimiento administrativo sancionador'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6902365/5962357-rde-000213-2024-de.pdf?v=1725642763'
    Archivo     = '01_disponen_modificacion_de_los_lineamientos_para_el_ejerc_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 2
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000224-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-09-18'
    Denominacion= 'Aprueban los Lineamientos para la elaboración de Declaraciones de Manejo de Fauna Silvestre aplicables a zoocriaderos'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6958518/6002554-rde-000224-2024-de.pdf?v=1726673890'
    Archivo     = '02_aprueban_los_lineamientos_para_la_elaboracion_de_declar_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 2
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000224-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-09-18'
    Denominacion= 'Aprueban los Lineamientos para la elaboración de Declaraciones de Manejo de Fauna Silvestre aplicables a zoocriaderos'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6958519/6002554-lin_elaboracion-de-demafs-de-zoocriadero-_-20-05-2024-limpio-rev-26-6-24ff.pdf?v=1726673891'
    Archivo     = '02_aprueban_los_lineamientos_para_la_elaboracion_de_declar_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 3
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000209-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-09-05'
    Denominacion= 'Modifican los Lineamientos para la elaboración de declaración de manejo para permisos de aprovechamiento forestal en Comunidades Nativas y Comunidades Campesinas'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6901176/5961498-rde-000209-2024-de.pdf?v=1725635912'
    Archivo     = '03_modifican_los_lineamientos_para_la_elaboracion_de_decla_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 3
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000209-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-09-05'
    Denominacion= 'Modifican los Lineamientos para la elaboración de declaración de manejo para permisos de aprovechamiento forestal en Comunidades Nativas y Comunidades Campesinas'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6902128/5961498-anexo-rde-modificacion-dema-en-ccnn-rev-abd-rev-dopm-final-03-09-24-1-f.pdf?v=1725641361'
    Archivo     = '03_modifican_los_lineamientos_para_la_elaboracion_de_decla_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 4
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000184-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-07-31'
    Denominacion= 'Aprobar lo "Lineamientos para la formulación del Plan Maestro de Gestión del Bosque de Producción Permanente"'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6724219/5835296-rde-000184-2024-de.pdf?v=1722542948'
    Archivo     = '04_aprobar_lo_lineamientos_para_la_formulacion_del_plan_ma_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 4
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000184-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-07-31'
    Denominacion= 'Aprobar lo "Lineamientos para la formulación del Plan Maestro de Gestión del Bosque de Producción Permanente"'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6724220/5835296-3-propuesta-de-lineamientos-plan-maestro.pdf?v=1722542949'
    Archivo     = '04_aprobar_lo_lineamientos_para_la_formulacion_del_plan_ma_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 5
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000072-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-04-15'
    Denominacion= 'Apruébese la creación de la Nómina de Especialistas del Servicio Nacional Forestal y de Fauna Silvestre - SERFOR; y aprueba los "Lineamientos para la inscripción, selección y contratación de terceros en la nómina de especialistas del SERFOR".'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6212937/5475114-rde-000072-2024-de.pdf?v=1713458475'
    Archivo     = '05_apruebese_la_creacion_de_la_nomina_de_especialistas_del_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 5
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000072-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-04-15'
    Denominacion= 'Apruébese la creación de la Nómina de Especialistas del Servicio Nacional Forestal y de Fauna Silvestre - SERFOR; y aprueba los "Lineamientos para la inscripción, selección y contratación de terceros en la nómina de especialistas del SERFOR".'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6212938/5475114-prop-de-lin-para-publicacion-27-3-24-actualizado-sgd-ultima-version-1-rev-ogaj-rev-dpr-11-4-24ff.pdf?v=1713458476'
    Archivo     = '05_apruebese_la_creacion_de_la_nomina_de_especialistas_del_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 6
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE D0000020-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-01-23'
    Denominacion= 'Modificar el numeral 6.5 de los “Lineamientos para el otorgamiento de la autorización del proyecto y autorización de funcionamiento del centro de cría en cautividad. Modificar el numeral 5.3.1 de los “Lineamientos para la elaboración de planes de manejo de fauna silvestre aplicables para zoológicos'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/5728766/5088022-rde-000020-2024-de.pdf?v=1706116544'
    Archivo     = '06_modificar_el_numeral_6_5_de_los_lineamientos_para_el_ot_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 7
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000270-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-12-15'
    Denominacion= 'Aprobar los Lineamientos para la elaboración del Estudio Técnico de Microzonificación.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/5562893/4949415-rde-000270-2023-de.pdf?v=1702837547'
    Archivo     = '07_aprobar_los_lineamientos_para_la_elaboracion_del_estudi_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 7
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000270-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-12-15'
    Denominacion= 'Aprobar los Lineamientos para la elaboración del Estudio Técnico de Microzonificación.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/5562894/4949415-12122023-lineamiento-para-etm-vff-2.pdf?v=1702837547'
    Archivo     = '07_aprobar_los_lineamientos_para_la_elaboracion_del_estudi_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 9
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000244-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-11-03'
    Denominacion= 'Aprobar los “Lineamientos para el otorgamiento de incentivos y/o beneficios por certificación forestal voluntaria y otras buenas prácticas para la competitividad forestal y de fauna silvestre”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/5374304/4810954-rde-000244-2023-de.pdf?v=1699277980'
    Archivo     = '09_aprobar_los_lineamientos_para_el_otorgamiento_de_incent_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 9
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000244-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-11-03'
    Denominacion= 'Aprobar los “Lineamientos para el otorgamiento de incentivos y/o beneficios por certificación forestal voluntaria y otras buenas prácticas para la competitividad forestal y de fauna silvestre”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/5374321/4810954-3-lin-incentivos_ggff.pdf?v=1699277980'
    Archivo     = '09_aprobar_los_lineamientos_para_el_otorgamiento_de_incent_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 9
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000244-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-11-03'
    Denominacion= 'Aprobar los “Lineamientos para el otorgamiento de incentivos y/o beneficios por certificación forestal voluntaria y otras buenas prácticas para la competitividad forestal y de fauna silvestre”.'
    TipoDoc     = 'anexo'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6383496/4810954-anexos-disp-modificat_rde_ggff.pdf?v=1716393578'
    Archivo     = '09_aprobar_los_lineamientos_para_el_otorgamiento_de_incent_anexo.pdf'
  }
  [pscustomobject]@{
    Item        = 10
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000209-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-09-12'
    Denominacion= 'Aprobar los “Lineamientos para el otorgamiento de la autorización de la tenencia de aves de presa procedentes de zoocriaderos para la práctica de cetrería”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/5122499/RDE-000209-2023-DE.pdf?v=1694615379'
    Archivo     = '10_aprobar_los_lineamientos_para_el_otorgamiento_de_la_aut_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 10
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000209-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-09-12'
    Denominacion= 'Aprobar los “Lineamientos para el otorgamiento de la autorización de la tenencia de aves de presa procedentes de zoocriaderos para la práctica de cetrería”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/5122500/LINEAMIENTOS%20TENENCIA%20AVES%20DE%20PRESA%20vs%20final%2020.7F%201.pdf?v=1694615380'
    Archivo     = '10_aprobar_los_lineamientos_para_el_otorgamiento_de_la_aut_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 11
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000167-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-07-24'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de los libros de registros genealógicos de especies amenazadas de fauna silvestre”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4944523/RDE-000167-2023-DEBqJWB.pdf?v=1691346028'
    Archivo     = '11_aprobar_los_lineamientos_para_la_elaboracion_de_los_lib_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 11
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000167-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-07-24'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de los libros de registros genealógicos de especies amenazadas de fauna silvestre”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4944527/Lineamiento_Registro_Genealogico_final-_05_07_23FFFPL5Eo.pdf?v=1691346028'
    Archivo     = '11_aprobar_los_lineamientos_para_la_elaboracion_de_los_lib_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 12
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000125-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-05-25'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de la declaración de manejo de fauna silvestre para centros de conservación”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4696740/RDE-000125-2023-DEhWdlt.pdf?v=1686936914'
    Archivo     = '12_aprobar_los_lineamientos_para_la_elaboracion_de_la_decl_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 12
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000125-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-05-25'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de la declaración de manejo de fauna silvestre para centros de conservación”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4696744/Proyectos_de_Lin._Dema_Centros_de_Conservacion_7_03_2023_vfFFlzzTs.pdf?v=1686936917'
    Archivo     = '12_aprobar_los_lineamientos_para_la_elaboracion_de_la_decl_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 13
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000081-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-23'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de declaraciones de manejo de fauna silvestre para centros de rescate”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429403/RDE-000081-2023-DE.pdf?v=1717086414'
    Archivo     = '13_aprobar_los_lineamientos_para_la_elaboracion_de_declara_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 13
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000081-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-23'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de declaraciones de manejo de fauna silvestre para centros de rescate”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6420755/4127165-0-2-proyecto-de-lineamiento-dpr-07-03-2023ff.pdf?v=1717086414'
    Archivo     = '13_aprobar_los_lineamientos_para_la_elaboracion_de_declara_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 14
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000082-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-24'
    Denominacion= 'Aprobar los “Lineamientos para el Registro, Sistematización y Remisión de la Información Forestal y de Fauna Silvestre”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429398/RDE-000082-2023-DE.pdf?v=1681421915'
    Archivo     = '14_aprobar_los_lineamientos_para_el_registro_sistematizaci_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 14
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000082-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-24'
    Denominacion= 'Aprobar los “Lineamientos para el Registro, Sistematización y Remisión de la Información Forestal y de Fauna Silvestre”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429402/A._LINEAMIENTO_PARA_EL_REGISTRO_DE_LA_INFORMACION_FORESTAL_Y_DE_FAUNA_SILVESTREFF.pdf?v=1681421916'
    Archivo     = '14_aprobar_los_lineamientos_para_el_registro_sistematizaci_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 15
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000075-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-18'
    Denominacion= 'Aprobar los “Lineamientos para la transferencia de productos, subproductos, o especímenes forestales decomisados o declarados en abandono”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429318/RDE-000075-2023-DE.pdf?v=1681421860'
    Archivo     = '15_aprobar_los_lineamientos_para_la_transferencia_de_produ_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 15
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000075-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-18'
    Denominacion= 'Aprobar los “Lineamientos para la transferencia de productos, subproductos, o especímenes forestales decomisados o declarados en abandono”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429330/LIN_Transferencia_de_Productos_ForestalesFF.pdf?v=1681421866'
    Archivo     = '15_aprobar_los_lineamientos_para_la_transferencia_de_produ_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 16
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000064-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-09'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de la declaración de manejo para el aprovechamiento forestal en bosques secundarios”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4238629/RDE-000064-2023-DE.pdf.pdf?v=1678447042'
    Archivo     = '16_aprobar_los_lineamientos_para_la_elaboracion_de_la_decl_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 16
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000064-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-09'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de la declaración de manejo para el aprovechamiento forestal en bosques secundarios”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4238630/LINEAMIENTOS%20DEMA%20BOSQUES%20SECUNDARIOS%20vfF.pdf.pdf?v=1678447042'
    Archivo     = '16_aprobar_los_lineamientos_para_la_elaboracion_de_la_decl_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 17
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000061-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-08'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de la declaración de manejo para el aprovechamiento forestal maderable en bosques secos”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429274/RDE-000061-2023-DE.pdf?v=1681421830'
    Archivo     = '17_aprobar_los_lineamientos_para_la_elaboracion_de_la_decl_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 17
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000061-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-03-08'
    Denominacion= 'Aprobar los “Lineamientos para la elaboración de la declaración de manejo para el aprovechamiento forestal maderable en bosques secos”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429277/LIN_DEMA_BOSQUES_SECOS_con_VB.pdf?v=1681421830'
    Archivo     = '17_aprobar_los_lineamientos_para_la_elaboracion_de_la_decl_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 18
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000038-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-02-10'
    Denominacion= 'Aprobar los “Lineamientos para el otorgamiento de autorizaciones de cambio de uso actual de la tierra para fines agropecuarios en tierras de dominio público”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4117410/RDE-D000038-2023-MIDAGRI-SERFOR-DE.pdf.pdf?v=1676312789'
    Archivo     = '18_aprobar_los_lineamientos_para_el_otorgamiento_de_autori_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 18
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000038-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-02-10'
    Denominacion= 'Aprobar los “Lineamientos para el otorgamiento de autorizaciones de cambio de uso actual de la tierra para fines agropecuarios en tierras de dominio público”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4117411/LIN%20Autorizac%20de%20Cambio%20de%20uso%20actual%2020220102_RDE-D000038-2023-MIDAGRI-SERFOR-DE.pdf.pdf?v=1676312789'
    Archivo     = '18_aprobar_los_lineamientos_para_el_otorgamiento_de_autori_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 19
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000012-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-01-10'
    Denominacion= 'Aprobar los “Lineamientos para la realización de auditorías y verificaciones a productores y exportadores de productos forestales maderables”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4035861/RDE-000012-2023-DE.pdf.pdf?v=1673451463'
    Archivo     = '19_aprobar_los_lineamientos_para_la_realizacion_de_auditor_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 19
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000012-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-01-10'
    Denominacion= 'Aprobar los “Lineamientos para la realización de auditorías y verificaciones a productores y exportadores de productos forestales maderables”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4035862/Lineamientos%20para%20la%20realizaci%C3%B3n%20de%20auditor%C3%ADas%20prodc%20y%20exportFFF.pdf.pdf?v=1673451463'
    Archivo     = '19_aprobar_los_lineamientos_para_la_realizacion_de_auditor_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 20
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000268-2022-MIDAGRI-SERFOR-DE'
    Fecha       = '2022-11-14'
    Denominacion= 'Aprobar los “Lineamientos para la compensación de multas por infracción a la legislación forestal y de fauna silvestre”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3946611/RDE_N_D000268-2022-MIDAGRI-SERFOR-DE.pdf.pdf?v=1671460692'
    Archivo     = '20_aprobar_los_lineamientos_para_la_compensacion_de_multas_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 20
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000268-2022-MIDAGRI-SERFOR-DE'
    Fecha       = '2022-11-14'
    Denominacion= 'Aprobar los “Lineamientos para la compensación de multas por infracción a la legislación forestal y de fauna silvestre”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3946612/LINEAMIENTO_COMPENSACION_04_10_2022_REV_OGAJ_1F.pdf.pdf?v=1671460692'
    Archivo     = '20_aprobar_los_lineamientos_para_la_compensacion_de_multas_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 21
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000175-2022-MIDAGRI-SERFOR-DE'
    Fecha       = '2022-08-05'
    Denominacion= 'Aprobar los “Lineamientos para la ampliación de la vigencia de los contratos de concesión forestal y de los contratos de concesión de fauna silvestre”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3488101/RDE-000175-2022-DE.pdf.pdf?v=1660149190'
    Archivo     = '21_aprobar_los_lineamientos_para_la_ampliacion_de_la_vigen_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 21
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000175-2022-MIDAGRI-SERFOR-DE'
    Fecha       = '2022-08-05'
    Denominacion= 'Aprobar los “Lineamientos para la ampliación de la vigencia de los contratos de concesión forestal y de los contratos de concesión de fauna silvestre”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3488102/2022_07_22_LIN_Ampliaci%C3%B3n_vigenciaF.pdf.pdf?v=1660149190'
    Archivo     = '21_aprobar_los_lineamientos_para_la_ampliacion_de_la_vigen_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 22
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000017-2022-MIDAGRI-SERFOR-DE'
    Fecha       = '2022-01-19'
    Denominacion= 'Aprobar los Lineamientos para elaboración de planes de manejo de fauna silvestre aplicables en zoológicos.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/2778020/RDE-000017-2022-DE.pdf?v=1642793623'
    Archivo     = '22_aprobar_los_lineamientos_para_elaboracion_de_planes_de_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 23
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000107-2021-MIDAGRI-SERFOR-DE'
    Fecha       = '2021-06-25'
    Denominacion= 'Aprobar los “Lineamientos para el otorgamiento de la autorización a personas naturales para la tenencia de especímenes de fauna silvestre nativa y exótica”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/2002084/RDE-000107-2021-DE.pdf?v=1625665729'
    Archivo     = '23_aprobar_los_lineamientos_para_el_otorgamiento_de_la_aut_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 23
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000107-2021-MIDAGRI-SERFOR-DE'
    Fecha       = '2021-06-25'
    Denominacion= 'Aprobar los “Lineamientos para el otorgamiento de la autorización a personas naturales para la tenencia de especímenes de fauna silvestre nativa y exótica”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/2002093/Lineamientos_aut_tenencia_vfinal_ok_1FFF.pdf?v=1625665738'
    Archivo     = '23_aprobar_los_lineamientos_para_el_otorgamiento_de_la_aut_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 24
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000069-2021-MIDAGRI-SERFOR-DE'
    Fecha       = '2021-04-21'
    Denominacion= 'Aprobar los Lineamientos para la elaboración e implementación de los planes de cierre de las concesiones forestales y de fauna silvestre'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1865476/RDE_N_D0069-2021-MIDAGRI-SERFOR-DE.pdf?v=1620150258'
    Archivo     = '24_aprobar_los_lineamientos_para_la_elaboracion_e_implemen_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 24
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000069-2021-MIDAGRI-SERFOR-DE'
    Fecha       = '2021-04-21'
    Denominacion= 'Aprobar los Lineamientos para la elaboración e implementación de los planes de cierre de las concesiones forestales y de fauna silvestre'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1865475/Lineamientos_Lineamientos_para_la_elaboracion_e_implementacion_de_los_planes_de_cierre_de_las_concesiones_forestales_y__de_fauna_silvest.pdf?v=1620150258'
    Archivo     = '24_aprobar_los_lineamientos_para_la_elaboracion_e_implemen_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 25
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000036-2021-MIDAGRI-SERFOR-DE'
    Fecha       = '2021-03-05'
    Denominacion= 'Aprobar los Lineamientos para la evaluación de planes operativos, declaraciones de manejo y planes de manejo forestal intermedio'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1814989/RDE_N_D0036-2021-MIDAGRI-SERFOR-DE.pdf?v=1618852179'
    Archivo     = '25_aprobar_los_lineamientos_para_la_evaluacion_de_planes_o_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 25
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000036-2021-MIDAGRI-SERFOR-DE'
    Fecha       = '2021-03-05'
    Denominacion= 'Aprobar los Lineamientos para la evaluación de planes operativos, declaraciones de manejo y planes de manejo forestal intermedio'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1814991/Lineamientos_para_la_evaluacion_de_planes_operativos_declaraciones_de_manejo_y_planes_de_manejo_forestal_intermedio.pdf?v=1618852179'
    Archivo     = '25_aprobar_los_lineamientos_para_la_evaluacion_de_planes_o_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 26
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000034-2021-MIDAGRI-SERFOR-DE'
    Fecha       = '2021-03-04'
    Denominacion= 'Aprobar los Lineamientos para la evaluación del Plan General de Manejo Forestal de concesiones forestales con fines maderables'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1721147/RDE_N%C2%B0_D00034-2021-MIDAGRI-SERFOR-DE.pdf?v=1615311057'
    Archivo     = '26_aprobar_los_lineamientos_para_la_evaluacion_del_plan_ge_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 26
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000034-2021-MIDAGRI-SERFOR-DE'
    Fecha       = '2021-03-04'
    Denominacion= 'Aprobar los Lineamientos para la evaluación del Plan General de Manejo Forestal de concesiones forestales con fines maderables'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1721146/Lineamientos_para_la_evaluaci%C3%B3n_del_Plan_General_de_Manejo_Forestal_de_concesiones_forestales_c.pdf?v=1615311056'
    Archivo     = '26_aprobar_los_lineamientos_para_la_evaluacion_del_plan_ge_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 27
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000135-2020-MIDAGRI-SERFOR-DE'
    Fecha       = '2020-12-28'
    Denominacion= 'Aprobar la versión actualizada del documento técnico denominado “Trazabilidad de los Recursos Forestales Maderables”'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1512263/RDE_N%C2%B0_D000135-2020-MIDAGRI-SERFOR-DE_Aprobar_la_version_actualizada_del_documento_tecnico_denominado_Trazabilidad_de_los_Recursos_Forestales_Maderables.pdf?v=1609642501'
    Archivo     = '27_aprobar_la_version_actualizada_del_documento_tecnico_de_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 27
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000135-2020-MIDAGRI-SERFOR-DE'
    Fecha       = '2020-12-28'
    Denominacion= 'Aprobar la versión actualizada del documento técnico denominado “Trazabilidad de los Recursos Forestales Maderables”'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1512268/Version_actualizada_DT_Trazabilidad_con_vb.pdf?v=1609642503'
    Archivo     = '27_aprobar_la_version_actualizada_del_documento_tecnico_de_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 28
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D0081-2020-MINAGRI-SERFOR-DE'
    Fecha       = '2020-09-24'
    Denominacion= 'Aprobar los lineamientos para el reconocimiento o acreditación de Custodios del Patrimonio Forestal y de Fauna Silvestre de la Nación'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1328520/RDE_N%C2%B0_D000081-2020-MINAGRI-SERFOR-DE.pdf?v=1601486470'
    Archivo     = '28_aprobar_los_lineamientos_para_el_reconocimiento_o_acred_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 28
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D0081-2020-MINAGRI-SERFOR-DE'
    Fecha       = '2020-09-24'
    Denominacion= 'Aprobar los lineamientos para el reconocimiento o acreditación de Custodios del Patrimonio Forestal y de Fauna Silvestre de la Nación'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1328522/Lineamientos_para_el_reconocimiento_o_acreditaci%C3%B3n_de_Custodios_del_Patrimonio_Forestal_y_de_Fauna_Silvestre_de_la_Naci%C3%B3n.pdf?v=1601486474'
    Archivo     = '28_aprobar_los_lineamientos_para_el_reconocimiento_o_acred_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 29
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0045-2020-MINAGRI-SERFOR-DE'
    Fecha       = '2020-04-27'
    Denominacion= 'Aprueba Lineamientos prevención control y acciones para mitigar el riesgo de propagación del COVID-19'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1088818/RDE_N__045-2020-MINAGRI-SERFOR-DE20200730-107894-1lfll84.pdf?v=1596143722'
    Archivo     = '29_aprueba_lineamientos_prevencion_control_y_acciones_para_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 30
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0043-2020-MINAGRI-SERFOR-DE'
    Fecha       = '2020-03-13'
    Denominacion= 'Aprobar los Lineamientos para el seguimiento y evaluación de políticas, estrategias, planes programas y proyectos en materia forestal y de fauna silvestre del SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1088807/RDE_N__043-2020-MINAGRI-SERFOR-DE20200730-107894-1nna1hf.pdf?v=1596143672'
    Archivo     = '30_aprobar_los_lineamientos_para_el_seguimiento_y_evaluaci_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 33
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0190-2021-SERFOR-DE'
    Fecha       = '2021-10-11'
    Denominacion= 'Aprueban la Estrategia para la Promoción de Plantaciones Forestales Comerciales 2021-2050'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/2244408/RDE_N_D000190-2021-MIDAGRI-SERFOR-DE.pdf.pdf?v=1634082355'
    Archivo     = '33_aprueban_la_estrategia_para_la_promocion_de_plantacione_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 33
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0190-2021-SERFOR-DE'
    Fecha       = '2021-10-11'
    Denominacion= 'Aprueban la Estrategia para la Promoción de Plantaciones Forestales Comerciales 2021-2050'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/2244409/EPPFC-28_09_2021-Revision_OGAJ_04_10_2021FF.pdf.pdf?v=1634082355'
    Archivo     = '33_aprueban_la_estrategia_para_la_promocion_de_plantacione_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 35
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0261-2019-MINAGRI-SERFOR-DE'
    Fecha       = '2019-12-23'
    Denominacion= 'Aprobar los Lineamientos para establecer hábitats críticos y sus medidas de conservación'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1137655/RDE_N__261-2019-MINAGRI-SERFOR-DE20200801-107894-fiau1k.pdf?v=1596259955'
    Archivo     = '35_aprobar_los_lineamientos_para_establecer_habitats_criti_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 37
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0287-2018-MINAGRI-SERFOR-DE'
    Fecha       = '2018-12-19'
    Denominacion= 'Aprobar los Lineamientos para la identificación de Ecosistemas Frágiles y su incorporación en la Lista Sectorial de Ecosistemas Frágiles'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1118595/RDE_N__287-2018-MINAGRI-SERFOR-DE20200731-107894-kjuix3.pdf?v=1596213734'
    Archivo     = '37_aprobar_los_lineamientos_para_la_identificacion_de_ecos_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 38
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0263-2018-MINAGRI-SERFOR-DE'
    Fecha       = '2018-11-21'
    Denominacion= 'Aprobar los lineamientos para la elaboración de declaración de manejo de concesiones para ecoturismo'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1118403/RDE_N__263-2018-MINAGRI-SERFOR-DE_Aprobar_los_lineamientos_para_la_elaboraci%C3%B3n_de_declaraci%C3%B3n_de_manejo_de_concesiones_para_ecoturismo20200731-107894-x3szyu.pdf?v=1596212760'
    Archivo     = '38_aprobar_los_lineamientos_para_la_elaboracion_de_declara_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 39
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0258-2018-MINAGRI-SERFOR-DE'
    Fecha       = '2018-11-13'
    Denominacion= 'Aprobar los lineamientos para la el otorgamiento de autorizaciones forestales para el aprovechamiento de productos forestales diferentes a la madera en asociaciones vegetales'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1118371/RDE_N__258-2018-MINAGRI20200731-107894-5k0jgf.pdf?v=1596212696'
    Archivo     = '39_aprobar_los_lineamientos_para_la_el_otorgamiento_de_aut_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 40
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0083-2018-MINAGRI-SERFOR-DE'
    Fecha       = '2018-04-23'
    Denominacion= 'Aprobar los lineamientos para la restauración de ecosistemas forestales y otros ecosistemas de vegetación silvestre'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1111584/RDE_N__083-2018-MINAGRI-SERFOR-DE_Aprobar_los_lineamientos_para_la_restauraci%C3%B3n_de_ecosistemas_forestales_y_otros_ecosistemas_de_vegetaci%C3%B3n_silvestre20200731-107894-16x7br.pdf?v=1596193630'
    Archivo     = '40_aprobar_los_lineamientos_para_la_restauracion_de_ecosis_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 40
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0083-2018-MINAGRI-SERFOR-DE'
    Fecha       = '2018-04-23'
    Denominacion= 'Aprobar los lineamientos para la restauración de ecosistemas forestales y otros ecosistemas de vegetación silvestre'
    TipoDoc     = 'anexo'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/5324013/4773353-n-083-2018-minagri-serfor-de.PDF?v=1698186578'
    Archivo     = '40_aprobar_los_lineamientos_para_la_restauracion_de_ecosis_anexo.pdf'
  }
  [pscustomobject]@{
    Item        = 41
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0073-2018-MINAGRI-SERFOR-DE'
    Fecha       = '2018-04-10'
    Denominacion= 'Aprobar los lineamientos para la elaboración del calendario regional de caza deportiva'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1110655/RDE_N__073-2018-MINAGRI-SERFOR-DE20200731-107894-1a3fw6d.pdf?v=1596188574'
    Archivo     = '41_aprobar_los_lineamientos_para_la_elaboracion_del_calend_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 42
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° 0052-2018-MINAGRI-SERFOR-DE'
    Fecha       = '2018-03-20'
    Denominacion= 'Aprobar los lineamientos para la elaboración de declaración de manejo para permisos de aprovechamiento forestal en predios privados'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1113372/RDE_N__052-2018-MINAGRI-SERFOR-DE20200731-107894-lp19lu.PDF?v=1596199521'
    Archivo     = '42_aprobar_los_lineamientos_para_la_elaboracion_de_declara_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 43
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0004-2018-SERFOR-DE'
    Fecha       = '2018-01-09'
    Denominacion= 'Aprobar los "Lineamientos para la aplicación de los criterios de gradualidad para la imposición de la sanción pecuniaria" '
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1115706/RDE_N%C2%BA_0004-2018-SERFOR-DE20200731-107894-xor6pn.pdf?v=1596206698'
    Archivo     = '43_aprobar_los_lineamientos_para_la_aplicacion_de_los_crit_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 47
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0147-2017-SERFOR-DE'
    Fecha       = '2017-06-09'
    Denominacion= 'Aprobar los Lineamientos para el otorgamiento de la autorización de proyecto y funcionamiento del centro de cría en cautividad.'
    TipoDoc     = 'resolucion'
    Url         = 'https://sinia.minam.gob.pe/sites/default/files/sial-rioja/archivos/public/docs/resolucion_direccion_ejecutiva_no_147-2017-serfor-de.pdf'
    Archivo     = '47_aprobar_los_lineamientos_para_el_otorgamiento_de_la_aut_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 48
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0146-2017-SERFOR-DE'
    Fecha       = '2017-06-09'
    Denominacion= 'Aprobar los Lineamientos para el otorgamiento de permisos para manejo de fauna silvestre en predios privados.'
    TipoDoc     = 'resolucion'
    Url         = 'https://sinia.minam.gob.pe/sites/default/files/siar-sanmartin/archivos/public/docs/resolucion_de_direccion_ejecutiva_no_146-2017-serfor-de.pdf'
    Archivo     = '48_aprobar_los_lineamientos_para_el_otorgamiento_de_permis_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 49
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0133-2017-SERFOR-DE'
    Fecha       = '2017-05-24'
    Denominacion= 'Aprobar los Lineamientos para el otorgamiento de concesiones para plantaciones forestales por concesión directa.'
    TipoDoc     = 'resolucion'
    Url         = 'https://www2.congreso.gob.pe/sicr/cendocbib/con5_uibd.nsf/6DB29E728F695A1C052588230052E823/$FILE/37.RDE_133-2017-SERFOR-DE.pdf'
    Archivo     = '49_aprobar_los_lineamientos_para_el_otorgamiento_de_conces_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 52
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0081-2017-SERFOR-DE'
    Fecha       = '2017-03-31'
    Denominacion= 'Aprobar los lineamientos para el otorgamiento de contratos de cesión en uso para sistemas agroforestales'
    TipoDoc     = 'resolucion'
    Url         = 'https://sinia.minam.gob.pe/sites/default/files/sial-rioja/archivos/public/docs/rde_ndeg_081-2017-serfor-de_aprobar_los_lineamientos_para_el_otorgamiento_de_contratos_de_cesion_en_uso_para_sistemas_agroforestales.pdf'
    Archivo     = '52_aprobar_los_lineamientos_para_el_otorgamiento_de_contra_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 53
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0078-2017-SERFOR-DE'
    Fecha       = '2017-03-30'
    Denominacion= 'Aprobar los Lineamientos para el otorgamiento de concesiones forestales con fines maderables por procedimiento abreviado'
    TipoDoc     = 'resolucion'
    Url         = 'https://sinia.minam.gob.pe/sites/default/files/siar-sanmartin/archivos/public/docs/rde_ndeg_078-2017-serfor-de_aprobar_los_lineamientos_para_el_otorgamiento_de_concesiones_forestales_con_fines_maderables_por_procedimiento_abreviado.pdf'
    Archivo     = '53_aprobar_los_lineamientos_para_el_otorgamiento_de_conces_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 54
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0282-2016-SERFOR-DE'
    Fecha       = '2016-12-28'
    Denominacion= 'Aprobar los Lineamientos para el otorgamiento de la autorización para la captura comercial de fauna silvestre'
    TipoDoc     = 'resolucion'
    Url         = 'https://sinia.minam.gob.pe/sites/default/files/sinia/archivos/public/docs/nl20161223-46-52.pdf'
    Archivo     = '54_aprobar_los_lineamientos_para_el_otorgamiento_de_la_aut_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 55
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE Nº 0281-2016-SERFOR-DE'
    Fecha       = '2016-12-28'
    Denominacion= 'Aprobar los Lineamientos para elaboración de la declaración de manejo de concesiones de conservación'
    TipoDoc     = 'resolucion'
    Url         = 'https://sinia.minam.gob.pe/sites/default/files/sinia/archivos/public/docs/nl20161223-38-46.pdf'
    Archivo     = '55_aprobar_los_lineamientos_para_elaboracion_de_la_declara_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 90
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D0026-2020-MINAGRI-SERFOR-DE'
    Fecha       = '2020-07-26'
    Denominacion= 'Aprobar los “Lineamientos para autorizar la realización de estudios del patrimonio en el marco del instrumento de gestión ambiental”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1227542/RDE_N__D000026-2020-MINAGRI-SERFOR-DE20200812-2906259-q661yi.pdf?v=1597204683'
    Archivo     = '90_aprobar_los_lineamientos_para_autorizar_la_realizacion_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 95
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000044-2025-MIDAGRI-SERFOR-DE'
    Fecha       = '2025-02-26'
    Denominacion= 'Lineamientos para el otorgamiento de la autorización de desbosque'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/7708270/6523622-rde-n-d000044-2025-midagri-serfor-de%282%29.pdf?v=1740777566'
    Archivo     = '95_lineamientos_para_el_otorgamiento_de_la_autorizacion_de_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 95
    Tipo        = 'Lineamiento'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000044-2025-MIDAGRI-SERFOR-DE'
    Fecha       = '2025-02-26'
    Denominacion= 'Lineamientos para el otorgamiento de la autorización de desbosque'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/7708569/6523622-a-serforjjneamiento-desbosque_para-vistosff.pdf?v=1740777566'
    Archivo     = '95_lineamientos_para_el_otorgamiento_de_la_autorizacion_de_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 1
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D00002-2025-MIDAGRI-SERFOR-GG'
    Fecha       = '2025-01-06'
    Denominacion= 'Aprobar la Directiva General N° D000001-2025-MIDAGRI-SERFOR-GG: Directiva que regula el reconocimiento de los servidores civiles del servicio nacional forestal y de fauna silvestre - SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/8176492/6840843-rgg-n-d000002-2025-midagri-serfor-gg.pdf?v=1749162698'
    Archivo     = '01_aprobar_la_directiva_general_n_d000001_2025_midagri_ser_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 1
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D00002-2025-MIDAGRI-SERFOR-GG'
    Fecha       = '2025-01-06'
    Denominacion= 'Aprobar la Directiva General N° D000001-2025-MIDAGRI-SERFOR-GG: Directiva que regula el reconocimiento de los servidores civiles del servicio nacional forestal y de fauna silvestre - SERFOR'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/8176471/6840828-directiva-general-n-d000001-2025-midagri-serfor-gg.pdf?v=1749162457'
    Archivo     = '01_aprobar_la_directiva_general_n_d000001_2025_midagri_ser_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 3
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D000029-2024-MIDAGRI-SERFOR-GG'
    Fecha       = '2024-12-27'
    Denominacion= 'Directiva de prevención, atención de denuncia, investigación y sanción de actos de hostigamiento sexual en el servicio nacional forestal y de fauna silvestre - SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/7432020/6331860-rgg-000029-2024-gg.pdf?v=1735345933'
    Archivo     = '03_directiva_de_prevencion_atencion_de_denuncia_investigac_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 3
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D000029-2024-MIDAGRI-SERFOR-GG'
    Fecha       = '2024-12-27'
    Denominacion= 'Directiva de prevención, atención de denuncia, investigación y sanción de actos de hostigamiento sexual en el servicio nacional forestal y de fauna silvestre - SERFOR'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/7440570/6331860-directiva-general-000005-2024-gg.pdf?v=1735655445'
    Archivo     = '03_directiva_de_prevencion_atencion_de_denuncia_investigac_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 4
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D000014-2024-MIDAGRI-SERFOR-GG'
    Fecha       = '2024-07-19'
    Denominacion= 'Directiva General N° D000003-2024-MIDAGRI-SERFOR-GG, “Directiva denominada “Implementación de la Gestión por Procesos en el SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://www.serfor.gob.pe/archivos/transparencia/RGG%20N%C2%B0%20D0014-2024-MIDAGRI-SERFOR-GG,%20que%20aprueba%20la%20Directiva%20N%C2%B0%20003-2024-SERFOR-GG%20Implementaci%C3%B3n%20de%20la%20gesti%C3%B3n%20por%20procesos%20en%20el%20SERFOR.pdf'
    Archivo     = '04_directiva_general_n_d000003_2024_midagri_serfor_gg_dire_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 5
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG Nº 0015-2024-SERFOR-GG'
    Fecha       = '2024-08-09'
    Denominacion= 'Aprobar la Directiva General N° D000004-2024-MIDAGRI-SERFOR-GG denominada “Directiva para la Gestión de la Ecoeficiencia en el Servicio Nacional Forestal y de Fauna Silvestre – SERFOR”'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6761834/5861551-rgg-000015-2024-gg.pdf?v=1723472339'
    Archivo     = '05_aprobar_la_directiva_general_n_d000004_2024_midagri_ser_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 5
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG Nº 0015-2024-SERFOR-GG'
    Fecha       = '2024-08-09'
    Denominacion= 'Aprobar la Directiva General N° D000004-2024-MIDAGRI-SERFOR-GG denominada “Directiva para la Gestión de la Ecoeficiencia en el Servicio Nacional Forestal y de Fauna Silvestre – SERFOR”'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/6771113/5867837-directiva-para-la-gestion-de-la-ecoeficiencia-en-el-servicio-nacional-forestal-y-de-fauna-silvestre-serfor.pdf?v=1723582484'
    Archivo     = '05_aprobar_la_directiva_general_n_d000004_2024_midagri_ser_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 6
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D00028-2023-MIDAGRI-SERFOR-GG'
    Fecha       = '2023-08-31'
    Denominacion= 'Aprobar la Directiva General N° D000004-2023-MIDAGRI-SERFOR-GG denominada “Normas para la Implementación y Funcionamiento del Lactario Institucional en el SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/5103629/RGG-000028-2023-GG.pdf?v=1694182686'
    Archivo     = '06_aprobar_la_directiva_general_n_d000004_2023_midagri_ser_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 8
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RCE N° D000004-2023-MIDAGRI-SERFOR-PKFW'
    Fecha       = '2023-03-08'
    Denominacion= 'Aprobar la Directiva N°0002-2023-MIDAGRI SERFOR PKFW "Directiva para la toma de inventario físico de bienes muebles patrimoniales del programa Fomento y Gestión sostenible de la producción forestal en el Perú'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4689394/RESOLUCION%20DE%20PKFW-2023-0004%5BR%5D%20%281%29%5BF%5D%5BF%5D%5BR%5D.pdf?v=1686854313'
    Archivo     = '08_aprobar_la_directiva_n_0002_2023_midagri_serfor_pkfw_di_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 8
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RCE N° D000004-2023-MIDAGRI-SERFOR-PKFW'
    Fecha       = '2023-03-08'
    Denominacion= 'Aprobar la Directiva N°0002-2023-MIDAGRI SERFOR PKFW "Directiva para la toma de inventario físico de bienes muebles patrimoniales del programa Fomento y Gestión sostenible de la producción forestal en el Perú'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4689363/DIRECTIVA%200002-2023-PKfW%20RCE%20004-2023%5BR%5D%20%281%29%5BF%5D%5BF%5D%5BR%5D.pdf?v=1686853321'
    Archivo     = '08_aprobar_la_directiva_n_0002_2023_midagri_serfor_pkfw_di_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 9
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000030-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-02-07'
    Denominacion= 'Aprobar la Directiva General denominada “Directiva para el Registro, Sistematización y Remisión de la Información Forestal y de Fauna Silvestre”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429175/RDE-000030-2023-DE.pdf?v=1681421767'
    Archivo     = '09_aprobar_la_directiva_general_denominada_directiva_para_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 9
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000030-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-02-07'
    Denominacion= 'Aprobar la Directiva General denominada “Directiva para el Registro, Sistematización y Remisión de la Información Forestal y de Fauna Silvestre”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429176/DIRECTIVA_GENERAL-000001-2023-DE.pdf?v=1681421764'
    Archivo     = '09_aprobar_la_directiva_general_denominada_directiva_para_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 9
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000030-2023-MIDAGRI-SERFOR-DE'
    Fecha       = '2023-02-07'
    Denominacion= 'Aprobar la Directiva General denominada “Directiva para el Registro, Sistematización y Remisión de la Información Forestal y de Fauna Silvestre”.'
    TipoDoc     = 'anexo'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4429173/ANEXO_N_01_Listado_de_los_Registros_Forestales_y_de_Fauna_SilvestreF.pdf?v=1681421766'
    Archivo     = '09_aprobar_la_directiva_general_denominada_directiva_para_anexo.pdf'
  }
  [pscustomobject]@{
    Item        = 14
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0039-2022-MIDAGRI-SERFOR-GG'
    Fecha       = '2022-11-18'
    Denominacion= 'Aprobar la Directiva General Nº D000006-2022-MIDAGRI-SERFOR-GG “Código de Conducta Institucional del Servicio Nacional Forestal y de Fauna Silvestre - SERFOR”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3874889/RGG-000039-2022-GG.pdf?v=1669387103'
    Archivo     = '14_aprobar_la_directiva_general_n_d000006_2022_midagri_ser_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 14
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0039-2022-MIDAGRI-SERFOR-GG'
    Fecha       = '2022-11-18'
    Denominacion= 'Aprobar la Directiva General Nº D000006-2022-MIDAGRI-SERFOR-GG “Código de Conducta Institucional del Servicio Nacional Forestal y de Fauna Silvestre - SERFOR”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3874906/DIRECTIVA_GENERAL-000006-2022-GG.pdf?v=1669387116'
    Archivo     = '14_aprobar_la_directiva_general_n_d000006_2022_midagri_ser_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 15
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0026-2022-MIDAGRI-SERFOR-GG'
    Fecha       = '2022-09-08'
    Denominacion= 'Aprobar la actualización de la Directiva General denominada “Directiva de Gestión Documental del - SERFOR”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/8846704/7300133-rgg-000026-2022-gg.pdf?v=1760724381'
    Archivo     = '15_aprobar_la_actualizacion_de_la_directiva_general_denomi_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 15
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0026-2022-MIDAGRI-SERFOR-GG'
    Fecha       = '2022-09-08'
    Denominacion= 'Aprobar la actualización de la Directiva General denominada “Directiva de Gestión Documental del - SERFOR”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/8846705/7300133-directiva-general-000005-2022-gg.pdf?v=1760724382'
    Archivo     = '15_aprobar_la_actualizacion_de_la_directiva_general_denomi_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 16
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0021-2022-MIDAGRI-SERFOR-GG'
    Fecha       = '2022-08-23'
    Denominacion= 'Aprobar la Directiva General Nº D000004-2022-MIDAGRI-SERFOR-GG “Directiva para la Gestión Editorial del Servicio Nacional Forestal y de Fauna Silvestre – SERFOR”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3543286/RGG-000021-2022-GG.pdf?v=1661409924'
    Archivo     = '16_aprobar_la_directiva_general_n_d000004_2022_midagri_ser_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 16
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0021-2022-MIDAGRI-SERFOR-GG'
    Fecha       = '2022-08-23'
    Denominacion= 'Aprobar la Directiva General Nº D000004-2022-MIDAGRI-SERFOR-GG “Directiva para la Gestión Editorial del Servicio Nacional Forestal y de Fauna Silvestre – SERFOR”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3543295/DIRECTIVA_GENERAL-000004-2022-GG.pdf?v=1661409931'
    Archivo     = '16_aprobar_la_directiva_general_n_d000004_2022_midagri_ser_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 17
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0019-2022-MIDAGRI-SERFOR-GG'
    Fecha       = '2022-07-12'
    Denominacion= 'Aprobar la Directiva denominada “Directiva del Servicio de Soporte Tecnológico de la Información del SERFOR”.'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3424387/RGG-000019-2022-GG.pdf?v=1658031819'
    Archivo     = '17_aprobar_la_directiva_denominada_directiva_del_servicio_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 17
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0019-2022-MIDAGRI-SERFOR-GG'
    Fecha       = '2022-07-12'
    Denominacion= 'Aprobar la Directiva denominada “Directiva del Servicio de Soporte Tecnológico de la Información del SERFOR”.'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3424388/DIRECTIVA_MESA_DE_AYUDA_09-04-2022_Cambios_v1_3FF.pdf?v=1658031821'
    Archivo     = '17_aprobar_la_directiva_denominada_directiva_del_servicio_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 19
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D000039-2022-MIDAGRI-SERFOR.GG'
    Fecha       = '2022-11-18'
    Denominacion= 'Directiva General Código de Conducta Institucional del Servicio Nacional Forestal y de Fauna Silvestre – SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3874889/RGG-000039-2022-GG.pdf?v=1669387103'
    Archivo     = '19_directiva_general_codigo_de_conducta_institucional_del_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 19
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D000039-2022-MIDAGRI-SERFOR.GG'
    Fecha       = '2022-11-18'
    Denominacion= 'Directiva General Código de Conducta Institucional del Servicio Nacional Forestal y de Fauna Silvestre – SERFOR'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/3874906/DIRECTIVA_GENERAL-000006-2022-GG.pdf?v=1669387116'
    Archivo     = '19_directiva_general_codigo_de_conducta_institucional_del_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 22
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0021-2021-MIDAGRI-SERFOR-GG'
    Fecha       = '2021-06-24'
    Denominacion= 'Aprobar la Directiva General Nº d000001-2021-MIDAGRI-SERFOR-GG, “Ciclo de Vida del Software para el Servicio Nacional Forestal y de Fauna Silvestre - SERFOR”'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1985000/RGG-000021-2021-GG.pdf?v=1689613418'
    Archivo     = '22_aprobar_la_directiva_general_n_d000001_2021_midagri_ser_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 22
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0021-2021-MIDAGRI-SERFOR-GG'
    Fecha       = '2021-06-24'
    Denominacion= 'Aprobar la Directiva General Nº d000001-2021-MIDAGRI-SERFOR-GG, “Ciclo de Vida del Software para el Servicio Nacional Forestal y de Fauna Silvestre - SERFOR”'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4858356/DIRECTIVA%20GENERAL%20N%C2%B0%20D00001-2021-MIDAGRI-SERFOR-GG%20Ciclo%20de%20vida%20de%20software%20para%20el%20Servicio%20Nacional%20Forestal%20y%20de%20Fauna%20Silvestre%20-%20SERFOR.pdf?v=1689613418'
    Archivo     = '22_aprobar_la_directiva_general_n_d000001_2021_midagri_ser_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 25
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG Nº 0004-2018-MINAGRI-SERFOR-GG'
    Fecha       = '2018-08-03'
    Denominacion= 'Aprobar la Directiva N° 001-2018-MINGARI-SERFOR-GG Directiva para la atención de Servicios Archivísticos en el archivo central del SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1115619/RGG_N__004-2018-MINAGRI-SERFOR-GG_Aprobar_la_Directiva_N__001-2018-MINGARI-SERFOR-GG_Directiva_para_la_atenci%C3%B3n_de_Servicios_Archivisticos_en_el_Archivo_Central_del_SERFOR20200731-107894-1myclyo.pdf?v=1596206462'
    Archivo     = '25_aprobar_la_directiva_n_001_2018_mingari_serfor_gg_direc_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 31
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RSG Nº 0017-2016-SERFOR-SG'
    Fecha       = '2016-06-06'
    Denominacion= 'Aprobar la Directiva Nº 003-2016-SERFOR-SG Funcionamiento del Sistema Institucional de Archivos del SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/8847673/7300720-directiva-sia-serfor.pdf?v=1760733133'
    Archivo     = '31_aprobar_la_directiva_n_003_2016_serfor_sg_funcionamient_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 37
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0003-2023-MIDAGRI-SERFOR-GG'
    Fecha       = '2023-01-31'
    Denominacion= 'Aprobar la Directiva General N.º D000002-2023-MIDAGRI-SERFOR-GG “Directiva para la gestión de denuncias por presuntos actos de corrupción y otorgamiento de medidas de protección al/a la Denunciante en el Servicio Nacional Forestal y de Fauna Silvestre – SERFOR”'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4087094/RGG-000003-2023-GG.pdf?v=1675368095'
    Archivo     = '37_aprobar_la_directiva_general_n_d000002_2023_midagri_ser_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 37
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0003-2023-MIDAGRI-SERFOR-GG'
    Fecha       = '2023-01-31'
    Denominacion= 'Aprobar la Directiva General N.º D000002-2023-MIDAGRI-SERFOR-GG “Directiva para la gestión de denuncias por presuntos actos de corrupción y otorgamiento de medidas de protección al/a la Denunciante en el Servicio Nacional Forestal y de Fauna Silvestre – SERFOR”'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/4087099/DIRECTIVA_GENERAL-000002-2023-GG.pdf?v=1675368101'
    Archivo     = '37_aprobar_la_directiva_general_n_d000002_2023_midagri_ser_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 39
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0000031-2025-MIDAGRI-SERFOR-GG'
    Fecha       = '2025-03-04'
    Denominacion= 'Directiva General N° D000002-2025-MIDAGRI-SERFOR-GG denominada 
“Directiva que regula la entrega y recepción de cargo de los/las Servidores/as 
Civiles del Servicio Nacional Forestal y de Fauna Silvestre – SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/7739046/6544035-rgg-000031-2025-gg.pdf?v=1741362764'
    Archivo     = '39_directiva_general_n_d000002_2025_midagri_serfor_gg_deno_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 39
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0000031-2025-MIDAGRI-SERFOR-GG'
    Fecha       = '2025-03-04'
    Denominacion= 'Directiva General N° D000002-2025-MIDAGRI-SERFOR-GG denominada 
“Directiva que regula la entrega y recepción de cargo de los/las Servidores/as 
Civiles del Servicio Nacional Forestal y de Fauna Silvestre – SERFOR'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/10141547/6544035-directiva-general-000002-2025-gg.pdf?v=1781190384'
    Archivo     = '39_directiva_general_n_d000002_2025_midagri_serfor_gg_deno_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 40
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D000034-2025-MIDAGRI-SERFOR-GG'
    Fecha       = ''
    Denominacion= 'Plan de Desarrollo de las Personas -PDP 2025 del Servicio Nacional Forestal y de Fauna Silvestre - SERFOR Y DOS MODIFICATORIAS'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/7792889/6579344-rgg-000034-2025-gg.pdf?v=1742329457'
    Archivo     = '40_plan_de_desarrollo_de_las_personas_pdp_2025_del_servici_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 40
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D000034-2025-MIDAGRI-SERFOR-GG'
    Fecha       = ''
    Denominacion= 'Plan de Desarrollo de las Personas -PDP 2025 del Servicio Nacional Forestal y de Fauna Silvestre - SERFOR Y DOS MODIFICATORIAS'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/7792890/6579344-pdp-2025.pdf?v=1742329458'
    Archivo     = '40_plan_de_desarrollo_de_las_personas_pdp_2025_del_servici_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 42
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0024-2021-MIDAGRI-SERFOR-GG'
    Fecha       = '2021-06-28'
    Denominacion= 'Aprobar la Directiva General N° D00004-2021-MIDAGRI-SERFOR-GG Gestión de la Información Espacial del Catastro Forestal'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/2004556/RGG_N_D0024-2021-MIDAGRI-SERFOR-GG.pdf?v=1625761954'
    Archivo     = '42_aprobar_la_directiva_general_n_d00004_2021_midagri_serf_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 42
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0024-2021-MIDAGRI-SERFOR-GG'
    Fecha       = '2021-06-28'
    Denominacion= 'Aprobar la Directiva General N° D00004-2021-MIDAGRI-SERFOR-GG Gestión de la Información Espacial del Catastro Forestal'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/2004564/DIRECTIVA_GENERAL_N_D00004-2021-GG_GEST_INFOR_ESPACIAL_DEL_CATASTRO_FORESTAL_A_TRAVES_DE_LA_INFRAEST_DE_DATOS_ESPACIALES_INSTIT_1.pdf?v=1625761963'
    Archivo     = '42_aprobar_la_directiva_general_n_d00004_2021_midagri_serf_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 43
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D0022-2021-MIDAGRI-SERFOR-GG'
    Fecha       = '2021-06-24'
    Denominacion= 'Aprobar la Directiva General Nº D000002-2021-MIDAGRI-SERFOR-GG, denominada “Procedimiento Administrativo Disciplinario del Servicio Nacional Forestal y de Fauna Silvestre - SERFOR”'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/1985020/RGG-000022-2021-GG.pdf?v=1625090398'
    Archivo     = '43_aprobar_la_directiva_general_n_d000002_2021_midagri_ser_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 45
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG Nº 0026-2022-MINAGRI-SERFOR-GG'
    Fecha       = '2020-05-27'
    Denominacion= 'Aprobar la Actualización de la Directiva N° 002-2020-MINAGRI-SERFOR-GG Directiva de Gestión Documental del SERFOR'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/8846704/7300133-rgg-000026-2022-gg.pdf?v=1760724381'
    Archivo     = '45_aprobar_la_actualizacion_de_la_directiva_n_002_2020_min_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 45
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG Nº 0026-2022-MINAGRI-SERFOR-GG'
    Fecha       = '2020-05-27'
    Denominacion= 'Aprobar la Actualización de la Directiva N° 002-2020-MINAGRI-SERFOR-GG Directiva de Gestión Documental del SERFOR'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/8846705/7300133-directiva-general-000005-2022-gg.pdf?v=1760724382'
    Archivo     = '45_aprobar_la_actualizacion_de_la_directiva_n_002_2020_min_documento.pdf'
  }
  [pscustomobject]@{
    Item        = 64
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RGG N° D000026-2021-MIDAGRI-SERFOR-GG'
    Fecha       = '2024-10-09'
    Denominacion= '“Directiva para la recepción, registro, canalización y seguimiento de denuncias vinculadas a infracciones y delitos en materia forestal y de fauna silvestre del Servicio Nacional Forestal y de Fauna Silvestre - SERFOR”'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/2002094/RGG-000026-2021-GG.pdf?v=1625665738'
    Archivo     = '64_directiva_para_la_recepcion_registro_canalizacion_y_seg_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 65
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000239-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-10-10'
    Denominacion= 'Directiva para el control y supervisión del comercio Internacional de especies CITES'
    TipoDoc     = 'resolucion'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/7077556/6088029-rde-000239-2024-de.pdf?v=1728925690'
    Archivo     = '65_directiva_para_el_control_y_supervision_del_comercio_in_resolucion.pdf'
  }
  [pscustomobject]@{
    Item        = 65
    Tipo        = 'Directiva'
    Estado      = 'Vigente'
    EstadoDir   = 'Vigente'
    Norma       = 'RDE N° D000239-2024-MIDAGRI-SERFOR-DE'
    Fecha       = '2024-10-10'
    Denominacion= 'Directiva para el control y supervisión del comercio Internacional de especies CITES'
    TipoDoc     = 'documento'
    Url         = 'https://cdn.www.gob.pe/uploads/document/file/7077557/6088029-directiva-especifica-000001-2024-de.pdf?v=1728925691'
    Archivo     = '65_directiva_para_el_control_y_supervision_del_comercio_in_documento.pdf'
  }
)
# ------------------------------------------------------------
#  Crear estructura de carpetas y descargar
# ------------------------------------------------------------
$grupos = $Documentos | Group-Object Tipo, EstadoDir
foreach($g in $grupos){
  $tipo, $estadoDir = $g.Name -split ', '
  $carpeta = Join-Path (Join-Path $Dest $tipo) $estadoDir
  if(-not (Test-Path $carpeta)){ New-Item -ItemType Directory -Path $carpeta -Force | Out-Null }
}

$ok = 0
$fallidos = @()
$omitidos = 0
$total = $Documentos.Count
$i = 0

foreach($d in $Documentos){
  $i++
  $carpeta = Join-Path (Join-Path $Dest $d.Tipo) $d.EstadoDir
  $destino = Join-Path $carpeta $d.Archivo

  if((Test-Path $destino) -and (Get-Item $destino).Length -gt 0){
    $omitidos++
    Write-Output "[$i/$total] Omitido (ya existe): $($d.Archivo)"
    continue
  }

  Write-Output "[$i/$total] Descargando: $($d.Archivo)"
  try {
    Invoke-WebRequest -Uri $d.Url -OutFile $destino -UseBasicParsing -TimeoutSec 60
    $ok++
  }
  catch {
    $fallidos += [pscustomobject]@{ Item=$d.Item; Archivo=$d.Archivo; Norma=$d.Norma; Url=$d.Url; Error=$_.Exception.Message }
    Write-Output "    ERROR: $($_.Exception.Message)"
  }
}

Write-Output ""
Write-Output "============================================================"
Write-Output "Descargados correctamente : $ok"
Write-Output "Omitidos (ya existian)    : $omitidos"
Write-Output "Fallidos                  : $($fallidos.Count)"
Write-Output "============================================================"

if($fallidos.Count -gt 0){
  $csvErrores = Join-Path $Dest "errores_descarga.csv"
  $fallidos | Export-Csv -LiteralPath $csvErrores -NoTypeInformation -Encoding UTF8
  Write-Output "Detalle de errores guardado en: $csvErrores"
  Write-Output "Puede volver a ejecutar este mismo script para reintentar solo los fallidos."
}
