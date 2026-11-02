# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

# Fixtures for the show page layout: boxed attribute values, calculations in
# the main panel and relationships in tabs.

defmodule AshAdmin.Test.ShowDomain do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource(AshAdmin.Test.ShowAuthor)
    resource(AshAdmin.Test.ShowBook)
    resource(AshAdmin.Test.ShowArticle)
  end
end

defmodule AshAdmin.Test.ShowAuthor do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.ShowDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  attributes do
    uuid_primary_key(:id)
    attribute(:first_name, :string, public?: true)
    attribute(:last_name, :string, public?: true)
    attribute(:email, :ci_string, public?: true)
    attribute(:nicknames, {:array, :string}, public?: true, default: [])
  end

  actions do
    default_accept(:*)
    defaults([:read, :create])
  end

  calculations do
    calculate(:full_name, :string, expr(first_name <> " " <> last_name), public?: true)

    calculate :greeting, :string, expr("Hello " <> ^arg(:salutation)) do
      public?(true)
      argument(:salutation, :string, allow_nil?: false)
    end
  end

  admin do
    show_calculations([:full_name, :greeting])
  end

  relationships do
    has_many(:books, AshAdmin.Test.ShowBook, public?: true, destination_attribute: :author_id)

    has_many(:articles, AshAdmin.Test.ShowArticle,
      public?: true,
      destination_attribute: :author_id
    )
  end
end

defmodule AshAdmin.Test.ShowBook do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.ShowDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, public?: true)
  end

  actions do
    default_accept(:*)
    defaults([:read, :create])
  end

  relationships do
    belongs_to(:author, AshAdmin.Test.ShowAuthor, public?: true)
  end
end

defmodule AshAdmin.Test.ShowArticle do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.ShowDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
    attribute(:headline, :string, public?: true)
  end

  actions do
    default_accept(:*)
    defaults([:read, :create])
  end

  relationships do
    belongs_to(:author, AshAdmin.Test.ShowAuthor, public?: true)
  end
end
