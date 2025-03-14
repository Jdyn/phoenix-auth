defmodule Nimble.ErrorController do
  use Nimble.Web, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(Nimble.ErrorJSON)
    |> render(:changeset_error, changeset: changeset)
  end

  def call(conn, {:error, _key, %Ecto.Changeset{} = changeset, _}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(Nimble.ErrorJSON)
    |> render(:changeset_error, changeset: changeset)
  end

  def call(conn, {:error, reason}) when is_binary(reason) do
    conn
    |> put_status(:not_found)
    |> put_view(Nimble.ErrorJSON)
    |> render(:error, error: reason)
  end

  def call(conn, {:not_found, reason}) when is_binary(reason) do
    conn
    |> put_status(:not_found)
    |> put_view(Nimble.ErrorJSON)
    |> render(:error, error: reason)
  end

  def call(conn, {:unauthorized, reason}) when is_binary(reason) do
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

  def call(conn, {:error, %Assent.InvalidResponseError{response: %Assent.HTTPAdapter.HTTPResponse{body: body}}}) do
    reason = Map.get(body, "error", "An unexpected OAuth error occurred. Please try again.")

    conn
    |> put_status(:unauthorized)
    |> put_view(Nimble.ErrorJSON)
    |> render(:error, error: reason)
  end
end
