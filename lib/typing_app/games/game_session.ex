defmodule TypingApp.Games.GameSession do
  use Ecto.Schema
  import Ecto.Changeset

  schema "game_sessions" do
    field :level, :integer
    field :score, :integer
    field :wpm, :float
    field :accuracy, :float
    field :time_taken, :integer
    field :completed_at, :naive_datetime

    belongs_to :user, TypingApp.Accounts.User

    timestamps()
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [:level, :score, :wpm, :accuracy, :time_taken, :completed_at, :user_id])
    |> validate_required([:level, :score, :user_id])
  end
end
