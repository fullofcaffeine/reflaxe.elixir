defmodule CreateUsers do
  def up() do
    "create table(:users) do\n      add :name, :string\n      add :email, :string\n      timestamps()\n    end"
  end
  def down() do
    "drop table(:users)"
  end
  def main() do
    _up_result = up()
    _down_result = down()
  end
end