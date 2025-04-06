defmodule Sevensageassignment.Repo do
  use Ecto.Repo,
    otp_app: :sevensageassignment,
    adapter: Ecto.Adapters.SQLite3
end
