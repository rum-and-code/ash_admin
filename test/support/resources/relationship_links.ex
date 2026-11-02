# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

# Fixtures for the belongs_to foreign key links. They are not part of an admin
# domain, so they do not show in the admin UI.

defmodule AshAdmin.Test.HiddenDomain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshAdmin.Test.HiddenTarget)
  end
end

defmodule AshAdmin.Test.HiddenTarget do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.HiddenDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end
end

defmodule AshAdmin.Test.LinkDomain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshAdmin.Test.LinkedNote)
    resource(AshAdmin.Test.UnlinkedNote)
  end
end

defmodule AshAdmin.Test.LinkedNote do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    belongs_to(:post, AshAdmin.Test.Post, public?: true, domain: AshAdmin.Test.Domain)
    belongs_to(:hidden_target, AshAdmin.Test.HiddenTarget, public?: true)
  end
end

defmodule AshAdmin.Test.UnlinkedNote do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  admin do
    link_relationships?(false)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    belongs_to(:post, AshAdmin.Test.Post, public?: true, domain: AshAdmin.Test.Domain)
  end
end
