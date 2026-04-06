--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 15.8

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

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text NOT NULL,
    code_challenge_method auth.code_challenge_method NOT NULL,
    code_challenge text NOT NULL,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'stores metadata for pkce logins';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048))
);


--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
00000000-0000-0000-0000-000000000000	f1c23d54-674e-4cd1-b55e-29821b59a762	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-07 18:52:15.242453+00	
00000000-0000-0000-0000-000000000000	82f3bff2-efe7-47ee-9280-0c00d1fcd5ce	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-07 20:24:29.687223+00	
00000000-0000-0000-0000-000000000000	3db3f701-f052-4dd8-a9dc-c3bbb8304584	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-07 21:32:08.507605+00	
00000000-0000-0000-0000-000000000000	e06375e8-bf84-45af-85f7-84e8bd55af9e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-07 21:32:08.513412+00	
00000000-0000-0000-0000-000000000000	bf1d016f-c195-42f4-a90e-15afa376e5d7	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-07 21:38:58.570921+00	
00000000-0000-0000-0000-000000000000	ff8aaaf6-bf31-49a1-b0f7-0eadeb410010	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-07 21:38:58.575466+00	
00000000-0000-0000-0000-000000000000	387a41e8-9cc6-4ed7-960f-c011cfb533b5	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-07 22:50:05.757363+00	
00000000-0000-0000-0000-000000000000	f71a35ce-a1e7-4c46-a813-962ad149b5b4	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-07 22:50:05.779281+00	
00000000-0000-0000-0000-000000000000	43f8e271-94b8-4070-9169-f0bea7c0ea16	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-07 23:55:20.208932+00	
00000000-0000-0000-0000-000000000000	5f416733-7e1a-4cca-bc57-ec30a9fd701a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-07 23:55:20.214856+00	
00000000-0000-0000-0000-000000000000	43ca219b-4ea4-4051-8c40-ce412c7b8599	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 00:55:41.978725+00	
00000000-0000-0000-0000-000000000000	39dfaad4-ac7e-4095-9409-012e3c4df840	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 00:55:39.641791+00	
00000000-0000-0000-0000-000000000000	9b10e2bb-beb0-4220-85c3-98569afb3d4a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 01:54:04.367472+00	
00000000-0000-0000-0000-000000000000	ce1f4570-0319-48e5-ae18-4ac32249874d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 01:54:04.38269+00	
00000000-0000-0000-0000-000000000000	ce4f3192-e353-4440-a8c6-a8b543b3cf95	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-08 02:04:03.993666+00	
00000000-0000-0000-0000-000000000000	925ecf0c-08be-4e8d-a030-5402bbc5d25b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 03:02:44.872177+00	
00000000-0000-0000-0000-000000000000	6132f2d6-1b80-4535-abb9-85ddc92cb553	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 03:02:44.878437+00	
00000000-0000-0000-0000-000000000000	2e05b3c7-b708-42ef-9872-e20715c98ee2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 04:08:15.287317+00	
00000000-0000-0000-0000-000000000000	13571cb0-5e79-40de-bc34-1ddea81d468c	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 04:08:15.310543+00	
00000000-0000-0000-0000-000000000000	36a6d622-f908-4134-92ce-bbfdaa3deab8	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-02-08 04:15:01.315289+00	
00000000-0000-0000-0000-000000000000	a710123a-5b32-4fcd-9265-316697da4b26	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-08 04:15:03.932239+00	
00000000-0000-0000-0000-000000000000	cd7fb8c3-d842-475c-a22a-f22b20add796	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-08 04:56:02.839823+00	
00000000-0000-0000-0000-000000000000	2e5855a6-7635-4cec-9328-ada95c247707	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 19:11:31.890802+00	
00000000-0000-0000-0000-000000000000	d0822dfd-f5d6-4dcd-a747-5a7f7c48901d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 19:11:31.907491+00	
00000000-0000-0000-0000-000000000000	ea3fc2a9-d3ba-478c-ac1a-69d8e99cefad	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-08 19:21:38.241528+00	
00000000-0000-0000-0000-000000000000	05ecec44-af6b-4539-8299-01ced57e5077	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-02-08 19:41:14.118958+00	
00000000-0000-0000-0000-000000000000	6895c313-406c-4157-b55a-e17fa35eb4cf	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 20:09:49.483775+00	
00000000-0000-0000-0000-000000000000	c7f34f17-d227-450e-abba-dd66427cd6d3	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 20:09:49.489306+00	
00000000-0000-0000-0000-000000000000	1376cc06-f23c-41e7-9be4-8821280ca8f5	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-08 21:18:31.335202+00	
00000000-0000-0000-0000-000000000000	4035ae6b-4de4-4164-94df-ada8dc26d244	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 22:21:04.990441+00	
00000000-0000-0000-0000-000000000000	f162f5d2-b4fb-45b7-9a01-38292312281a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 22:21:05.005396+00	
00000000-0000-0000-0000-000000000000	106699b1-e88e-42a3-8c6b-fbd18f0ad1c9	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 23:19:13.220734+00	
00000000-0000-0000-0000-000000000000	4660fbf9-4401-42ea-801b-ed470d503943	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-08 23:19:13.231339+00	
00000000-0000-0000-0000-000000000000	027f2673-b190-4cc4-b43a-a119051f9b5a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-09 04:17:34.68049+00	
00000000-0000-0000-0000-000000000000	c586c047-2d13-407d-8bff-5550a80e38fe	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-09 04:17:34.730406+00	
00000000-0000-0000-0000-000000000000	25125413-664b-49f6-8d6c-5a23811e4b48	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-09 18:16:09.280347+00	
00000000-0000-0000-0000-000000000000	18d83f01-c7c0-4dcf-a114-02489f577d2d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-09 18:16:09.344694+00	
00000000-0000-0000-0000-000000000000	55c8a03c-bf56-4ea6-9b73-2815f0518a0f	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 00:10:35.528673+00	
00000000-0000-0000-0000-000000000000	ef09c893-c033-4955-aeb5-4eab1a1f14f3	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 00:10:35.610729+00	
00000000-0000-0000-0000-000000000000	ca31e843-b7fc-4593-b24e-e23e484c0846	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-10 00:10:37.159985+00	
00000000-0000-0000-0000-000000000000	c69608e4-3be4-47e5-9b19-dc569f209667	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-10 00:11:20.65456+00	
00000000-0000-0000-0000-000000000000	ea662956-3e28-4541-873f-e2bdfd09bc73	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-02-10 00:34:09.706313+00	
00000000-0000-0000-0000-000000000000	a848b6b6-113a-4238-9947-fa54efb8fd94	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 00:57:36.431729+00	
00000000-0000-0000-0000-000000000000	e3cb9cdd-25fd-466b-8928-4b0d4eb82176	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 00:57:36.451542+00	
00000000-0000-0000-0000-000000000000	3ed02d8f-c8ab-4b50-b9cb-86468c5762b3	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 02:11:21.354993+00	
00000000-0000-0000-0000-000000000000	af64900a-dc5f-410f-9b56-752acd400b93	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 02:11:21.361096+00	
00000000-0000-0000-0000-000000000000	0db4e8d6-873f-41d5-948f-b2264dd1a597	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 03:48:08.972449+00	
00000000-0000-0000-0000-000000000000	f37be5ff-0748-4f01-bc0a-ca827a8f0b1e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 03:48:08.978298+00	
00000000-0000-0000-0000-000000000000	d62eb4e4-1adb-4085-9484-7a0e5949c94f	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 14:57:19.41897+00	
00000000-0000-0000-0000-000000000000	9da2b7d0-52bf-43cd-9377-c7512c1b9455	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 14:57:19.451695+00	
00000000-0000-0000-0000-000000000000	5d68f94c-6f88-41d1-b008-86aa17124647	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 16:02:11.450972+00	
00000000-0000-0000-0000-000000000000	616cdb7c-51e2-442a-a46d-cac536707473	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 16:02:11.457658+00	
00000000-0000-0000-0000-000000000000	46ae4516-26a5-4d01-8767-de58cc78b407	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 17:32:24.139459+00	
00000000-0000-0000-0000-000000000000	481a895e-b4d7-4d75-85c3-78d4e203d296	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 17:32:24.145146+00	
00000000-0000-0000-0000-000000000000	6c5fb971-e234-402e-bab3-f7f0c0e213ce	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 18:41:17.797381+00	
00000000-0000-0000-0000-000000000000	bb85bf24-042f-4888-a6a2-01d94fda0856	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 18:41:17.803385+00	
00000000-0000-0000-0000-000000000000	e187f356-a28e-4b9b-8fdd-2eb741c051ef	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 22:58:26.723605+00	
00000000-0000-0000-0000-000000000000	802431d9-b142-4c9e-b987-29f6a6f785bd	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-10 22:58:26.846782+00	
00000000-0000-0000-0000-000000000000	99f5840b-c34f-4dcd-91f7-00f39e91e226	{"action":"login","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-12 19:41:47.477816+00	
00000000-0000-0000-0000-000000000000	b5d29c80-2f5d-4181-94b0-9848491284e6	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 13:42:16.513898+00	
00000000-0000-0000-0000-000000000000	e2dbeca2-43a7-46f1-80e7-4df2e4efdd62	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 13:42:16.582488+00	
00000000-0000-0000-0000-000000000000	2d900ffb-911e-4583-abd0-1b1f197633ff	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-13 16:35:06.941973+00	
00000000-0000-0000-0000-000000000000	5c6716d2-e5a2-4085-9a0a-fe5dd4ece137	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-02-13 16:41:12.849426+00	
00000000-0000-0000-0000-000000000000	baaf8b7d-26e1-4544-81b0-eb2de593699c	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-13 16:41:29.674931+00	
00000000-0000-0000-0000-000000000000	1df7232d-60c4-49c0-a1c6-1f61615b8bcc	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 18:24:28.29091+00	
00000000-0000-0000-0000-000000000000	74737bb9-2a14-43e7-8f82-50f60b5e9316	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 18:24:28.368781+00	
00000000-0000-0000-0000-000000000000	653df25d-acdf-4a1d-b870-b616094ce70e	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 21:25:13.360983+00	
00000000-0000-0000-0000-000000000000	9a7a1689-50d6-4ef2-8bb4-d8f1f1cb2e16	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 21:25:13.39409+00	
00000000-0000-0000-0000-000000000000	0190e21c-991b-473d-a447-82b45623a084	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 22:28:50.295419+00	
00000000-0000-0000-0000-000000000000	c6287fc9-da94-4f04-9077-bc90e7e214e4	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 22:28:50.371945+00	
00000000-0000-0000-0000-000000000000	d29ad35f-fd55-4457-88ba-711239719a36	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 23:37:15.582375+00	
00000000-0000-0000-0000-000000000000	c60f3167-3c60-4709-8be4-536c81c9305c	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-13 23:37:15.587497+00	
00000000-0000-0000-0000-000000000000	4297a764-b353-40b2-95ca-10174205cb4e	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-15 01:00:25.260436+00	
00000000-0000-0000-0000-000000000000	ad326191-a45e-41bd-8b17-ce0e64282312	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-02-15 01:00:40.10083+00	
00000000-0000-0000-0000-000000000000	072c12a3-a568-4c20-967b-e52a6a648ad1	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-15 03:34:58.145652+00	
00000000-0000-0000-0000-000000000000	9d8d5546-0eae-476f-b164-d58e27bfe5ec	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-15 12:54:20.731062+00	
00000000-0000-0000-0000-000000000000	b205b5a6-2382-4ff8-ac13-d08c10553f71	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-15 12:54:20.775665+00	
00000000-0000-0000-0000-000000000000	fcddcbaa-110b-4fb3-92e4-2883bd59e461	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-15 16:55:27.830416+00	
00000000-0000-0000-0000-000000000000	f109f6c7-c421-423c-a633-e7dff750b8d7	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-15 16:55:27.834393+00	
00000000-0000-0000-0000-000000000000	5f00a524-057f-485d-8db1-9242d8e66a86	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-15 17:11:23.003444+00	
00000000-0000-0000-0000-000000000000	16834c96-3f3f-4c42-bd44-29bf601c7b04	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-15 17:16:12.081104+00	
00000000-0000-0000-0000-000000000000	179749e5-351f-4c17-aa13-ece4261fe263	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-02-15 17:46:24.448402+00	
00000000-0000-0000-0000-000000000000	af2ac5a7-1f38-4c66-9c87-3d49c8e30339	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-15 21:20:18.961236+00	
00000000-0000-0000-0000-000000000000	80a6d21d-8d8f-48a8-b534-d0e69bfae7b5	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-15 21:20:18.983246+00	
00000000-0000-0000-0000-000000000000	2942260e-a319-4ada-afd7-fad10a8d375b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-15 21:57:03.809687+00	
00000000-0000-0000-0000-000000000000	c2d0ddbe-2613-4ac2-b431-54d0df101bac	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-15 21:57:03.812372+00	
00000000-0000-0000-0000-000000000000	b46a588e-f10b-418e-83f2-f7f4decc0dd2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 01:19:23.204305+00	
00000000-0000-0000-0000-000000000000	28e8200a-6db0-4ab8-8c15-03c3b5f5bca4	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 01:19:23.206422+00	
00000000-0000-0000-0000-000000000000	488f4088-d08d-4c3a-b6f3-4a43c5b4c992	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 12:13:38.870453+00	
00000000-0000-0000-0000-000000000000	cb090465-934e-4f51-9461-075490313f89	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 12:13:38.907186+00	
00000000-0000-0000-0000-000000000000	615def2b-0d21-499f-ab7c-6384acf4c725	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 14:39:23.926158+00	
00000000-0000-0000-0000-000000000000	6cdc8516-0d95-49ba-9939-be7f76aab2e0	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 14:39:23.929105+00	
00000000-0000-0000-0000-000000000000	c3c0cb4c-43b6-4786-8cd4-5b2c627f89ce	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 15:37:38.160256+00	
00000000-0000-0000-0000-000000000000	381e2d5d-5f72-4867-9c29-89353759988d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 15:37:38.162761+00	
00000000-0000-0000-0000-000000000000	c167617f-5b1d-4d51-a272-58d556fb4c0e	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 16:36:46.258475+00	
00000000-0000-0000-0000-000000000000	b9000f2f-8e9b-4597-8a04-11e14f44bdce	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 16:36:46.261351+00	
00000000-0000-0000-0000-000000000000	740bc770-d3ed-4c59-8873-a84c8caaa421	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-02-16 16:37:27.586026+00	
00000000-0000-0000-0000-000000000000	0ef6623e-f1e1-4799-a923-289d68c0b0e8	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-16 16:37:32.698046+00	
00000000-0000-0000-0000-000000000000	8ff0c2a0-90c7-4704-9b3e-db72aec5c5e5	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-02-16 16:38:01.855622+00	
00000000-0000-0000-0000-000000000000	b3452ee2-359f-492a-9828-b076ada6bbba	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-16 16:38:04.659338+00	
00000000-0000-0000-0000-000000000000	146c3565-372a-4f79-94b2-56395d29feb0	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 19:24:41.630875+00	
00000000-0000-0000-0000-000000000000	956f2f3a-df41-414f-9bf2-3b009eb170e9	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 19:24:41.702853+00	
00000000-0000-0000-0000-000000000000	3ca2b809-01be-43aa-8444-63be319e0392	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 20:23:14.217423+00	
00000000-0000-0000-0000-000000000000	0d8ac222-8c48-41cb-b683-62a1dc571eda	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-16 20:23:14.219404+00	
00000000-0000-0000-0000-000000000000	464daeac-06ee-486c-9b09-d5f6b5b03393	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-17 19:52:06.548074+00	
00000000-0000-0000-0000-000000000000	ffc97ca2-a86b-41dd-8cd6-5ba8c52bf5da	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-17 19:52:06.578176+00	
00000000-0000-0000-0000-000000000000	b231752a-6195-4dd2-bfd5-ddda9d3cb726	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-17 21:48:14.360185+00	
00000000-0000-0000-0000-000000000000	02a8aef6-e545-45c4-bdfe-ed75e20c0fff	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-17 21:48:14.392217+00	
00000000-0000-0000-0000-000000000000	15de7046-ff53-43ba-9b95-4ee63061efd8	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-18 15:55:01.374902+00	
00000000-0000-0000-0000-000000000000	ce5161d4-ad0c-4645-9bdb-f0bf7139f369	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-18 15:55:01.40893+00	
00000000-0000-0000-0000-000000000000	70e2c2a6-a82e-47bb-b02a-35da3f6db4dd	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-18 16:22:54.957799+00	
00000000-0000-0000-0000-000000000000	01ba49a1-95a5-4fac-8899-7a1571671719	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-18 16:22:54.959872+00	
00000000-0000-0000-0000-000000000000	107a8fc8-67c6-48c5-92b8-6c61781a9f94	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-19 13:39:48.047544+00	
00000000-0000-0000-0000-000000000000	028968ae-819c-4766-9030-f41a2e21d888	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-19 13:39:48.079872+00	
00000000-0000-0000-0000-000000000000	c9be45cb-9ef4-4766-a777-234d774df98f	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-19 17:18:43.363065+00	
00000000-0000-0000-0000-000000000000	b3e20f0a-9158-4e3c-8bb4-5f00c47d468d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-19 17:18:43.365595+00	
00000000-0000-0000-0000-000000000000	1283eb89-e557-4b2d-8e87-7af670ece12a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-19 19:56:51.006547+00	
00000000-0000-0000-0000-000000000000	25516428-f803-40a8-b3fd-35128106e59e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-19 19:56:51.009485+00	
00000000-0000-0000-0000-000000000000	65b26559-c97f-4d16-a542-a15c0dbe7cc3	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-19 22:44:55.552254+00	
00000000-0000-0000-0000-000000000000	81a38e77-db7d-4fd0-b6ff-0e3ee9ed4129	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-20 11:23:37.798705+00	
00000000-0000-0000-0000-000000000000	ed45d902-5fc3-4e2b-942f-3b578e868830	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-20 11:23:37.836554+00	
00000000-0000-0000-0000-000000000000	18b5e7cc-87e8-48c6-b1b7-85ef66c38cbf	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-20 11:24:03.973077+00	
00000000-0000-0000-0000-000000000000	1fb47f7b-32b9-4d53-b2fd-2499e7f66ca3	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-20 11:24:04.976424+00	
00000000-0000-0000-0000-000000000000	afe03912-d4a1-4c33-b3ab-4ff4aacd0e41	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-20 12:55:42.316199+00	
00000000-0000-0000-0000-000000000000	f854be07-6227-4d95-be9e-09ccd1612e82	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-20 12:55:42.348353+00	
00000000-0000-0000-0000-000000000000	5c759f63-c28f-471f-b2f7-f93f67ee6cd5	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-20 21:26:05.244359+00	
00000000-0000-0000-0000-000000000000	5d962a00-80a9-4527-b318-7ff842a7ffba	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-20 21:26:05.246644+00	
00000000-0000-0000-0000-000000000000	5a0a9478-907e-4ac4-a61b-8ff7cff38f1b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-21 16:15:08.876342+00	
00000000-0000-0000-0000-000000000000	2d78eff5-597e-406c-aa6e-241364d54efd	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-21 16:15:08.913552+00	
00000000-0000-0000-0000-000000000000	8c986cd4-4503-4b37-92ca-bfb635e5f6f9	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-21 20:46:41.654986+00	
00000000-0000-0000-0000-000000000000	1961123f-c829-4ff0-ae22-9fb8ee9cf53a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-21 20:46:41.659932+00	
00000000-0000-0000-0000-000000000000	fe383373-be9f-408d-8605-76e272d94a6c	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-22 17:27:56.75372+00	
00000000-0000-0000-0000-000000000000	1cba13b4-c211-4c12-a3de-59c9928da94d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-22 17:27:56.787466+00	
00000000-0000-0000-0000-000000000000	1124ecc3-37c5-459a-af0a-0a94eba6ea99	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-23 00:56:40.397387+00	
00000000-0000-0000-0000-000000000000	1efa2945-3087-4fa3-b46c-0013c3579a6a	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-02-23 01:08:59.699489+00	
00000000-0000-0000-0000-000000000000	baf846c6-690e-4a40-9e2b-bc94394074c8	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-23 21:54:05.771544+00	
00000000-0000-0000-0000-000000000000	c3a2d3a3-8784-4f97-be56-3fabe4f24250	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-23 21:54:05.809644+00	
00000000-0000-0000-0000-000000000000	ab062cbb-b311-4026-b9b0-ccd8cff3418d	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-23 22:53:17.776879+00	
00000000-0000-0000-0000-000000000000	5ead3a6e-70f1-4484-a30f-02ccec855548	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-23 22:53:17.779168+00	
00000000-0000-0000-0000-000000000000	cf032304-f979-4909-9d1a-555fa8ac9cd5	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-23 23:51:26.811721+00	
00000000-0000-0000-0000-000000000000	b5986a09-58e8-4857-9a6c-2e3f121bce00	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-23 23:51:26.814269+00	
00000000-0000-0000-0000-000000000000	76353337-cea2-4306-baf7-4a71b4279e64	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 02:05:02.062142+00	
00000000-0000-0000-0000-000000000000	42e74c11-0638-45f9-bda3-c7d30e77bf00	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 02:05:02.075491+00	
00000000-0000-0000-0000-000000000000	a3dae6e1-4463-4e60-a481-6ccfb8ccc038	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 03:03:08.964433+00	
00000000-0000-0000-0000-000000000000	1e6dc87d-e213-4a36-ae76-2cab05354c3a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 03:03:08.968519+00	
00000000-0000-0000-0000-000000000000	3ed06306-1ed9-4d8a-9724-58598c1aa904	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 04:01:15.78257+00	
00000000-0000-0000-0000-000000000000	02fe82fc-8cc2-4ad8-a60c-683db773dc80	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 04:01:15.785776+00	
00000000-0000-0000-0000-000000000000	dbb8c465-fdd6-4050-a823-04b47c9c3812	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 04:59:45.79513+00	
00000000-0000-0000-0000-000000000000	ee3b33ac-eb97-427d-91f2-0fe80d7eaaf7	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 04:59:45.805055+00	
00000000-0000-0000-0000-000000000000	5f591131-05a3-4acd-898b-10766f758a2a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 05:58:15.508748+00	
00000000-0000-0000-0000-000000000000	055224ce-9bf7-42a1-869a-8f079a386cf5	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 05:58:15.51245+00	
00000000-0000-0000-0000-000000000000	be06415c-66bf-4fd6-98f6-d8655265103c	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 06:56:45.316739+00	
00000000-0000-0000-0000-000000000000	37ebe78e-9e9c-4315-b383-508f41f080be	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 06:56:45.319592+00	
00000000-0000-0000-0000-000000000000	9c5cbb8d-9475-4f30-9a93-d777f2cdb51c	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 07:55:15.644275+00	
00000000-0000-0000-0000-000000000000	7d99d4d8-e9eb-4793-82c7-5554240f7697	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 07:55:15.672521+00	
00000000-0000-0000-0000-000000000000	3a440df7-853d-4f2c-b757-85b55d00df64	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 08:53:44.929313+00	
00000000-0000-0000-0000-000000000000	85554d7a-f714-4db1-b058-c5a3f1181313	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 08:53:44.93129+00	
00000000-0000-0000-0000-000000000000	46dc2d72-3a67-4cb9-a748-237aa62c411c	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 09:51:44.732445+00	
00000000-0000-0000-0000-000000000000	72386e56-85b4-4e34-8d0e-90d9ed2b162e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 09:51:44.735628+00	
00000000-0000-0000-0000-000000000000	b56ec2c8-5a75-4b12-afc4-2faaa1b8ccfd	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 10:49:44.579299+00	
00000000-0000-0000-0000-000000000000	172dc419-a708-412b-aa69-e6f16a97d88a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 10:49:44.581551+00	
00000000-0000-0000-0000-000000000000	1c94b918-7362-4e61-9242-0fef0f041a9c	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 11:47:44.60679+00	
00000000-0000-0000-0000-000000000000	e51f4890-c307-4060-aa98-0b10550cd95f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 11:47:44.609769+00	
00000000-0000-0000-0000-000000000000	693e8840-699b-4a53-b215-4d90ed7d0f07	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 12:45:44.225254+00	
00000000-0000-0000-0000-000000000000	f615752b-cc2c-4c89-9f98-eb4a1aa9a6cd	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 12:45:44.228121+00	
00000000-0000-0000-0000-000000000000	ee7ec38b-d6e6-4b0a-b4a7-3e431c61a7e2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 13:43:55.773067+00	
00000000-0000-0000-0000-000000000000	ce0b46f8-eb97-447b-8d62-6fddb68ac532	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 13:43:55.785345+00	
00000000-0000-0000-0000-000000000000	eb5e0410-f571-4809-80af-2b2302e41162	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 15:38:34.135032+00	
00000000-0000-0000-0000-000000000000	520708da-1da6-487f-8b6c-694bc17502a8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 15:38:34.13893+00	
00000000-0000-0000-0000-000000000000	cff63c48-0e21-433f-8724-c6e1c87180d8	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 16:15:46.955787+00	
00000000-0000-0000-0000-000000000000	01c8a00b-f598-4ed6-af46-83cc050be3ee	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 16:15:46.960371+00	
00000000-0000-0000-0000-000000000000	159b46fa-eab2-485b-b9e1-95372045d39d	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 17:27:17.950004+00	
00000000-0000-0000-0000-000000000000	5fb4b684-2231-44b3-bd0c-8f4f63086c56	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 17:27:17.986919+00	
00000000-0000-0000-0000-000000000000	775c0cf9-c777-4207-af18-cd637d8f7e1d	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 17:37:27.799454+00	
00000000-0000-0000-0000-000000000000	6ab6194a-72db-4736-becf-74cb6d4c04a5	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 17:37:27.802953+00	
00000000-0000-0000-0000-000000000000	20013f7d-97be-4416-bf5b-ab90d0295c56	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 18:40:19.847973+00	
00000000-0000-0000-0000-000000000000	f52cd958-fc74-432e-91b7-a5be27fd2acf	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 18:40:19.850716+00	
00000000-0000-0000-0000-000000000000	10742287-60a7-49d6-bca4-789ec0a5497a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 19:00:07.350617+00	
00000000-0000-0000-0000-000000000000	e8802367-e06c-4e4e-b502-d35e06bb7a64	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 19:00:07.35268+00	
00000000-0000-0000-0000-000000000000	6745d8ce-5f2a-44e5-ab61-9f4bbaf1ac41	{"action":"login","actor_id":"5a58caed-c1fe-4094-875a-4a87f1208244","actor_username":"sales@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-24 19:16:03.404344+00	
00000000-0000-0000-0000-000000000000	545f540f-8c3d-41b2-b4df-0f69eff0ef97	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-02-24 19:25:46.31296+00	
00000000-0000-0000-0000-000000000000	3e5a506d-2d5f-45f8-b94a-ae1ab9c17e01	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 20:24:59.320786+00	
00000000-0000-0000-0000-000000000000	d02c7fe2-3b0e-4057-a3c2-0e999869ec7a	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 20:24:59.322561+00	
00000000-0000-0000-0000-000000000000	b3659d50-9453-41d6-aaf1-0065ba55ad90	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 20:25:34.203747+00	
00000000-0000-0000-0000-000000000000	15f8a2fc-7ee1-472a-96b4-ece4f1f9d251	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 20:25:34.205797+00	
00000000-0000-0000-0000-000000000000	ee43ec42-306c-4505-9867-bdb86c98cb15	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 21:22:58.286932+00	
00000000-0000-0000-0000-000000000000	9aa19d2f-8109-4f53-a9f0-d4065b953e8c	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 21:22:58.289435+00	
00000000-0000-0000-0000-000000000000	dbd82316-3f35-49bd-b512-bf9fb6808dbf	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 22:20:58.198318+00	
00000000-0000-0000-0000-000000000000	9f73863f-cc23-4751-b03e-2a71581d6e94	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 22:20:58.2006+00	
00000000-0000-0000-0000-000000000000	b1eb0828-977e-4014-bbaa-f34218f6d074	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 23:29:29.168547+00	
00000000-0000-0000-0000-000000000000	b118e044-d146-4b74-b351-0561b2956cbf	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-24 23:29:29.170399+00	
00000000-0000-0000-0000-000000000000	6be46694-6378-466c-a135-7c2510861d44	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-25 02:26:02.595117+00	
00000000-0000-0000-0000-000000000000	8e915dfc-d3ac-4006-8373-804fdbe337e9	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-25 02:26:02.598313+00	
00000000-0000-0000-0000-000000000000	a95d5ac9-ffff-4f27-8f6b-a90c2bfdb8ef	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-25 15:52:40.407038+00	
00000000-0000-0000-0000-000000000000	888da9e2-87ce-410f-a206-a0b1bcd0ab57	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-25 15:52:40.437938+00	
00000000-0000-0000-0000-000000000000	63f726f2-b28d-45eb-8687-140c0d5c4fb6	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-25 16:51:06.310764+00	
00000000-0000-0000-0000-000000000000	da6a05b7-1e7c-4a92-9305-f11488c0c4a3	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-25 16:51:06.31369+00	
00000000-0000-0000-0000-000000000000	1d7f32b6-4bd3-427a-b17e-4607b10ad8cf	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 00:22:59.186691+00	
00000000-0000-0000-0000-000000000000	076eb224-b585-4ce7-b2a0-e7a938b4c162	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 00:22:59.216802+00	
00000000-0000-0000-0000-000000000000	f2e07e79-d96d-4189-bbcf-0972583ea188	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 13:45:33.922093+00	
00000000-0000-0000-0000-000000000000	c988db8b-286e-4610-96f3-370d24bed0ee	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 13:45:33.950944+00	
00000000-0000-0000-0000-000000000000	5550e1e7-1871-4951-8abd-ce732a2fe3ee	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 13:52:37.793038+00	
00000000-0000-0000-0000-000000000000	c8fd95fd-2d84-4a7e-b464-623b39a5dbd9	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 13:52:37.795213+00	
00000000-0000-0000-0000-000000000000	a8362374-e4d6-4050-a1a9-435c49028ca5	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 14:59:49.742619+00	
00000000-0000-0000-0000-000000000000	b5285a65-342b-442c-8e47-0bdf774a5b6b	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 14:59:49.747302+00	
00000000-0000-0000-0000-000000000000	ad9dfc1f-4bd2-4f7d-9c44-386ef142a74b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 16:51:56.908854+00	
00000000-0000-0000-0000-000000000000	0cce29c5-4895-4f5c-849e-d2f9992d5d5a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 16:51:56.910977+00	
00000000-0000-0000-0000-000000000000	03716075-e1eb-4c87-a15d-46e923fffce7	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 18:45:02.070669+00	
00000000-0000-0000-0000-000000000000	91ce5303-fc0c-4b03-bb24-ec68c998777e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 18:45:02.072559+00	
00000000-0000-0000-0000-000000000000	45b90d66-03e3-4156-8f2d-d7051733f82b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 21:10:22.752931+00	
00000000-0000-0000-0000-000000000000	abc5721b-e480-4de6-8ead-4d21c0e1601f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 21:10:22.769353+00	
00000000-0000-0000-0000-000000000000	374a185d-8b88-4f25-ab1f-27b05f34458a	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 22:13:25.474265+00	
00000000-0000-0000-0000-000000000000	5b6e02d2-7e44-484d-b29f-768ae7f2cf0f	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 22:13:25.477113+00	
00000000-0000-0000-0000-000000000000	2712f5e0-0fc9-447e-86bd-235206da7a56	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 22:33:54.45046+00	
00000000-0000-0000-0000-000000000000	71ed6ba3-1bab-44d6-aed5-330bcdb9e600	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-26 22:33:54.452514+00	
00000000-0000-0000-0000-000000000000	a51f37eb-7aa1-477a-97a0-375c907e6285	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 19:11:25.018204+00	
00000000-0000-0000-0000-000000000000	3b98f5a1-9fde-42d2-a3e9-9a981a7db8a8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 19:11:25.053377+00	
00000000-0000-0000-0000-000000000000	69e9bad2-4fd4-457c-9858-fa57fcaedca3	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 20:06:18.478339+00	
00000000-0000-0000-0000-000000000000	dbfa1cc6-5ca1-43e7-a482-eaf01db844c1	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 20:06:18.482739+00	
00000000-0000-0000-0000-000000000000	74aa67f7-67d2-45cf-9022-6a56e77bac97	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 20:09:40.587764+00	
00000000-0000-0000-0000-000000000000	b54a0248-746b-4042-9a6e-e3b696b0830f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 20:09:40.589966+00	
00000000-0000-0000-0000-000000000000	a808a39d-b4e9-4532-9d91-c7154ef2e1c0	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 21:07:40.409124+00	
00000000-0000-0000-0000-000000000000	e05659f1-9dc7-4bb8-aa99-58a088b6f523	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 21:07:40.411989+00	
00000000-0000-0000-0000-000000000000	79d262a3-a5d5-4f15-8904-1a1d93c2252b	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 21:20:16.486497+00	
00000000-0000-0000-0000-000000000000	bed2e437-f49f-40ae-a16b-b3b59d862d54	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 21:20:16.489068+00	
00000000-0000-0000-0000-000000000000	295d786c-364b-4b11-91cc-2aaa18f4d372	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 22:05:40.254115+00	
00000000-0000-0000-0000-000000000000	83524328-3056-456a-8733-2befb71226fa	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-27 22:05:40.256034+00	
00000000-0000-0000-0000-000000000000	ab52b6b6-b1eb-429d-bb7d-77010c76ffc4	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-28 00:23:01.811775+00	
00000000-0000-0000-0000-000000000000	cdb185c8-9374-4cf8-ae43-e773eb455ccb	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-28 00:23:01.814382+00	
00000000-0000-0000-0000-000000000000	a83ba2e7-6972-4918-a828-c06517fb015d	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-28 01:21:19.209478+00	
00000000-0000-0000-0000-000000000000	bc27a5fa-847d-434e-b87c-20d85100975a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-02-28 01:21:19.21199+00	
00000000-0000-0000-0000-000000000000	6f9cbce0-156e-4987-b0f4-71c9f34fac0f	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-01 03:17:59.921132+00	
00000000-0000-0000-0000-000000000000	9d975f61-a780-4bd5-bc92-72ee5b6d80c8	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-03-01 03:19:14.564452+00	
00000000-0000-0000-0000-000000000000	b5cf1818-1d7b-4c44-bc2b-ec266f47a29e	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-02 00:39:55.478781+00	
00000000-0000-0000-0000-000000000000	0055e3b4-78ac-478e-ae20-a29076432c86	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-03-02 00:45:27.212252+00	
00000000-0000-0000-0000-000000000000	98a3f5c0-7899-4553-9f15-51b8000a20e1	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 13:00:43.262508+00	
00000000-0000-0000-0000-000000000000	6b213c17-1760-47a6-ab25-3776dcc0d446	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 13:00:43.309863+00	
00000000-0000-0000-0000-000000000000	e45022a5-a77a-490d-8273-736895afd752	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 13:58:59.667452+00	
00000000-0000-0000-0000-000000000000	061f627b-0d5e-4702-a24b-269f61cd056c	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 13:58:59.671474+00	
00000000-0000-0000-0000-000000000000	e8a9d605-1e43-45ad-b2ad-6e8ad1465b3e	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 14:23:35.077057+00	
00000000-0000-0000-0000-000000000000	813c6c89-5773-4c51-9512-7b4e7e317ba6	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 14:23:35.079025+00	
00000000-0000-0000-0000-000000000000	5ab780c3-7c9f-43df-b6d0-072123e5a94a	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 16:32:00.044005+00	
00000000-0000-0000-0000-000000000000	0f58795f-09ad-48d2-916c-4658513ed7e5	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 16:32:00.046265+00	
00000000-0000-0000-0000-000000000000	98ead89a-930d-41f0-87c1-50bfe3460fed	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 18:40:27.369384+00	
00000000-0000-0000-0000-000000000000	dc63abe4-532a-4586-9ef0-64f233d768ff	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 18:40:27.374519+00	
00000000-0000-0000-0000-000000000000	2d5edaac-e89f-4226-bb09-7c7b72e3c6e9	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 22:10:21.259243+00	
00000000-0000-0000-0000-000000000000	b7e05138-cbc9-4b95-952a-18391998c7b0	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-02 22:10:21.262412+00	
00000000-0000-0000-0000-000000000000	6d229f66-86a8-4625-98b3-3350954c0d23	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-03 01:55:59.200156+00	
00000000-0000-0000-0000-000000000000	8f161af3-8a40-4e19-a0eb-89327eb59768	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-03-03 02:31:23.244156+00	
00000000-0000-0000-0000-000000000000	464f9578-e093-492f-bcd6-ad37582b6b01	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 02:50:57.37505+00	
00000000-0000-0000-0000-000000000000	cd499991-1411-461f-8fd0-ac17f2ac723b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 02:50:57.378253+00	
00000000-0000-0000-0000-000000000000	9eccb3f0-1196-45fa-a48d-b0f2ee5ef7c8	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 13:18:03.045506+00	
00000000-0000-0000-0000-000000000000	8d3b1bce-2e5e-4f3b-b0e9-f7b320b65542	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 13:18:03.07785+00	
00000000-0000-0000-0000-000000000000	c86f104d-0f6d-4d63-853c-7a9d14266ab0	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 14:47:05.825465+00	
00000000-0000-0000-0000-000000000000	335e4066-64cc-4d68-bc6d-b632dc4a91df	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 14:47:05.829856+00	
00000000-0000-0000-0000-000000000000	994b7382-a9d5-4cd0-9944-7a9bce23c422	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 15:54:43.94439+00	
00000000-0000-0000-0000-000000000000	3acc329e-4b0a-4105-8809-a01a9b497865	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 15:54:43.946492+00	
00000000-0000-0000-0000-000000000000	59ca4221-ca94-4f83-84b1-ae978653d99d	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 18:36:00.248963+00	
00000000-0000-0000-0000-000000000000	97396bfc-f998-41b8-8337-e3abb796390d	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 18:36:00.25091+00	
00000000-0000-0000-0000-000000000000	946221c4-c9b9-427c-8536-504559ad079a	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"provider":"email","user_email":"jbuente@glassaero.com","user_id":"fa1253e3-c3cb-4337-be53-e71b69f23592","user_phone":""}}	2026-03-03 20:32:09.145339+00	
00000000-0000-0000-0000-000000000000	0090b9e9-10ca-4cdc-9890-58bd67ef41ca	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"provider":"email","user_email":"logistics@glassaero.com","user_id":"358c2f01-5aec-4ee5-aa76-dde5e15e87ef","user_phone":""}}	2026-03-03 20:33:53.798832+00	
00000000-0000-0000-0000-000000000000	98662574-9cd6-444a-9e46-f279f98c51f1	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 20:41:31.617607+00	
00000000-0000-0000-0000-000000000000	f47b50a7-73fd-4f1f-84a2-314ca4e932b6	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 20:41:31.61989+00	
00000000-0000-0000-0000-000000000000	5cea27bc-8c6d-4755-8d2b-5453bb0820c4	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 21:39:31.56567+00	
00000000-0000-0000-0000-000000000000	a3ae7eae-a10e-49f0-b745-478c2b582b83	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-03 21:39:31.56962+00	
00000000-0000-0000-0000-000000000000	3241bbe9-2320-40c2-a7ea-af84029ef98e	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-04 01:11:42.206801+00	
00000000-0000-0000-0000-000000000000	d614c1fc-528a-4a10-926c-d691a3512a7b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 01:16:23.548608+00	
00000000-0000-0000-0000-000000000000	b94f572b-7523-4095-aa9d-985d05cbebfd	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 01:16:23.563434+00	
00000000-0000-0000-0000-000000000000	0b577b54-cd64-4c8a-93b0-1afd3df7af11	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-03-04 01:28:58.808152+00	
00000000-0000-0000-0000-000000000000	771e652e-2530-4da1-9105-b6974403b95c	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-04 01:48:20.36165+00	
00000000-0000-0000-0000-000000000000	ca0eaed3-448a-40d0-9ae2-ea62c9d336ad	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-03-04 02:12:40.708154+00	
00000000-0000-0000-0000-000000000000	7a729be4-3ac2-4e0f-bce8-8948d3c1e382	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 02:14:37.907252+00	
00000000-0000-0000-0000-000000000000	b2a4fad0-adce-4d74-8c99-90ffa1720d0b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 02:14:37.909878+00	
00000000-0000-0000-0000-000000000000	03177f35-28c1-468f-a8cb-dd52f39c1b84	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 03:12:37.761091+00	
00000000-0000-0000-0000-000000000000	bf923ef2-e5ac-47a5-975f-498c5dbabd82	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 03:12:37.764848+00	
00000000-0000-0000-0000-000000000000	47ba1b14-225c-4d57-ba92-64b94f13d7ee	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 04:10:42.519902+00	
00000000-0000-0000-0000-000000000000	864c5834-94c5-4b22-9257-68f7a49c1fb8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 04:10:42.522309+00	
00000000-0000-0000-0000-000000000000	8aec1585-773f-44d0-a78b-ca97410c79c2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 05:08:42.358096+00	
00000000-0000-0000-0000-000000000000	f7704b15-fcd0-4043-85b7-965a49a71019	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 05:08:42.360013+00	
00000000-0000-0000-0000-000000000000	f2ae6a69-6dcd-467f-a6a7-1536bb76caee	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 06:06:42.210474+00	
00000000-0000-0000-0000-000000000000	c38243dc-c5f8-43a0-bca2-371264f73c83	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 06:06:42.212987+00	
00000000-0000-0000-0000-000000000000	f888647d-d8d1-4a5a-822d-bd7e4fcd1faa	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 07:04:42.135577+00	
00000000-0000-0000-0000-000000000000	68e898a6-15db-49c9-9a2b-e53836a4f2ce	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 07:04:42.137454+00	
00000000-0000-0000-0000-000000000000	1a27385a-a798-46dd-9f2a-57c140c16f68	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 08:02:42.104709+00	
00000000-0000-0000-0000-000000000000	0d43e597-7890-4ade-836f-b94d70c2a77f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 08:02:42.108273+00	
00000000-0000-0000-0000-000000000000	7d5a7b07-9981-46a3-afcf-72c7c9d47137	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 09:00:42.413101+00	
00000000-0000-0000-0000-000000000000	96f2124e-cf72-476a-932f-9d4bc84e6558	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 09:00:42.443047+00	
00000000-0000-0000-0000-000000000000	43a19f85-9343-46c0-91bb-3f05a91c6fad	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 09:58:41.562886+00	
00000000-0000-0000-0000-000000000000	67c74bd1-dcab-4185-850e-2871b067e698	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 09:58:41.566489+00	
00000000-0000-0000-0000-000000000000	7330c89c-9b9f-4b7d-a226-20a1b396d734	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 10:56:41.536861+00	
00000000-0000-0000-0000-000000000000	3b4b8447-212e-4671-82f6-8682715338a8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 10:56:41.538853+00	
00000000-0000-0000-0000-000000000000	0603e59a-812c-4c1f-8528-3daf843fafb5	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 11:54:41.245888+00	
00000000-0000-0000-0000-000000000000	ef030c02-71a3-4d0b-aab6-477b01b0e43a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 11:54:41.248351+00	
00000000-0000-0000-0000-000000000000	85569f6b-a05c-4bca-a40b-02ec7b8aa83e	{"action":"login","actor_id":"fa1253e3-c3cb-4337-be53-e71b69f23592","actor_username":"jbuente@glassaero.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-04 12:02:46.644444+00	
00000000-0000-0000-0000-000000000000	89b32c2d-75f9-4462-b4c1-52ef6cdc4944	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 12:53:05.087425+00	
00000000-0000-0000-0000-000000000000	7b31cce9-3605-4961-832d-40ab768525a8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 12:53:05.118032+00	
00000000-0000-0000-0000-000000000000	bbc2b386-589d-4566-81d2-e8b642ebbaa4	{"action":"token_refreshed","actor_id":"fa1253e3-c3cb-4337-be53-e71b69f23592","actor_username":"jbuente@glassaero.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 13:00:51.909276+00	
00000000-0000-0000-0000-000000000000	bd6bf063-e445-44ad-b4b9-a7fd7786f93c	{"action":"token_revoked","actor_id":"fa1253e3-c3cb-4337-be53-e71b69f23592","actor_username":"jbuente@glassaero.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 13:00:51.912152+00	
00000000-0000-0000-0000-000000000000	413d33a4-a652-4d27-9c5a-f76cb7772d60	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 13:51:25.596133+00	
00000000-0000-0000-0000-000000000000	1fdb31a0-4c8f-494c-b710-7d3e4cc3f384	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 13:51:25.598821+00	
00000000-0000-0000-0000-000000000000	4b6a839b-f62b-412a-add4-3f4053163ffc	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 14:49:25.413726+00	
00000000-0000-0000-0000-000000000000	34cd8020-f985-406f-98e8-ebec3f5040df	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 14:49:25.415793+00	
00000000-0000-0000-0000-000000000000	da170782-350a-4514-8547-04152d14db0d	{"action":"token_refreshed","actor_id":"fa1253e3-c3cb-4337-be53-e71b69f23592","actor_username":"jbuente@glassaero.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 14:57:43.543034+00	
00000000-0000-0000-0000-000000000000	a419811a-3aaf-4685-9b90-56434f35cd6e	{"action":"token_revoked","actor_id":"fa1253e3-c3cb-4337-be53-e71b69f23592","actor_username":"jbuente@glassaero.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 14:57:43.545099+00	
00000000-0000-0000-0000-000000000000	7de996f3-3a2c-4ed3-bbd4-ddac8e03b206	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 15:47:25.32889+00	
00000000-0000-0000-0000-000000000000	f44f21b7-d499-4f1b-93e1-888f8b20a1cc	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 15:47:25.331233+00	
00000000-0000-0000-0000-000000000000	cf75d899-6598-4426-b6ac-84109444860b	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 16:34:48.226273+00	
00000000-0000-0000-0000-000000000000	46c0856c-9143-494e-a439-4f1dc76aa1c3	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 16:34:48.22936+00	
00000000-0000-0000-0000-000000000000	8bc577bc-7eea-4114-9bb7-6872525caedc	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"provider":"email","user_email":"ssully@avemargroup.com","user_id":"735de1e4-a0af-453f-8812-81789d11140e","user_phone":""}}	2026-03-04 16:38:16.289557+00	
00000000-0000-0000-0000-000000000000	83d1c88b-4833-4655-8d08-0c03146d2ec8	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 16:45:25.614971+00	
00000000-0000-0000-0000-000000000000	32be2c92-3629-468f-8974-dcad38f1fad4	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 16:45:25.618606+00	
00000000-0000-0000-0000-000000000000	1ac6b7e5-b25c-4cd6-9bcc-29a005a07617	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 17:43:47.319204+00	
00000000-0000-0000-0000-000000000000	83d9c59a-6d68-47c1-ba94-0930de58a5d9	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 17:43:47.325802+00	
00000000-0000-0000-0000-000000000000	0615aa04-3996-43bc-a22a-222123fec28a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 18:41:47.112385+00	
00000000-0000-0000-0000-000000000000	0f50b2bb-a3c9-4c53-9c05-6d398c33344b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 18:41:47.115401+00	
00000000-0000-0000-0000-000000000000	98d1dd7c-1558-48be-816c-7534f2774bca	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 18:56:57.445013+00	
00000000-0000-0000-0000-000000000000	b5d56f67-9ffc-41c9-81d3-507612a7f4c9	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 18:56:57.456295+00	
00000000-0000-0000-0000-000000000000	3e55aaba-9318-490a-849d-ff2b72c75528	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 19:39:47.032958+00	
00000000-0000-0000-0000-000000000000	abe1ee91-148d-412a-8a08-24dfaceb45f0	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 19:39:47.035499+00	
00000000-0000-0000-0000-000000000000	8695c01b-41ee-4c5d-813d-557ce9eff0bd	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 20:06:16.867587+00	
00000000-0000-0000-0000-000000000000	24d742c4-da0f-4242-afe8-b90654e52ce4	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 20:06:16.876702+00	
00000000-0000-0000-0000-000000000000	ac5785d8-f42a-4462-9a18-ebb4acb33b5e	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 20:37:47.147916+00	
00000000-0000-0000-0000-000000000000	cba04498-8d71-486e-b52b-8d1f2e9efde7	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 20:37:47.151135+00	
00000000-0000-0000-0000-000000000000	6cb68a95-ec29-4bfa-8ccf-617b85301376	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 21:35:46.667499+00	
00000000-0000-0000-0000-000000000000	fcbd7b3f-036a-4221-8296-79f0ceae0f98	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 21:35:46.669527+00	
00000000-0000-0000-0000-000000000000	8b58ba79-d0c6-452e-a913-3966c102c5f2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 22:33:46.459388+00	
00000000-0000-0000-0000-000000000000	a33eddaf-abd9-4662-8c29-c7ca0dd680ec	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 22:33:46.461576+00	
00000000-0000-0000-0000-000000000000	c743209b-c2ba-402b-bdc6-6efb5e96dfa6	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 23:31:46.360886+00	
00000000-0000-0000-0000-000000000000	98030928-bfde-44b4-b281-c4ada36e0f41	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-04 23:31:46.363014+00	
00000000-0000-0000-0000-000000000000	eb489374-34bd-4d5c-b371-e563dee48cae	{"action":"login","actor_id":"42636eed-d413-4d7f-975d-2db61fd13db9","actor_username":"jdickinson214@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-05 00:04:35.42256+00	
00000000-0000-0000-0000-000000000000	8f55bcea-16dd-43d2-b7fb-1f0cb79ff20e	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 00:51:26.092993+00	
00000000-0000-0000-0000-000000000000	3babd911-d5a7-443a-a656-a195c437cae9	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 00:51:26.097206+00	
00000000-0000-0000-0000-000000000000	f6f762bb-7374-4874-89a8-ef271b4a3e83	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 01:49:29.202935+00	
00000000-0000-0000-0000-000000000000	046d09c9-4dbd-4f50-ba93-7244be87a641	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 01:49:29.22003+00	
00000000-0000-0000-0000-000000000000	3e484d94-ee7b-48c3-92b9-efd7ca3db9ac	{"action":"token_refreshed","actor_id":"42636eed-d413-4d7f-975d-2db61fd13db9","actor_username":"jdickinson214@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 01:53:32.919097+00	
00000000-0000-0000-0000-000000000000	b8edbcaf-d7cd-41b4-8a95-7e38b536599e	{"action":"token_revoked","actor_id":"42636eed-d413-4d7f-975d-2db61fd13db9","actor_username":"jdickinson214@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 01:53:32.922257+00	
00000000-0000-0000-0000-000000000000	f9dd8324-2c17-491c-bd39-8612ee40cf89	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 02:54:05.658253+00	
00000000-0000-0000-0000-000000000000	cdc81a42-3316-429b-99e9-e5dea2cfbfe0	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 02:54:05.662316+00	
00000000-0000-0000-0000-000000000000	141419bf-43f8-45aa-903f-3a7a90dc988d	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 13:27:06.552234+00	
00000000-0000-0000-0000-000000000000	f7001aca-b042-48aa-bd88-87e37a20dae2	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 13:27:06.592088+00	
00000000-0000-0000-0000-000000000000	42e25478-d22d-4a42-bc74-bcaf09b396dc	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 13:49:14.152242+00	
00000000-0000-0000-0000-000000000000	19154a20-8c61-4fd6-b81f-dab3feab17d5	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 13:49:14.170633+00	
00000000-0000-0000-0000-000000000000	45fab8ef-e760-4ffc-9b34-0f047fc41540	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 15:27:46.843187+00	
00000000-0000-0000-0000-000000000000	c5d57a40-27ca-4f65-b8d9-050610172c5e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 15:27:46.855689+00	
00000000-0000-0000-0000-000000000000	1c6c4572-ed1a-420e-8cea-0f6246594b90	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 15:38:12.750559+00	
00000000-0000-0000-0000-000000000000	81f14979-fa16-4e87-b31e-3099a28af6cb	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 15:38:12.766729+00	
00000000-0000-0000-0000-000000000000	546e1b08-816d-47e8-9f9a-5f128e6d77c0	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 16:26:01.644073+00	
00000000-0000-0000-0000-000000000000	1c26906d-c722-4337-a398-7653d9c6de13	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 16:26:01.656293+00	
00000000-0000-0000-0000-000000000000	a6718c1c-2e6c-4d5d-9c39-92c84892e83c	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 16:37:14.481763+00	
00000000-0000-0000-0000-000000000000	cc86ad20-1a57-48ae-96d3-0970c1f00ec3	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 16:37:14.498795+00	
00000000-0000-0000-0000-000000000000	106d89d5-b753-4824-a245-65ae9c33e36e	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 17:24:31.491384+00	
00000000-0000-0000-0000-000000000000	9ab00a03-c94d-4810-90af-8bea346146b8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 17:24:31.510002+00	
00000000-0000-0000-0000-000000000000	590e82cf-c0ec-485b-988a-024658c9e5a3	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 18:23:01.298412+00	
00000000-0000-0000-0000-000000000000	c56b36b4-d216-448e-b711-bb979aae07a9	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 18:23:01.317661+00	
00000000-0000-0000-0000-000000000000	47bd8686-99e6-463e-a577-ee7dea1e642e	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 19:16:33.164537+00	
00000000-0000-0000-0000-000000000000	25967f68-06e6-4b72-9c58-4c18e501d791	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 19:16:33.179052+00	
00000000-0000-0000-0000-000000000000	f719af17-3244-4a17-8915-f79469a5747f	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 19:21:00.975204+00	
00000000-0000-0000-0000-000000000000	86b07d04-a917-40ea-a276-cb25d516f24d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 19:21:00.987345+00	
00000000-0000-0000-0000-000000000000	c11b0c6f-9d8c-40f3-ba53-ecd6ac4b796e	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 20:19:00.927426+00	
00000000-0000-0000-0000-000000000000	4ed38412-c507-4d23-8960-981a394b315f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 20:19:00.946091+00	
00000000-0000-0000-0000-000000000000	0015f1e5-3fa1-44e6-9210-d9b53bcd35f6	{"action":"login","actor_id":"735de1e4-a0af-453f-8812-81789d11140e","actor_username":"ssully@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-05 20:41:26.664759+00	
00000000-0000-0000-0000-000000000000	541c1d8a-d7cc-4494-94aa-bebf2e7a3bec	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 21:17:00.720056+00	
00000000-0000-0000-0000-000000000000	776d52d9-af7a-44d2-93a7-980b4c5b9325	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 21:17:00.728781+00	
00000000-0000-0000-0000-000000000000	b1d02124-7c29-47ed-af1c-8daf79d9d299	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 21:47:46.325113+00	
00000000-0000-0000-0000-000000000000	1f5bbce0-317e-4aab-8fc2-18f8845370c2	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 21:47:46.334407+00	
00000000-0000-0000-0000-000000000000	b33dc9c1-6b20-4d08-be1c-19c99a35fe2f	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 22:15:00.540864+00	
00000000-0000-0000-0000-000000000000	599e2f9a-8b30-42c7-aecc-38c84d3d0e8d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 22:15:00.555699+00	
00000000-0000-0000-0000-000000000000	326871be-e9d9-4dd0-a139-2b9e06b3ef80	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 23:13:00.616289+00	
00000000-0000-0000-0000-000000000000	fa861fa9-ab74-4221-9279-e1807fd4c389	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-05 23:13:00.63333+00	
00000000-0000-0000-0000-000000000000	9fb4096d-80d6-418a-972b-245ef146af20	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 00:11:00.254873+00	
00000000-0000-0000-0000-000000000000	128920e0-408c-4cd1-95f2-cb0b3dc4f3a8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 00:11:00.269505+00	
00000000-0000-0000-0000-000000000000	2af5a6f7-10e3-494f-bb77-80a18b5750af	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 01:09:00.129373+00	
00000000-0000-0000-0000-000000000000	5ef1616b-b891-48e0-9559-08401b791dd2	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 01:09:00.1389+00	
00000000-0000-0000-0000-000000000000	19dd7ad2-040c-43b7-b20e-68e7ea2f8c24	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 02:06:59.918287+00	
00000000-0000-0000-0000-000000000000	ab723b26-4dfe-4a0f-9880-12494648e5a8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 02:06:59.932529+00	
00000000-0000-0000-0000-000000000000	4799269f-d01d-4381-a82e-f7f46a6dbaa3	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 03:04:59.744511+00	
00000000-0000-0000-0000-000000000000	2a954176-f0e3-4473-a461-3e402f0e9b44	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 03:04:59.752637+00	
00000000-0000-0000-0000-000000000000	23796998-d9a1-4c0d-a424-f7d0ac38a02d	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 04:02:59.887643+00	
00000000-0000-0000-0000-000000000000	431298d6-143b-44fa-91a4-341110b745f5	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 04:02:59.899694+00	
00000000-0000-0000-0000-000000000000	f8a3927f-9d07-49e0-890e-464b314666ef	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 05:00:59.545301+00	
00000000-0000-0000-0000-000000000000	b6dcffbb-0a61-448e-8fa8-df0159454e02	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 05:00:59.558712+00	
00000000-0000-0000-0000-000000000000	0b2f7ecf-a9b4-4904-914c-acb7c3b16cfd	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 05:58:59.233862+00	
00000000-0000-0000-0000-000000000000	991f443c-8570-4f89-9ff0-b0167e3d725e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 05:58:59.24071+00	
00000000-0000-0000-0000-000000000000	ed871e6d-bc2d-400b-aa74-f565447e6ee5	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 06:56:59.064232+00	
00000000-0000-0000-0000-000000000000	3397500a-470a-4064-bc90-15bb8f06e9d6	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 06:56:59.072532+00	
00000000-0000-0000-0000-000000000000	a44f0484-0e9e-4d1e-bd1a-174ae54fb873	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 07:54:58.93134+00	
00000000-0000-0000-0000-000000000000	4061eb5d-32f8-4604-9d46-5e9796a710d5	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 07:54:58.942977+00	
00000000-0000-0000-0000-000000000000	3acdf233-805d-4e54-8882-5854ef8414db	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 08:52:58.645806+00	
00000000-0000-0000-0000-000000000000	7078ed8b-8009-4ed7-bb49-cc25f9f13fd3	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 08:52:58.659217+00	
00000000-0000-0000-0000-000000000000	19fec8b0-e591-4cf7-a6be-77d0a0d70ec4	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 09:50:58.537812+00	
00000000-0000-0000-0000-000000000000	82d4b1b5-3dec-49bd-851c-6c3e55ad72b1	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 09:50:58.554587+00	
00000000-0000-0000-0000-000000000000	888f90a7-2009-4711-98c1-2a903e12144d	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 10:48:58.312278+00	
00000000-0000-0000-0000-000000000000	30105fa8-f4db-495a-b704-b4ad35041ca4	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 10:48:58.328369+00	
00000000-0000-0000-0000-000000000000	95e66ea2-70c5-4ac9-8bd6-a5d26e5a3223	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 11:46:58.388834+00	
00000000-0000-0000-0000-000000000000	56d16802-6741-4d0d-970e-d1028a8202f6	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 11:46:58.403311+00	
00000000-0000-0000-0000-000000000000	7d80f73a-3a66-490d-8f12-c2de8ee5fe08	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 12:44:58.123041+00	
00000000-0000-0000-0000-000000000000	9ebea4b8-dd8c-47de-8717-7a2ed8f2f5e6	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 12:44:58.138627+00	
00000000-0000-0000-0000-000000000000	f3db78f9-e418-47a3-91f2-b647e1756eab	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 13:42:57.833615+00	
00000000-0000-0000-0000-000000000000	e75e3805-9e01-4be7-932c-7271deca26b6	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 13:42:57.845271+00	
00000000-0000-0000-0000-000000000000	4337eb79-ee6d-4b78-867c-30697ef2ac6b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 14:40:57.760574+00	
00000000-0000-0000-0000-000000000000	1743f092-a321-4412-8928-782b448be2e6	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 14:40:57.77361+00	
00000000-0000-0000-0000-000000000000	e3fdbac4-ca70-4080-8d56-f69550eff23f	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 15:38:57.74917+00	
00000000-0000-0000-0000-000000000000	9d9a410a-db7f-434d-95b5-6c914510e336	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 15:38:57.761598+00	
00000000-0000-0000-0000-000000000000	b9e8b2e6-0a90-4c97-879e-7fc5ee957b41	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 16:36:57.466075+00	
00000000-0000-0000-0000-000000000000	862721d7-4dfc-459b-af92-ac49185e8b13	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 16:36:57.473998+00	
00000000-0000-0000-0000-000000000000	e7e37c51-692d-464e-ae6d-d7203ecc9dc6	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 17:34:57.361393+00	
00000000-0000-0000-0000-000000000000	50a09ca1-8108-40f8-b1e7-44477835b9f1	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 17:34:57.373149+00	
00000000-0000-0000-0000-000000000000	7b19ba0e-2505-4e62-b7d0-bf6f463467f7	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 18:32:57.107561+00	
00000000-0000-0000-0000-000000000000	06106897-19c0-40fa-9b4a-a6223ca159eb	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 18:32:57.122209+00	
00000000-0000-0000-0000-000000000000	04843a2a-f19d-45c9-b577-d43dc65d582f	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 19:30:57.229607+00	
00000000-0000-0000-0000-000000000000	936bbc89-cce7-4222-9b60-0000f7b19f01	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 19:30:57.241294+00	
00000000-0000-0000-0000-000000000000	41f015d6-3cf1-4068-82a0-0ff91c025ef8	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 20:28:56.649058+00	
00000000-0000-0000-0000-000000000000	8b9cc209-1fa3-4b8b-acc8-e8562ce086de	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 20:28:56.66565+00	
00000000-0000-0000-0000-000000000000	28ce4fe5-47ae-4e8c-8b89-74529722ce20	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 21:26:56.62901+00	
00000000-0000-0000-0000-000000000000	47681bd8-eada-470e-8a49-7a6e8fbe7e81	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 21:26:56.637322+00	
00000000-0000-0000-0000-000000000000	bde4a04f-03ad-4ea8-b4e6-5fd1cf58be0a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 22:24:56.737714+00	
00000000-0000-0000-0000-000000000000	526d304c-2f5d-46c3-89d1-ff9234627f59	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 22:24:56.753849+00	
00000000-0000-0000-0000-000000000000	cb346ea3-c9bd-40ad-a3b6-bbb4d742d5ca	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 23:22:56.316265+00	
00000000-0000-0000-0000-000000000000	ebc65b0e-2599-4e95-8eb4-41a14be8ffc1	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-06 23:22:56.328179+00	
00000000-0000-0000-0000-000000000000	a8148bcc-f992-4f1a-8dc2-8faa81dbe8ff	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 00:20:55.972551+00	
00000000-0000-0000-0000-000000000000	66c5b3d8-b8e2-4783-85ed-7f540f1c389c	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 00:20:55.989439+00	
00000000-0000-0000-0000-000000000000	0c25e88d-2d71-4d98-8162-5453a0032d51	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 01:18:56.096269+00	
00000000-0000-0000-0000-000000000000	043003cb-9434-4b66-9a3d-bed3794eec65	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 01:18:56.109965+00	
00000000-0000-0000-0000-000000000000	276926a0-6c03-4855-9538-aa53a8ba8d94	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 02:16:55.914631+00	
00000000-0000-0000-0000-000000000000	da1fe6a3-4b63-4f3f-823e-492e52c10221	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 02:16:55.930951+00	
00000000-0000-0000-0000-000000000000	4c430a32-73f6-4cc7-88f9-fb5e62d83c07	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 03:14:56.24423+00	
00000000-0000-0000-0000-000000000000	fb7b9032-ab03-4814-8070-b921337952dc	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 03:14:56.268699+00	
00000000-0000-0000-0000-000000000000	83e5cd5e-9819-4866-b038-411370c28f7e	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 04:12:55.712416+00	
00000000-0000-0000-0000-000000000000	412318d7-0824-43f1-99bf-04d8fb5dc594	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 04:12:55.723175+00	
00000000-0000-0000-0000-000000000000	b2582f33-a084-452f-b611-a16da487fb53	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 05:10:55.326749+00	
00000000-0000-0000-0000-000000000000	8c0f4ed4-028e-4b2f-b6c1-74e7e248a825	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 05:10:55.338751+00	
00000000-0000-0000-0000-000000000000	74679b9b-a8e0-4df9-9c0f-72de0f3e2bd3	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 06:08:55.574113+00	
00000000-0000-0000-0000-000000000000	e3ef7989-df80-4fe7-a82a-8605c4ca2cb8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 06:08:55.586245+00	
00000000-0000-0000-0000-000000000000	2f600d8d-ef5f-4eb0-bbab-6990c714d751	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 07:06:54.961475+00	
00000000-0000-0000-0000-000000000000	26017c46-0668-4b1b-b687-d124a02a4c53	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 07:06:54.976873+00	
00000000-0000-0000-0000-000000000000	f1ca747a-721f-420b-a3e3-522dbb11d9a6	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 08:04:54.793936+00	
00000000-0000-0000-0000-000000000000	65456802-9f70-4510-8a48-598b1c0b403a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 08:04:54.80562+00	
00000000-0000-0000-0000-000000000000	ea21cb88-c9b7-4b34-bc72-85568ab248ed	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 09:02:54.452663+00	
00000000-0000-0000-0000-000000000000	4a9f5687-15ab-4f50-9696-54d9c985444d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 09:02:54.467091+00	
00000000-0000-0000-0000-000000000000	352c5b05-207b-4828-9736-74eee3a5dfc9	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 10:00:54.452521+00	
00000000-0000-0000-0000-000000000000	002f20e0-63ed-4339-a61d-09553763b0b1	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 10:00:54.463684+00	
00000000-0000-0000-0000-000000000000	4f31fd7e-f87f-4f53-9f54-0effbbd48066	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 10:58:54.172558+00	
00000000-0000-0000-0000-000000000000	1384b640-8f88-46d4-adc3-629852d3a673	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 10:58:54.179326+00	
00000000-0000-0000-0000-000000000000	0faca341-8db0-4b70-ad8d-1b9ce3bce130	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 11:56:54.104785+00	
00000000-0000-0000-0000-000000000000	9faacd30-1f43-4dc8-9602-0c25585f589f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 11:56:54.116528+00	
00000000-0000-0000-0000-000000000000	92565c4f-954c-4d6d-b893-297b13b95f96	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 12:54:54.472794+00	
00000000-0000-0000-0000-000000000000	9fa58a69-0426-4222-a712-a26a3e261367	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 12:54:54.485365+00	
00000000-0000-0000-0000-000000000000	09c3af38-d216-45f0-b6e8-dd61d5050826	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 13:52:53.788428+00	
00000000-0000-0000-0000-000000000000	92f20eaa-84ad-489d-bac9-eb9048b2a158	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 13:52:53.804418+00	
00000000-0000-0000-0000-000000000000	cc92a4ac-917a-4607-897d-f9ecc5c2c4b2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 14:50:53.532415+00	
00000000-0000-0000-0000-000000000000	221c10d2-1086-44e9-a824-3fae3d3cc554	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 14:50:53.548544+00	
00000000-0000-0000-0000-000000000000	ba5af329-07b7-4f73-b82a-9aedffa42c3b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 15:48:53.704362+00	
00000000-0000-0000-0000-000000000000	ead75658-2ee7-49ce-bdbd-ecb2c0990916	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 15:48:53.714069+00	
00000000-0000-0000-0000-000000000000	7849354b-6939-4585-936f-7449e2055464	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 16:46:53.423178+00	
00000000-0000-0000-0000-000000000000	580d5363-a53b-4e6d-91ef-7507e8b6a8ba	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-07 16:46:53.435373+00	
00000000-0000-0000-0000-000000000000	c9c9c44d-9a0c-4cf4-9327-5592c5b153e7	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-07 17:11:07.086976+00	
00000000-0000-0000-0000-000000000000	8d28f95b-e357-4e2f-8557-d4af371d1dea	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-03-07 17:13:36.214149+00	
00000000-0000-0000-0000-000000000000	3400f9d0-f8ac-49f3-9c9c-cad298f529ef	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-07 17:13:40.283246+00	
00000000-0000-0000-0000-000000000000	3c2269be-edd5-4d1e-bbdf-5553f9f2d45c	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-03-07 17:35:56.654443+00	
00000000-0000-0000-0000-000000000000	e467e272-9c52-47b7-ae80-c5f809b7c9df	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-08 19:35:57.041578+00	
00000000-0000-0000-0000-000000000000	be59eb83-60cd-4b1a-b5d5-15c08ffad9fc	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-08 19:42:35.717065+00	
00000000-0000-0000-0000-000000000000	af620aea-35fc-4905-8d19-fb94bab3ba98	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-08 19:42:35.725899+00	
00000000-0000-0000-0000-000000000000	d2cd5a0a-4718-40cc-9a19-b7a48a20ed5f	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-03-08 19:44:36.552926+00	
00000000-0000-0000-0000-000000000000	4afef418-15b3-41c5-8dcc-9635eaedd101	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 02:20:10.861301+00	
00000000-0000-0000-0000-000000000000	202deeff-fcbf-46e0-97c4-cbcfb0a3b9af	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 02:20:10.8714+00	
00000000-0000-0000-0000-000000000000	a17f2049-b65c-448e-bbd6-42440d16e0a4	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 12:34:28.510653+00	
00000000-0000-0000-0000-000000000000	50b6ae1a-01c1-4eea-a12f-ac527e45733f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 12:34:28.524927+00	
00000000-0000-0000-0000-000000000000	3c4db429-6d53-411c-9a62-d16ca74496fa	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 14:46:42.055322+00	
00000000-0000-0000-0000-000000000000	0efa1a15-75b8-4a56-a65a-1d98d803c86a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 14:46:42.065756+00	
00000000-0000-0000-0000-000000000000	7bc8ca4e-5a25-4012-a433-c29990fc17d4	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 15:20:25.759574+00	
00000000-0000-0000-0000-000000000000	5ae6dd16-2398-48df-9a71-db7a1a0402df	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 15:20:25.77221+00	
00000000-0000-0000-0000-000000000000	7fcc6455-fcc1-4adb-ae28-4b16a49e50fc	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 15:44:24.552066+00	
00000000-0000-0000-0000-000000000000	c841e7d3-3040-4ec0-ba35-14690ab02cb0	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 15:44:24.566515+00	
00000000-0000-0000-0000-000000000000	3c68a2ec-7bcc-4043-a101-b4f89970cdf5	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 17:47:12.234789+00	
00000000-0000-0000-0000-000000000000	8ab9bf72-0c03-4755-9c62-18aaf0894d9f	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 17:47:12.246573+00	
00000000-0000-0000-0000-000000000000	bffeb197-a1ee-4123-8468-d9bcea01a758	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 18:54:54.242206+00	
00000000-0000-0000-0000-000000000000	6cd3caf4-68ec-4bcd-bd11-264f3cd0353d	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 18:54:54.258322+00	
00000000-0000-0000-0000-000000000000	d57c6326-bb3f-45fc-b2a6-ad8e5a2616ec	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 21:25:52.151707+00	
00000000-0000-0000-0000-000000000000	20dfe789-1672-47dd-82e5-da0d55fdac8b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-09 21:25:52.16791+00	
00000000-0000-0000-0000-000000000000	bff26aa0-a7ad-4ef1-9572-a60904e2b0ea	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-09 21:46:07.634336+00	
00000000-0000-0000-0000-000000000000	0da0f15b-c05a-423f-bac2-0ca515d69fd2	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-03-09 22:08:23.209383+00	
00000000-0000-0000-0000-000000000000	5a4395b8-4846-4bbd-8c32-8a01a16ab4e3	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 14:47:59.073443+00	
00000000-0000-0000-0000-000000000000	a9c95c35-1017-49a3-b07c-a50c21bcb178	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 14:47:59.087263+00	
00000000-0000-0000-0000-000000000000	7b346935-e730-4e3a-8431-3affad76689b	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 15:45:50.58997+00	
00000000-0000-0000-0000-000000000000	b31959c8-15fc-479f-9225-1ccca7ab98b6	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 15:45:50.601597+00	
00000000-0000-0000-0000-000000000000	8654f201-c978-4a8d-b83c-54f0765a00fc	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 16:43:50.642418+00	
00000000-0000-0000-0000-000000000000	35d853f3-dd8a-4e96-8b7a-39e3cbc3300d	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 16:43:50.651795+00	
00000000-0000-0000-0000-000000000000	f4c530f2-5cbd-41e3-9631-ee42bab6f1e0	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 17:41:50.539764+00	
00000000-0000-0000-0000-000000000000	6769e902-298f-4cfa-89ff-ce7029938300	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 17:41:50.554575+00	
00000000-0000-0000-0000-000000000000	788c1306-2de3-483f-a58d-b86f1a2ff7f0	{"action":"token_refreshed","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 18:51:56.651259+00	
00000000-0000-0000-0000-000000000000	d6a112fe-1d51-4ba4-99a2-1ba9de09acf3	{"action":"token_revoked","actor_id":"d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a","actor_username":"robert@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-10 18:51:56.656755+00	
00000000-0000-0000-0000-000000000000	0c649a9a-cd44-40eb-9e90-fb3aa972f84d	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-11 11:32:07.874497+00	
00000000-0000-0000-0000-000000000000	41195243-7f15-48c3-ab63-c9a5e144cf5b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-11 11:32:07.919371+00	
00000000-0000-0000-0000-000000000000	c5bbf7f8-1c43-4683-b6eb-eebb6393ea3c	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-11 12:30:05.925925+00	
00000000-0000-0000-0000-000000000000	92ea2900-6029-43b8-9fdb-6d2cbbc5627c	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-11 12:30:05.940573+00	
00000000-0000-0000-0000-000000000000	e7fc8cf7-d1ab-4544-942e-7a3147c63cca	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"provider":"email","user_email":"johndoe@gmail.com","user_id":"63b376fe-8e34-4084-abbd-4eaf5faa683f","user_phone":""}}	2026-03-11 12:47:43.580514+00	
00000000-0000-0000-0000-000000000000	c9697e2d-e8ca-4033-a89e-05fc1c06c155	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"johndoe@gmail.com","user_id":"63b376fe-8e34-4084-abbd-4eaf5faa683f","user_phone":""}}	2026-03-11 12:48:23.847481+00	
00000000-0000-0000-0000-000000000000	6866864a-9d93-4a8f-8139-9fa0067d06b5	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-03-11 12:52:45.354881+00	
00000000-0000-0000-0000-000000000000	7ce653c3-f8ef-490e-b3d3-9b8d3975de07	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-11 12:52:51.058776+00	
00000000-0000-0000-0000-000000000000	69559449-2d83-4238-8460-29f327d19d26	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-03-11 12:53:35.482876+00	
00000000-0000-0000-0000-000000000000	55e2ce94-2795-4e69-a914-a8310c590756	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-11 12:54:44.160186+00	
00000000-0000-0000-0000-000000000000	8a02f0e1-2461-48f1-af36-364e36de010f	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-03-11 13:04:25.63589+00	
00000000-0000-0000-0000-000000000000	3e3ee5c6-3226-43f2-9ef2-6fd5411f6b2b	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-11 13:04:29.590212+00	
00000000-0000-0000-0000-000000000000	f68be2c0-5006-4c58-acbf-40aef297d4a6	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-03-11 13:04:41.068112+00	
00000000-0000-0000-0000-000000000000	f7f4be0f-eee3-43db-b067-f6dd89fed148	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-11 13:04:47.062354+00	
00000000-0000-0000-0000-000000000000	148c85a8-a016-4c64-9da3-f2f0cec7c6e5	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-03-11 13:04:54.295824+00	
00000000-0000-0000-0000-000000000000	e5f43f8a-91da-4d5c-a6c8-41657dd145ff	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-11 13:04:56.377859+00	
00000000-0000-0000-0000-000000000000	59908a0a-1c65-493d-8c33-38277a085894	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"provider":"email","user_email":"testuser@example.com","user_id":"52feed68-1c5f-4f2f-b0ec-a3c074441ec1","user_phone":""}}	2026-03-11 13:06:46.05639+00	
00000000-0000-0000-0000-000000000000	f7460f86-758b-45cf-b562-54911b202e00	{"action":"logout","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account"}	2026-03-11 13:07:08.978732+00	
00000000-0000-0000-0000-000000000000	971efc14-ffdf-4a3a-a5e6-7b543b2bbc65	{"action":"login","actor_id":"52feed68-1c5f-4f2f-b0ec-a3c074441ec1","actor_username":"testuser@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-11 13:07:34.149023+00	
00000000-0000-0000-0000-000000000000	a6d7c7b5-1bca-466f-a851-fc2b9ece052b	{"action":"token_refreshed","actor_id":"52feed68-1c5f-4f2f-b0ec-a3c074441ec1","actor_username":"testuser@example.com","actor_via_sso":false,"log_type":"token"}	2026-03-12 02:15:29.661293+00	
00000000-0000-0000-0000-000000000000	67bd7dc4-9003-4b5c-95d4-37312f57d53e	{"action":"token_revoked","actor_id":"52feed68-1c5f-4f2f-b0ec-a3c074441ec1","actor_username":"testuser@example.com","actor_via_sso":false,"log_type":"token"}	2026-03-12 02:15:29.718991+00	
00000000-0000-0000-0000-000000000000	9843d782-0740-4f70-a8aa-d896129af893	{"action":"token_refreshed","actor_id":"52feed68-1c5f-4f2f-b0ec-a3c074441ec1","actor_username":"testuser@example.com","actor_via_sso":false,"log_type":"token"}	2026-03-12 12:28:58.0031+00	
00000000-0000-0000-0000-000000000000	cf2a3306-f16f-4565-8628-994457b1de6a	{"action":"token_revoked","actor_id":"52feed68-1c5f-4f2f-b0ec-a3c074441ec1","actor_username":"testuser@example.com","actor_via_sso":false,"log_type":"token"}	2026-03-12 12:28:58.014095+00	
00000000-0000-0000-0000-000000000000	fc5ccb88-397d-41ea-bbfd-6882c16e1549	{"action":"token_refreshed","actor_id":"52feed68-1c5f-4f2f-b0ec-a3c074441ec1","actor_username":"testuser@example.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 00:37:16.509311+00	
00000000-0000-0000-0000-000000000000	4b9d7deb-6343-4708-9ab0-bd813f17c126	{"action":"token_revoked","actor_id":"52feed68-1c5f-4f2f-b0ec-a3c074441ec1","actor_username":"testuser@example.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 00:37:16.525225+00	
00000000-0000-0000-0000-000000000000	ea8de9b7-1bc0-49fd-b18a-f7fa2f38cfe9	{"action":"logout","actor_id":"52feed68-1c5f-4f2f-b0ec-a3c074441ec1","actor_username":"testuser@example.com","actor_via_sso":false,"log_type":"account"}	2026-03-13 01:33:23.851484+00	
00000000-0000-0000-0000-000000000000	810a52b3-34b7-450b-ae82-613f5aedc6fa	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-13 01:33:27.274824+00	
00000000-0000-0000-0000-000000000000	a9d9af00-a8a8-425a-a20c-2e2af24fd283	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 02:31:00.886915+00	
00000000-0000-0000-0000-000000000000	10330730-0a75-4d00-83d7-668c05346221	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 02:31:00.901097+00	
00000000-0000-0000-0000-000000000000	d6aa6716-a0d7-4b95-8d1f-d03a83711b54	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 03:28:45.933489+00	
00000000-0000-0000-0000-000000000000	4c8c5870-2aef-4b79-85f1-e28da378e4d8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 03:28:45.947603+00	
00000000-0000-0000-0000-000000000000	7cf390c0-cdf8-4569-9225-45ec5c72685a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 04:26:15.295716+00	
00000000-0000-0000-0000-000000000000	8384c2a2-6964-404e-a2fc-33c747f54b82	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 04:26:15.307385+00	
00000000-0000-0000-0000-000000000000	51360147-24e8-49c5-a620-6eb16df29e2c	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 05:23:45.301932+00	
00000000-0000-0000-0000-000000000000	a37a7236-d0a0-4412-89fa-ee45687132b0	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 05:23:45.313793+00	
00000000-0000-0000-0000-000000000000	7745fec7-4cc8-4f5a-b61c-d6a51aa1b993	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 06:21:15.282014+00	
00000000-0000-0000-0000-000000000000	3c907b91-c30c-4a8d-b26f-b9e2eddd0721	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 06:21:15.330846+00	
00000000-0000-0000-0000-000000000000	16a8c976-6fa0-4c78-b790-d153ab2f9794	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 07:18:45.035493+00	
00000000-0000-0000-0000-000000000000	ce9efe93-2441-4486-bb8e-2c00dc7a0fa8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 07:18:45.048878+00	
00000000-0000-0000-0000-000000000000	338e38c8-819b-493a-868f-9b7a5f2ab41e	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 08:16:14.614954+00	
00000000-0000-0000-0000-000000000000	aa6a516b-4373-41f3-9b67-fb4dfcf6a74b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 08:16:14.6252+00	
00000000-0000-0000-0000-000000000000	337fa96f-4c43-4afc-b5bf-0ba6beb6bb63	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 09:13:44.552526+00	
00000000-0000-0000-0000-000000000000	ad903939-8ea5-49f6-b50e-9638cc844e2f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 09:13:44.565679+00	
00000000-0000-0000-0000-000000000000	741a0f0d-c8af-4bd6-8efb-4433452fead3	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 10:11:14.397892+00	
00000000-0000-0000-0000-000000000000	e2c0bb30-73ea-4831-a44b-55291a8720ba	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 10:11:14.412155+00	
00000000-0000-0000-0000-000000000000	f85f4b96-bdbc-4623-83ba-55ae79dd3286	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 11:08:44.278315+00	
00000000-0000-0000-0000-000000000000	8021a0b0-250f-4f11-a9f3-4e1bc780ed6e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 11:08:44.302341+00	
00000000-0000-0000-0000-000000000000	31b78f92-15d8-45f7-b970-e170ac180d97	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 16:47:52.576818+00	
00000000-0000-0000-0000-000000000000	d1779f95-c1e6-4e09-9818-a2d5909086db	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-13 16:47:52.589153+00	
00000000-0000-0000-0000-000000000000	99d00114-dd44-483a-a384-62b69d12da39	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-15 15:50:28.451818+00	
00000000-0000-0000-0000-000000000000	3c974530-996e-4d54-99d1-f57c2baeb41b	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-03-15 15:51:48.489091+00	
00000000-0000-0000-0000-000000000000	64bc700e-2f96-467b-b6ae-9d290948af06	{"action":"login","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-15 15:52:09.224455+00	
00000000-0000-0000-0000-000000000000	52133d4a-26b5-45b0-ac9d-80beb8bf966a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-15 15:53:46.431592+00	
00000000-0000-0000-0000-000000000000	59999bfa-0db9-4707-8644-a731b5114bce	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-15 15:53:46.443354+00	
00000000-0000-0000-0000-000000000000	3367bf95-ede4-4701-9620-c60e6b13660b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-15 20:43:33.302923+00	
00000000-0000-0000-0000-000000000000	9416f701-d30d-42f0-a045-efa5a1019ca2	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-15 20:43:33.313685+00	
00000000-0000-0000-0000-000000000000	da227f61-b22c-4a37-9fd1-a9f7f2bfeabb	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-16 22:27:22.871696+00	
00000000-0000-0000-0000-000000000000	dca87ffe-0988-4260-ae20-e364b5459c1f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-16 22:27:22.921648+00	
00000000-0000-0000-0000-000000000000	db2e19b7-89c4-4697-8a97-fc2f15e57cf8	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-16 23:25:29.25765+00	
00000000-0000-0000-0000-000000000000	b2494e03-cdf8-4401-ab6d-cabf9a5e2c4e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-16 23:25:29.274533+00	
00000000-0000-0000-0000-000000000000	c547dce5-aafe-4328-9332-9d64a2873597	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-17 12:01:28.61857+00	
00000000-0000-0000-0000-000000000000	80cff2f9-b5ea-40c4-86f5-0172f06781d8	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-17 12:01:28.635006+00	
00000000-0000-0000-0000-000000000000	4eb61c2a-4cb0-4f81-a631-9f5da65c9098	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-17 21:37:37.372411+00	
00000000-0000-0000-0000-000000000000	24557438-91e9-45c7-b58e-4db0805d3f47	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-17 21:37:37.384361+00	
00000000-0000-0000-0000-000000000000	dcd42f7a-32db-4bcd-885b-280c4f8db799	{"action":"login","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-03-17 21:41:40.363267+00	
00000000-0000-0000-0000-000000000000	31dc928e-7868-4487-8734-f8e06fd4cc7f	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 12:39:37.098009+00	
00000000-0000-0000-0000-000000000000	a56f644d-d99f-4766-9cac-ed5c2492d4bc	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 12:39:37.135086+00	
00000000-0000-0000-0000-000000000000	5341b859-f897-45eb-9028-bffeabe486ec	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 20:24:12.849949+00	
00000000-0000-0000-0000-000000000000	c1ba39a9-0e2a-4bc8-b250-22d6dabab18b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 20:24:12.901468+00	
00000000-0000-0000-0000-000000000000	585ccc2d-99b5-422d-8b9c-8e88001d8533	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 20:25:35.440312+00	
00000000-0000-0000-0000-000000000000	904ee438-36ff-4cf3-b8ef-cb2cf39a079b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 20:25:35.45387+00	
00000000-0000-0000-0000-000000000000	47499d1e-6235-490e-ba2b-cb212618a466	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 21:22:32.927455+00	
00000000-0000-0000-0000-000000000000	0fc47726-bce9-4860-8eb5-8de4c8c47205	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 21:22:32.934885+00	
00000000-0000-0000-0000-000000000000	28a20c66-5f86-4661-8159-9a77143289d7	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 21:23:39.591808+00	
00000000-0000-0000-0000-000000000000	38da0a73-e025-47d2-89e5-35a50f66e2ef	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 21:23:39.603387+00	
00000000-0000-0000-0000-000000000000	39c6c3fa-dd1e-4384-b3af-c73db7035cdc	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 22:20:37.134858+00	
00000000-0000-0000-0000-000000000000	37fe67c8-6604-4f49-b243-d4160cb76701	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-18 22:20:37.146661+00	
00000000-0000-0000-0000-000000000000	1e9a01cd-30fd-4df2-aeef-55dfd09605a2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-19 13:05:53.517469+00	
00000000-0000-0000-0000-000000000000	44ba7927-177a-4e8b-a57e-312a8b89a156	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-19 13:05:53.547304+00	
00000000-0000-0000-0000-000000000000	e15901c0-9b68-4c3f-be68-d579d0405076	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-19 14:17:43.075483+00	
00000000-0000-0000-0000-000000000000	6d2a09c2-2078-4158-a936-d3e0cd8e7998	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-19 14:17:43.091668+00	
00000000-0000-0000-0000-000000000000	00399199-dc2a-42d2-bb27-8f662ebcce90	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-21 01:32:56.674703+00	
00000000-0000-0000-0000-000000000000	bda53fa7-8025-4408-ba3c-7f6cd7757787	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-21 01:32:56.723871+00	
00000000-0000-0000-0000-000000000000	fb227fd5-1088-4ec2-9031-168e6660b803	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-21 03:00:20.687343+00	
00000000-0000-0000-0000-000000000000	ff2f78ac-af2a-473b-95dd-18f11f7a546b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-21 03:00:20.700628+00	
00000000-0000-0000-0000-000000000000	709bcfa2-7145-42ac-9070-82eb1be0bab2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-21 15:43:44.727674+00	
00000000-0000-0000-0000-000000000000	51083841-ae21-4aee-a14c-72baa5bbff2a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-21 15:43:44.758796+00	
00000000-0000-0000-0000-000000000000	e415e7d4-ee1d-4c42-9a70-4afe298567fb	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-22 14:14:05.034968+00	
00000000-0000-0000-0000-000000000000	760c507d-fba4-4547-bbfa-9f1f2a487eca	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-22 14:14:05.077421+00	
00000000-0000-0000-0000-000000000000	331aeefa-2bca-4776-a4c3-99bc159a6986	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-23 18:46:18.110451+00	
00000000-0000-0000-0000-000000000000	55deae5e-7c0b-4ded-a047-2b9c2d3b719b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-23 18:46:18.147717+00	
00000000-0000-0000-0000-000000000000	bf623bab-9fcc-4af5-8038-3c73de72ddc3	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-23 19:46:37.75696+00	
00000000-0000-0000-0000-000000000000	4b3eef63-d0ea-4a1c-bcea-888ee52c0651	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-23 19:46:37.823091+00	
00000000-0000-0000-0000-000000000000	5512983e-c081-4264-9ff4-c6ec16671b56	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-23 21:46:31.629871+00	
00000000-0000-0000-0000-000000000000	5f609ca6-9a7c-4583-8bbd-beebcdea7497	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-23 21:46:31.651139+00	
00000000-0000-0000-0000-000000000000	b4c712a9-7217-4f91-8941-b76fc3d3b194	{"action":"token_refreshed","actor_id":"5a58caed-c1fe-4094-875a-4a87f1208244","actor_username":"sales@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-24 18:56:49.349217+00	
00000000-0000-0000-0000-000000000000	8c5b8788-2492-4e95-a88e-a17bfb317d70	{"action":"token_revoked","actor_id":"5a58caed-c1fe-4094-875a-4a87f1208244","actor_username":"sales@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-24 18:56:49.404802+00	
00000000-0000-0000-0000-000000000000	b63ec2ef-d409-4046-bc2b-86e10b103379	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-24 21:28:50.216889+00	
00000000-0000-0000-0000-000000000000	00a0da32-9e71-4187-890b-bc64cfb6d78d	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-24 21:28:50.266929+00	
00000000-0000-0000-0000-000000000000	0fe06ec7-446c-44f6-a01c-d7f019356bc9	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 00:20:39.036394+00	
00000000-0000-0000-0000-000000000000	8e02da5c-17fb-4741-868d-0018e45a532a	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 00:20:39.048783+00	
00000000-0000-0000-0000-000000000000	679a665f-5fe7-4b04-bf3a-6506ec5c40e5	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 01:19:18.028905+00	
00000000-0000-0000-0000-000000000000	2177ae41-5689-4014-920d-54d89799f06b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 01:19:18.036878+00	
00000000-0000-0000-0000-000000000000	65a45377-abd3-4711-9306-28428f21d161	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 02:17:48.005824+00	
00000000-0000-0000-0000-000000000000	e804d9f2-c60d-4333-bf78-ca376adf4658	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 02:17:48.017+00	
00000000-0000-0000-0000-000000000000	a5c03508-c24e-4397-ac7b-0b56d5effea6	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 03:16:17.738286+00	
00000000-0000-0000-0000-000000000000	f8fe4e4e-1287-43f6-928e-fac913c3711c	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 03:16:17.749431+00	
00000000-0000-0000-0000-000000000000	6d996421-6b92-4965-a8bf-4740021cac72	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 04:14:47.415387+00	
00000000-0000-0000-0000-000000000000	3381b645-88ba-4473-8e9a-ed3b61201df9	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 04:14:47.423521+00	
00000000-0000-0000-0000-000000000000	03d0c1dd-1859-4c06-83c7-8a179becee2a	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 05:13:17.371978+00	
00000000-0000-0000-0000-000000000000	7ea1fa98-03cc-422f-9ddf-c7fc385cbadb	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 05:13:17.382262+00	
00000000-0000-0000-0000-000000000000	7b6cce12-7712-4e20-a1c1-71c433359382	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 06:11:47.195465+00	
00000000-0000-0000-0000-000000000000	0347c65c-ec9c-4e3f-8c52-42311fd9a729	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 06:11:47.207073+00	
00000000-0000-0000-0000-000000000000	0f95a23d-cbbb-4aec-925b-1e948507e661	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 07:10:17.203672+00	
00000000-0000-0000-0000-000000000000	124a3168-b105-4aa2-aa8c-32d468d33367	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 07:10:17.21825+00	
00000000-0000-0000-0000-000000000000	1af2e014-1397-435e-a386-f31a0311b10c	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 08:08:47.576016+00	
00000000-0000-0000-0000-000000000000	5a54b539-67a7-43b8-b59c-fb2a5f0308ab	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 08:08:47.627573+00	
00000000-0000-0000-0000-000000000000	9f71d2cb-eca7-4f12-a5c9-50ed1f513653	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 09:07:16.784133+00	
00000000-0000-0000-0000-000000000000	99db3c4d-c83a-4c01-9d44-afc1275ef98f	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 09:07:16.795455+00	
00000000-0000-0000-0000-000000000000	ec2b14b4-d603-4806-a657-f15e75700672	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 10:05:46.592463+00	
00000000-0000-0000-0000-000000000000	980ba340-1488-4ed9-b247-808e67d62df1	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 10:05:46.60649+00	
00000000-0000-0000-0000-000000000000	ce03ccf9-380b-47ca-8905-3d93726c9613	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 11:04:16.362673+00	
00000000-0000-0000-0000-000000000000	044ce3ae-5dd9-4c7e-b6bf-55151f7925ea	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 11:04:16.375032+00	
00000000-0000-0000-0000-000000000000	a857c845-3497-469b-9dc2-34bbd4c8d2f4	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 12:09:06.228394+00	
00000000-0000-0000-0000-000000000000	c2449b9b-c463-4f78-b173-915f83a501f7	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 12:09:06.246433+00	
00000000-0000-0000-0000-000000000000	70fe62fc-3229-4426-8e75-ad0d47dea110	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 14:46:44.090571+00	
00000000-0000-0000-0000-000000000000	45de7356-f707-4835-9e41-a4b65489bbe7	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-25 14:46:44.109314+00	
00000000-0000-0000-0000-000000000000	e5d10ec1-364f-4729-8063-59423acd8525	{"action":"token_refreshed","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-26 20:50:56.234387+00	
00000000-0000-0000-0000-000000000000	ed3b6d1c-b83a-4127-8d13-9a5ef47e0e1c	{"action":"token_revoked","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-03-26 20:50:56.294601+00	
00000000-0000-0000-0000-000000000000	12c623cf-31f6-4509-87fc-7b6a8ffa3106	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-29 22:30:50.579509+00	
00000000-0000-0000-0000-000000000000	4ce3d4cf-497a-4812-879e-fdd6118de0a6	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-29 22:30:50.649655+00	
00000000-0000-0000-0000-000000000000	20f1d30c-bd97-4e21-9baa-42d554df1fc9	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-29 23:29:07.233+00	
00000000-0000-0000-0000-000000000000	89e031e2-28ec-486c-8e7c-8ed56ba2eaad	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-29 23:29:07.245834+00	
00000000-0000-0000-0000-000000000000	762b9327-cfed-4d7f-94fa-2e8144d19463	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-30 00:29:37.812184+00	
00000000-0000-0000-0000-000000000000	6d1871dc-4918-4af5-8400-ad2d980bd134	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-30 00:29:37.877133+00	
00000000-0000-0000-0000-000000000000	0464ee21-0d49-4617-ac30-7b454888efbc	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-30 18:21:05.247533+00	
00000000-0000-0000-0000-000000000000	6f57dfac-54d4-498d-b678-d7022ce4bea2	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-30 18:21:05.330072+00	
00000000-0000-0000-0000-000000000000	64b64d44-80d5-495c-9831-151fc4d5800e	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-30 19:41:24.782587+00	
00000000-0000-0000-0000-000000000000	031b1762-0058-4071-8ceb-e01277701550	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-30 19:41:24.79612+00	
00000000-0000-0000-0000-000000000000	71b31fc9-2587-40ea-ae7b-39aeb4312765	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-30 21:39:04.618454+00	
00000000-0000-0000-0000-000000000000	5f37cf18-dc46-4fa6-b3c6-47590d8e4531	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-30 21:39:04.634332+00	
00000000-0000-0000-0000-000000000000	1a29abbd-1abb-45c9-9f22-bd690148bff7	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-31 12:31:15.783328+00	
00000000-0000-0000-0000-000000000000	a00d0a4c-f56c-4a03-b8d5-f37b99b61491	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-31 12:31:15.817767+00	
00000000-0000-0000-0000-000000000000	6bf3d6a9-5557-43ba-a36b-cbe5e485d6ca	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-31 19:28:57.08561+00	
00000000-0000-0000-0000-000000000000	2661ab50-3f72-43c9-bf60-111393d0d4bb	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-03-31 19:28:57.143512+00	
00000000-0000-0000-0000-000000000000	fc649165-7b6c-4127-93a6-819d04379385	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-01 01:14:44.438533+00	
00000000-0000-0000-0000-000000000000	28741814-7560-4442-811c-8202966d7877	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-01 01:14:44.483887+00	
00000000-0000-0000-0000-000000000000	fd7335fd-7485-4d2a-88f5-e073d4d08be8	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-01 23:02:22.615257+00	
00000000-0000-0000-0000-000000000000	3d63a941-ba88-4439-b6a6-92b184efecf7	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-01 23:02:22.682399+00	
00000000-0000-0000-0000-000000000000	8e00abc5-6226-49d7-b78a-1ff5c4f14754	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 15:05:41.984995+00	
00000000-0000-0000-0000-000000000000	413c8307-55a3-46ee-93e6-3f9b51435cbb	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 15:05:42.016923+00	
00000000-0000-0000-0000-000000000000	4522f298-d8dc-4fd8-b631-792459d8ee81	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 16:04:57.651752+00	
00000000-0000-0000-0000-000000000000	a3352bc1-29e2-43e8-b53f-9a8ea9215d62	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 16:04:57.661163+00	
00000000-0000-0000-0000-000000000000	71fddac7-de42-434d-9c99-9001d8d9048b	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 17:04:28.016618+00	
00000000-0000-0000-0000-000000000000	e51a35b8-49c2-4ca1-8e34-87156e26b7b1	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 17:04:28.02829+00	
00000000-0000-0000-0000-000000000000	d58fcb5b-56aa-4cf4-975b-02525b1f29fa	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 18:03:57.941932+00	
00000000-0000-0000-0000-000000000000	9d71d93e-fd99-4aa4-a327-2933229e274c	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 18:03:57.999073+00	
00000000-0000-0000-0000-000000000000	4d92187e-4072-499a-a52f-d2c8749033b2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 19:03:27.26386+00	
00000000-0000-0000-0000-000000000000	a03737ad-c13f-4612-a71f-ac72f0b89c6b	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 19:03:27.281125+00	
00000000-0000-0000-0000-000000000000	ac77cfb7-1e5b-40bc-ac93-0e654496f083	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 20:02:57.085946+00	
00000000-0000-0000-0000-000000000000	dfac9518-3d4f-406b-8478-ba2e4534e0a5	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 20:02:57.099415+00	
00000000-0000-0000-0000-000000000000	d1e75dad-d45f-4bcb-939c-36ba32ec3337	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 21:02:26.676597+00	
00000000-0000-0000-0000-000000000000	44d26fbf-f573-412d-8fa8-87a503d6c5fc	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-02 21:02:26.691446+00	
00000000-0000-0000-0000-000000000000	72a12019-31fa-4a8e-b51c-527c6babe051	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 01:52:27.134269+00	
00000000-0000-0000-0000-000000000000	1b5306de-ac7a-4d65-aa08-c80eac534d46	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 01:52:27.202387+00	
00000000-0000-0000-0000-000000000000	01829dca-69d0-44ee-a94f-bf0d0ecb9aba	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 15:21:39.579654+00	
00000000-0000-0000-0000-000000000000	25394ce2-4f2c-41ec-aeb8-30bc59ddbc53	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 15:21:39.593347+00	
00000000-0000-0000-0000-000000000000	791a0aa6-9cb6-4194-9095-afcd0a1c52f3	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 17:53:17.005118+00	
00000000-0000-0000-0000-000000000000	62b340b8-7c2c-4d33-8016-ec5cf9e1c8c6	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 17:53:17.040139+00	
00000000-0000-0000-0000-000000000000	7bd29800-eabb-452b-bdcd-d3aedc0da9df	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 21:00:08.371325+00	
00000000-0000-0000-0000-000000000000	7abe4d2a-75e4-49dd-81e5-4b4aefa2a95e	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 21:00:08.383608+00	
00000000-0000-0000-0000-000000000000	bbdf7166-f6ce-4440-b1e2-abe7c82da774	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 21:59:27.757662+00	
00000000-0000-0000-0000-000000000000	2c26392a-7c45-481b-aaeb-61161bf9db80	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 21:59:27.760146+00	
00000000-0000-0000-0000-000000000000	2b2566c6-b7a2-4769-bba6-23045a4627c8	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 22:58:47.236944+00	
00000000-0000-0000-0000-000000000000	02cc07bf-79dc-4236-b39f-442846a67c42	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-03 22:58:47.244444+00	
00000000-0000-0000-0000-000000000000	6f28287e-b2e6-445d-a1f5-0114425c1b57	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-04 00:35:22.395231+00	
00000000-0000-0000-0000-000000000000	b0c30fcc-fb7c-44a6-b6d7-99d8fad25617	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-04 00:35:22.402342+00	
00000000-0000-0000-0000-000000000000	6e7e9162-ac6d-437c-9e07-64b8540d78a0	{"action":"token_refreshed","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-04-05 16:03:25.830389+00	
00000000-0000-0000-0000-000000000000	c80a4e3a-f43d-42c5-a341-b7ef5cf38882	{"action":"token_revoked","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"token"}	2026-04-05 16:03:25.864601+00	
00000000-0000-0000-0000-000000000000	44ed726d-7775-4997-989e-f6af94060360	{"action":"logout","actor_id":"a7a9325a-81d9-49c4-944f-d96b29987581","actor_username":"chaundra@avemargroup.com","actor_via_sso":false,"log_type":"account"}	2026-04-05 16:03:37.851994+00	
00000000-0000-0000-0000-000000000000	d7e35f16-f984-47eb-8f21-617818f2a2d3	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-05 18:51:33.262606+00	
00000000-0000-0000-0000-000000000000	7b91122d-3a47-4d12-9117-d06b9a110419	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-05 18:51:33.297237+00	
00000000-0000-0000-0000-000000000000	5e94ccb5-0039-4422-be92-13b02a2f91bc	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-05 19:07:56.996262+00	
00000000-0000-0000-0000-000000000000	376273b7-384d-48f2-846e-f230b01863e0	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-05 19:07:56.998229+00	
00000000-0000-0000-0000-000000000000	c0aa5b25-6f23-41ca-8aac-6db89b9e6aad	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-05 20:29:12.468424+00	
00000000-0000-0000-0000-000000000000	763dc1e9-0930-4f39-b145-732b22dae640	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-05 20:29:12.483139+00	
00000000-0000-0000-0000-000000000000	587c8117-e934-4926-97e9-c5933f5ec7f2	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-06 00:38:57.823338+00	
00000000-0000-0000-0000-000000000000	ed930c19-eb1f-4ab0-a8c4-ee3ea6fe1a23	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-06 00:38:57.826912+00	
00000000-0000-0000-0000-000000000000	4c895fb8-cd74-4e66-818b-9c85d86f3531	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-06 01:59:19.458213+00	
00000000-0000-0000-0000-000000000000	d59802c5-2203-4b24-bd64-1b5d379ff448	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-06 01:59:19.459966+00	
00000000-0000-0000-0000-000000000000	e12d600a-e7c8-43c7-97a4-0fb7753baf71	{"action":"token_refreshed","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-06 13:20:11.353619+00	
00000000-0000-0000-0000-000000000000	591480be-6139-4df1-973c-d6f669ec64cf	{"action":"token_revoked","actor_id":"cc517b59-4ac4-486d-9523-c9b5325063e5","actor_username":"jcdenterprisesokc@gmail.com","actor_via_sso":false,"log_type":"token"}	2026-04-06 13:20:11.390223+00	
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
fa1253e3-c3cb-4337-be53-e71b69f23592	fa1253e3-c3cb-4337-be53-e71b69f23592	{"sub": "fa1253e3-c3cb-4337-be53-e71b69f23592", "email": "jbuente@glassaero.com", "email_verified": false, "phone_verified": false}	email	2026-03-03 20:32:09.122623+00	2026-03-03 20:32:09.122656+00	2026-03-03 20:32:09.122656+00	5b3191f3-8935-41d1-a622-b4b059b87936
358c2f01-5aec-4ee5-aa76-dde5e15e87ef	358c2f01-5aec-4ee5-aa76-dde5e15e87ef	{"sub": "358c2f01-5aec-4ee5-aa76-dde5e15e87ef", "email": "logistics@glassaero.com", "email_verified": false, "phone_verified": false}	email	2026-03-03 20:33:53.78261+00	2026-03-03 20:33:53.78264+00	2026-03-03 20:33:53.78264+00	67e115dc-0994-41a6-9b31-4dc1f9da89ab
735de1e4-a0af-453f-8812-81789d11140e	735de1e4-a0af-453f-8812-81789d11140e	{"sub": "735de1e4-a0af-453f-8812-81789d11140e", "email": "ssully@avemargroup.com", "email_verified": false, "phone_verified": false}	email	2026-03-04 16:38:16.271559+00	2026-03-04 16:38:16.271595+00	2026-03-04 16:38:16.271595+00	2d7c834a-bd13-41d0-9cfa-4ea56dc7ba22
52feed68-1c5f-4f2f-b0ec-a3c074441ec1	52feed68-1c5f-4f2f-b0ec-a3c074441ec1	{"sub": "52feed68-1c5f-4f2f-b0ec-a3c074441ec1", "email": "testuser@example.com", "email_verified": false, "phone_verified": false}	email	2026-03-11 13:06:45.996389+00	2026-03-11 13:06:45.996504+00	2026-03-11 13:06:45.996504+00	4e78950c-c591-4fc3-82e4-6c9c614e1d53
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
36698c6c-1a0a-4afa-851a-ee06148f5ec0	2026-02-12 19:41:47.878931+00	2026-02-12 19:41:47.878931+00	password	c013f4b8-de4b-44fe-a4e5-1aa16f4f1aa5
10442552-b682-45ff-ac11-06c7c38abf54	2026-02-24 19:16:03.433008+00	2026-02-24 19:16:03.433008+00	password	0c228608-b7b9-4836-a17f-ad8ca7e53268
3045596d-f705-4cc0-86d0-4b14eff41ebd	2026-03-04 12:02:46.656927+00	2026-03-04 12:02:46.656927+00	password	ace4153d-2f75-4e58-9c4b-b830acda4e12
81fbdbba-b739-4640-925c-f6098748bdd0	2026-03-05 00:04:35.442154+00	2026-03-05 00:04:35.442154+00	password	cdea9cb9-12b9-4dae-b536-25f6548b3bbf
bb2a9030-8d20-4c22-b39a-737eb7e9275f	2026-03-05 20:41:26.792377+00	2026-03-05 20:41:26.792377+00	password	8d9c0913-3538-430b-ad0c-0c1092a111e0
ad8800af-a968-4a41-97e0-8f67fd888e58	2026-03-13 01:33:27.464603+00	2026-03-13 01:33:27.464603+00	password	a20dee55-f8a7-4156-87a7-84424ee5181b
40f7a419-1fea-43bc-9914-4b76c6278b1d	2026-03-17 21:41:40.521307+00	2026-03-17 21:41:40.521307+00	password	70e6e32e-f6ee-495d-b0b5-64536807799f
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid, last_webauthn_challenge_data) FROM stdin;
\.


--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_authorizations (id, authorization_id, client_id, user_id, redirect_uri, scope, state, resource, code_challenge, code_challenge_method, response_type, status, authorization_code, created_at, expires_at, approved_at, nonce) FROM stdin;
\.


--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_client_states (id, provider_type, code_verifier, created_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_clients (id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at, client_type) FROM stdin;
\.


--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_consents (id, user_id, client_id, scopes, granted_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
00000000-0000-0000-0000-000000000000	628	hpo3cxnm63lf	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-23 18:46:18.158514+00	2026-03-23 19:46:37.824604+00	c4dwosi52r3h	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	629	qywa36bq43is	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-23 19:46:37.857434+00	2026-03-23 21:46:31.653766+00	hpo3cxnm63lf	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	427	zteakgk7t2pp	5a58caed-c1fe-4094-875a-4a87f1208244	t	2026-02-24 19:16:03.429958+00	2026-03-24 18:56:49.406116+00	\N	10442552-b682-45ff-ac11-06c7c38abf54
00000000-0000-0000-0000-000000000000	576	sy3bafmfvz5z	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-09 18:54:54.266825+00	2026-03-10 14:47:59.08917+00	575blep37kv7	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	580	ka6dqasxiplh	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-10 15:45:50.609763+00	2026-03-10 16:43:50.652692+00	bjlqj3mkytzz	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	633	aaomu4u6grjd	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 00:20:39.057879+00	2026-03-25 01:19:18.038906+00	klbayroffgth	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	637	h45yzpg2h524	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 04:14:47.430644+00	2026-03-25 05:13:17.384667+00	gxtv2lw46tcc	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	641	rx6o2jdqeen3	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 08:08:47.663147+00	2026-03-25 09:07:16.797437+00	jx2pyr7ijaaq	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	596	f5gygn5jo3yz	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 02:31:00.907029+00	2026-03-13 03:28:45.949831+00	dpaeblg6agex	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	645	6f62hygebvz2	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 12:09:06.254666+00	2026-03-25 14:46:44.111417+00	hperhrqdkso4	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	600	xagjqocapumy	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 06:21:15.373065+00	2026-03-13 07:18:45.050237+00	m5gwmmssqhwv	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	604	wwzmklh7f524	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 10:11:14.419297+00	2026-03-13 11:08:44.304101+00	ya5jaimi6yy7	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	612	pdon4cjpodct	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-16 23:25:29.286597+00	2026-03-17 12:01:28.63713+00	fytzsedqibbg	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	649	uo5iopxpgouz	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-29 23:29:07.255566+00	2026-03-30 00:29:37.880957+00	3ey5dh4vdqul	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	616	fhqsnr75gjyj	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-18 12:39:37.143094+00	2026-03-18 20:24:12.902225+00	34yy4awmkqxw	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	620	kbdcs2h2up5a	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-18 21:23:39.610147+00	2026-03-30 21:39:04.636749+00	tg53sswnqcek	40f7a419-1fea-43bc-9914-4b76c6278b1d
00000000-0000-0000-0000-000000000000	624	us5njcqmqnxt	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-21 01:32:56.753529+00	2026-03-21 03:00:20.702478+00	4j256rnu4jrf	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	657	qxoe7kldw7ow	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-01 23:02:22.719188+00	2026-04-02 15:05:42.017985+00	yyxnr5m25gkk	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	661	iewkdtkjmpny	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-02 18:03:58.03331+00	2026-04-02 19:03:27.284578+00	qa27b2pkck2m	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	665	y3igg3x4mxlb	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-03 01:52:27.231098+00	2026-04-03 15:21:39.594221+00	wuik4ilxlonc	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	666	wgf36gqnkrz3	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-03 15:21:39.618943+00	2026-04-03 17:53:17.041638+00	y3igg3x4mxlb	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	668	jrqitfk7dbv7	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-03 21:00:08.403767+00	2026-04-03 21:59:27.762244+00	uclwdy3oq6ml	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	670	zrcdo2uottx4	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-03 22:58:47.272059+00	2026-04-04 00:35:22.403948+00	notwp7xdgwua	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	653	qssdq44s66x5	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-30 21:39:04.645263+00	2026-04-05 18:51:33.298392+00	kbdcs2h2up5a	40f7a419-1fea-43bc-9914-4b76c6278b1d
00000000-0000-0000-0000-000000000000	674	ld7jgljovkah	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-05 19:07:57.000396+00	2026-04-05 20:29:12.483702+00	isk6hvkplfgx	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	678	57xs55x22nsg	cc517b59-4ac4-486d-9523-c9b5325063e5	f	2026-04-06 13:20:11.408061+00	2026-04-06 13:20:11.408061+00	c2mwe2jb7htb	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	363	4evoqixfuuhn	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-12 19:41:47.709412+00	2026-02-13 21:25:13.396098+00	\N	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	370	r3wv36pa65iq	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-13 21:25:13.413264+00	2026-02-16 19:24:41.70351+00	4evoqixfuuhn	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	388	dlsdihfvmec3	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-16 19:24:41.738895+00	2026-02-16 20:23:14.220337+00	r3wv36pa65iq	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	389	wllwqxjibhem	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-16 20:23:14.221596+00	2026-02-17 19:52:06.578953+00	dlsdihfvmec3	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	390	tnghbb6sboac	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-17 19:52:06.597836+00	2026-02-17 21:48:14.392908+00	wllwqxjibhem	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	391	hmjzgc6ao2uj	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-17 21:48:14.411836+00	2026-02-18 15:55:01.409984+00	tnghbb6sboac	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	392	ul2otokpapax	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-18 15:55:01.433325+00	2026-02-24 16:15:46.961268+00	hmjzgc6ao2uj	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	422	olpekjzkkbqk	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-24 16:15:46.96361+00	2026-02-24 17:37:27.803601+00	ul2otokpapax	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	424	4uqntkbzxgco	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-24 17:37:27.80506+00	2026-02-24 18:40:19.851214+00	olpekjzkkbqk	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	425	qo3sligfv45n	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-24 18:40:19.852426+00	2026-02-24 20:24:59.323044+00	4uqntkbzxgco	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	429	34vs7r3uns6m	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-24 20:24:59.324235+00	2026-02-24 21:22:58.289973+00	qo3sligfv45n	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	431	iqwk4mjyuv7r	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-24 21:22:58.29194+00	2026-02-24 22:20:58.201869+00	34vs7r3uns6m	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	432	fo4ttda3kbno	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-24 22:20:58.20281+00	2026-02-26 13:52:37.795725+00	iqwk4mjyuv7r	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	630	ng3jojfkg7yw	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-23 21:46:31.666423+00	2026-03-24 21:28:50.270225+00	qywa36bq43is	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	444	g3amsfiszoe5	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-26 22:13:25.479099+00	2026-02-27 20:06:18.483835+00	jqxez7v2clm4	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	573	bsjctsfsd3br	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-09 15:20:25.78313+00	2026-03-09 17:47:12.248449+00	abzwpbbk3kdm	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	634	5kutwdb5bwu3	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 01:19:18.043896+00	2026-03-25 02:17:48.019737+00	aaomu4u6grjd	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	581	lavzj6xwktcp	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-10 16:43:50.658833+00	2026-03-10 17:41:50.555794+00	ka6dqasxiplh	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	638	csbxshv6fsky	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 05:13:17.394489+00	2026-03-25 06:11:47.208952+00	h45yzpg2h524	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	439	nwuwcuchguor	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-26 13:52:37.79703+00	2026-02-26 14:59:49.748161+00	fo4ttda3kbno	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	447	yzddteyjlh25	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-27 20:06:18.48608+00	2026-02-27 21:20:16.489531+00	g3amsfiszoe5	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	642	q2zhwugczis3	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 09:07:16.805245+00	2026-03-25 10:05:46.609189+00	rx6o2jdqeen3	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	646	pfalhzzokqzx	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 14:46:44.116395+00	2026-03-29 22:30:50.652303+00	6f62hygebvz2	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	597	kwmmygv4tec4	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 03:28:45.954435+00	2026-03-13 04:26:15.309499+00	f5gygn5jo3yz	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	650	c7af25zjxxt3	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-30 00:29:37.920518+00	2026-03-30 18:21:05.332443+00	uo5iopxpgouz	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	440	jqxez7v2clm4	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-26 14:59:49.750273+00	2026-02-26 22:13:25.477704+00	nwuwcuchguor	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	601	eufnmplmyspv	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 07:18:45.054723+00	2026-03-13 08:16:14.626191+00	xagjqocapumy	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	605	kyica4buwmnt	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 11:08:44.307318+00	2026-03-13 16:47:52.591685+00	wwzmklh7f524	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	654	vmaeishzsbex	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-31 12:31:15.826959+00	2026-03-31 19:28:57.144306+00	6vshppkm3cf6	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	609	6xlbj4dkpytb	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-15 15:53:46.451966+00	2026-03-15 20:43:33.315855+00	dmvwnobwppiv	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	613	6kd4dsbh753k	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-17 12:01:28.643978+00	2026-03-17 21:37:37.386217+00	pdon4cjpodct	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	658	rsnm2v5sxuf3	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-02 15:05:42.027129+00	2026-04-02 16:04:57.662578+00	qxoe7kldw7ow	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	617	5lvlxlrnyfnl	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-18 20:24:12.931884+00	2026-03-18 21:22:32.937033+00	fhqsnr75gjyj	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	621	ro5b66qshjrw	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-18 22:20:37.155574+00	2026-03-19 13:05:53.548365+00	eqhyo3v2w24o	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	662	tg2bkul2ohle	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-02 19:03:27.296092+00	2026-04-02 20:02:57.10136+00	iewkdtkjmpny	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	625	xo2h42rfpboh	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-21 03:00:20.709715+00	2026-03-21 15:43:44.761132+00	us5njcqmqnxt	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	450	ndvdtb4ephd4	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-02-27 21:20:16.491286+00	2026-03-02 14:23:35.079589+00	yzddteyjlh25	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	667	uclwdy3oq6ml	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-03 17:53:17.043673+00	2026-04-03 21:00:08.384296+00	wgf36gqnkrz3	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	458	fhxrbo2cad5t	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-02 14:23:35.080415+00	2026-03-02 16:32:00.046803+00	ndvdtb4ephd4	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	459	jcb5hafv352l	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-02 16:32:00.048105+00	2026-03-02 18:40:27.375015+00	fhxrbo2cad5t	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	669	notwp7xdgwua	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-03 21:59:27.763331+00	2026-04-03 22:58:47.245116+00	jrqitfk7dbv7	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	460	tg2chbuweqnt	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-02 18:40:27.376433+00	2026-03-02 22:10:21.263165+00	jcb5hafv352l	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	671	isk6hvkplfgx	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-04 00:35:22.406424+00	2026-04-05 19:07:56.999173+00	zrcdo2uottx4	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	675	4niyv3kmffzl	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-05 20:29:12.486532+00	2026-04-06 00:38:57.829691+00	ld7jgljovkah	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	461	2rbbrmy6krkr	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-02 22:10:21.272486+00	2026-03-03 14:47:05.832024+00	tg2chbuweqnt	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	465	iseprv66jex4	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-03 14:47:05.837863+00	2026-03-03 18:36:00.251558+00	2rbbrmy6krkr	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	484	lochf6i264mp	fa1253e3-c3cb-4337-be53-e71b69f23592	t	2026-03-04 12:02:46.65321+00	2026-03-04 13:00:51.912689+00	\N	3045596d-f705-4cc0-86d0-4b14eff41ebd
00000000-0000-0000-0000-000000000000	486	jsukacnm7hpy	fa1253e3-c3cb-4337-be53-e71b69f23592	t	2026-03-04 13:00:51.914119+00	2026-03-04 14:57:43.545613+00	lochf6i264mp	3045596d-f705-4cc0-86d0-4b14eff41ebd
00000000-0000-0000-0000-000000000000	467	so5brd2yimg7	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-03 18:36:00.254989+00	2026-03-04 16:34:48.229972+00	iseprv66jex4	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	631	nf2xwhikj3tt	5a58caed-c1fe-4094-875a-4a87f1208244	f	2026-03-24 18:56:49.417631+00	2026-03-24 18:56:49.417631+00	zteakgk7t2pp	10442552-b682-45ff-ac11-06c7c38abf54
00000000-0000-0000-0000-000000000000	489	xqxff5e7zgrn	fa1253e3-c3cb-4337-be53-e71b69f23592	f	2026-03-04 14:57:43.547524+00	2026-03-04 14:57:43.547524+00	jsukacnm7hpy	3045596d-f705-4cc0-86d0-4b14eff41ebd
00000000-0000-0000-0000-000000000000	520	abzwpbbk3kdm	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-05 21:47:46.343055+00	2026-03-09 15:20:25.774691+00	leets5e33uqz	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	635	dlob4xh7y4nk	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 02:17:48.026257+00	2026-03-25 03:16:17.750487+00	5kutwdb5bwu3	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	639	3vbttbcbjqc4	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 06:11:47.214945+00	2026-03-25 07:10:17.222414+00	csbxshv6fsky	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	582	agfeaolekr6a	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-10 17:41:50.563449+00	2026-03-10 18:51:56.657616+00	lavzj6xwktcp	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	643	egh2p4xb62nn	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 10:05:46.615936+00	2026-03-25 11:04:16.376111+00	q2zhwugczis3	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	491	xpgddf4bzfc6	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-04 16:34:48.231478+00	2026-03-04 18:56:57.456899+00	so5brd2yimg7	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	651	7kfihit5fbkw	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-30 18:21:05.368126+00	2026-03-30 19:41:24.798694+00	c7af25zjxxt3	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	598	43ohw4dq6baa	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 04:26:15.313705+00	2026-03-13 05:23:45.315745+00	kwmmygv4tec4	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	495	oqx5v5i4sc7p	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-04 18:56:57.4761+00	2026-03-04 20:06:16.87728+00	xpgddf4bzfc6	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	602	nj4yn5i2ihbw	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 08:16:14.628122+00	2026-03-13 09:13:44.56795+00	eufnmplmyspv	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	655	bxkqhjkpnwgl	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-31 19:28:57.169455+00	2026-04-01 01:14:44.489299+00	vmaeishzsbex	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	606	dmvwnobwppiv	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 16:47:52.598363+00	2026-03-15 15:53:46.445364+00	kyica4buwmnt	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	610	bzoq36yxgnsm	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-15 20:43:33.322643+00	2026-03-16 22:27:22.924022+00	6xlbj4dkpytb	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	659	exdvzt37iaal	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-02 16:04:57.667275+00	2026-04-02 17:04:28.030256+00	rsnm2v5sxuf3	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	614	34yy4awmkqxw	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-17 21:37:37.393242+00	2026-03-18 12:39:37.136845+00	6kd4dsbh753k	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	618	tg53sswnqcek	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-18 20:25:35.465174+00	2026-03-18 21:23:39.605437+00	irzfg4va5kvg	40f7a419-1fea-43bc-9914-4b76c6278b1d
00000000-0000-0000-0000-000000000000	663	da4bmwsj3iqa	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-02 20:02:57.109715+00	2026-04-02 21:02:26.693825+00	tg2bkul2ohle	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	622	xgiqgkfv37ny	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-19 13:05:53.55358+00	2026-03-19 14:17:43.092639+00	ro5b66qshjrw	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	626	wagimjbvbeh2	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-21 15:43:44.769194+00	2026-03-22 14:14:05.080274+00	xo2h42rfpboh	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	502	4rgjhbxokcgd	42636eed-d413-4d7f-975d-2db61fd13db9	t	2026-03-05 00:04:35.439598+00	2026-03-05 01:53:32.92281+00	\N	81fbdbba-b739-4640-925c-f6098748bdd0
00000000-0000-0000-0000-000000000000	505	kn2dw33cpy6i	42636eed-d413-4d7f-975d-2db61fd13db9	f	2026-03-05 01:53:32.923892+00	2026-03-05 01:53:32.923892+00	4rgjhbxokcgd	81fbdbba-b739-4640-925c-f6098748bdd0
00000000-0000-0000-0000-000000000000	676	rcy7lfbwyj76	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-06 00:38:57.831535+00	2026-04-06 01:59:19.460466+00	4niyv3kmffzl	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	497	6y56ti77hnho	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-04 20:06:16.905689+00	2026-03-05 13:49:14.17286+00	oqx5v5i4sc7p	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	508	2gbgt6mbsebz	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-05 13:49:14.180252+00	2026-03-05 15:38:12.768844+00	6y56ti77hnho	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	510	ao2rbrs3avrt	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-05 15:38:12.774769+00	2026-03-05 16:37:14.501073+00	2gbgt6mbsebz	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	512	s7rx72y6ltcc	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-05 16:37:14.505927+00	2026-03-05 19:16:33.180939+00	ao2rbrs3avrt	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	518	kqw2cifg2wje	735de1e4-a0af-453f-8812-81789d11140e	f	2026-03-05 20:41:26.745184+00	2026-03-05 20:41:26.745184+00	\N	bb2a9030-8d20-4c22-b39a-737eb7e9275f
00000000-0000-0000-0000-000000000000	515	leets5e33uqz	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-05 19:16:33.188415+00	2026-03-05 21:47:46.33722+00	s7rx72y6ltcc	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	632	klbayroffgth	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-24 21:28:50.298039+00	2026-03-25 00:20:39.050718+00	ng3jojfkg7yw	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	636	gxtv2lw46tcc	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 03:16:17.756372+00	2026-03-25 04:14:47.425878+00	dlob4xh7y4nk	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	575	575blep37kv7	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-09 17:47:12.255013+00	2026-03-09 18:54:54.260333+00	bsjctsfsd3br	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	579	bjlqj3mkytzz	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	t	2026-03-10 14:47:59.096774+00	2026-03-10 15:45:50.603726+00	sy3bafmfvz5z	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	583	k5g6ni6qcljo	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	f	2026-03-10 18:51:56.660431+00	2026-03-10 18:51:56.660431+00	agfeaolekr6a	36698c6c-1a0a-4afa-851a-ee06148f5ec0
00000000-0000-0000-0000-000000000000	640	jx2pyr7ijaaq	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 07:10:17.227555+00	2026-03-25 08:08:47.629736+00	3vbttbcbjqc4	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	644	hperhrqdkso4	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-25 11:04:16.381756+00	2026-03-25 12:09:06.247387+00	egh2p4xb62nn	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	595	dpaeblg6agex	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 01:33:27.43617+00	2026-03-13 02:31:00.901913+00	\N	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	648	3ey5dh4vdqul	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-29 22:30:50.687351+00	2026-03-29 23:29:07.248264+00	pfalhzzokqzx	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	599	m5gwmmssqhwv	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 05:23:45.319645+00	2026-03-13 06:21:15.335826+00	43ohw4dq6baa	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	603	ya5jaimi6yy7	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-13 09:13:44.571783+00	2026-03-13 10:11:14.414626+00	nj4yn5i2ihbw	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	652	6vshppkm3cf6	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-30 19:41:24.806226+00	2026-03-31 12:31:15.82079+00	7kfihit5fbkw	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	611	fytzsedqibbg	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-16 22:27:22.957159+00	2026-03-16 23:25:29.276601+00	bzoq36yxgnsm	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	656	yyxnr5m25gkk	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-01 01:14:44.522479+00	2026-04-01 23:02:22.684907+00	bxkqhjkpnwgl	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	615	irzfg4va5kvg	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-17 21:41:40.467725+00	2026-03-18 20:25:35.456113+00	\N	40f7a419-1fea-43bc-9914-4b76c6278b1d
00000000-0000-0000-0000-000000000000	619	eqhyo3v2w24o	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-18 21:22:32.941122+00	2026-03-18 22:20:37.148544+00	5lvlxlrnyfnl	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	660	qa27b2pkck2m	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-02 17:04:28.037899+00	2026-04-02 18:03:58.001323+00	exdvzt37iaal	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	623	4j256rnu4jrf	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-19 14:17:43.097228+00	2026-03-21 01:32:56.727039+00	xgiqgkfv37ny	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	627	c4dwosi52r3h	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-03-22 14:14:05.090181+00	2026-03-23 18:46:18.150008+00	wagimjbvbeh2	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	664	wuik4ilxlonc	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-02 21:02:26.702396+00	2026-04-03 01:52:27.203924+00	da4bmwsj3iqa	ad8800af-a968-4a41-97e0-8f67fd888e58
00000000-0000-0000-0000-000000000000	673	gseqqds245jy	cc517b59-4ac4-486d-9523-c9b5325063e5	f	2026-04-05 18:51:33.320274+00	2026-04-05 18:51:33.320274+00	qssdq44s66x5	40f7a419-1fea-43bc-9914-4b76c6278b1d
00000000-0000-0000-0000-000000000000	677	c2mwe2jb7htb	cc517b59-4ac4-486d-9523-c9b5325063e5	t	2026-04-06 01:59:19.461365+00	2026-04-06 13:20:11.391099+00	rcy7lfbwyj76	ad8800af-a968-4a41-97e0-8f67fd888e58
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
20250804100000
20250901200500
20250903112500
20250904133000
20250925093508
20251007112900
20251104100000
20251111201300
20251201000000
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) FROM stdin;
ad8800af-a968-4a41-97e0-8f67fd888e58	cc517b59-4ac4-486d-9523-c9b5325063e5	2026-03-13 01:33:27.292083+00	2026-04-06 13:20:11.42141+00	\N	aal1	\N	2026-04-06 13:20:11.421356	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	172.18.0.1	\N	\N	\N	\N	\N
36698c6c-1a0a-4afa-851a-ee06148f5ec0	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	2026-02-12 19:41:47.587673+00	2026-03-10 18:51:56.665205+00	\N	aal1	\N	2026-03-10 18:51:56.665144	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	172.18.0.1	\N	\N	\N	\N	\N
40f7a419-1fea-43bc-9914-4b76c6278b1d	cc517b59-4ac4-486d-9523-c9b5325063e5	2026-03-17 21:41:40.378684+00	2026-04-05 18:51:33.336839+00	\N	aal1	\N	2026-04-05 18:51:33.336789	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	172.18.0.1	\N	\N	\N	\N	\N
3045596d-f705-4cc0-86d0-4b14eff41ebd	fa1253e3-c3cb-4337-be53-e71b69f23592	2026-03-04 12:02:46.647167+00	2026-03-04 14:57:43.550059+00	\N	aal1	\N	2026-03-04 14:57:43.550015	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	172.18.0.1	\N	\N	\N	\N	\N
bb2a9030-8d20-4c22-b39a-737eb7e9275f	735de1e4-a0af-453f-8812-81789d11140e	2026-03-05 20:41:26.679477+00	2026-03-05 20:41:26.679477+00	\N	aal1	\N	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	172.18.0.1	\N	\N	\N	\N	\N
81fbdbba-b739-4640-925c-f6098748bdd0	42636eed-d413-4d7f-975d-2db61fd13db9	2026-03-05 00:04:35.425546+00	2026-03-05 01:53:32.926288+00	\N	aal1	\N	2026-03-05 01:53:32.926245	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36	172.18.0.1	\N	\N	\N	\N	\N
10442552-b682-45ff-ac11-06c7c38abf54	5a58caed-c1fe-4094-875a-4a87f1208244	2026-02-24 19:16:03.406496+00	2026-03-24 18:56:49.473207+00	\N	aal1	\N	2026-03-24 18:56:49.473099	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	172.18.0.1	\N	\N	\N	\N	\N
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
00000000-0000-0000-0000-000000000000	c32a1d63-4bbd-4d72-bf76-2bc75e0dbf4b	authenticated	authenticated	rf@avemargroup.com	$2a$10$WMOVt.iZ0Uq/zv2ESZ5V5eI1L7LsfuAliSxG2Cx1ZRvfFKA0BBsO2	2025-12-09 01:01:25.13469+00	\N		\N		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2025-12-09 01:01:25.126268+00	2025-12-09 01:01:25.136621+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	d1cfe5aa-76cb-46a0-85a5-f3e90df98f8a	authenticated	authenticated	robert@avemargroup.com	$2a$10$S8S3jYP6Sh5XDK2mzAe0V.pLAhD9Zf7y4R/Skj2pR83Vl1d4r8GJC	2026-01-19 21:27:42.61935+00	\N		\N		\N			\N	2026-02-12 19:41:47.586701+00	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-01-19 21:27:42.614705+00	2026-03-10 18:51:56.66347+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	42636eed-d413-4d7f-975d-2db61fd13db9	authenticated	authenticated	jdickinson214@gmail.com	$2a$10$ISo3KLNDx8eKPtlMEtRvIugAhWwpgcTJLYEduDr1fMzsIx.FZhP2q	2025-12-07 01:07:13.647826+00	\N		\N		\N			\N	2026-03-05 00:04:35.425494+00	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2025-12-07 01:07:13.643972+00	2026-03-05 01:53:32.925401+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	735de1e4-a0af-453f-8812-81789d11140e	authenticated	authenticated	ssully@avemargroup.com	$2a$10$svbkovc/9kvkdLimYqwc0ucJcpNlkE9/x37gXZa0wiz.ffn.4pB9i	2026-03-04 16:38:16.299739+00	\N		\N		\N			\N	2026-03-05 20:41:26.679272+00	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-03-04 16:38:16.265017+00	2026-03-05 20:41:26.783444+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	5a58caed-c1fe-4094-875a-4a87f1208244	authenticated	authenticated	sales@avemargroup.com	$2a$10$CHgpnYyOE30fwD0yEkLskOdh4eDz5fu26/aLPhr4yNknB.o6ePAkm	2026-01-19 21:41:31.623171+00	\N		\N		\N			\N	2026-02-24 19:16:03.406445+00	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-01-19 21:41:31.59849+00	2026-03-24 18:56:49.469362+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	cc517b59-4ac4-486d-9523-c9b5325063e5	authenticated	authenticated	jcdenterprisesokc@gmail.com	$2a$10$Wu0CqSltMv.j4OKIw00es.iO8HrGK.GSD5RKB3VzGd.A0R9qHu/2a	2025-12-07 00:52:40.045994+00	\N		\N		\N			\N	2026-03-17 21:41:40.378448+00	{"role": "admin", "provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2025-12-07 00:52:40.042707+00	2026-04-06 13:20:11.41999+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	a7a9325a-81d9-49c4-944f-d96b29987581	authenticated	authenticated	chaundra@avemargroup.com	$2a$10$8cstuiQoejQf3CHbNnVgQOuPPl4vPes5b.lUTovZmwAclGsdBs79.	2025-12-07 00:50:32.076062+00	\N		\N		\N			\N	2026-03-15 15:52:09.240307+00	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2025-12-07 00:50:32.0489+00	2026-04-05 16:03:25.913538+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	358c2f01-5aec-4ee5-aa76-dde5e15e87ef	authenticated	authenticated	logistics@glassaero.com	$2a$10$wFERAYYbBpOjotVBWtVHYu74sm2xfYF.Hh9nxHCrnndTFEgThxIn2	2026-03-03 20:33:53.807911+00	\N		\N		\N			\N	\N	{"role": "admin", "provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-03-03 20:33:53.778412+00	2026-03-03 20:33:53.808671+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	fa1253e3-c3cb-4337-be53-e71b69f23592	authenticated	authenticated	jbuente@glassaero.com	$2a$10$ItpZUVThH8krfZwpnbpTxe7AJ.30AuMvtJoxHvt20Ze5plEX.2xFu	2026-03-03 20:32:09.166838+00	\N		\N		\N			\N	2026-03-04 12:02:46.647097+00	{"role": "admin", "provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-03-03 20:32:09.109545+00	2026-03-04 14:57:43.549057+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	52feed68-1c5f-4f2f-b0ec-a3c074441ec1	authenticated	authenticated	testuser@example.com	$2a$10$mljDex0gCvb3ED2N5Yq4neoZFSWUCTequRV9neQssnhTG79E0RWUe	2026-03-11 13:06:46.07314+00	\N		\N		\N			\N	2026-03-11 13:07:34.193167+00	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-03-11 13:06:45.980811+00	2026-03-13 00:37:16.537034+00	\N	\N			\N		0	\N		\N	f	\N	f
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 678, true);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

