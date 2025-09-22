defmodule TypingAppWeb.TypingLive do
  use TypingAppWeb, :live_view

  alias TypingApp.Games
  alias TypingApp.Accounts
  alias TypingApp.Games.GameHelpers

  def mount(_params, _session, socket) do
    # Handle both authenticated users and guests
    {current_user, user_id} = get_current_user(socket)
    
    # Get progress based on user_id (handles nil for guests)
    {:ok, progress} = Games.get_user_progress(user_id)

    # Available text sources
    text_sources = [
      {:zenquotes, "ZenQuotes API"},
      {:dummyjson, "DummyJSON API"},
      {:default, "Built-in Text"}
    ]

    socket =
      socket
      |> assign(:current_user, current_user) # Add the current user to assigns
      |> assign(:progress, progress)
      |> assign(:current_level, progress.current_level)
      |> assign(:game_state, :waiting)
      |> assign(:current_text, "")
      |> assign(:typed_text, "")
      |> assign(:current_index, 0)
      |> assign(:score, 0)
      |> assign(:lives, 5)
      |> assign(:start_time, nil)
      |> assign(:wpm, 0.0)
      |> assign(:accuracy, 100.0)
      |> assign(:streak, 0)
      |> assign(:sound_enabled, current_user.sound_enabled)
      |> assign(:typing_sound_enabled, current_user.typing_sound_enabled)
      |> assign(:background_music_enabled, current_user.background_music_enabled)
      |> assign(:time_left, 60)
      |> assign(:timer_ref, nil)
      # For triggering JS sounds
      |> assign(:last_sound_event, nil)
      # For text sources
      |> assign(:text_sources, text_sources)
      |> assign(:selected_source, get_user_text_source_preference(current_user))
      # Track completed texts for level progression
      |> assign(:texts_completed, 0)
      |> assign(:texts_required_for_level, 3)

    {:ok, socket}
  end

  def handle_event("start_game", _params, socket) do
    # Get text from the selected source
    current_text = Games.get_typing_text(
      socket.assigns.current_level,
      socket.assigns.selected_source
    )
    timer_ref = schedule_timer()

    socket =
      socket
      |> assign(:game_state, :playing)
      |> assign(:current_text, current_text)
      |> assign(:typed_text, "")
      |> assign(:current_index, 0)
      |> assign(:start_time, System.monotonic_time(:second))
      |> assign(:time_left, GameHelpers.calculate_time_left(socket.assigns.current_level, current_text))
      |> assign(:timer_ref, timer_ref)
      |> assign(:lives, 5)

    {:noreply, socket}
  end

  def handle_event("key_typed", %{"value" => typed_text}, socket) do
    socket = handle_typing_input(socket, typed_text)
    {:noreply, socket}
  end

  # Handle synchronizing the input field with the current state
  defp maybe_push_sync_event(socket, typed_text) do
    if socket.assigns.typed_text != typed_text do
      push_event(socket, "sync_input", %{value: socket.assigns.typed_text})
    else
      socket
    end
  end

  def handle_event("toggle_sound", _params, socket) do
    IO.inspect(socket.assigns.sound_enabled, label: "Sound enabled")
    new_sound_state = !socket.assigns.sound_enabled
    socket = assign(socket, :sound_enabled, new_sound_state)
    
    # If the game is in playing state, we need to refocus the typing input
    socket = if socket.assigns.game_state == :playing do
      push_event(socket, "refocus_typing", %{})
    else
      socket
    end
    
    {:noreply, socket}
  end

  def handle_event("select_text_source", %{"source" => source}, socket) do
    # Convert the string value to an atom safely
    source_atom = case source do
      "default" -> :default
      "zenquotes" -> :zenquotes
      "dummyjson" -> :dummyjson
      _ -> :default
    end
    
    # Save preference to database for registered users
    {current_user, user_id} = get_current_user(socket)
    
    # Prepare updated socket with selected source
    socket = assign(socket, :selected_source, source_atom)
    
    if user_id do
      # Only save for authenticated users
      case TypingApp.Accounts.update_user_game_settings(current_user, %{selected_source: Atom.to_string(source_atom)}) do
        {:ok, _updated_user} ->
          # Successfully saved preference
          socket = put_flash(socket, :info, "Text source preference saved.")
        {:error, _changeset} ->
          # Failed to save preference but still update the current session
          socket = put_flash(socket, :error, "Could not save text source preference.")
      end
    end
    
    {:noreply, socket}
  end

  def handle_event("next_level", _params, socket) do
    # Only allow proceeding to next level if current level is complete
    if socket.assigns.game_state == :level_complete do
      new_level = socket.assigns.current_level + 1
      {_, user_id} = get_current_user(socket)
      
      # For registered users, update progress in database
      if user_id do
        {:ok, _} =
          Games.update_user_progress(socket.assigns.progress, %{
            current_level: new_level,
            total_score: socket.assigns.progress.total_score + socket.assigns.score
          })
      end
      
      # For both guest and registered users, update the socket assigns
      socket =
        socket
        |> assign(:current_level, new_level)
        |> assign(:game_state, :waiting)
        |> assign(:lives, 3)
        |> assign(:score, 0)
        |> assign(:texts_completed, 0)
        |> assign(:last_sound_event, "levelup")
        |> reset_timer()

      {:noreply, socket}
    else
      # If level not complete, don't allow progression
      {:noreply, socket}
    end
  end

  def handle_event("reset_game", _params, socket) do
    socket =
      socket
      |> assign(:current_level, 1)
      |> assign(:game_state, :waiting)
      |> assign(:score, 0)
      |> assign(:lives, 3)
      |> assign(:typed_text, "")
      |> assign(:texts_completed, 0)
      |> reset_timer()

    {:noreply, socket}
  end

  def handle_info(:timer_tick, socket) do
    time_left = socket.assigns.time_left - 1

    if time_left <= 0 do
      # Check if any progress has been made (require at least some typing)
      socket = if socket.assigns.current_index > 0 do
        # Complete level only if player has typed something
        complete_level(socket)
      else
        # End game if time ran out without typing
        socket
        |> assign(:game_state, :game_over)
        |> assign(:last_sound_event, "incorrect")
        |> reset_timer()
      end
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

  # calculate_time_left has been moved to GameHelpers

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
        # Mistake made - don't update typed_text and sync input field
        socket
        |> assign(:last_sound_event, "incorrect")
        |> handle_mistake()
        |> update_stats(socket.assigns.typed_text, false)
        |> maybe_push_sync_event(typed_text)
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

    # Save game session (only for authenticated users)
    {_current_user, user_id} = get_current_user(socket)
    
    # Only save sessions for authenticated users
    if user_id do
      Games.create_game_session(%{
        user_id: user_id,
        level: socket.assigns.current_level,
        score: score_earned,
        wpm: wpm,
        accuracy: socket.assigns.accuracy,
        time_taken: elapsed_time
      })
    end

    # Increment the text completion counter
    texts_completed = socket.assigns.texts_completed + 1
    
    # Get required number of texts per level - higher levels require more texts
    texts_required = cond do
      socket.assigns.current_level <= 5 -> 2
      socket.assigns.current_level <= 10 -> 3
      socket.assigns.current_level <= 15 -> 4
      true -> 5
    end
    
    # Check if player has completed enough texts to advance a level
    if texts_completed >= texts_required do
      # Level complete!
      complete_level(socket |> assign(:score, new_score) |> assign(:texts_completed, 0))
    else
      # Not enough texts completed yet, generate new text and continue
      new_text = Games.get_typing_text(
        socket.assigns.current_level,
        socket.assigns.selected_source
      )

      socket
      |> assign(:score, new_score)
      |> assign(:texts_completed, texts_completed)
      |> assign(:current_text, new_text)
      |> assign(:typed_text, "")
      |> assign(:current_index, 0)
      |> assign(:start_time, System.monotonic_time(:second))
      |> assign(:last_sound_event, "complete")
    end
  end

  defp complete_level(socket) do
    # Calculate typing progress percentage
    current_text = socket.assigns.current_text
    progress_percentage = if String.length(current_text) > 0 do
      socket.assigns.current_index / String.length(current_text) * 100
    else
      0
    end

    # Require at least 30% completion of the text to pass a level
    # This prevents getting credit for minimal typing
    if progress_percentage >= 30 do
      socket
      |> assign(:game_state, :level_complete)
      |> assign(:last_sound_event, "levelup")
      |> reset_timer()
    else
      # Not enough typing progress to complete level
      socket
      |> assign(:game_state, :game_over)
      |> assign(:last_sound_event, "incorrect")
      |> reset_timer()
    end
  end

  defp handle_mistake(socket) do
    # Get current user (either authenticated or guest)
    {current_user, _user_id} = get_current_user(socket)
    
    # Check if live_check is enabled for the current user
    should_decrement_lives = current_user.live_check != false

    # Only decrement lives if needed
    new_lives = if should_decrement_lives do
      lives = socket.assigns.lives - 1
      if lives < 0, do: 0, else: lives
    else
      socket.assigns.lives
    end

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
          GameHelpers.count_correct_chars(typed_text, String.slice(current_text, 0, typed_length))

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

  # count_correct_chars has been moved to GameHelpers

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

  # Helper to get current user or create a guest user if not authenticated
  defp get_current_user(socket) do
    if socket.assigns[:current_scope] && socket.assigns.current_scope.user do
      # Authenticated user
      user = socket.assigns.current_scope.user
      {user, user.id}
    else
      # Guest user
      guest_user = Accounts.create_guest_user()
      {guest_user, nil}
    end
  end

  # Helper for rendering character states - delegated to GameHelpers
  def char_class(index, current_index, typed_text, original_text) do
    GameHelpers.char_class(index, current_index, typed_text, original_text)
  end
  
  # Helper to get the user's preferred text source
  defp get_user_text_source_preference(user) do
    if user.selected_source do
      # Convert string from database to atom
      case user.selected_source do
        "default" -> :default
        "zenquotes" -> :zenquotes
        "dummyjson" -> :dummyjson
        _ -> :zenquotes # Default fallback
      end
    else
      # Default if no preference is set
      :zenquotes
    end
  end

  # View helpers delegated to GameHelpers
  defp level_description(level) do
    GameHelpers.level_description(level)
  end

  defp lives_message(lives) do
    GameHelpers.lives_message(lives)
  end

  defp progress_percentage(index, text) do
    GameHelpers.progress_percentage(index, text)
  end
end
