defmodule Ecto._Migration.AlterOperation do
  def add_column(arg0, arg1, arg2) do
    {:AddColumn, arg0, arg1, arg2}
  end
  def remove_column(arg0) do
    {:RemoveColumn, arg0}
  end
  def modify_column(arg0, arg1, arg2) do
    {:ModifyColumn, arg0, arg1, arg2}
  end
  def rename_column(arg0, arg1) do
    {:RenameColumn, arg0, arg1}
  end
end