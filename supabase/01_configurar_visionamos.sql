-- Visionamos: ejecutar una vez en SQL Editor de Supabase.
-- Lectura pública; escritura únicamente para soporte@infycredit.com confirmado.
BEGIN;
CREATE SCHEMA IF NOT EXISTS visionamos_private;
REVOKE ALL ON SCHEMA visionamos_private FROM PUBLIC;
GRANT USAGE ON SCHEMA visionamos_private TO authenticated;

CREATE OR REPLACE FUNCTION visionamos_private.can_edit()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = auth.uid()
  AND lower(u.email) = 'soporte@infycredit.com'
  AND u.email_confirmed_at IS NOT NULL AND u.is_anonymous IS NOT TRUE);
$$;
REVOKE ALL ON FUNCTION visionamos_private.can_edit() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION visionamos_private.can_edit() TO authenticated;

CREATE OR REPLACE FUNCTION visionamos_private.valid_report(m text, r jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path = '' AS $$
DECLARE row_data jsonb; seen text[] := ARRAY[]::text[]; entity_name text; quantity numeric;
BEGIN
 IF m !~ '^(2026-(0[3-9]|1[0-2])|2027-0[12])$' OR jsonb_typeof(r) IS DISTINCT FROM 'object'
 OR r->>'month' IS DISTINCT FROM m OR jsonb_typeof(r->'source') IS DISTINCT FROM 'string'
 OR length(trim(r->>'source')) NOT BETWEEN 1 AND 200
 OR jsonb_typeof(r->'rows') IS DISTINCT FROM 'array' THEN RETURN false; END IF;
 IF jsonb_array_length(r->'rows') NOT BETWEEN 1 AND 500 THEN RETURN false; END IF;
 FOR row_data IN SELECT value FROM jsonb_array_elements(r->'rows') LOOP
  IF jsonb_typeof(row_data) IS DISTINCT FROM 'object' OR jsonb_typeof(row_data->'entity') IS DISTINCT FROM 'string' THEN RETURN false; END IF;
  entity_name := upper(trim(row_data->>'entity'));
  IF length(entity_name) NOT BETWEEN 1 AND 100 OR entity_name = ANY(seen) THEN RETURN false; END IF;
  seen := array_append(seen, entity_name);
  IF jsonb_typeof(row_data->'debtor') IS DISTINCT FROM 'number' OR jsonb_typeof(row_data->'codebtor') IS DISTINCT FROM 'number' THEN RETURN false; END IF;
  quantity := (row_data->>'debtor')::numeric;
  IF quantity < 0 OR quantity > 1000000 OR quantity <> trunc(quantity) THEN RETURN false; END IF;
  quantity := (row_data->>'codebtor')::numeric;
  IF quantity < 0 OR quantity > 1000000 OR quantity <> trunc(quantity) THEN RETURN false; END IF;
 END LOOP;
 RETURN true;
EXCEPTION WHEN others THEN RETURN false;
END;
$$;
REVOKE ALL ON FUNCTION visionamos_private.valid_report(text,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION visionamos_private.valid_report(text,jsonb) TO authenticated;

CREATE TABLE IF NOT EXISTS public.visionamos_reports (
 month text PRIMARY KEY,
 report jsonb NOT NULL,
 updated_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT valid_visionamos_report CHECK (visionamos_private.valid_report(month,report))
);
ALTER TABLE public.visionamos_reports ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.visionamos_reports FROM anon, authenticated;
GRANT SELECT ON public.visionamos_reports TO anon, authenticated;
GRANT INSERT, UPDATE ON public.visionamos_reports TO authenticated;
DROP POLICY IF EXISTS visionamos_public_read ON public.visionamos_reports;
CREATE POLICY visionamos_public_read ON public.visionamos_reports FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS visionamos_editor_insert ON public.visionamos_reports;
CREATE POLICY visionamos_editor_insert ON public.visionamos_reports FOR INSERT TO authenticated WITH CHECK ((SELECT visionamos_private.can_edit()));
DROP POLICY IF EXISTS visionamos_editor_update ON public.visionamos_reports;
CREATE POLICY visionamos_editor_update ON public.visionamos_reports FOR UPDATE TO authenticated USING ((SELECT visionamos_private.can_edit())) WITH CHECK ((SELECT visionamos_private.can_edit()));

CREATE OR REPLACE FUNCTION visionamos_private.touch_report()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;
REVOKE ALL ON FUNCTION visionamos_private.touch_report() FROM PUBLIC;
DROP TRIGGER IF EXISTS visionamos_report_updated ON public.visionamos_reports;
CREATE TRIGGER visionamos_report_updated BEFORE UPDATE ON public.visionamos_reports FOR EACH ROW EXECUTE FUNCTION visionamos_private.touch_report();

-- Cargar informes originales sin reemplazar meses que ya estén guardados.
INSERT INTO public.visionamos_reports (month,report) VALUES ('2026-03', '{"month": "2026-03", "source": "01._Informes_Consumos_Visionamo_Marzo_2026.pdf", "rows": [{"entity": "AMAR", "debtor": 254, "codebtor": 41}, {"entity": "COAGROSUR", "debtor": 95, "codebtor": 40}, {"entity": "COINPROGUA", "debtor": 40, "codebtor": 1}, {"entity": "CONGENTE", "debtor": 0, "codebtor": 0}, {"entity": "COOBETHEL", "debtor": 13, "codebtor": 9}, {"entity": "COODESS", "debtor": 1, "codebtor": 0}, {"entity": "COOGRANADA", "debtor": 69, "codebtor": 2}, {"entity": "COOINPE", "debtor": 2, "codebtor": 0}, {"entity": "COOPANTEX", "debtor": 11, "codebtor": 0}, {"entity": "COOPINTEGRATE", "debtor": 27, "codebtor": 2}, {"entity": "COOSANLUIS", "debtor": 164, "codebtor": 1}, {"entity": "COOTRAUNION", "debtor": 16, "codebtor": 0}, {"entity": "COOTREGUA", "debtor": 20, "codebtor": 9}, {"entity": "CREDIFUTURO", "debtor": 0, "codebtor": 0}, {"entity": "FAVI UTP", "debtor": 24, "codebtor": 0}, {"entity": "FINECOOP", "debtor": 80, "codebtor": 0}, {"entity": "FODELSA", "debtor": 34, "codebtor": 0}, {"entity": "MUTUAL CANAPRO", "debtor": 15, "codebtor": 4}, {"entity": "MUTUAL SAN JERONIMO", "debtor": 2, "codebtor": 1}, {"entity": "SUPRESENCIA", "debtor": 3, "codebtor": 1}]}'::jsonb) ON CONFLICT (month) DO NOTHING;
INSERT INTO public.visionamos_reports (month,report) VALUES ('2026-04', '{"month": "2026-04", "source": "02._Informe_Consumo_Visionamos_Abril__2026.pdf", "rows": [{"entity": "AMAR", "debtor": 203, "codebtor": 32}, {"entity": "COOSANLUIS", "debtor": 156, "codebtor": 1}, {"entity": "COOGRANADA", "debtor": 96, "codebtor": 1}, {"entity": "COAGROSUR", "debtor": 67, "codebtor": 26}, {"entity": "FINECOOP", "debtor": 75, "codebtor": 0}, {"entity": "COINPROGUA", "debtor": 40, "codebtor": 5}, {"entity": "COOPINTEGRATE", "debtor": 36, "codebtor": 6}, {"entity": "FODELSA", "debtor": 38, "codebtor": 0}, {"entity": "FAVI UTP", "debtor": 31, "codebtor": 1}, {"entity": "MUTUAL CANAPRO", "debtor": 18, "codebtor": 3}, {"entity": "COOPANTEX", "debtor": 20, "codebtor": 0}, {"entity": "COOTRAUNION", "debtor": 20, "codebtor": 0}, {"entity": "COOBETHEL", "debtor": 9, "codebtor": 9}, {"entity": "COOTREGUA", "debtor": 15, "codebtor": 3}, {"entity": "COOINPE", "debtor": 4, "codebtor": 1}, {"entity": "SUPRESENCIA", "debtor": 3, "codebtor": 1}, {"entity": "CONSOLIDARIDAD", "debtor": 2, "codebtor": 0}, {"entity": "PREVENSERVICIOS", "debtor": 1, "codebtor": 0}, {"entity": "CONGENTE", "debtor": 0, "codebtor": 0}, {"entity": "COODESS", "debtor": 0, "codebtor": 0}, {"entity": "MULTIROBLE", "debtor": 0, "codebtor": 0}, {"entity": "MUTUAL SAN JERONIMO", "debtor": 0, "codebtor": 0}]}'::jsonb) ON CONFLICT (month) DO NOTHING;
INSERT INTO public.visionamos_reports (month,report) VALUES ('2026-05', '{"month": "2026-05", "source": "03._Informe_Consumo_Visionamos_Mayo_2026.pdf", "rows": [{"entity": "AMAR", "debtor": 248, "codebtor": 58}, {"entity": "COOSANLUIS", "debtor": 159, "codebtor": 2}, {"entity": "COAGROSUR", "debtor": 66, "codebtor": 33}, {"entity": "COOGRANADA", "debtor": 69, "codebtor": 0}, {"entity": "COOTRAUNION", "debtor": 67, "codebtor": 0}, {"entity": "COOPANTEX", "debtor": 48, "codebtor": 0}, {"entity": "FODELSA", "debtor": 46, "codebtor": 0}, {"entity": "FINECOOP", "debtor": 45, "codebtor": 0}, {"entity": "COINPROGUA", "debtor": 36, "codebtor": 5}, {"entity": "COOPINTEGRATE", "debtor": 33, "codebtor": 2}, {"entity": "FAVI UTP", "debtor": 34, "codebtor": 0}, {"entity": "COOTREGUA", "debtor": 21, "codebtor": 9}, {"entity": "MUTUAL CANAPRO", "debtor": 16, "codebtor": 2}, {"entity": "CONSOLIDARIDAD", "debtor": 14, "codebtor": 0}, {"entity": "COOBETHEL", "debtor": 3, "codebtor": 2}, {"entity": "FONEMCAP", "debtor": 2, "codebtor": 1}, {"entity": "PREVENSERVICIOS", "debtor": 2, "codebtor": 1}, {"entity": "MULTIROBLE", "debtor": 2, "codebtor": 0}, {"entity": "COOINPE", "debtor": 1, "codebtor": 0}, {"entity": "FENDESA", "debtor": 1, "codebtor": 0}, {"entity": "MUTUAL SAN JERONIMO", "debtor": 1, "codebtor": 0}, {"entity": "SUPRESENCIA", "debtor": 1, "codebtor": 0}, {"entity": "CONGENTE", "debtor": 0, "codebtor": 0}]}'::jsonb) ON CONFLICT (month) DO NOTHING;
INSERT INTO public.visionamos_reports (month,report) VALUES ('2026-06', '{"month": "2026-06", "source": "04._Informe_Consumo_Visionamos_Junio_2026.pdf", "rows": [{"entity": "AMAR", "debtor": 228, "codebtor": 45}, {"entity": "COOSANLUIS", "debtor": 121, "codebtor": 2}, {"entity": "COAGROSUR", "debtor": 84, "codebtor": 38}, {"entity": "COOPANTEX", "debtor": 81, "codebtor": 0}, {"entity": "COOGRANADA", "debtor": 58, "codebtor": 0}, {"entity": "FODELSA", "debtor": 55, "codebtor": 0}, {"entity": "COOPINTEGRATE", "debtor": 49, "codebtor": 4}, {"entity": "COOTRAUNION", "debtor": 53, "codebtor": 0}, {"entity": "COINPROGUA", "debtor": 42, "codebtor": 6}, {"entity": "FINECOOP", "debtor": 44, "codebtor": 0}, {"entity": "COOTREGUA", "debtor": 21, "codebtor": 4}, {"entity": "FAVI UTP", "debtor": 17, "codebtor": 0}, {"entity": "MULTIROBLE", "debtor": 17, "codebtor": 0}, {"entity": "MUTUAL CANAPRO", "debtor": 14, "codebtor": 1}, {"entity": "FONEMCAP", "debtor": 8, "codebtor": 1}, {"entity": "CONSOLIDARIDAD", "debtor": 4, "codebtor": 0}, {"entity": "FENDESA", "debtor": 2, "codebtor": 0}, {"entity": "SUPRESENCIA", "debtor": 2, "codebtor": 0}, {"entity": "PREVENSERVICIOS", "debtor": 1, "codebtor": 0}, {"entity": "CONGENTE", "debtor": 0, "codebtor": 0}, {"entity": "COOBETHEL", "debtor": 0, "codebtor": 0}, {"entity": "COOINPE", "debtor": 0, "codebtor": 0}, {"entity": "MUTUAL SAN JERONIMO", "debtor": 0, "codebtor": 0}]}'::jsonb) ON CONFLICT (month) DO NOTHING;
INSERT INTO public.visionamos_reports (month,report) VALUES ('2026-07', '{"month": "2026-07", "source": "05._Informe_Consumo_Visionamos_Julio_2026.pdf", "rows": [{"entity": "AMAR", "debtor": 255, "codebtor": 54}, {"entity": "COOSANLUIS", "debtor": 143, "codebtor": 2}, {"entity": "COAGROSUR", "debtor": 103, "codebtor": 36}, {"entity": "COOTRAUNION", "debtor": 78, "codebtor": 0}, {"entity": "FODELSA", "debtor": 75, "codebtor": 1}, {"entity": "COOTREGUA", "debtor": 58, "codebtor": 11}, {"entity": "COOGRANADA", "debtor": 63, "codebtor": 2}, {"entity": "FINECOOP", "debtor": 62, "codebtor": 0}, {"entity": "COOPANTEX", "debtor": 55, "codebtor": 0}, {"entity": "COINPROGUA", "debtor": 43, "codebtor": 7}, {"entity": "FAVI UTP", "debtor": 35, "codebtor": 0}, {"entity": "COOPINTEGRATE", "debtor": 32, "codebtor": 2}, {"entity": "MUTUAL CANAPRO", "debtor": 24, "codebtor": 2}, {"entity": "FONEMCAP", "debtor": 21, "codebtor": 2}, {"entity": "CONSOLIDARIDAD", "debtor": 8, "codebtor": 0}, {"entity": "MULTIROBLE", "debtor": 6, "codebtor": 0}, {"entity": "PREVENSERVICIOS", "debtor": 3, "codebtor": 0}, {"entity": "COOINPE", "debtor": 2, "codebtor": 0}, {"entity": "COOTRACHEC", "debtor": 2, "codebtor": 0}, {"entity": "MUTUAL SAN JERONIMO", "debtor": 2, "codebtor": 0}]}'::jsonb) ON CONFLICT (month) DO NOTHING;
INSERT INTO public.visionamos_reports (month,report) VALUES ('2026-08', '{"month": "2026-08", "source": "06._Informe_Consumo_Visionamos_Agosto_2026.pdf", "rows": [{"entity": "AMAR", "debtor": 199, "codebtor": 48}, {"entity": "COOSANLUIS", "debtor": 178, "codebtor": 0}, {"entity": "COAGROSUR", "debtor": 96, "codebtor": 43}, {"entity": "FINECOOP", "debtor": 97, "codebtor": 0}, {"entity": "FODELSA", "debtor": 77, "codebtor": 0}, {"entity": "COOPANTEX", "debtor": 73, "codebtor": 0}, {"entity": "COOTRAUNION", "debtor": 70, "codebtor": 0}, {"entity": "COOGRANADA", "debtor": 64, "codebtor": 1}, {"entity": "COOTREGUA", "debtor": 52, "codebtor": 8}, {"entity": "COINPROGUA", "debtor": 39, "codebtor": 3}, {"entity": "FONEMCAP", "debtor": 32, "codebtor": 4}, {"entity": "FAVI UTP", "debtor": 35, "codebtor": 0}, {"entity": "COOPINTEGRATE", "debtor": 22, "codebtor": 5}, {"entity": "MUTUAL CANAPRO", "debtor": 19, "codebtor": 5}, {"entity": "COOINPE", "debtor": 14, "codebtor": 0}, {"entity": "MULTIROBLE", "debtor": 14, "codebtor": 0}, {"entity": "CONSOLIDARIDAD", "debtor": 12, "codebtor": 0}, {"entity": "COOTRACHEC", "debtor": 0, "codebtor": 0}, {"entity": "MUTUAL SAN JERONIMO", "debtor": 0, "codebtor": 0}, {"entity": "PREVENSERVICIOS", "debtor": 0, "codebtor": 0}]}'::jsonb) ON CONFLICT (month) DO NOTHING;
COMMIT;
SELECT month, jsonb_array_length(report->'rows') AS entidades FROM public.visionamos_reports ORDER BY month;
