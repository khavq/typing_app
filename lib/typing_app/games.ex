defmodule TypingApp.Games do
  @moduledoc "Context for game-related functionality"

  import Ecto.Query
  alias TypingApp.Repo
  alias TypingApp.Games.{GameSession, UserProgress}

  require Logger

  @typing_texts %{
    # Level 1-5: Basic progression (same as original)
    1 => ["cat", "dog", "sun", "fun", "run", "hat", "bat", "rat"],
    2 => ["apple", "happy", "jumps", "quick", "brown", "water", "tiger", "smile"],
    3 => ["elephant", "rainbow", "butterfly", "treasure", "adventure", "keyboard"],
    4 => ["The quick brown fox jumps", "Kids love to play games", "Practice makes perfect"],
    5 => ["The quick brown fox jumps over the lazy dog", "Learning to type is fun and rewarding"],
    
    # Level 6-10: Intermediate typing challenges
    6 => ["Programming is a skill best learned by practice", "Typing fast requires regular practice and patience"],
    7 => ["The five boxing wizards jump quickly over the lazy dog pack", "How vexingly quick daft zebras jump!"],
    8 => ["A journey of a thousand miles begins with a single step", "All that glitters is not gold; all who wander are not lost"],
    9 => ["To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment"],
    10 => ["In three words I can sum up everything I've learned about life: it goes on", "The only way to do great work is to love what you do"],
    
    # Level 11-15: Advanced typing with punctuation and numbers
    11 => ["In 2023, over 85% of jobs required computer skills.", "The meeting is scheduled for July 14th, 2025 at 10:30 AM."],
    12 => ["He said, \"You must type carefully; accuracy is more important than speed!\" I nodded in agreement."],
    13 => ["When asked about the project timeline, she replied: \"We expect completion by Q3, assuming all goes well.\""],
    14 => ["Email: support@example.com | Phone: (555) 123-4567 | Address: 123 Main St., Suite 456, Springfield, IL 62701"],
    15 => ["The package includes: 3 widgets ($19.99 each), 2 gadgets ($24.50 each), and 1 premium tool set ($149.95)."],
    
    # Level 16-20: Expert challenges with mixed content and programming concepts
    16 => ["function calculateTotal(price, quantity) { return price * quantity * (1 + TAX_RATE); } // JavaScript function"],
    17 => ["def fibonacci(n):\n  if n <= 1:\n    return n\n  else:\n    return fibonacci(n-1) + fibonacci(n-2)  # Python recursive function"],
    18 => ["SELECT users.name, COUNT(orders.id) AS order_count FROM users JOIN orders ON users.id = orders.user_id GROUP BY users.id;"],
    19 => ["<div class=\"container\">\n  <h1>Welcome to our site!</h1>\n  <p>Learn to type <strong>HTML</strong> and <em>CSS</em> code quickly.</p>\n</div>"],
    20 => ["#!/bin/bash\nfor file in $(ls *.txt); do\n  echo \"Processing $file...\"\n  grep -l \"ERROR\" $file >> error_logs.txt\ndone"]
  }

  # Define function head with default parameter
  def get_typing_text(level, source \\ :default)

  # Implementation for valid levels
  def get_typing_text(level, source) when level in 1..20 do
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
      :advice ->
        case get_advice_text(level) do
          {:ok, text} -> {:ok, text}
          {:error, _reason} -> {:error, :api_failed}
        end
      :bored ->
        case get_bored_text(level) do
          {:ok, text} -> {:ok, text}
          {:error, _reason} -> {:error, :api_failed}
        end
      :programming ->
        case get_programming_quote_text(level) do
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

  @doc """
  Get short advice lines from Advice Slip API (https://api.adviceslip.com/)
  """
  def get_advice_text(_level) do
    urls = [
      "https://api.adviceslip.com/advice"
    ]
    try_advice_api_call(urls)
  end

  defp try_advice_api_call([url | remaining_urls]) do
    try do
      case Req.get(url, connect_options: [timeout: 5000], retry: false) do
        {:ok, %{status: 200, body: body}} when is_binary(body) ->
          # The API returns a JSON string; Req may not decode when content-type is text/html
          case Jason.decode(body) do
            {:ok, %{"slip" => %{"advice" => advice}}} when is_binary(advice) -> {:ok, advice}
            _ -> if remaining_urls == [], do: {:error, :bad_format}, else: try_advice_api_call(remaining_urls)
          end
        {:ok, %{status: 200, body: %{"slip" => %{"advice" => advice}}}} ->
          {:ok, advice}
        {:ok, %{status: code}} ->
          Logger.warning("Advice API returned status #{code}")
          if remaining_urls == [], do: {:error, :bad_status}, else: try_advice_api_call(remaining_urls)
        {:error, reason} ->
          Logger.error("Failed to fetch from Advice API: #{inspect(reason)}")
          if remaining_urls == [], do: {:error, reason}, else: try_advice_api_call(remaining_urls)
      end
    rescue
      e -> 
        Logger.error("Advice API exception: #{inspect(e)}")
        if remaining_urls == [], do: {:error, :exception}, else: try_advice_api_call(remaining_urls)
    end
  end

  defp try_advice_api_call([]), do: {:error, :all_urls_failed}

  @doc """
  Get short activity text from Bored API (https://www.boredapi.com/)
  """
  def get_bored_text(_level) do
    urls = [
      "https://www.boredapi.com/api/activity"
    ]
    try_bored_api_call(urls)
  end

  defp try_bored_api_call([url | remaining_urls]) do
    try do
      case Req.get(url, connect_options: [timeout: 5000]) do
        {:ok, %{status: 200, body: %{"activity" => activity}}} when is_binary(activity) ->
          {:ok, activity}
        {:ok, %{status: code}} ->
          Logger.warning("Bored API returned status #{code}")
          if remaining_urls == [], do: {:error, :bad_status}, else: try_bored_api_call(remaining_urls)
        {:error, reason} ->
          Logger.error("Failed to fetch from Bored API: #{inspect(reason)}")
          if remaining_urls == [], do: {:error, reason}, else: try_bored_api_call(remaining_urls)
      end
    rescue
      e -> 
        Logger.error("Bored API exception: #{inspect(e)}")
        if remaining_urls == [], do: {:error, :exception}, else: try_bored_api_call(remaining_urls)
    end
  end

  defp try_bored_api_call([]), do: {:error, :all_urls_failed}

  @doc """
  Programming quotes API: https://programming-quotes-api.vercel.app/api/random
  """
  def get_programming_quote_text(_level) do
    urls = [
      "https://programming-quotes-api.vercel.app/api/random"
    ]
    try_programming_api_call(urls)
  end

  defp try_programming_api_call([url | remaining_urls]) do
    try do
      case Req.get(url, connect_options: [timeout: 5000]) do
        {:ok, %{status: 200, body: %{"en" => quote}}} when is_binary(quote) ->
          {:ok, quote}
        {:ok, %{status: code}} ->
          Logger.warning("Programming Quotes API returned status #{code}")
          if remaining_urls == [], do: {:error, :bad_status}, else: try_programming_api_call(remaining_urls)
        {:error, reason} ->
          Logger.error("Failed to fetch from Programming Quotes API: #{inspect(reason)}")
          if remaining_urls == [], do: {:error, reason}, else: try_programming_api_call(remaining_urls)
      end
    rescue
      e -> 
        Logger.error("Programming Quotes API exception: #{inspect(e)}")
        if remaining_urls == [], do: {:error, :exception}, else: try_programming_api_call(remaining_urls)
    end
  end

  defp try_programming_api_call([]), do: {:error, :all_urls_failed}

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
