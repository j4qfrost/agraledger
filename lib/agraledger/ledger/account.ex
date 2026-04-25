defmodule Agraledger.Ledger.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @types [:asset, :liability, :equity, :revenue, :expense]
  @debit_normal [:asset, :expense]
  @credit_normal [:liability, :equity, :revenue]

  schema "accounts" do
    field :code, :string
    field :name, :string
    field :type, Ecto.Enum, values: @types
    field :is_postable, :boolean, default: true

    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  def types, do: @types
  def debit_normal_types, do: @debit_normal
  def credit_normal_types, do: @credit_normal

  def normal_side(:asset), do: :debit
  def normal_side(:expense), do: :debit
  def normal_side(:liability), do: :credit
  def normal_side(:equity), do: :credit
  def normal_side(:revenue), do: :credit

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:code, :name, :type, :is_postable, :parent_id])
    |> validate_required([:code, :name, :type])
    |> validate_format(:code, ~r/^\d{3,6}$/, message: "must be 3-6 digits")
    |> unique_constraint(:code)
    |> assoc_constraint(:parent)
  end
end
