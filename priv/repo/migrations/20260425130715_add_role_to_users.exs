defmodule Agraledger.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, null: false, default: "viewer"
      add :name, :string
    end

    create index(:users, [:role])
  end
end
