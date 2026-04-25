defmodule Agraledger.Repo.Migrations.CreateJournalLines do
  use Ecto.Migration

  def change do
    create table(:journal_lines) do
      add :debit, :money_with_currency
      add :credit, :money_with_currency
      add :line_memo, :string
      add :journal_entry_id, references(:journal_entries, on_delete: :delete_all), null: false
      add :account_id, references(:accounts, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:journal_lines, [:journal_entry_id])
    create index(:journal_lines, [:account_id])

    create constraint(:journal_lines, :debit_xor_credit,
             check: "(debit IS NULL) <> (credit IS NULL)"
           )
  end
end
