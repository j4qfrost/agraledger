defmodule Agraledger.Repo.Migrations.CreateSupplyLinks do
  use Ecto.Migration

  def change do
    create table(:supply_links) do
      add :role, :string, null: false, default: "upstream"
      add :notes, :text
      add :active, :boolean, default: true, null: false
      add :from_vendor_id, references(:vendors, on_delete: :delete_all), null: false
      add :to_vendor_id, references(:vendors, on_delete: :delete_all)
      add :product_id, references(:products, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:supply_links, [:from_vendor_id])
    create index(:supply_links, [:to_vendor_id])
    create index(:supply_links, [:product_id])
  end
end
