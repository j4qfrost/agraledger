defmodule Agraledger.Ledger.FiscalPeriod do
  use Ecto.Schema
  import Ecto.Changeset

  schema "fiscal_periods" do
    field :start_date, :date
    field :end_date, :date
    field :closed, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(fiscal_period, attrs) do
    fiscal_period
    |> cast(attrs, [:start_date, :end_date, :closed])
    |> validate_required([:start_date, :end_date])
    |> validate_dates()
    |> unique_constraint([:start_date, :end_date])
    |> check_constraint(:end_date, name: :end_after_start, message: "must be on or after start date")
  end

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(end_date, start_date) == :lt do
      add_error(changeset, :end_date, "must be on or after start date")
    else
      changeset
    end
  end
end
