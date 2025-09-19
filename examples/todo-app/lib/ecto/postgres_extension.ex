defmodule Ecto.PostgresExtension do
  def uuid_ossp() do
    {0}
  end
  def post_gis() do
    {1}
  end
  def h_store() do
    {2}
  end
  def pg_trgm() do
    {3}
  end
  def pg_crypto() do
    {4}
  end
  def jsonb_plv8() do
    {5}
  end
end