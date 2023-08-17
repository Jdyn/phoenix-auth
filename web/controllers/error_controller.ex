defmodule Nimble.ErrorController do
  use Nimble.Web, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(Nimble.ErrorJSON)
    |> render(:changeset_error, changeset: changeset)
  end

  def call(conn, {:not_found, reason}) do
    conn
    |> put_status(:not_found)
    |> put_view(Nimble.ErrorJSON)
    |> render(:error, error: reason)
  end

  def call(conn, {:unauthorized, reason}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(Nimble.ErrorJSON)
    |> render(:error, error: reason)
  end

  def call(conn, {:error, %Assent.RequestError{} = error}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(Nimble.ErrorJSON)
    |> render(:error, error: error.message)
  end
end
