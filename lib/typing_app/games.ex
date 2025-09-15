defmodule TypingApp.Games do
  @moduledoc "Context for game-related functionality"

  import Ecto.Query
  alias TypingApp.Repo
  alias TypingApp.Games.{GameSession, UserProgress}

  @typing_texts %{
    1 => ["cat", "dog", "sun", "fun", "run", "hat", "bat", "rat"],
    2 => ["apple", "happy", "jumps", "quick", "brown", "water", "tiger", "smile"],
    3 => ["elephant", "rainbow", "butterfly", "treasure", "adventure", "keyboard"],
    4 => ["The quick brown fox jumps", "Kids love to play games", "Practice makes perfect"],
    5 => ["The quick brown fox jumps over the lazy dog", "Learning to type is fun and rewarding"]
  }

  def get_typing_text(level) when level in 1..5 do
    texts = Map.get(@typing_texts, level, @typing_texts[1])
    Enum.random(texts)
  end

  def get_typing_text(_level), do: get_typing_text(1)

  def get_user_progress(user_id) do
    case Repo.get_by(UserProgress, user_id: user_id) do
      nil -> create_user_progress(%{user_id: user_id})
      progress -> {:ok, progress}
    end
  end

  def create_user_progress(attrs) do
    %UserProgress{}
    |> UserProgress.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_progress(%UserProgress{} = progress, attrs) do
    progress
    |> UserProgress.changeset(attrs)
    |> Repo.update()
  end

  def create_game_session(attrs) do
    %GameSession{}
    |> GameSession.changeset(attrs)
    |> Repo.insert()
  end

  def calculate_wpm(correct_chars, time_seconds) when time_seconds > 0 do
    correct_chars / 5 / (time_seconds / 60)
  end

  def calculate_wpm(_, _), do: 0.0

  def calculate_score(text_length, wpm, accuracy, streak_bonus \\ 0) do
    base_score = text_length * 10
    wpm_bonus = round(wpm * 2)
    accuracy_bonus = round(accuracy * 5)
    base_score + wpm_bonus + accuracy_bonus + streak_bonus
  end
end
