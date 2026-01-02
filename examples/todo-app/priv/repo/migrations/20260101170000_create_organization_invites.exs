defmodule TodoApp.Repo.Migrations.CreateOrganizationInvites do
  use Ecto.Migration
  def up() do
    create table(:organization_invites) do
      add(:organization_id, :integer, [null: false])
      add(:email, :string, [null: false])
      add(:role, :string, [null: false, default: "user"])
      add(:accepted_at, :naive_datetime)
      add(:accepted_by_user_id, :integer)
      timestamps()
    end
    create(index(:organization_invites, [:organization_id]))
    create(index(:organization_invites, [:email]))
    create(unique_index(:organization_invites, [:organization_id, :email], [name: :organization_invites_org_email_unique]))
  end
  def down() do
    drop(table(:organization_invites))
  end
end
