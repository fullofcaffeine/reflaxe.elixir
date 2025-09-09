defmodule Ecto.PostgresExtension do
  def uuid_ossp() do
    {:UuidOssp}
  end
  def post_gis() do
    {:PostGIS}
  end
  def h_store() do
    {:HStore}
  end
  def pg_trgm() do
    {:PgTrgm}
  end
  def pg_crypto() do
    {:PgCrypto}
  end
  def jsonb_plv8() do
    {:JsonbPlv8}
  end
end