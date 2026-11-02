# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Resource.Verifiers.VerifyFieldResources do
  @moduledoc """
  Ensures that a field with the `resource` option references an action
  argument of the resource, points to an Ash resource with a `label_field`,
  and does not also set a text `type`.
  """

  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  def verify(dsl_state) do
    dsl_state
    |> AshAdmin.Resource.fields()
    |> Enum.reject(&is_nil(&1.resource))
    |> Enum.reduce_while(:ok, fn field, :ok ->
      case verify_field(dsl_state, field) do
        :ok -> {:cont, :ok}
        {:error, message} -> {:halt, {:error, error(dsl_state, field, message)}}
      end
    end)
  end

  defp verify_field(dsl_state, field) do
    cond do
      not argument_exists?(dsl_state, field.name) ->
        {:error,
         "`#{field.name}` has `resource` set but `#{module_name(dsl_state)}` has no action with an argument named `#{field.name}`."}

      field.type not in [nil, :default] ->
        {:error,
         "`#{field.name}` sets both `resource` and `type: #{inspect(field.type)}`. A field with `resource` renders as a relationship field, so remove `type`."}

      not Ash.Resource.Info.resource?(field.resource) ->
        {:error,
         "`#{field.name}` has `resource: #{inspect(field.resource)}`, but `#{inspect(field.resource)}` is not an Ash resource."}

      is_nil(AshAdmin.Resource.label_field(field.resource)) ->
        {:error,
         "`#{field.name}` has `resource: #{inspect(field.resource)}`, but `#{inspect(field.resource)}` has no `label_field` in its `admin` section."}

      true ->
        :ok
    end
  end

  defp error(dsl_state, field, message) do
    Spark.Error.DslError.exception(
      message: message,
      path: [:admin, :form, :field, field.name],
      module: Verifier.get_persisted(dsl_state, :module)
    )
  end

  defp module_name(dsl_state) do
    String.trim_leading(to_string(Verifier.get_persisted(dsl_state, :module)), "Elixir.")
  end

  defp argument_exists?(dsl_state, name) do
    dsl_state
    |> Ash.Resource.Info.actions()
    |> Enum.flat_map(fn action -> action.arguments end)
    |> Enum.any?(&(&1.name == name))
  end
end
