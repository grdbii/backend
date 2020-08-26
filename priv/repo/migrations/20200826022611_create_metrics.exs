defmodule Grdbii.Repo.Migrations.CreateMetrics do
  use Ecto.Migration

  def change do
    create table(:metrics) do
      add :name, :string

      add :pickle, :binary

      add :line_element, :text
      add :metric, {:array, :text}
      add :coordinates, {:array, :text}
      add :variables, {:array, :text}
      add :functions, {:array, :text}

      add :symmetries, {:array, :text}
      add :references, {:array, :text}
      add :notes, {:array, :text}

      add :christoffel, {:array, :text}
      add :riemann, {:array, :text}
      add :weyl, {:array, :text}
      add :einstein, {:array, :text}
      add :ricci_tensor, {:array, :text}
      add :ricci_scalar, :text
    end
  end
end
