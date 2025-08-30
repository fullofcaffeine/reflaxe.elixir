defmodule TodoApp.Repo do
  def get() do
    fn queryable, id -> throw(%NotImplementedException{}) end
  end
  def get_by() do
    fn queryable, conditions -> throw(%NotImplementedException{}) end
  end
  def all() do
    fn query -> throw(%NotImplementedException{}) end
  end
  def one() do
    fn query -> throw(%NotImplementedException{}) end
  end
  def one_not_null() do
    fn query -> throw(%NotImplementedException{}) end
  end
  def exists() do
    fn query -> throw(%NotImplementedException{}) end
  end
  def insert() do
    fn changeset -> throw(%NotImplementedException{}) end
  end
  def insert_not_null() do
    fn changeset -> throw(%NotImplementedException{}) end
  end
  def update() do
    fn changeset -> throw(%NotImplementedException{}) end
  end
  def update_not_null() do
    fn changeset -> throw(%NotImplementedException{}) end
  end
  def delete() do
    fn record -> throw(%NotImplementedException{}) end
  end
  def delete_not_null() do
    fn record -> throw(%NotImplementedException{}) end
  end
  def preload() do
    fn record, associations -> throw(%NotImplementedException{}) end
  end
  def transaction() do
    fn fun -> throw(%NotImplementedException{}) end
  end
  def rollback() do
    fn value -> throw(%NotImplementedException{}) end
  end
end