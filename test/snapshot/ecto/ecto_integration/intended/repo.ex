defmodule Repo do
  def all(_schema) do
    []
  end
  def get(_schema, _id) do
    nil
  end
  def insert(_changeset) do
    nil
  end
  def update(_changeset) do
    nil
  end
  def delete(_entity) do
    nil
  end
  def preload(entity, _associations) do
    entity
  end
end