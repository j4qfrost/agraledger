defmodule Agraledger.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :sku, :string, null: false
      add :category, :string, null: false, default: "other"
      add :unit, :string, null: false, default: "each"
      add :default_price, :money_with_currency

      timestamps(type: :utc_datetime)
    end

    create unique_index(:products, [:sku])
    create index(:products, [:category])
  end
end
