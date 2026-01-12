-- =========================================================================
-- FIX TRIGGER FUNCTION TO USE TEXT INSTEAD OF ENUM TYPE
-- =========================================================================
-- The handle_new_user() trigger runs in auth schema context where the public.user_role
-- enum is not visible. Cast the value to TEXT instead.
-- Also fix gen_random_bytes() call which fails in auth schema context.

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_invite_slug TEXT;
    v_family_id UUID;
    v_role TEXT;
    v_family_name TEXT;
    v_full_name TEXT;
BEGIN
    v_invite_slug := new.raw_user_meta_data->>'invite_slug';

    IF new.raw_user_meta_data ? 'role' THEN
        v_role := new.raw_user_meta_data->>'role';
    ELSE
        v_role := 'member';
    END IF;

    v_full_name := COALESCE(
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'name',
        'Anonymous User'
    );

    IF v_invite_slug IS NOT NULL THEN
        SELECT id INTO v_family_id FROM families WHERE invite_slug = v_invite_slug;

        IF v_family_id IS NOT NULL THEN
            INSERT INTO public.profiles (auth_user_id, family_id, full_name, avatar_url, role)
            VALUES (
                new.id,
                v_family_id,
                v_full_name,
                new.raw_user_meta_data->>'avatar_url',
                v_role::public.user_role
            );
        END IF;
    ELSE
        v_invite_slug := lower(substring(md5(new.id::text || now()::text), 1, 8));

        v_family_name := COALESCE(
            new.raw_user_meta_data->>'family_name',
            new.raw_user_meta_data->>'full_name',
            'My Family'
        );

        INSERT INTO public.families (name, invite_slug)
        VALUES (v_family_name, v_invite_slug)
        RETURNING id INTO v_family_id;

        INSERT INTO public.profiles (auth_user_id, family_id, full_name, avatar_url, role)
        VALUES (
            new.id,
            v_family_id,
            v_full_name,
            new.raw_user_meta_data->>'avatar_url',
            'organizer'::public.user_role
        );
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
