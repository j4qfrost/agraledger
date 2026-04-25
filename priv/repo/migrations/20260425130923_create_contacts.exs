defmodule Agraledger.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :name, :string, null: false
      add :role, :string
      add :email, :string
      add :phone, :string
      add :notes, :text
      add :is_primary, :boolean, default: false, null: false
      add :vendor_id, references(:vendors, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:contacts, [:vendor_id])
  end
end
