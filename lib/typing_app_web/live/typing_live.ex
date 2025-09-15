defmodule TypingAppWeb.TypingLive do
  use TypingAppWeb, :live_view

  alias TypingApp.Games
  alias TypingApp.Accounts

  def mount(params, session, socket) do
    user_id = get_user_id_from_session(session)
    {:ok, progress} = Games.get_user_progress(user_id)

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:progress, progress)
      |> assign(:current_level, progress.current_level)
      |> assign(:game_state, :waiting)
      |> assign(:current_text, "")
      |> assign(:typed_text, "")
      |> assign(:current_index, 0)
      |> assign(:score, 0)
      |> assign(:lives, 3)
      |> assign(:start_time, nil)
      |> assign(:wpm, 0.0)
      |> assign(:accuracy, 100.0)
      |> assign(:streak, 0)
      |> assign(:time_left, 60)
      |> assign(:timer_ref, nil)
      |> assign(:sound_enabled, true)
      # For triggering JS sounds
      |> assign(:last_sound_event, nil)

    {:ok, socket}
  end

  def handle_event("start_game", _params, socket) do
    current_text = Games.get_typing_text(socket.assigns.current_level)
    timer_ref = schedule_timer()

    socket =
      socket
      |> assign(:game_state, :playing)
      |> assign(:current_text, current_text)
      |> assign(:typed_text, "")
      |> assign(:current_index, 0)
      |> assign(:start_time, System.monotonic_time(:second))
      |> assign(:time_left, 60)
      |> assign(:timer_ref, timer_ref)

    {:noreply, socket}
  end

  def handle_event("key_typed", %{"value" => typed_text}, socket) do
    socket = handle_typing_input(socket, typed_text)
    {:noreply, socket}
  end

  def handle_event("toggle_sound", _params, socket) do
    IO.inspect(socket.assigns.sound_enabled, label: "Sound enabled")
    new_sound_state = !socket.assigns.sound_enabled
    {:noreply, assign(socket, :sound_enabled, new_sound_state)}
  end

  def handle_event("next_level", _params, socket) do
    new_level = socket.assigns.current_level + 1

    # Update progress in database
    {:ok, _} =
      Games.update_user_progress(socket.assigns.progress, %{
        current_level: new_level,
        total_score: socket.assigns.progress.total_score + socket.assigns.score
      })

    socket =
      socket
      |> assign(:current_level, new_level)
      |> assign(:game_state, :waiting)
      |> assign(:lives, 3)
      |> assign(:score, 0)
      |> assign(:last_sound_event, "levelup")
      |> reset_timer()

    {:noreply, socket}
  end

  def handle_event("reset_game", _params, socket) do
    socket =
      socket
      |> assign(:current_level, 1)
      |> assign(:game_state, :waiting)
      |> assign(:score, 0)
      |> assign(:lives, 3)
      |> assign(:typed_text, "")
      |> reset_timer()

    {:noreply, socket}
  end

  def handle_info(:timer_tick, socket) do
    time_left = socket.assigns.time_left - 1

    if time_left <= 0 do
      socket = complete_level(socket)
      {:noreply, socket}
    else
      timer_ref = schedule_timer()

      socket =
        socket
        |> assign(:time_left, time_left)
        |> assign(:timer_ref, timer_ref)

      {:noreply, socket}
    end
  end

  defp handle_typing_input(socket, typed_text) do
    current_text = socket.assigns.current_text
    expected_text = String.slice(current_text, 0, String.length(typed_text))

    cond do
      typed_text == current_text ->
        # Text completed successfully
        complete_text(socket, typed_text)

      typed_text == expected_text ->
        # Correct so far
        socket
        |> assign(:typed_text, typed_text)
        |> assign(:current_index, String.length(typed_text))
        |> assign(:last_sound_event, "correct")
        |> update_stats(typed_text, true)

      true ->
        # Mistake made
        socket
        |> assign(:typed_text, typed_text)
        |> assign(:last_sound_event, "incorrect")
        |> handle_mistake()
        |> update_stats(typed_text, false)
    end
  end

  defp complete_text(socket, typed_text) do
    # Calculate score and update progress
    elapsed_time = System.monotonic_time(:second) - socket.assigns.start_time
    wpm = Games.calculate_wpm(String.length(typed_text), elapsed_time)

    score_earned =
      Games.calculate_score(
        String.length(typed_text),
        wpm,
        socket.assigns.accuracy,
        socket.assigns.streak * 10
      )

    new_score = socket.assigns.score + score_earned

    # Save game session
    Games.create_game_session(%{
      user_id: socket.assigns.user_id,
      level: socket.assigns.current_level,
      score: score_earned,
      wpm: wpm,
      accuracy: socket.assigns.accuracy,
      time_taken: elapsed_time
    })

    # Check if level should be completed (after 3 successful texts for demo)
    if new_score >= socket.assigns.current_level * 300 do
      complete_level(socket |> assign(:score, new_score))
    else
      # Generate new text and continue
      new_text = Games.get_typing_text(socket.assigns.current_level)

      socket
      |> assign(:score, new_score)
      |> assign(:current_text, new_text)
      |> assign(:typed_text, "")
      |> assign(:current_index, 0)
      |> assign(:start_time, System.monotonic_time(:second))
      |> assign(:last_sound_event, "complete")
    end
  end

  defp complete_level(socket) do
    socket
    |> assign(:game_state, :level_complete)
    |> assign(:last_sound_event, "levelup")
    |> reset_timer()
  end

  defp handle_mistake(socket) do
    new_lives = socket.assigns.lives - 1

    socket = assign(socket, :lives, new_lives)

    if new_lives <= 0 do
      assign(socket, :game_state, :game_over)
    else
      socket
    end
  end

  defp update_stats(socket, typed_text, correct?) do
    current_text = socket.assigns.current_text
    typed_length = String.length(typed_text)

    accuracy =
      if typed_length > 0 do
        correct_chars =
          count_correct_chars(typed_text, String.slice(current_text, 0, typed_length))

        correct_chars / typed_length * 100
      else
        100.0
      end

    streak = if correct?, do: socket.assigns.streak + 1, else: 0

    elapsed_time =
      if socket.assigns.start_time do
        System.monotonic_time(:second) - socket.assigns.start_time
      else
        1
      end

    wpm = Games.calculate_wpm(typed_length, elapsed_time)

    socket
    |> assign(:accuracy, accuracy)
    |> assign(:streak, streak)
    |> assign(:wpm, wpm)
  end

  defp count_correct_chars(typed, expected) do
    typed
    |> String.graphemes()
    |> Enum.zip(String.graphemes(expected))
    |> Enum.count(fn {t, e} -> t == e end)
  end

  defp schedule_timer do
    Process.send_after(self(), :timer_tick, 1000)
  end

  defp reset_timer(socket) do
    if socket.assigns.timer_ref do
      Process.cancel_timer(socket.assigns.timer_ref)
    end

    socket
    |> assign(:timer_ref, nil)
    |> assign(:time_left, 60)
  end

  defp get_user_id_from_session(session) do
    # In a real app, extract from session or create guest user
    session["user_id"] || 1
  end

  # Helper for rendering character states
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

  # View helpers
  defp level_description(1), do: "Easy Mode - Single words"
  defp level_description(2), do: "Getting Better - Short words"
  defp level_description(3), do: "Intermediate - Longer words"
  defp level_description(4), do: "Advanced - Short sentences"
  defp level_description(5), do: "Expert - Full sentences"

  defp lives_message(3), do: "Perfect!"
  defp lives_message(2), do: "Good job!"
  defp lives_message(1), do: "Be careful!"
  defp lives_message(0), do: "Try again!"

  defp progress_percentage(_index, ""), do: 0

  defp progress_percentage(index, text) do
    round(index / String.length(text) * 100)
  end
end
