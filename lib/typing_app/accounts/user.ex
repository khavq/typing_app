defmodule TypingApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer

    has_many :game_sessions, TypingApp.Games.GameSession
    has_one :user_progress, TypingApp.Games.UserProgress

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name])
    |> validate_number(:age, greater_than: 0, less_than: 18)
  end
end
