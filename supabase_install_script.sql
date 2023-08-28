
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

ALTER SCHEMA "public" OWNER TO "postgres";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE TYPE "public"."feedback_info" AS (
	"promotion_name" "text",
	"key_id" bigint
);

ALTER TYPE "public"."feedback_info" OWNER TO "postgres";

CREATE TYPE "public"."promotion_info" AS (
	"promotion_id" bigint,
	"promotion_name" "text",
	"promotion_description" "text",
	"claimed" boolean
);

ALTER TYPE "public"."promotion_info" OWNER TO "postgres";

CREATE TYPE "public"."redeemed_info" AS (
	"promotion_name" "text",
	"key_id" bigint,
	"feedback_given" boolean
);

ALTER TYPE "public"."redeemed_info" OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."claim_key"("promotion_id" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    key_id bigint;
BEGIN
    -- Check if the user has already claimed a key for the promotion
    SELECT
      key_id INTO key_id
    FROM
      public.keys
    WHERE
      claimed_by = auth.uid() AND
      promotion_id = promotion_id;

    -- If a key is found, the user has already claimed a key for the promotion
    IF key_id IS NOT NULL THEN
        RETURN false;
    END IF;

    -- Get the first unclaimed key ID for the promotion
    SELECT
      key_id
    INTO
      key_id
    FROM
      public.keys
    WHERE
      promotion_id = promotion_id AND
      claimed = false
    ORDER BY created_at
    LIMIT 1;

    -- If an unclaimed key ID is found, assign it to the user
    IF key_id IS NOT NULL THEN
        UPDATE
          public.keys
        SET
          claimed_by = auth.uid(),
          claimed = true
        WHERE
          key_id = key_id;
        RETURN true;
    ELSE
        RETURN false; -- No unclaimed keys available
    END IF;
END;
$$;

ALTER FUNCTION "public"."claim_key"("promotion_id" bigint) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_awaiting_feedback"() RETURNS SETOF "public"."feedback_info"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
      p.name as promotion_name,
      k.key_id as key_id
    FROM public.keys k
    JOIN public.promotions p ON k.promotion_id = p.promotion_id
    WHERE k.claimed_by = auth.uid()
    AND k.feedback_given = false;
END;
$$;

ALTER FUNCTION "public"."get_awaiting_feedback"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_redeemed"() RETURNS SETOF "public"."redeemed_info"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
      p.name as promotion_name,
      k.key_id as key_id,
      k.feedback_given as feedback_given
    FROM public.keys k
    JOIN public.promotions p ON k.promotion_id = p.promotion_id
    WHERE k.claimed_by = auth.uid()
    AND k.claimed = true;
END;
$$;

ALTER FUNCTION "public"."get_redeemed"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_running_promotions"() RETURNS SETOF "public"."promotion_info"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
      p.promotion_id as promotion_id,
      p.name as promotion_name,
      p.description as promotion_description,
      EXISTS (
          SELECT 1
          FROM public.keys k
          WHERE k.promotion_id = p.promotion_id AND k.claimed_by = auth.uid()
      ) AS claimed
    FROM public.promotions p
    WHERE p.expiration_date IS NULL OR p.expiration_date >= current_date;
END;
$$;

ALTER FUNCTION "public"."get_running_promotions"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, role)
  values (new.id, 'user');
  return new;
end;
$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."keys" (
    "key_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "key" "text" DEFAULT ''::"text" NOT NULL,
    "claimed_by" "uuid",
    "claimed" boolean NOT NULL,
    "feedback_given" boolean DEFAULT false NOT NULL,
    "promotion_id" bigint NOT NULL,
    CONSTRAINT "keys_key_check" CHECK (("length"("key") <= 17))
);

ALTER TABLE "public"."keys" OWNER TO "postgres";

ALTER TABLE "public"."keys" ALTER COLUMN "key_id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."keys_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "role" character varying(255)
);

ALTER TABLE "public"."profiles" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."promotions" (
    "promotion_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "name" "text" NOT NULL,
    "description" "text",
    "temporary" boolean DEFAULT false NOT NULL,
    "expiration_date" "date"
);

ALTER TABLE "public"."promotions" OWNER TO "postgres";

ALTER TABLE "public"."promotions" ALTER COLUMN "promotion_id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."promotions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY "public"."keys"
    ADD CONSTRAINT "keys_key_key" UNIQUE ("key");

ALTER TABLE ONLY "public"."keys"
    ADD CONSTRAINT "keys_pkey" PRIMARY KEY ("key_id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."promotions"
    ADD CONSTRAINT "promotions_name_key" UNIQUE ("name");

ALTER TABLE ONLY "public"."promotions"
    ADD CONSTRAINT "promotions_pkey" PRIMARY KEY ("promotion_id");

ALTER TABLE ONLY "public"."keys"
    ADD CONSTRAINT "keys_claimed_by_fkey" FOREIGN KEY ("claimed_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."keys"
    ADD CONSTRAINT "keys_promotion_id_fkey" FOREIGN KEY ("promotion_id") REFERENCES "public"."promotions"("promotion_id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

CREATE POLICY "Allow Admins to do everything" ON "public"."keys" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("auth"."uid"() = "profiles"."id") AND (("profiles"."role")::"text" = 'admin'::"text"))))) WITH CHECK (true);

CREATE POLICY "Allow Admins to do everything" ON "public"."promotions" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("auth"."uid"() = "profiles"."id") AND (("profiles"."role")::"text" = 'admin'::"text"))))) WITH CHECK (true);

CREATE POLICY "Allow Authenticated Users to Read" ON "public"."promotions" FOR SELECT TO "authenticated" USING (true);

CREATE POLICY "Only allow Users to SELECT on their own Profile" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));

CREATE POLICY "Show Logged In Users only THEIR claimed Keys" ON "public"."keys" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "claimed_by"));

ALTER TABLE "public"."keys" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."promotions" ENABLE ROW LEVEL SECURITY;

REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."claim_key"("promotion_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."claim_key"("promotion_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_key"("promotion_id" bigint) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_awaiting_feedback"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_awaiting_feedback"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_awaiting_feedback"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_redeemed"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_redeemed"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_redeemed"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_running_promotions"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_running_promotions"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_running_promotions"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON TABLE "public"."keys" TO "anon";
GRANT ALL ON TABLE "public"."keys" TO "authenticated";
GRANT ALL ON TABLE "public"."keys" TO "service_role";

GRANT ALL ON SEQUENCE "public"."keys_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."keys_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."keys_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";

GRANT ALL ON TABLE "public"."promotions" TO "anon";
GRANT ALL ON TABLE "public"."promotions" TO "authenticated";
GRANT ALL ON TABLE "public"."promotions" TO "service_role";

GRANT ALL ON SEQUENCE "public"."promotions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."promotions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."promotions_id_seq" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
