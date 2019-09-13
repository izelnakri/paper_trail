item_type = case Application.get_env(:paper_trail, :item_type, :integer) do
  :integer -> {:id, :id, autogenerate: true}
  Ecto.UUID -> {:id, :binary_id, autogenerate: true}
end

defmodule Assoc do
  defmodule Post do
    use Ecto.Schema
    import Ecto.Changeset

    schema "assoc_posts" do
      field :name, :string
      field :content, :string
      has_many :comments, Assoc.Comment, on_delete: :delete_all

      timestamps()
    end

    @fields ~w[name content]a

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, @fields)
      |> cast_assoc(:comments)
    end
  end

  defmodule Comment do
    use Ecto.Schema
    import Ecto.Changeset

    schema "assoc_comments" do
      field :content, :string

      belongs_to :post, Assoc.Post

      timestamps()
    end

    @fields ~w[content]a

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, @fields)
      |> cast_assoc(:post)
    end
  end
end

defmodule Embed do

  defmodule Make do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key item_type
    schema "embed_makes" do
      field :name, :string
      has_many :cars, Embed.Car, on_delete: :nilify_all, foreign_key: :make_id

      timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:name])
      |> cast_assoc(:cars)
    end
  end

  defmodule Car do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key item_type
    schema "embed_cars" do
      field :model, :string
      belongs_to :make, Embed.Make
      embeds_many :extras, Embed.Extra

      timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:model])
      |> cast_assoc(:make)
      |> cast_embed(:extras)
    end
  end

  defmodule Extra do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
      field :price, :float
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:name, :price])
    end
  end
end
