defmodule Agraledger.Ledger.JournalLine do
  use Ecto.Schema
  import Ecto.Changeset

  schema "journal_lines" do
    field :debit, Money.Ecto.Composite.Type
    field :credit, Money.Ecto.Composite.Type
    field :line_memo, :string

    belongs_to :journal_entry, Agraledger.Ledger.JournalEntry
    belongs_to :account, Agraledger.Ledger.Account

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(journal_line, attrs) do
    journal_line
    |> cast(attrs, [:debit, :credit, :line_memo, :account_id])
    |> validate_required([:account_id])
    |> validate_exactly_one_amount()
    |> validate_positive()
    |> assoc_constraint(:account)
    |> check_constraint(:debit, name: :debit_xor_credit, message: "exactly one of debit or credit")
  end

  defp validate_exactly_one_amount(changeset) do
    debit = get_field(changeset, :debit)
    credit = get_field(changeset, :credit)

    case {debit, credit} do
      {nil, nil} -> add_error(changeset, :debit, "must set either debit or credit")
      {%Money{}, %Money{}} -> add_error(changeset, :debit, "set either debit or credit, not both")
      _ -> changeset
    end
  end

  defp validate_positive(changeset) do
    Enum.reduce([:debit, :credit], changeset, fn field, acc ->
      case get_field(acc, field) do
        %Money{amount: amount} ->
          if Decimal.positive?(amount),
            do: acc,
            else: add_error(acc, field, "must be positive")

        _ ->
          acc
      end
    end)
  end
end
