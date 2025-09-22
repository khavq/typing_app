defmodule TypingApp.Games.GameHelpers do
  @moduledoc """
  Helper functions for typing game functionality.
  These were extracted from the LiveView to make them reusable.
  """

  @doc """
  Count the number of correctly typed characters.
  """
  def count_correct_chars(typed, expected) do
    typed
    |> String.graphemes()
    |> Enum.zip(String.graphemes(expected))
    |> Enum.count(fn {t, e} -> t == e end)
  end

  @doc """
  Calculate the percentage of progress through a text.
  """
  def progress_percentage(_index, ""), do: 0

  def progress_percentage(index, text) do
    round(index / String.length(text) * 100)
  end

  @doc """
  Calculate time allowed based on level and text length.
  Provides more time for longer texts and adjusts for level difficulty.
  The formula decreases allowed time as levels increase.
  """
  def calculate_time_left(level, text) do
    base_time = String.length(text) * 0.2
    # Apply level difficulty factor (higher levels get less time)
    Float.round(base_time * (21 - level) / 10)
  end

  @doc """
  Get a description for each game level.
  """
  # Levels 1-5: Basic progression
  def level_description(1), do: "Easy Mode - Single words"
  def level_description(2), do: "Getting Better - Short words"
  def level_description(3), do: "Intermediate - Longer words"
  def level_description(4), do: "Advanced - Short sentences"
  def level_description(5), do: "Expert - Full sentences"
  
  # Levels 6-10: Intermediate typing challenges
  def level_description(6), do: "Fluency - Sentence practice"
  def level_description(7), do: "Pangrams - Sentences with all alphabet letters"
  def level_description(8), do: "Proverbs - Common sayings and wisdom"
  def level_description(9), do: "Quotations - Famous quotes"
  def level_description(10), do: "Inspirational - Motivational phrases"
  
  # Levels 11-15: Advanced typing with punctuation and numbers
  def level_description(11), do: "Statistics - Text with numbers and percentages"
  def level_description(12), do: "Dialogue - Text with quotation marks"
  def level_description(13), do: "Business - Professional communication"
  def level_description(14), do: "Contact - Formatted information"
  def level_description(15), do: "E-commerce - Product listings with prices"
  
  # Levels 16-20: Expert challenges with mixed content and programming
  def level_description(16), do: "JavaScript - Basic programming syntax"
  def level_description(17), do: "Python - Code with indentation"
  def level_description(18), do: "SQL - Database queries"
  def level_description(19), do: "HTML - Web markup language"
  def level_description(20), do: "Bash - Shell scripting commands"
  
  # Fallback for unknown levels
  def level_description(_), do: "Unknown level"

  @doc """
  Get a message based on the number of lives remaining.
  """
  def lives_message(5), do: "Expert"
  def lives_message(4), do: "You're doing great!"
  def lives_message(3), do: "Perfect!"
  def lives_message(2), do: "Good job!"
  def lives_message(1), do: "Be careful!"
  def lives_message(0), do: "Try again!"

  @doc """
  Determine the CSS class for a character based on its state in the typing game.
  """
  def char_class(index, current_index, typed_text, original_text) do
    cond do
      index < current_index ->
        typed_char = String.at(typed_text, index)
        original_char = String.at(original_text, index)
        if typed_char == original_char, do: "correct", else: "incorrect"

      index == current_index ->
        "current"

      true ->
        ""
    end
  end
end
