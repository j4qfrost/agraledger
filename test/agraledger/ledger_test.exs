defmodule Agraledger.LedgerTest do
  use Agraledger.DataCase, async: true

  alias Agraledger.{Ledger, Repo}
  alias Agraledger.Ledger.{Account, JournalEntry}

  setup do
    cash =
      %Account{}
      |> Account.changeset(%{code: "1000", name: "Cash", type: :asset})
      |> Repo.insert!()

    expense =
      %Account{}
      |> Account.changeset(%{code: "5100", name: "Seed & Feed", type: :expense})
      |> Repo.insert!()

    revenue =
      %Account{}
      |> Account.changeset(%{code: "4100", name: "Crop Sales", type: :revenue})
      |> Repo.insert!()

    {:ok, cash: cash, expense: expense, revenue: revenue}
  end

  describe "journal entries" do
    test "creates a balanced entry", %{cash: cash, expense: expense} do
      assert {:ok, entry} =
               Ledger.create_journal_entry(%{
                 posted_on: ~D[2026-01-15],
                 memo: "Buy seed",
                 reference: "PO-1",
                 posted: true,
                 lines: [
                   %{account_id: expense.id, debit: Money.new(:USD, "100.00")},
                   %{account_id: cash.id, credit: Money.new(:USD, "100.00")}
                 ]
               })

      assert entry.posted
      assert length(entry.lines) == 2
    end

    test "rejects unbalanced entries", %{cash: cash, expense: expense} do
      assert {:error, cs} =
               Ledger.create_journal_entry(%{
                 posted_on: ~D[2026-01-15],
                 memo: "Bad",
                 reference: "PO-2",
                 posted: true,
                 lines: [
                   %{account_id: expense.id, debit: Money.new(:USD, "100.00")},
                   %{account_id: cash.id, credit: Money.new(:USD, "90.00")}
                 ]
               })

      {msg, _} = cs.errors[:lines]
      assert String.starts_with?(msg, "must balance")
    end

    test "rejects entries with mixed currencies", %{cash: cash, expense: expense} do
      assert {:error, cs} =
               Ledger.create_journal_entry(%{
                 posted_on: ~D[2026-01-15],
                 memo: "Mixed",
                 reference: "PO-3",
                 posted: true,
                 lines: [
                   %{account_id: expense.id, debit: Money.new(:USD, "100.00")},
                   %{account_id: cash.id, credit: Money.new(:EUR, "100.00")}
                 ]
               })

      {msg, _} = cs.errors[:lines]
      assert String.starts_with?(msg, "all lines must use the same currency")
    end

    test "rejects single-line entries", %{cash: cash} do
      assert {:error, cs} =
               Ledger.create_journal_entry(%{
                 posted_on: ~D[2026-01-15],
                 memo: "One",
                 reference: "PO-4",
                 posted: true,
                 lines: [%{account_id: cash.id, debit: Money.new(:USD, "0.00")}]
               })

      {msg, _} = cs.errors[:lines]
      assert msg == "must have at least 2 lines"
    end

    test "rejects posting into a closed fiscal period", %{cash: cash, expense: expense} do
      {:ok, _} =
        Ledger.create_fiscal_period(%{
          start_date: ~D[2026-01-01],
          end_date: ~D[2026-01-31],
          closed: true
        })

      assert {:error, cs} =
               Ledger.create_journal_entry(%{
                 posted_on: ~D[2026-01-15],
                 memo: "Closed",
                 reference: "PO-5",
                 posted: true,
                 lines: [
                   %{account_id: expense.id, debit: Money.new(:USD, "10.00")},
                   %{account_id: cash.id, credit: Money.new(:USD, "10.00")}
                 ]
               })

      {msg, _} = cs.errors[:posted_on]
      assert msg == "fiscal period is closed"
    end

    test "allows draft entries into closed period", %{cash: cash, expense: expense} do
      {:ok, _} =
        Ledger.create_fiscal_period(%{
          start_date: ~D[2026-01-01],
          end_date: ~D[2026-01-31],
          closed: true
        })

      assert {:ok, _} =
               Ledger.create_journal_entry(%{
                 posted_on: ~D[2026-01-15],
                 memo: "Draft",
                 reference: "PO-6",
                 posted: false,
                 lines: [
                   %{account_id: expense.id, debit: Money.new(:USD, "10.00")},
                   %{account_id: cash.id, credit: Money.new(:USD, "10.00")}
                 ]
               })
    end
  end

  describe "trial balance" do
    test "sums posted entries by account", %{cash: cash, expense: expense, revenue: revenue} do
      {:ok, _} =
        Ledger.create_journal_entry(%{
          posted_on: ~D[2026-02-01],
          memo: "Buy seed",
          reference: "PO-A",
          posted: true,
          lines: [
            %{account_id: expense.id, debit: Money.new(:USD, "200.00")},
            %{account_id: cash.id, credit: Money.new(:USD, "200.00")}
          ]
        })

      {:ok, _} =
        Ledger.create_journal_entry(%{
          posted_on: ~D[2026-02-10],
          memo: "Sell crop",
          reference: "PO-B",
          posted: true,
          lines: [
            %{account_id: cash.id, debit: Money.new(:USD, "500.00")},
            %{account_id: revenue.id, credit: Money.new(:USD, "500.00")}
          ]
        })

      tb = Ledger.trial_balance(~D[2026-12-31])
      tb_map = Map.new(tb, fn {a, d, c} -> {a.code, {d, c}} end)

      {cash_d, cash_c} = tb_map["1000"]
      assert Decimal.equal?(cash_d, Decimal.new("300"))
      assert Decimal.equal?(cash_c, Decimal.new(0))

      {exp_d, exp_c} = tb_map["5100"]
      assert Decimal.equal?(exp_d, Decimal.new("200"))
      assert Decimal.equal?(exp_c, Decimal.new(0))

      {rev_d, rev_c} = tb_map["4100"]
      assert Decimal.equal?(rev_d, Decimal.new(0))
      assert Decimal.equal?(rev_c, Decimal.new("500"))
    end

    test "ignores draft entries", %{cash: cash, expense: expense} do
      {:ok, _} =
        Ledger.create_journal_entry(%{
          posted_on: ~D[2026-02-01],
          memo: "Draft",
          reference: "PO-D",
          posted: false,
          lines: [
            %{account_id: expense.id, debit: Money.new(:USD, "999.00")},
            %{account_id: cash.id, credit: Money.new(:USD, "999.00")}
          ]
        })

      tb = Ledger.trial_balance(~D[2026-12-31])
      tb_map = Map.new(tb, fn {a, d, c} -> {a.code, {d, c}} end)

      {exp_d, exp_c} = tb_map["5100"]
      assert Decimal.equal?(exp_d, Decimal.new(0))
      assert Decimal.equal?(exp_c, Decimal.new(0))
    end
  end

  describe "income statement" do
    test "computes net income for period", %{cash: cash, expense: expense, revenue: revenue} do
      {:ok, _} =
        Ledger.create_journal_entry(%{
          posted_on: ~D[2026-03-01],
          memo: "Sale",
          reference: "S-1",
          posted: true,
          lines: [
            %{account_id: cash.id, debit: Money.new(:USD, "1000.00")},
            %{account_id: revenue.id, credit: Money.new(:USD, "1000.00")}
          ]
        })

      {:ok, _} =
        Ledger.create_journal_entry(%{
          posted_on: ~D[2026-03-15],
          memo: "Buy",
          reference: "B-1",
          posted: true,
          lines: [
            %{account_id: expense.id, debit: Money.new(:USD, "300.00")},
            %{account_id: cash.id, credit: Money.new(:USD, "300.00")}
          ]
        })

      is = Ledger.income_statement(~D[2026-03-01], ~D[2026-03-31])
      assert Decimal.equal?(is.revenue, Decimal.new("1000"))
      assert Decimal.equal?(is.expenses, Decimal.new("300"))
      assert Decimal.equal?(is.net_income, Decimal.new("700"))
    end
  end

  describe "schema validations" do
    test "Account validates code format" do
      cs = Account.changeset(%Account{}, %{code: "abc", name: "Bad", type: :asset})
      refute cs.valid?
    end

    test "JournalEntry exposes lines association" do
      assert %JournalEntry{lines: %Ecto.Association.NotLoaded{}} = %JournalEntry{}
    end
  end
end
