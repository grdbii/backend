defmodule Grdbii.Metric do
  alias Grdbii.{Repo, Python}
  use Ecto.Schema
  import Ecto.Changeset

  @calculations [
    :christoffel,
    :riemann,
    :weyl,
    :ricci_tensor,
    :ricci_scalar,
    :einstein
  ]

  schema "metrics" do
    field(:name, :string)

    field(:pickle, :binary)

    field(:line_element, :string)
    field(:metric, {:array, :string})
    field(:coordinates, {:array, :string})
    field(:variables, {:array, :string})
    field(:functions, {:array, :string})

    field(:symmetries, {:array, :string})
    field(:references, {:array, :string})
    field(:notes, {:array, :string})

    field(:christoffel, {:array, :string})
    field(:riemann, {:array, :string})
    field(:weyl, {:array, :string})
    field(:einstein, {:array, :string})
    field(:ricci_tensor, {:array, :string})
    field(:ricci_scalar, :string)
  end

  def changeset(%__MODULE__{} = metric, params \\ %{}) do
    cast(metric, params, [:pickle | @calculations])
  end

  def calculate(%__MODULE__{pickle: pickle} = metric, attr) when attr in @calculations do
    case Map.fetch!(metric, attr) do
      nil ->
        try do
          {result, pickle} = Python.calculate(:python, pickle, attr)
          changeset = changeset(metric, Map.new([{attr, parse(result)}, {:pickle, pickle}]))
          Repo.update(changeset)
        rescue
          reason ->
            case reason do
              %ErlangError{original: {:python, error, _, _}} -> handle_error(metric, attr, error)
              _ -> :noop
            end

            raise reason
        end

      x when x in [[], ""] ->
        {:error, :too_complex}

      _ ->
        {:ok, metric}
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

  defp handle_error(metric, :ricci_scalar, :"builtins.TimeoutError") do
    changeset = changeset(metric, %{ricci_scalar: ""})
    Repo.update(changeset)
  end

  defp handle_error(metric, attr, :"builtins.TimeoutError") do
    changeset = changeset(metric, Map.new([{attr, []}]))
    Repo.update(changeset)
  end

  defp handle_error(_metric, _attr, _reason), do: :noop
end
