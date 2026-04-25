defmodule Agraledger.Ledger.JournalEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Agraledger.Ledger.JournalLine

  schema "journal_entries" do
    field :posted_on, :date
    field :memo, :string
    field :reference, :string
    field :posted, :boolean, default: false

    belongs_to :vendor, Agraledger.Directory.Vendor
    belongs_to :created_by_user, Agraledger.Accounts.User

    has_many :lines, JournalLine,
      foreign_key: :journal_entry_id,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(journal_entry, attrs) do
    journal_entry
    |> cast(attrs, [:posted_on, :memo, :reference, :posted, :vendor_id, :created_by_user_id])
    |> validate_required([:posted_on])
    |> cast_assoc(:lines, with: &JournalLine.changeset/2, required: true)
    |> validate_balanced()
    |> validate_single_currency()
    |> validate_min_lines()
  end

  defp validate_balanced(changeset) do
    lines = get_field(changeset, :lines) || []

    {debit_sum, credit_sum} =
      Enum.reduce(lines, {Decimal.new(0), Decimal.new(0)}, fn line, {d, c} ->
        {
          Decimal.add(d, money_amount(line.debit)),
          Decimal.add(c, money_amount(line.credit))
        }
      end)

    if Decimal.equal?(debit_sum, credit_sum) do
      changeset
    else
      add_error(
        changeset,
        :lines,
        "must balance — debits #{Decimal.to_string(debit_sum)} ≠ credits #{Decimal.to_string(credit_sum)}"
      )
    end
  end

  defp validate_single_currency(changeset) do
    currencies =
      (get_field(changeset, :lines) || [])
      |> Enum.flat_map(fn line ->
        [money_currency(line.debit), money_currency(line.credit)]
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    case currencies do
      [] -> changeset
      [_] -> changeset
      many -> add_error(changeset, :lines, "all lines must use the same currency, got: #{inspect(many)}")
    end
  end

  defp validate_min_lines(changeset) do
    lines = get_field(changeset, :lines) || []

    if length(lines) >= 2 do
      changeset
    else
      add_error(changeset, :lines, "must have at least 2 lines")
    end
  end

  defp money_amount(nil), do: Decimal.new(0)
  defp money_amount(%Money{amount: amount}), do: amount

  defp money_currency(nil), do: nil
  defp money_currency(%Money{currency: c}), do: c
end
