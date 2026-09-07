-- ============================================================
--  Corregir la cuenta que quedo con el perfil equivocado
--
--  Causa: la Edge Function 'admin-usuarios' desplegada era la version
--  anterior, que solo conocia 'admin' y 'especialista'. Al pedirle
--  'normas_oti' lo descartaba y asignaba 'especialista' SIN avisar.
--
--  Lo correcto es redesplegar la funcion (Edge Functions ->
--  admin-usuarios -> Deploy) y luego cambiar el perfil desde la
--  pestaña Usuarios. Este script es la alternativa directa.
--
--  Cambia el correo por el de la cuenta afectada.
-- ============================================================

-- 1. Ver como quedaron las cuentas
select email, role, debe_cambiar_clave from public.profiles order by email;

-- 2. Corregir la que corresponda  (AJUSTAR EL CORREO)
update public.profiles
   set role = 'normas_oti'
 where lower(email) = lower('correo@serfor.gob.pe');

-- 3. Comprobar
select email, role from public.profiles order by role, email;
