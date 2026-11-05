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

  defmodule Coupon do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshAdmin.Resource]

    admin do
      label_field :code
    end

    actions do
      defaults([:read])
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:code, :string, public?: true)
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
        field :email, type: :short_text

        action :apply_coupon do
          field :coupon_id, resource: Coupon
          field :email, type: :long_text
        end
      end
    end

    actions do
      defaults([:read])

      create :invite do
        accept([:email])
        argument(:organization_id, :uuid)
        argument(:note, :string)
      end

      update :apply_coupon do
        accept([:email])
        argument(:coupon_id, :uuid)
      end

      update :redeem_gift_card do
        argument(:coupon_id, :uuid)
      end
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:email, :string, public?: true)
    end
  end

  defp field(name, action_name \\ :invite) do
    action = Ash.Resource.Info.action(Member, action_name)
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

  describe "action block" do
    test "a field in an action block applies to that action" do
      assert %{related_resource: Coupon} = field(:coupon_id, :apply_coupon)
    end

    test "it does not apply to other actions with the same argument" do
      refute Map.has_key?(field(:coupon_id, :redeem_gift_card), :related_resource)
    end

    test "it replaces the form-level field for that action" do
      assert AshAdmin.Resource.field(Member, :email, :apply_coupon).type == :long_text
      assert AshAdmin.Resource.field(Member, :email, :invite).type == :short_text
      assert AshAdmin.Resource.field(Member, :email).type == :short_text
    end

    test "form-level fields still apply to every action" do
      assert %{related_resource: Organization} = field(:organization_id, :invite)
    end

    test "fields/1 only returns form-level fields" do
      assert Enum.map(AshAdmin.Resource.fields(Member), & &1.name) == [:organization_id, :email]
    end
  end

  describe "VerifyFormActions" do
    test "rejects an action block for an unknown action" do
      warnings =
        compile_warnings(
          quote do
            admin do
              form do
                action :missing do
                  field :note, type: :long_text
                end
              end
            end
          end
        )

      assert warnings =~ "has no action named `missing`"
    end

    test "rejects a field that is not an input of the action" do
      warnings =
        compile_warnings(
          quote do
            admin do
              form do
                action :invite do
                  field :note, type: :long_text
                end
              end
            end

            actions do
              create :invite do
                argument(:organization_id, :uuid)
              end
            end
          end
        )

      assert warnings =~ "is not an argument or an accepted attribute of that action"
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

    test "rejects a field in an action block whose action has no such argument" do
      warnings =
        compile_warnings(
          quote do
            admin do
              form do
                action :invite do
                  field :organization_id,
                    resource: AshAdmin.Test.FieldResourceTest.Organization
                end
              end
            end

            attributes do
              attribute(:organization_id, :uuid, public?: true)
            end

            actions do
              create :invite do
                accept([:organization_id])
              end
            end
          end
        )

      assert warnings =~ "the `invite` action of"
      assert warnings =~ "has no argument named `organization_id`"
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
