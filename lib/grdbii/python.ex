defmodule Grdbii.Python do
  use Export.Python
  use GenServer

  @timeout 12_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl true
  def init(_), do: Python.start_link(python_path: Path.expand("priv/python"))

  @impl true
  def handle_call({:fetch, timeout}, _from, python) do
    python_lib = Application.fetch_env!(:grdbii, :python_lib)

    python
    |> Python.call("grdbii", "fetch", ["#{python_lib}/site-packages/riccipy/metrics", timeout])
    |> (&{:reply, &1, python}).()
  end

  @impl true
  def handle_call({:calculate, pickle, attr, timeout}, _from, python) do
    python
    |> Python.call("grdbii", "calculate", [pickle, attr, timeout])
    |> (&{:reply, &1, python}).()
  end

  def fetch(pool, timeout \\ @timeout) do
    action = &GenServer.call(&1, {:fetch, timeout}, :infinity)
    :poolboy.transaction(pool, action, :infinity)
  end

  def calculate(pool, pickle, attr, timeout \\ @timeout) do
    action = &GenServer.call(&1, {:calculate, pickle, attr, timeout}, :infinity)
    :poolboy.transaction(pool, action, :infinity)
  end
end
