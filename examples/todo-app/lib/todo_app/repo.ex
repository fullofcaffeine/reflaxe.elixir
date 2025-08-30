defmodule TodoApp.Repo do
  def get(queryable, id) do
    fn queryable, id -> throw(%NotImplementedException{}) end
  end
  def get_by(queryable, conditions) do
    fn queryable, conditions -> throw(%NotImplementedException{}) end
  end
  def all(query) do
    fn query -> throw(%NotImplementedException{}) end
  end
  def one(query) do
    fn query -> throw(%NotImplementedException{}) end
  end
  def one_not_null(query) do
    fn query -> throw(%NotImplementedException{}) end
  end
  def exists(query) do
    fn query -> throw(%NotImplementedException{}) end
  end
  def insert(changeset) do
    fn changeset -> throw(%NotImplementedException{}) end
  end
  def insert_not_null(changeset) do
    fn changeset -> throw(%NotImplementedException{}) end
  end
  def update(changeset) do
    fn changeset -> throw(%NotImplementedException{}) end
  end
  def update_not_null(changeset) do
    fn changeset -> throw(%NotImplementedException{}) end
  end
  def delete(record) do
    fn record -> throw(%NotImplementedException{}) end
  end
  def delete_not_null(record) do
    fn record -> throw(%NotImplementedException{}) end
  end
  def preload(record, associations) do
    fn record, associations -> throw(%NotImplementedException{}) end
  end
  def transaction(fun) do
    fn fun -> throw(%NotImplementedException{}) end
  end
  def rollback(value) do
    fn value -> throw(%NotImplementedException{}) end
  end
end