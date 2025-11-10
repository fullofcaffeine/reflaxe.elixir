defmodule Ecto.Migration.AlterOperation do
  def add_column(arg0, arg1, arg2) do
    {0, arg0, arg1, arg2}
  end
  def remove_column(arg0) do
    {1, arg0}
  end
  def modify_column(arg0, arg1, arg2) do
    {2, arg0, arg1, arg2}
  end
  def rename_column(arg0, arg1) do
    {3, arg0, arg1}
  end
end
