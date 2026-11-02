# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.FieldResourceTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias AshAdmin.Components.Resource.Form

  defmodule Domain do
    @moduledoc false
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      allow_unregistered?(true)
    end
  end

  defmodule Organization do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshAdmin.Resource]

    admin do
      label_field :name
    end

    actions do
      defaults([:read])
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, public?: true)
    end
  end

  defmodule Tag do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshAdmin.Resource]

    actions do
      defaults([:read])
    end

    attributes do
      uuid_primary_key(:id)
    end
  end

  defmodule Member do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshAdmin.Resource]

    admin do
      form do
        field :organization_id, resource: Organization
      end
    end

    actions do
      defaults([:read])

      create :invite do
        accept([:email])
        argument(:organization_id, :uuid)
        argument(:note, :string)
      end
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:email, :string, public?: true)
    end
  end

  defp field(name) do
    action = Ash.Resource.Info.action(Member, :invite)
    {auto_sorted, _flags, _defaults, _relationship_args} = Form.attributes(Member, action)
    Enum.find(auto_sorted, &(&1.name == name))
  end

  describe "field resource option" do
    test "an argument with a field resource gets its related resource" do
      assert %{related_resource: Organization} = field(:organization_id)
    end

    test "other arguments are left unchanged" do
      refute Map.has_key?(field(:note), :related_resource)
    end

    test "the label drops the _id suffix" do
      assert AshAdmin.Helpers.to_name(field(:organization_id)) == "Organization"
    end
  end

  describe "VerifyFieldResources" do
    defp compile_warnings(fields_and_actions) do
      name = Module.concat(__MODULE__, "Bad#{System.unique_integer([:positive])}")

      capture_io(:stderr, fn ->
        Code.eval_quoted(
          quote do
            defmodule unquote(name) do
              use Ash.Resource,
                domain: AshAdmin.Test.FieldResourceTest.Domain,
                data_layer: Ash.DataLayer.Ets,
                extensions: [AshAdmin.Resource]

              unquote(fields_and_actions)

              attributes do
                uuid_primary_key(:id)
              end
            end
          end
        )
      end)
    end

    test "rejects a field that is not an action argument" do
      warnings =
        compile_warnings(
          quote do
            admin do
              form do
                field :organization_id, resource: AshAdmin.Test.FieldResourceTest.Organization
              end
            end
          end
        )

      assert warnings =~ "has no action with an argument named `organization_id`"
    end

    test "rejects a field that also sets a text type" do
      warnings =
        compile_warnings(
          quote do
            admin do
              form do
                field :organization_id,
                  resource: AshAdmin.Test.FieldResourceTest.Organization,
                  type: :short_text
              end
            end

            actions do
              create :invite do
                argument(:organization_id, :uuid)
              end
            end
          end
        )

      assert warnings =~ "sets both `resource` and `type: :short_text`"
    end

    test "rejects a target resource with no label_field" do
      warnings =
        compile_warnings(
          quote do
            admin do
              form do
                field :tag_id, resource: AshAdmin.Test.FieldResourceTest.Tag
              end
            end

            actions do
              create :tag do
                argument(:tag_id, :uuid)
              end
            end
          end
        )

      assert warnings =~ "has no `label_field`"
    end

    test "rejects a target that is not an Ash resource" do
      warnings =
        compile_warnings(
          quote do
            admin do
              form do
                field :thing_id, resource: String
              end
            end

            actions do
              create :thing do
                argument(:thing_id, :uuid)
              end
            end
          end
        )

      assert warnings =~ "is not an Ash resource"
    end

    test "accepts a valid configuration" do
      warnings =
        compile_warnings(
          quote do
            admin do
              form do
                field :organization_id, resource: AshAdmin.Test.FieldResourceTest.Organization
              end
            end

            actions do
              create :invite do
                argument(:organization_id, :uuid)
              end
            end
          end
        )

      refute warnings =~ "VerifyFieldResources"
      refute warnings =~ "`organization_id`"
    end
  end
end
