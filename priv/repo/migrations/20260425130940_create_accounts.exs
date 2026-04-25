defmodule Agraledger.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :code, :string, null: false
      add :name, :string, null: false
      add :type, :string, null: false
      add :is_postable, :boolean, default: true, null: false
      add :parent_id, references(:accounts, on_delete: :restrict)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounts, [:code])
    create index(:accounts, [:parent_id])
  end
end
