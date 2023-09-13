
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

CREATE TYPE "public"."claim_info" AS (
	"success" boolean,
	"error_message" "text",
	"claimed_key" "text"
);

ALTER TYPE "public"."claim_info" OWNER TO "postgres";

CREATE TYPE "public"."feedback_info" AS (
	"promotion_name" "text",
	"promotion_id" bigint,
	"key_id" bigint
);

ALTER TYPE "public"."feedback_info" OWNER TO "postgres";

CREATE TYPE "public"."promotion_info" AS (
	"promotion_id" bigint,
	"promotion_name" "text",
	"promotion_description" "text",
	"promotion_expiry_date" "date",
	"promotion_claimed" boolean,
	"promotion_total_keys" bigint,
	"promotion_unclaimed_keys" bigint
);

ALTER TYPE "public"."promotion_info" OWNER TO "postgres";

CREATE TYPE "public"."redeemed_info" AS (
	"promotion_name" "text",
	"key" "text",
	"feedback_given" boolean
);

ALTER TYPE "public"."redeemed_info" OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."add_feedback"("user_id" "uuid", "target_promotion_id" bigint, "target_key_id" bigint, "feedback_text" "text") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    key_feedback_id bigint;
BEGIN
    -- Check if the specified key exists, belongs to the passed Promotion / User, and that no feedback for it exists yet
    IF NOT EXISTS (
        SELECT 1
        FROM public.keys as k
        WHERE k.key_id = target_key_id AND k.promotion_id = target_promotion_id AND k.claimed_by = user_id AND k.feedback_id IS NULL
    ) THEN
        -- The key does not exist or doesn't belong to the User / Promotion, return false
        RETURN FALSE;
    END IF;

    -- Insert a new feedback entry and retrieve the generated feedback_id
    INSERT INTO Feedback (promotion_id, feedback_text, user_id)
    VALUES (target_promotion_id, feedback_text, user_id)
    RETURNING feedback_id INTO key_feedback_id;

    -- Update the key's feedback_id with the generated feedback_id
    UPDATE public.keys
    SET feedback_id = key_feedback_id
    WHERE key_id = target_key_id;

    -- Return true to indicate successful feedback addition
    RETURN TRUE;
END;
$$;

ALTER FUNCTION "public"."add_feedback"("user_id" "uuid", "target_promotion_id" bigint, "target_key_id" bigint, "feedback_text" "text") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."claim_key"("user_id" "uuid", "target_promotion_id" bigint) RETURNS "public"."claim_info"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    claim_key_id bigint;
    claim_key_text text;
    promotion_expired_date date;
    result claim_info;
BEGIN
    -- Check if the promotion is already expired
    SELECT 
      p.expiration_date INTO promotion_expired_date
    FROM 
      public.promotions p
    WHERE 
      p.promotion_id = target_promotion_id;

    IF promotion_expired_date IS NOT NULL AND promotion_expired_date < current_date THEN
        result := (false, 'This promotion has already expired.', NULL);
    ELSE
        -- Check if the user has already claimed a key for the promotion
        SELECT 
          k.key_id INTO claim_key_id
        FROM 
          public.keys as k
        WHERE 
          k.claimed_by = user_id AND 
          k.promotion_id = target_promotion_id;

        -- If a key is found, the user has already claimed a key for the promotion
        IF claim_key_id IS NOT NULL THEN
            result := (false, 'You have already claimed a key for this promotion.', NULL);
        ELSE
            -- Get the first unclaimed key for the promotion
            SELECT 
              k.key_id, k.key INTO claim_key_id, claim_key_text
            FROM 
              public.keys as k
            WHERE 
              k.promotion_id = target_promotion_id AND
              k.claimed_by IS NULL
            ORDER BY k.created_at
            LIMIT 1;

            -- If an unclaimed key is found, assign it to the user
            IF claim_key_id IS NOT NULL THEN
                UPDATE 
                  public.keys
                SET 
                  claimed_by = user_id
                WHERE 
                  key_id = claim_key_id;
                result := (true, NULL, claim_key_text);
            ELSE
                result := (false, 'No unclaimed keys available for this promotion.', NULL);
            END IF;
        END IF;
    END IF;

    RETURN result;
END;
$$;

ALTER FUNCTION "public"."claim_key"("user_id" "uuid", "target_promotion_id" bigint) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_awaiting_feedback"() RETURNS SETOF "public"."feedback_info"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
      p.name as promotion_name,
      p.promotion_id as promotion_id,
      k.key_id as key_id
    FROM public.keys k
    JOIN public.promotions p ON k.promotion_id = p.promotion_id
    WHERE k.claimed_by = auth.uid()
    AND k.feedback_id IS NULL;
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
      k.key as key,
      (k.feedback_id IS NOT NULL) as feedback_given
    FROM public.keys k
    JOIN public.promotions p ON k.promotion_id = p.promotion_id
    WHERE k.claimed_by = auth.uid();
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
      p.expiration_date as promotion_expiry_date,
      EXISTS (
          SELECT 1
          FROM public.keys k
          WHERE k.promotion_id = p.promotion_id AND k.claimed_by = auth.uid()
      ) AS promotion_claimed,
      ps.total_keys AS promotion_total_keys,
      ps.unclaimed_keys AS promotion_unclaimed_keys
    FROM public.promotions p
    LEFT JOIN public.promotion_key_summary ps USING(promotion_id)
    WHERE p.expiration_date IS NULL OR p.expiration_date >= current_date;
END;
$$;

ALTER FUNCTION "public"."get_running_promotions"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles) THEN
    INSERT INTO public.profiles (id, role)
    VALUES (NEW.id, 'admin');
  ELSE
    INSERT INTO public.profiles (id, role)
    VALUES (NEW.id, 'user');
  END IF;
  
  RETURN NEW;
END;$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."feedback" (
    "feedback_id" bigint NOT NULL,
    "promotion_id" bigint NOT NULL,
    "feedback_text" "text" NOT NULL,
    "user_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."feedback" OWNER TO "postgres";

ALTER TABLE "public"."feedback" ALTER COLUMN "feedback_id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."feedback_feedback_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."keys" (
    "key_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "key" "text" DEFAULT ''::"text" NOT NULL,
    "claimed_by" "uuid",
    "promotion_id" bigint NOT NULL,
    "feedback_id" bigint,
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
    "expiration_date" "date"
);

ALTER TABLE "public"."promotions" OWNER TO "postgres";

CREATE OR REPLACE VIEW "public"."promotion_admin_info" AS
 SELECT "p"."promotion_id",
    "p"."created_at",
    "p"."name",
    "p"."description",
    "p"."expiration_date",
    COALESCE("key_summary"."total_keys", (0)::bigint) AS "total_keys",
    COALESCE("key_summary"."claimed_keys", (0)::bigint) AS "claimed_keys",
        CASE
            WHEN (COALESCE("key_summary"."claimed_keys", (0)::bigint) > 0) THEN ((COALESCE("key_summary"."claimed_keys_with_feedback", (0)::bigint))::numeric / (COALESCE("key_summary"."claimed_keys", (0)::bigint))::numeric)
            ELSE (0)::numeric
        END AS "feedback_ratio"
   FROM ("public"."promotions" "p"
     LEFT JOIN ( SELECT "k"."promotion_id",
            "count"(*) AS "total_keys",
            "sum"(
                CASE
                    WHEN ("k"."claimed_by" IS NOT NULL) THEN 1
                    ELSE 0
                END) AS "claimed_keys",
            "sum"(
                CASE
                    WHEN (("k"."claimed_by" IS NOT NULL) AND ("k"."feedback_id" IS NOT NULL)) THEN 1
                    ELSE 0
                END) AS "claimed_keys_with_feedback"
           FROM "public"."keys" "k"
          GROUP BY "k"."promotion_id") "key_summary" ON (("p"."promotion_id" = "key_summary"."promotion_id")));

ALTER TABLE "public"."promotion_admin_info" OWNER TO "postgres";

CREATE OR REPLACE VIEW "public"."promotion_key_summary" AS
 SELECT "p"."promotion_id",
    "count"("k"."key_id") AS "total_keys",
    "count"(
        CASE
            WHEN ("k"."claimed_by" IS NULL) THEN 1
            ELSE NULL::integer
        END) AS "unclaimed_keys"
   FROM ("public"."promotions" "p"
     LEFT JOIN "public"."keys" "k" USING ("promotion_id"))
  GROUP BY "p"."promotion_id";

ALTER TABLE "public"."promotion_key_summary" OWNER TO "postgres";

ALTER TABLE "public"."promotions" ALTER COLUMN "promotion_id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."promotions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_pkey" PRIMARY KEY ("feedback_id");

ALTER TABLE ONLY "public"."keys"
    ADD CONSTRAINT "keys_feedback_id_key" UNIQUE ("feedback_id");

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

ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_promotion_id_fkey" FOREIGN KEY ("promotion_id") REFERENCES "public"."promotions"("promotion_id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."keys"
    ADD CONSTRAINT "keys_claimed_by_fkey" FOREIGN KEY ("claimed_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."keys"
    ADD CONSTRAINT "keys_feedback_id_fkey" FOREIGN KEY ("feedback_id") REFERENCES "public"."feedback"("feedback_id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."keys"
    ADD CONSTRAINT "keys_promotion_id_fkey" FOREIGN KEY ("promotion_id") REFERENCES "public"."promotions"("promotion_id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

CREATE POLICY "Allow Admins to do everything" ON "public"."feedback" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("auth"."uid"() = "profiles"."id") AND (("profiles"."role")::"text" = 'admin'::"text"))))) WITH CHECK (true);

CREATE POLICY "Allow Admins to do everything" ON "public"."keys" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("auth"."uid"() = "profiles"."id") AND (("profiles"."role")::"text" = 'admin'::"text"))))) WITH CHECK (true);

CREATE POLICY "Allow Admins to do everything" ON "public"."promotions" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("auth"."uid"() = "profiles"."id") AND (("profiles"."role")::"text" = 'admin'::"text"))))) WITH CHECK (true);

CREATE POLICY "Allow Authenticated Users to Read" ON "public"."promotions" FOR SELECT TO "authenticated" USING (true);

CREATE POLICY "Allow Users access to THEIR Profile" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));

CREATE POLICY "Allow Users to SELECT their own Feedack" ON "public"."feedback" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));

CREATE POLICY "Enable INSERT if the User has Keys without Feedback" ON "public"."feedback" FOR INSERT TO "authenticated" WITH CHECK ((NOT (EXISTS ( SELECT 1
   FROM "public"."keys" "k"
  WHERE (("k"."promotion_id" = "k"."promotion_id") AND ("k"."claimed_by" = "auth"."uid"()) AND ("k"."feedback_id" IS NULL))))));

CREATE POLICY "Show Logged In Users only THEIR claimed Keys" ON "public"."keys" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "claimed_by"));

ALTER TABLE "public"."feedback" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."keys" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."promotions" ENABLE ROW LEVEL SECURITY;

REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."add_feedback"("user_id" "uuid", "target_promotion_id" bigint, "target_key_id" bigint, "feedback_text" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_feedback"("user_id" "uuid", "target_promotion_id" bigint, "target_key_id" bigint, "feedback_text" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_feedback"("user_id" "uuid", "target_promotion_id" bigint, "target_key_id" bigint, "feedback_text" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."claim_key"("user_id" "uuid", "target_promotion_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."claim_key"("user_id" "uuid", "target_promotion_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_key"("user_id" "uuid", "target_promotion_id" bigint) TO "service_role";

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

GRANT ALL ON TABLE "public"."feedback" TO "anon";
GRANT ALL ON TABLE "public"."feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."feedback" TO "service_role";

GRANT ALL ON SEQUENCE "public"."feedback_feedback_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."feedback_feedback_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."feedback_feedback_id_seq" TO "service_role";

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

GRANT ALL ON TABLE "public"."promotion_admin_info" TO "anon";
GRANT ALL ON TABLE "public"."promotion_admin_info" TO "authenticated";
GRANT ALL ON TABLE "public"."promotion_admin_info" TO "service_role";

GRANT ALL ON TABLE "public"."promotion_key_summary" TO "anon";
GRANT ALL ON TABLE "public"."promotion_key_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."promotion_key_summary" TO "service_role";

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
