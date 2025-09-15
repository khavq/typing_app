defmodule TypingAppWeb.PageController do
  use TypingAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
