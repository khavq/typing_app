defmodule TypingApp.Repo do
  use Ecto.Repo,
    otp_app: :typing_app,
    adapter: Ecto.Adapters.Postgres
end
