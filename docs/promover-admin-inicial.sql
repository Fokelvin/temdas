-- Procedimento manual, separado das migrations. Executar somente depois da
-- migration 20261008000720453-usuario-admin e após confirmar o JWT.sub da
-- conta inicial. Substitua o marcador abaixo pelo supabaseUserId (UUID) exato.
-- Em caso de erro, a transação não deve ser confirmada.

BEGIN;
SET LOCAL lock_timeout = '5s';

DO $$
DECLARE
    target_sub uuid := '<JWT_SUB_DO_USUARIO_INICIAL>'::uuid;
BEGIN
    -- Serializa outras alterações em usuarios durante o bootstrap.
    LOCK TABLE public.usuarios IN SHARE ROW EXCLUSIVE MODE;

    IF NOT EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE "supabaseUserId" = target_sub::text
    ) THEN
        RAISE EXCEPTION 'Usuario não encontrado para o JWT.sub informado.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE "isAdmin" AND "supabaseUserId" <> target_sub::text
    ) THEN
        RAISE EXCEPTION 'Já existe outro administrador; bootstrap recusado.';
    END IF;

    UPDATE public.usuarios
       SET "isAdmin" = true
     WHERE "supabaseUserId" = target_sub::text
       AND "isAdmin" = false;
END;
$$;

COMMIT;
