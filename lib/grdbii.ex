defmodule Grdbii do
  alias Grdbii.{Error, Metric, Repo}
  import Ecto.Query, only: [from: 2]
  use Plug.Router
  use Plug.ErrorHandler

  plug Plug.Logger
  plug CORSPlug

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Poison

  plug :match
  plug :dispatch

  def handle_errors(conn, %{reason: reason}) do
    resp =
      case reason do
        %Error.TooComplex{} -> %Error.TooComplex{}
        %Error.TimeoutError{} -> %Error.TimeoutError{}
        %ArgumentError{} -> %Error.InvalidParameter{}
        %FunctionClauseError{} -> %Error.InvalidParameter{}
        %Ecto.Query.CastError{} -> %Error.InvalidParameter{}
        %Ecto.Query.CompileError{} -> %Error.InvalidParameter{}
        _ -> %Error.InternalError{}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(resp.code, Poison.encode!(%{error: resp}))
  end

  get "/list" do
    offset =
      conn.params
      |> Map.get("p", "0")
      |> String.to_integer()

    limit =
      conn.params
      |> Map.get("limit", "10")
      |> String.to_integer()

    query =
      from Metric,
        select: [:id, :name],
        distinct: :name,
        limit: ^limit,
        offset: ^offset,
        order_by: :id

    resp =
      Repo.all(query)
      |> Enum.map(&Map.take(&1, [:id, :name]))
      |> (&%{list: &1, p: offset + limit}).()
      |> Poison.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, resp)
  end

  get "/variants" do
    query = from Metric, where: [name: ^conn.params["name"]], order_by: [asc: :id]

    resp =
      Repo.all(query)
      |> Stream.map(&Map.from_struct/1)
      |> Stream.map(&Map.drop(&1, [:pickle, :__meta__]))
      |> Poison.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, resp)
  end

  get "/metric" do
    resp =
      Repo.get(Metric, conn.params["id"])
      |> Map.from_struct()
      |> Map.drop([:pickle, :__meta__])
      |> Poison.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, resp)
  end

  get "/search" do
    query = String.trim(conn.params["q"])
    limit = Map.get(conn.params, "limit", 7)

    if query == "" do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(:no_content, "")
    else
      resp =
        Metric
        |> Repo.search("#{query}:*", limit)
        |> Map.fetch!(:rows)
        |> Enum.map(fn [id, match] -> %{id: id, match: match} end)
        |> Poison.encode!()

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(:ok, resp)
    end
  end

  get "/calc" do
    metric = Repo.get(Metric, conn.params["id"])
    attr = String.to_existing_atom(conn.params["attr"])

    resp =
      metric
      |> Metric.calculate(attr)
      |> Map.fetch!(attr)
      |> Poison.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, resp)
  end

  match _, do: send_resp(conn, :not_found, "Unknown request")
end
