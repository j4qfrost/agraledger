defmodule Agraledger.Ledger do
  @moduledoc """
  The Ledger context — chart of accounts, journal entries, fiscal periods,
  trial balance and report aggregations.
  """

  import Ecto.Query, warn: false
  alias Agraledger.Repo
  alias Agraledger.Ledger.{Account, JournalEntry, JournalLine, FiscalPeriod}

  # ---------- Accounts ----------

  def list_accounts, do: Repo.all(from a in Account, order_by: a.code)

  def list_postable_accounts,
    do: Repo.all(from a in Account, where: a.is_postable, order_by: a.code)

  def get_account!(id), do: Repo.get!(Account, id)
  def get_account_by_code(code), do: Repo.get_by(Account, code: code)

  def create_account(attrs),
    do: %Account{} |> Account.changeset(attrs) |> Repo.insert()

  def update_account(%Account{} = a, attrs),
    do: a |> Account.changeset(attrs) |> Repo.update()

  def delete_account(%Account{} = a), do: Repo.delete(a)
  def change_account(%Account{} = a, attrs \\ %{}), do: Account.changeset(a, attrs)

  # ---------- Journal entries ----------

  def list_journal_entries(opts \\ []) do
    JournalEntry
    |> order_by([e], desc: e.posted_on, desc: e.id)
    |> maybe_filter_vendor(opts[:vendor_id])
    |> maybe_filter_account(opts[:account_id])
    |> maybe_filter_date_range(opts[:from], opts[:to])
    |> preload([:vendor, :created_by_user, lines: :account])
    |> Repo.all()
  end

  defp maybe_filter_vendor(q, nil), do: q
  defp maybe_filter_vendor(q, id), do: from(e in q, where: e.vendor_id == ^id)

  defp maybe_filter_account(q, nil), do: q

  defp maybe_filter_account(q, id) do
    from e in q,
      join: l in JournalLine,
      on: l.journal_entry_id == e.id,
      where: l.account_id == ^id,
      distinct: true
  end

  defp maybe_filter_date_range(q, nil, nil), do: q
  defp maybe_filter_date_range(q, from, nil), do: from(e in q, where: e.posted_on >= ^from)
  defp maybe_filter_date_range(q, nil, to), do: from(e in q, where: e.posted_on <= ^to)

  defp maybe_filter_date_range(q, from, to),
    do: from(e in q, where: e.posted_on >= ^from and e.posted_on <= ^to)

  def get_journal_entry!(id),
    do: Repo.get!(JournalEntry, id) |> Repo.preload([:vendor, :created_by_user, lines: :account])

  def change_journal_entry(%JournalEntry{} = e, attrs \\ %{}),
    do: JournalEntry.changeset(e, attrs)

  @doc """
  Creates a journal entry. Validates balance, single currency, and that the posted_on
  date does not fall inside a closed fiscal period (when the entry is being posted).
  """
  def create_journal_entry(attrs) do
    %JournalEntry{}
    |> JournalEntry.changeset(attrs)
    |> guard_period_open(attrs)
    |> Repo.insert()
  end

  def update_journal_entry(%JournalEntry{} = e, attrs) do
    e
    |> JournalEntry.changeset(attrs)
    |> guard_period_open(attrs)
    |> Repo.update()
  end

  def delete_journal_entry(%JournalEntry{} = e), do: Repo.delete(e)

  defp guard_period_open(changeset, attrs) do
    posted_on = Ecto.Changeset.get_field(changeset, :posted_on)
    posted = Ecto.Changeset.get_field(changeset, :posted) || attrs["posted"] == true

    if posted && posted_on && period_closed?(posted_on) do
      Ecto.Changeset.add_error(changeset, :posted_on, "fiscal period is closed")
    else
      changeset
    end
  end

  # ---------- Fiscal periods ----------

  def list_fiscal_periods,
    do: Repo.all(from p in FiscalPeriod, order_by: [desc: p.start_date])

  def get_fiscal_period!(id), do: Repo.get!(FiscalPeriod, id)

  def create_fiscal_period(attrs),
    do: %FiscalPeriod{} |> FiscalPeriod.changeset(attrs) |> Repo.insert()

  def update_fiscal_period(%FiscalPeriod{} = p, attrs),
    do: p |> FiscalPeriod.changeset(attrs) |> Repo.update()

  def delete_fiscal_period(%FiscalPeriod{} = p), do: Repo.delete(p)

  def change_fiscal_period(%FiscalPeriod{} = p, attrs \\ %{}),
    do: FiscalPeriod.changeset(p, attrs)

  def period_closed?(%Date{} = date) do
    Repo.exists?(
      from p in FiscalPeriod,
        where: p.closed and p.start_date <= ^date and p.end_date >= ^date
    )
  end

  # ---------- Reports ----------

  @doc """
  Returns a list of {%Account{}, %Money{} | nil debit_balance, %Money{} | nil credit_balance}
  for posted entries on or before `as_of`.
  """
  def trial_balance(as_of \\ Date.utc_today()) do
    accounts = list_accounts()

    sums =
      from(l in JournalLine,
        join: e in assoc(l, :journal_entry),
        where: e.posted and e.posted_on <= ^as_of,
        group_by: l.account_id,
        select: %{
          account_id: l.account_id,
          debit: type(sum(fragment("(?).amount", l.debit)), :decimal),
          credit: type(sum(fragment("(?).amount", l.credit)), :decimal)
        }
      )
      |> Repo.all()
      |> Map.new(&{&1.account_id, &1})

    Enum.map(accounts, fn account ->
      sum = Map.get(sums, account.id, %{debit: Decimal.new(0), credit: Decimal.new(0)})
      debit = sum.debit || Decimal.new(0)
      credit = sum.credit || Decimal.new(0)
      net = Decimal.sub(debit, credit)

      case Account.normal_side(account.type) do
        :debit -> {account, net, Decimal.new(0)}
        :credit -> {account, Decimal.new(0), Decimal.negate(net)}
      end
    end)
  end

  @doc """
  Sums for a given account type as of `as_of`. Returns a Decimal.
  """
  def total_for_type(type, as_of \\ Date.utc_today()) when type in [:asset, :liability, :equity, :revenue, :expense] do
    type_str = Atom.to_string(type)

    from(l in JournalLine,
      join: e in assoc(l, :journal_entry),
      join: a in assoc(l, :account),
      where: e.posted and e.posted_on <= ^as_of and a.type == ^type_str,
      select: {
        type(sum(fragment("(?).amount", l.debit)), :decimal),
        type(sum(fragment("(?).amount", l.credit)), :decimal)
      }
    )
    |> Repo.one()
    |> case do
      {nil, nil} -> Decimal.new(0)
      {d, c} ->
        d = d || Decimal.new(0)
        c = c || Decimal.new(0)

        case Account.normal_side(type) do
          :debit -> Decimal.sub(d, c)
          :credit -> Decimal.sub(c, d)
        end
    end
  end

  def balance_sheet(as_of \\ Date.utc_today()) do
    %{
      assets: total_for_type(:asset, as_of),
      liabilities: total_for_type(:liability, as_of),
      equity: total_for_type(:equity, as_of),
      as_of: as_of
    }
  end

  def income_statement(from_date, to_date) do
    revenue = period_total_for_type(:revenue, from_date, to_date)
    expenses = period_total_for_type(:expense, from_date, to_date)

    %{
      revenue: revenue,
      expenses: expenses,
      net_income: Decimal.sub(revenue, expenses),
      from: from_date,
      to: to_date
    }
  end

  defp period_total_for_type(type, from_date, to_date) do
    type_str = Atom.to_string(type)

    from(l in JournalLine,
      join: e in assoc(l, :journal_entry),
      join: a in assoc(l, :account),
      where:
        e.posted and e.posted_on >= ^from_date and e.posted_on <= ^to_date and
          a.type == ^type_str,
      select: {
        type(sum(fragment("(?).amount", l.debit)), :decimal),
        type(sum(fragment("(?).amount", l.credit)), :decimal)
      }
    )
    |> Repo.one()
    |> case do
      {nil, nil} -> Decimal.new(0)
      {d, c} ->
        d = d || Decimal.new(0)
        c = c || Decimal.new(0)

        case Account.normal_side(type) do
          :debit -> Decimal.sub(d, c)
          :credit -> Decimal.sub(c, d)
        end
    end
  end
end
