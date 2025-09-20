defmodule TypingApp.Games do
  @moduledoc "Context for game-related functionality"

  import Ecto.Query
  alias TypingApp.Repo
  alias TypingApp.Games.{GameSession, UserProgress}

  require Logger

  @typing_texts %{
    1 => ["cat", "dog", "sun", "fun", "run", "hat", "bat", "rat"],
    2 => ["apple", "happy", "jumps", "quick", "brown", "water", "tiger", "smile"],
    3 => ["elephant", "rainbow", "butterfly", "treasure", "adventure", "keyboard"],
    4 => ["The quick brown fox jumps", "Kids love to play games", "Practice makes perfect"],
    5 => ["The quick brown fox jumps over the lazy dog", "Learning to type is fun and rewarding"]
  }

  # Define function head with default parameter
  def get_typing_text(level, source \\ :default)

  # Implementation for valid levels
  def get_typing_text(level, source) when level in 1..5 do
    result = case source do
      :default -> 
        {:ok, get_default_text(level)}
      :zenquotes -> 
        # Try API with fallback
        case get_zenquotes_text(level) do
          {:ok, text} -> {:ok, text}
          {:error, _reason} -> {:error, :api_failed}
        end
      :dummyjson -> 
        # Try API with fallback
        case get_dummyjson_text(level) do
          {:ok, text} -> {:ok, text}
          {:error, _reason} -> {:error, :api_failed}
        end
      _ -> 
        # Unknown source, use default
        {:ok, get_default_text(level)}
    end
    
    case result do
      {:ok, text} -> text
      {:error, :api_failed} ->
        Logger.info("API call failed, using fallback text")
        get_default_text(level)
    end
  end
  
  # Helper function for getting default text
  defp get_default_text(level) do
    texts = Map.get(@typing_texts, level, @typing_texts[1])
    Enum.random(texts)
  end

  # Fallback for invalid levels
  def get_typing_text(_level, _source), do: get_typing_text(1)

  # Removed Quotable API code as it was failing to connect

  @doc """
  Get quotes from ZenQuotes API (https://zenquotes.io/)
  """
  def get_zenquotes_text(_level) do
    # ZenQuotes alternative URLs
    urls = [
      "https://zenquotes.io/api/random",
      "https://type.fit/api/quotes"
    ]
    
    try_zenquotes_api_call(urls)
  end
  
  # Helper function to try ZenQuotes API URLs
  defp try_zenquotes_api_call([url | remaining_urls]) do
    try do
      case Req.get(url, connect_options: [timeout: 5000]) do
        {:ok, %{status: 200} = resp} ->
          # Handle different API formats
          cond do
            # ZenQuotes format
            is_list(resp.body) && Enum.any?(resp.body, &Map.has_key?(&1, "q")) ->
              [%{"q" => quote_text} | _] = resp.body
              {:ok, quote_text}
              
            # type.fit format (alternative API)
            is_list(resp.body) && Enum.any?(resp.body, &Map.has_key?(&1, "text")) ->
              quote = Enum.random(resp.body)
              {:ok, quote["text"]}
              
            # Unknown format
            true ->
              Logger.warning("API returned unexpected response format")
              if remaining_urls == [], do: {:error, :bad_format}, else: try_zenquotes_api_call(remaining_urls)
          end
        {:ok, %{status: code}} ->
          Logger.warning("API returned status code #{code}")
          if remaining_urls == [], do: {:error, :bad_status}, else: try_zenquotes_api_call(remaining_urls)
        {:error, reason} ->
          Logger.error("Failed to fetch from API: #{inspect(reason)}")
          if remaining_urls == [], do: {:error, reason}, else: try_zenquotes_api_call(remaining_urls)
      end
    rescue
      e -> 
        Logger.error("Error processing API response: #{inspect(e)}")
        if remaining_urls == [], do: {:error, :exception}, else: try_zenquotes_api_call(remaining_urls)
    end
  end
  
  defp try_zenquotes_api_call([]) do
    {:error, :all_urls_failed}
  end

  @doc """
  Get quotes from DummyJSON API (https://dummyjson.com/docs/quotes)
  """
  def get_dummyjson_text(_level) do
    # DummyJSON alternative URLs
    urls = [
      "https://dummyjson.com/quotes/random",
      "https://jsonplaceholder.typicode.com/posts/1" # Fallback API that's very reliable
    ]
    
    try_dummyjson_api_call(urls)
  end
  
  # Helper function to try DummyJSON API URLs
  defp try_dummyjson_api_call([url | remaining_urls]) do
    try do
      case Req.get(url, connect_options: [timeout: 5000]) do
        {:ok, %{status: 200} = resp} ->
          # Handle different API formats
          cond do
            # DummyJSON format
            is_map(resp.body) && Map.has_key?(resp.body, "quote") ->
              {:ok, resp.body["quote"]}
              
            # JSONPlaceholder format (alternative API)
            is_map(resp.body) && Map.has_key?(resp.body, "title") ->
              {:ok, resp.body["title"] <> ". " <> resp.body["body"]}
              
            # Unknown format
            true ->
              Logger.warning("API returned unexpected response format")
              if remaining_urls == [], do: {:error, :bad_format}, else: try_dummyjson_api_call(remaining_urls)
          end
        {:ok, %{status: code}} ->
          Logger.warning("API returned status code #{code}")
          if remaining_urls == [], do: {:error, :bad_status}, else: try_dummyjson_api_call(remaining_urls)
        {:error, reason} ->
          Logger.error("Failed to fetch from API: #{inspect(reason)}")
          if remaining_urls == [], do: {:error, reason}, else: try_dummyjson_api_call(remaining_urls)
      end
    rescue
      e -> 
        Logger.error("Error processing API response: #{inspect(e)}")
        if remaining_urls == [], do: {:error, :exception}, else: try_dummyjson_api_call(remaining_urls)
    end
  end
  
  defp try_dummyjson_api_call([]) do
    {:error, :all_urls_failed}
  end

  def get_user_progress(user_id) when is_integer(user_id) do
    case Repo.get_by(UserProgress, user_id: user_id) do
      nil -> create_user_progress(%{user_id: user_id})
      progress -> {:ok, progress}
    end
  end
  
  # Handle guest users (nil user_id)
  def get_user_progress(nil) do
    # Return default progress for guest users
    {:ok, %UserProgress{
      current_level: 1,
      total_score: 0,
      best_wpm: 0.0,
      games_played: 0
    }}
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
