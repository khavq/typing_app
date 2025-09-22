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
  """
  def calculate_time_left(level, text) do
    Float.round(String.length(text) / level * 10)
  end

  @doc """
  Get a description for each game level.
  """
  def level_description(1), do: "Easy Mode - Single words"
  def level_description(2), do: "Getting Better - Short words"
  def level_description(3), do: "Intermediate - Longer words"
  def level_description(4), do: "Advanced - Short sentences"
  def level_description(5), do: "Expert - Full sentences"

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
  Calculate time allowed based on level and text length.
  Provides more time for longer texts and adjusts for level difficulty.
  """
  def calculate_time_left(level, text) do
    Float.round(String.length(text) / level * 10)
  end

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
