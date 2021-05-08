defmodule Nimble.ErrorView do
  use Nimble.Web, :view

  alias Nimble.ErrorHelpers

  # Customize a particular status code:
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  def render("changeset_error.json", %{changeset: changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        ErrorHelpers.translate_error({msg, opts})
      end)

    %{
      ok: false,
      errors: errors
    }
  end

  def render("error.json", %{error: reason}) do
    %{
      ok: false,
      error: reason
    }
  end
end
