defmodule Agraledger.Repo.Migrations.CreateJournalEntries do
  use Ecto.Migration

  def change do
    create table(:journal_entries) do
      add :posted_on, :date, null: false
      add :memo, :text
      add :reference, :string
      add :posted, :boolean, default: false, null: false
      add :vendor_id, references(:vendors, on_delete: :nilify_all)
      add :created_by_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:journal_entries, [:vendor_id])
    create index(:journal_entries, [:created_by_user_id])
    create index(:journal_entries, [:posted_on])
    create index(:journal_entries, [:posted])
  end
end
