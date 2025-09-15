defmodule TypingApp.Games.UserProgress do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_progress" do
    field :current_level, :integer, default: 1
    field :total_score, :integer, default: 0
    field :best_wpm, :float, default: 0.0
    field :games_played, :integer, default: 0

    belongs_to :user, TypingApp.Accounts.User

    timestamps()
  end

  def changeset(progress, attrs) do
    progress
    |> cast(attrs, [:current_level, :total_score, :best_wpm, :games_played, :user_id])
    |> validate_required([:user_id])
  end
end
