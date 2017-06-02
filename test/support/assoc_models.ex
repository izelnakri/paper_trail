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
