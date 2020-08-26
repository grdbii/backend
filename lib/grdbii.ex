defmodule Grdbii do
  alias Grdbii.{Metric, Repo}
  use Plug.Router
  use Plug.ErrorHandler

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Poison

  plug :match
  plug :dispatch

  @bad_request %{
    code: :bad_request,
    type: :invalid_parameter,
    message: "Could not parse request parameter."
  }

  @timeout_error %{
    code: :internal_server_error,
    type: :timeout_error,
    message: "Server timed out. Request took to long to process."
  }

  @internal_server_error %{
    code: :internal_server_error,
    type: :unexpected_error,
    message: """
    An unexpected error occured on the server, please contact the maintainer of the site.
    """
  }

  def handle_errors(conn, %{reason: reason}) do
    resp =
      case reason do
        %ErlangError{original: {:python, :"builtins.TimeoutError", _, _}} -> @timeout_error
        %ArgumentError{} -> @bad_request
        _ -> @internal_server_error
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(resp.code, Poison.encode!(%{error: resp}))
  end

  get "/search" do
    query = String.trim(conn.params["q"])

    if query == "" do
      send_resp(conn, :no_content, "")
    else
      resp =
        Metric
        |> Repo.search("#{query}:*", 7)
        |> Poison.encode!()

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(:ok, resp)
    end
  end

  get "/calc" do
    metric = Repo.get(Metric, conn.params["id"])
    attr = String.to_existing_atom(conn.params["attr"])
    {:ok, result} = Metric.calculate(metric, attr)

    resp =
      result
      |> Map.fetch!(attr)
      |> Poison.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, resp)
  end

  match _, do: send_resp(conn, :not_found, "Unknown request")
end
