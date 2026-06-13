defmodule FixedGear.Repo do
  use Ecto.Repo,
    otp_app: :fixedgear,
    adapter: Ecto.Adapters.Postgres
end
