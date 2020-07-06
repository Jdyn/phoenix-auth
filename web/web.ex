defmodule Nimble do

  def view do
    quote do
      import Phoenix.View

      import Nimble.ErrorHelpers
      alias Nimble.Router.Helpers, as: Routes
    end
  end

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]

      @timestamps_opts [type: :utc_datetime]
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: Nimble

      import Plug.Conn
      alias Nimble.Router.Helpers, as: Routes
    end
  end

  def service do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
