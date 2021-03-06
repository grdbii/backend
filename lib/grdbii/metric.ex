defmodule Grdbii.Metric do
  alias Grdbii.{Error, Repo, Python}
  use Ecto.Schema
  import Ecto.Changeset

  @calculations [
    :metric,
    :christoffel,
    :riemann,
    :weyl,
    :ricci_tensor,
    :ricci_scalar,
    :einstein
  ]

  schema "metrics" do
    field :name, :string
    field :coordinate_type, :string

    field :pickle, :binary

    field :line_element, :string
    field :metric, {:array, :string}
    field :coordinates, {:array, :string}
    field :variables, {:array, :string}
    field :functions, {:array, :string}

    field :symmetries, {:array, :string}
    field :references, {:array, :string}
    field :notes, {:array, :string}

    field :christoffel, {:array, :string}
    field :riemann, {:array, :string}
    field :weyl, {:array, :string}
    field :einstein, {:array, :string}
    field :ricci_tensor, {:array, :string}
    field :ricci_scalar, :string
  end

  def changeset(%__MODULE__{} = metric, params \\ %{}) do
    cast(metric, params, [:pickle | @calculations])
  end

  def calculate(%__MODULE__{pickle: pickle} = metric, attr) when attr in @calculations do
    with nil <- Map.fetch!(metric, attr),
         {:ok, {result, pickle}} <- Python.calculate(:python, pickle, attr) do
      changeset = changeset(metric, Map.new([{attr, parse(result)}, {:pickle, pickle}]))
      Repo.update!(changeset)
    else
      x when x in [[], ""] ->
        raise Error.TooComplex

      {:error, %Error.TimeoutError{}} ->
        sentinel = if attr == :ricci_scalar, do: "", else: []
        changeset = changeset(metric, Map.new([{attr, sentinel}]))
        Repo.update!(changeset)
        raise Error.TimeoutError

      _ ->
        metric
    end
  end

  def from_python(metric) do
    metric
    |> Map.new(&{List.to_atom(elem(&1, 0)), parse(elem(&1, 1))})
    |> (&struct(__MODULE__, &1)).()
  end

  defp parse(value) when value in [[], ""], do: nil
  defp parse([h | t]) when is_list(h), do: Enum.map([h | t], &to_string/1)
  defp parse(value), do: to_string(value)
end
