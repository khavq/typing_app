defmodule TypingAppWeb.UserLive.Settings do
  use TypingAppWeb, :live_view

  on_mount {TypingAppWeb.UserAuth, :require_sudo_mode}

  alias TypingApp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          Account Settings
          <:subtitle>Manage your account email address, password, and game settings</:subtitle>
        </.header>
      </div>

      <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
        <.input
          field={@email_form[:email]}
          type="email"
          label="Email"
          autocomplete="username"
          required
        />
        <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
      </.form>

      <div class="divider" />

      <.form
        for={@password_form}
        id="password_form"
        action={~p"/users/update-password"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <input
          name={@password_form[:email].name}
          type="hidden"
          id="hidden_user_email"
          autocomplete="username"
          value={@current_email}
        />
        <.input
          field={@password_form[:password]}
          type="password"
          label="New password"
          autocomplete="new-password"
          required
        />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          autocomplete="new-password"
        />
        <.button variant="primary" phx-disable-with="Saving...">
          Save Password
        </.button>
      </.form>

      <div class="divider" />
      
      <.header>
        Game Settings
        <:subtitle>Customize your gameplay experience</:subtitle>
      </.header>

      <.form for={@game_form} id="game_form" phx-submit="update_game_settings">
        <div class="space-y-4">
          <label class="flex items-center gap-4 cursor-pointer">
            <.input type="checkbox" field={@game_form[:sound_enabled]} />
            <div>
              <span class="font-medium">Sound Enabled</span>
              <p class="text-sm text-gray-500">Play sound effects while typing</p>
            </div>
          </label>
          
          <label class="flex items-center gap-4 cursor-pointer">
            <.input type="checkbox" field={@game_form[:live_check]} />
            <div>
              <span class="font-medium">Live Checking</span>
              <p class="text-sm text-gray-500">When enabled, mistakes will reduce lives. When disabled, practice without losing lives.</p>
            </div>
          </label>
        </div>
        
        <div class="mt-4">
          <.button variant="primary" phx-disable-with="Saving...">
            Save Game Settings
          </.button>
        </div>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)
    
    # Create the game settings form
    game_changeset = Accounts.change_user_game_settings(user, %{})

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:game_form, to_form(game_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  def handle_event("update_game_settings", %{"user" => game_params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_game_settings(user, game_params) do
      {:ok, updated_user} ->
        # Update the game form with the new values
        game_changeset = Accounts.change_user_game_settings(updated_user, %{})
        
        {:noreply, 
          socket
          |> put_flash(:info, "Game settings updated successfully.")
          |> assign(:game_form, to_form(game_changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, game_form: to_form(changeset, action: :insert))}
    end
  end
end
