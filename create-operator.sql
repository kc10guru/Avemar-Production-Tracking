-- Create uuid=text operator so GoTrue migration 20221208132122 can parse
CREATE OR REPLACE FUNCTION pg_catalog.uuid_eq_text(uuid, text) RETURNS boolean AS $$
  SELECT $1::text = $2;
$$ LANGUAGE sql IMMUTABLE;

CREATE OPERATOR pg_catalog.= (
  LEFTARG = uuid,
  RIGHTARG = text,
  FUNCTION = pg_catalog.uuid_eq_text,
  COMMUTATOR = =
);
