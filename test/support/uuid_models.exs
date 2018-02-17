defmodule Product do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "products" do
    field(:name, :string)

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end

defmodule Admin do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "admins" do
    field(:email, :string)

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:email])
    |> validate_required([:email])
  end
end

defmodule Item do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:item_id, :binary_id, autogenerate: true}
  schema "items" do
    field(:title, :string)

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:title])
    |> validate_required(:title)
  end
end
