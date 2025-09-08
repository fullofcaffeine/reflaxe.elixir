defmodule CreateTodos do
  @title nil
  @description nil
  @completed nil
  @priority nil
  @due_date nil
  @tags nil
  @user_id nil
  def migrate_add_indexes(_struct) do
    nil
  end
  def rollback_custom_operation(_struct) do
    nil
  end
end