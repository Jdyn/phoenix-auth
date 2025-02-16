defmodule Nimble.Web do
  @moduledoc false

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Multi
      import Ecto.Query

      # `:binary_id` does not support `:autogenerate` tuples
      # so we have to use `Ecto.UUID` or `Uniq.UUID` type.
      @primary_key {:id, Ecto.UUID, autogenerate: {Uniq.UUID, :uuid7, []}}

      # For foreign keys, we can use either `:binary_id` or UUID types
      @foreign_key_type :binary_id

      # parse timestamps as `DateTime` (for better ISO 8601 serialization)
      @timestamps_opts [type: :utc_datetime]
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: Nimble, formats: [:json]

      import Ecto.Query
      import Plug.Conn

      alias Nimble.Router.Helpers, as: Routes

      def current_user(conn), do: conn.assigns[:current_user]
    end
  end

  def context do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]
    end
  end

  def router do
    quote do
      use Phoenix.Router
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
