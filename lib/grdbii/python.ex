defmodule Grdbii.Python do
  alias Grdbii.Error
  use Export.Python
  use GenServer

  @timeout 12_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl true
  def init(_), do: Python.start_link(python_path: Path.expand("priv/python"))

  @impl true
  def handle_call({:fetch, timeout}, _from, python) do
    try do
      python_lib = Application.fetch_env!(:grdbii, :python_lib)

      python
      |> Python.call("grdbii", "fetch", ["#{python_lib}/site-packages/riccipy/metrics", timeout])
      |> (&{:reply, {:ok, &1}, python}).()
    rescue
      ErlangError -> {:reply, {:error, %Error.TimeoutError{}}, python}
    end
  end

  @impl true
  def handle_call({:calculate, pickle, attr, timeout}, _from, python) do
    try do
      python
      |> Python.call("grdbii", "calculate", [pickle, attr, timeout])
      |> (&{:reply, {:ok, &1}, python}).()
    rescue
      ErlangError -> {:reply, {:error, %Error.TimeoutError{}}, python}
    end
  end

  def fetch(pool, timeout \\ @timeout) do
    action = &GenServer.call(&1, {:fetch, timeout}, :infinity)
    :poolboy.transaction(pool, action, :infinity)
  end

  def calculate(pool, pickle, attr, timeout \\ @timeout) do
    action = &GenServer.call(&1, {:calculate, pickle, attr, timeout}, :infinity)
    :poolboy.transaction(pool, action, :infinity)
  end

  def fetch!(pool, timeout \\ @timeout) do
    case fetch(pool, timeout) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  def calculate!(pool, pickle, attr, timeout \\ @timeout) do
    case calculate(pool, pickle, attr, timeout) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end
end
