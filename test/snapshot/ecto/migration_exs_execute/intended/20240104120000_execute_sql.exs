defmodule TestApp.Repo.Migrations.ExecuteSql do
  use Ecto.Migration
  def up() do
    create table(:execute_records) do
      add(:label, :string, [null: false])
    end
    execute("INSERT INTO execute_records (label) VALUES ('first')")
    execute("INSERT INTO execute_records (label) VALUES ('quote '' slash \\ interpolation \#{untouched}')\n-- retained SQL comment")
    execute("CREATE TABLE execute_audit AS SELECT label FROM execute_records ORDER BY id")
  end
  def down() do
    execute("DELETE FROM execute_audit WHERE label = 'first'")
    execute("DROP TABLE execute_audit")
    drop(table(:execute_records))
  end
end
