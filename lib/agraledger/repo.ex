defmodule Agraledger.Repo do
  use Ecto.Repo,
    otp_app: :agraledger,
    adapter: Ecto.Adapters.Postgres
end
