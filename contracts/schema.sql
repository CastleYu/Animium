-- PostgreSQL 16+
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE source_kind AS ENUM ('NEWS','DATABASE','OFFICIAL');
CREATE TYPE access_method AS ENUM ('API','RSS','CRAWLER');
CREATE TYPE legal_status AS ENUM ('approved','review','blocked');
CREATE TYPE health_status AS ENUM ('healthy','degraded','rate_limited','auth_error','schema_drift','disabled');

CREATE TABLE source (
  id text PRIMARY KEY,
  name text NOT NULL,
  kind source_kind NOT NULL,
  access_method access_method NOT NULL,
  trust_tier text NOT NULL CHECK (trust_tier IN ('T0','T1','T2','T3','T4')),
  enabled boolean NOT NULL DEFAULT false,
  legal_status legal_status NOT NULL DEFAULT 'review',
  poll_interval_seconds integer,
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE source_endpoint (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id text NOT NULL REFERENCES source(id) ON DELETE CASCADE,
  endpoint_type text NOT NULL,
  url text,
  locale text,
  auth_mode text NOT NULL DEFAULT 'none',
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE(source_id, endpoint_type, locale)
);

CREATE TABLE source_cursor (
  source_id text PRIMARY KEY REFERENCES source(id) ON DELETE CASCADE,
  etag text,
  last_modified text,
  cursor jsonb,
  last_external_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE source_health (
  source_id text PRIMARY KEY REFERENCES source(id) ON DELETE CASCADE,
  status health_status NOT NULL DEFAULT 'disabled',
  consecutive_failures integer NOT NULL DEFAULT 0,
  consecutive_successes integer NOT NULL DEFAULT 0,
  last_success_at timestamptz,
  last_error_at timestamptz,
  last_http_status integer,
  last_error_code text,
  last_error_message text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ingest_run (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id text NOT NULL REFERENCES source(id),
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  status text NOT NULL,
  http_status integer,
  fetched_count integer NOT NULL DEFAULT 0,
  accepted_count integer NOT NULL DEFAULT 0,
  duplicate_count integer NOT NULL DEFAULT 0,
  error_count integer NOT NULL DEFAULT 0,
  error_code text,
  error_message text
);
CREATE INDEX ingest_run_source_started_idx ON ingest_run(source_id, started_at DESC);

CREATE TABLE anime (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  canonical_title text NOT NULL,
  original_title text,
  format text,
  status text,
  start_date date,
  end_date date,
  season text,
  season_year integer,
  adult_flag boolean,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX anime_title_trgm_idx ON anime USING gin (canonical_title gin_trgm_ops);

CREATE TABLE anime_title (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  anime_id uuid NOT NULL REFERENCES anime(id) ON DELETE CASCADE,
  title text NOT NULL,
  normalized_title text NOT NULL,
  language text,
  script text,
  title_type text NOT NULL,
  source_id text REFERENCES source(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(anime_id, normalized_title, title_type, source_id)
);
CREATE INDEX anime_title_norm_trgm_idx ON anime_title USING gin (normalized_title gin_trgm_ops);

CREATE TABLE anime_external_id (
  anime_id uuid NOT NULL REFERENCES anime(id) ON DELETE CASCADE,
  namespace text NOT NULL,
  external_id text NOT NULL,
  source_id text REFERENCES source(id),
  observed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(namespace, external_id),
  UNIQUE(anime_id, namespace)
);

CREATE TABLE anime_provenance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  anime_id uuid NOT NULL REFERENCES anime(id) ON DELETE CASCADE,
  field_name text NOT NULL,
  source_id text NOT NULL REFERENCES source(id),
  source_value jsonb NOT NULL,
  confidence numeric(5,4) NOT NULL DEFAULT 1,
  observed_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX anime_prov_idx ON anime_provenance(anime_id, field_name, observed_at DESC);

CREATE TABLE news_article (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  normalized_title text NOT NULL,
  canonical_url text NOT NULL,
  language text,
  excerpt text,
  published_at timestamptz NOT NULL,
  updated_at timestamptz,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  content_fingerprint text,
  story_cluster_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(canonical_url)
);
CREATE INDEX news_pub_idx ON news_article(published_at DESC, id DESC);
CREATE INDEX news_title_trgm_idx ON news_article USING gin (normalized_title gin_trgm_ops);

CREATE TABLE news_source_item (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  news_id uuid NOT NULL REFERENCES news_article(id) ON DELETE CASCADE,
  source_id text NOT NULL REFERENCES source(id),
  external_id text,
  source_url text NOT NULL,
  source_published_at timestamptz,
  raw_hash text NOT NULL,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(source_id, external_id),
  UNIQUE(source_id, source_url)
);

CREATE TABLE news_anime (
  news_id uuid NOT NULL REFERENCES news_article(id) ON DELETE CASCADE,
  anime_id uuid NOT NULL REFERENCES anime(id) ON DELETE CASCADE,
  relation_type text NOT NULL,
  confidence numeric(5,4) NOT NULL,
  matched_title text,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(news_id, anime_id)
);

CREATE TABLE official_post (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id text NOT NULL REFERENCES source(id),
  external_id text NOT NULL,
  channel_id text,
  title text NOT NULL,
  url text NOT NULL,
  published_at timestamptz NOT NULL,
  updated_at timestamptz,
  content_fingerprint text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(source_id, external_id),
  UNIQUE(url)
);
CREATE INDEX official_post_pub_idx ON official_post(published_at DESC, id DESC);

CREATE TABLE official_post_anime (
  post_id uuid NOT NULL REFERENCES official_post(id) ON DELETE CASCADE,
  anime_id uuid NOT NULL REFERENCES anime(id) ON DELETE CASCADE,
  relation_type text NOT NULL,
  confidence numeric(5,4) NOT NULL,
  PRIMARY KEY(post_id, anime_id)
);

CREATE TABLE schedule_entry (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  anime_id uuid NOT NULL REFERENCES anime(id) ON DELETE CASCADE,
  source_id text NOT NULL REFERENCES source(id),
  external_id text,
  air_type text NOT NULL DEFAULT 'unknown',
  episode_number numeric(8,2),
  starts_at timestamptz NOT NULL,
  source_timezone text,
  status text,
  observed_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(source_id, external_id)
);
CREATE INDEX schedule_time_idx ON schedule_entry(starts_at, anime_id);

CREATE TABLE match_candidate (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  object_type text NOT NULL,
  object_id uuid NOT NULL,
  anime_id uuid NOT NULL REFERENCES anime(id) ON DELETE CASCADE,
  score numeric(5,4) NOT NULL,
  reasons jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now()
);
