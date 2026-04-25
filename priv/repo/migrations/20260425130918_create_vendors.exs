defmodule Agraledger.Repo.Migrations.CreateVendors do
  use Ecto.Migration

  def change do
    create table(:vendors) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :kind, :string, null: false, default: "supplier"
      add :tax_id, :string
      add :website, :string
      add :notes, :text
      add :tags, {:array, :string}, default: []
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:vendors, [:slug])
    create index(:vendors, [:kind])
  end
end
