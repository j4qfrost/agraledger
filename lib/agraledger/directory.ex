defmodule Agraledger.Directory do
  @moduledoc """
  The Directory context.
  """

  import Ecto.Query, warn: false
  alias Agraledger.Repo

  alias Agraledger.Directory.Vendor

  @doc """
  Returns the list of vendors.

  ## Examples

      iex> list_vendors()
      [%Vendor{}, ...]

  """
  def list_vendors do
    Repo.all(Vendor)
  end

  @doc """
  Gets a single vendor.

  Raises `Ecto.NoResultsError` if the Vendor does not exist.

  ## Examples

      iex> get_vendor!(123)
      %Vendor{}

      iex> get_vendor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_vendor!(id), do: Repo.get!(Vendor, id)

  @doc """
  Creates a vendor.

  ## Examples

      iex> create_vendor(%{field: value})
      {:ok, %Vendor{}}

      iex> create_vendor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_vendor(attrs) do
    %Vendor{}
    |> Vendor.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a vendor.

  ## Examples

      iex> update_vendor(vendor, %{field: new_value})
      {:ok, %Vendor{}}

      iex> update_vendor(vendor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_vendor(%Vendor{} = vendor, attrs) do
    vendor
    |> Vendor.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a vendor.

  ## Examples

      iex> delete_vendor(vendor)
      {:ok, %Vendor{}}

      iex> delete_vendor(vendor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_vendor(%Vendor{} = vendor) do
    Repo.delete(vendor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking vendor changes.

  ## Examples

      iex> change_vendor(vendor)
      %Ecto.Changeset{data: %Vendor{}}

  """
  def change_vendor(%Vendor{} = vendor, attrs \\ %{}) do
    Vendor.changeset(vendor, attrs)
  end

  alias Agraledger.Directory.Contact

  @doc """
  Returns the list of contacts.

  ## Examples

      iex> list_contacts()
      [%Contact{}, ...]

  """
  def list_contacts do
    Repo.all(Contact)
  end

  @doc """
  Gets a single contact.

  Raises `Ecto.NoResultsError` if the Contact does not exist.

  ## Examples

      iex> get_contact!(123)
      %Contact{}

      iex> get_contact!(456)
      ** (Ecto.NoResultsError)

  """
  def get_contact!(id), do: Repo.get!(Contact, id)

  @doc """
  Creates a contact.

  ## Examples

      iex> create_contact(%{field: value})
      {:ok, %Contact{}}

      iex> create_contact(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_contact(attrs) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a contact.

  ## Examples

      iex> update_contact(contact, %{field: new_value})
      {:ok, %Contact{}}

      iex> update_contact(contact, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_contact(%Contact{} = contact, attrs) do
    contact
    |> Contact.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a contact.

  ## Examples

      iex> delete_contact(contact)
      {:ok, %Contact{}}

      iex> delete_contact(contact)
      {:error, %Ecto.Changeset{}}

  """
  def delete_contact(%Contact{} = contact) do
    Repo.delete(contact)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking contact changes.

  ## Examples

      iex> change_contact(contact)
      %Ecto.Changeset{data: %Contact{}}

  """
  def change_contact(%Contact{} = contact, attrs \\ %{}) do
    Contact.changeset(contact, attrs)
  end
end
