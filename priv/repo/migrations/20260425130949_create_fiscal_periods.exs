defmodule Agraledger.Repo.Migrations.CreateFiscalPeriods do
  use Ecto.Migration

  def change do
    create table(:fiscal_periods) do
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :closed, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:fiscal_periods, [:start_date, :end_date])
    create constraint(:fiscal_periods, :end_after_start, check: "end_date >= start_date")
  end
end
