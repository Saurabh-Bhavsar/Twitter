defmodule Proj4.Repo do
  use Ecto.Repo,
    otp_app: :proj4,
    adapter: Ecto.Adapters.Postgres
end
