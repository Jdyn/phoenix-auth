defmodule Nimble.ErrorJSON do
  alias Nimble.Errors

  # Customize a particular status code:
  def render("404.json", _assigns) do
    %{errors: %{detail: "Not Found"}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal Server Error"}}
  end

  def changeset_error(%{changeset: changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Errors.translate_error({msg, opts})
      end)

    %{
      errors: errors
    }
  end

  def error(%{error: reason}) do
    %{
      error: reason
    }
  end
end
