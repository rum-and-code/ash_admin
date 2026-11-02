# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.Show do
  @moduledoc false
  use Phoenix.LiveComponent

  require Logger

  alias AshAdmin.Components.Resource.{Helpers.FormatHelper, SensitiveAttribute, Table}
  import AshAdmin.Helpers
  import AshAdmin.CoreComponents

  attr :resource, :any
  attr :record, :any, default: nil
  attr :domain, :any, default: nil
  attr :action, :any
  attr :authorizing, :boolean, default: false
  attr :actor, :any
  attr :tenant, :any
  attr :table, :any, required: true
  attr :prefix, :any, required: true

  @value_box_class "mt-1 block w-full min-h-[2.375rem] px-3 py-2 rounded-md border shadow-sm sm:text-sm break-words border-slate-300 bg-slate-50 text-slate-900 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-100"

  def render(assigns) do
    ~H"""
    <div class="md:pt-10 sm:mt-0">
      <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {render_show(assigns, @record, @resource, nil, true, true)}
        </div>
      </div>
      <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {render_relationships(assigns, @record, @resource)}
        </div>
      </div>
    </div>
    """
  end

  def render_show(
        assigns,
        record,
        resource,
        title \\ nil,
        buttons? \\ true,
        calculations? \\ false
      ) do
    assigns =
      assign(assigns,
        record: record,
        resource: resource,
        title: title,
        buttons: buttons?,
        show_calculations: calculations? && assigns[:calculations] not in [nil, []]
      )

    ~H"""
    <div class="shadow-sm ring-1 ring-slate-200 dark:ring-slate-700 overflow-hidden sm:rounded-md bg-white dark:bg-slate-900">
      <h1 :if={@title} class="pt-2 pl-4 text-lg">{@title}</h1>
      <button
        :if={AshAdmin.Resource.actor?(@resource)}
        class="float-right pt-4 pr-4"
        phx-click="set_actor"
        phx-value-resource={AshAdmin.Resource.name(@resource)}
        phx-value-domain={AshAdmin.Domain.name(@domain)}
        phx-value-pkey={encode_primary_key(@record)}
      >
        <.icon name="hero-key" class="h-5 w-5 text-slate-500 dark:text-slate-400" />
      </button>
      <div class="px-4 py-5 sm:p-6">
        <div>
          {render_attributes(assigns, @record, @resource)}
          <div :if={@show_calculations}>
            <div class="hidden sm:block" aria-hidden="true">
              <div class="py-5">
                <div class="border-t border-slate-200 dark:border-slate-700" />
              </div>
            </div>
            {render_calculations(assigns, @record, @resource)}
          </div>
          <div :if={@buttons} class="px-4 py-3 text-right sm:px-6">
            <.link
              :if={destroy?(@resource)}
              navigate={
                admin_path(@prefix,
                  domain: AshAdmin.Domain.name(@domain),
                  resource: AshAdmin.Resource.name(@resource),
                  action_type: "destroy",
                  table: @table,
                  primary_key: encode_primary_key(@record)
                )
              }
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-slate-800 hover:bg-slate-700 dark:bg-slate-200 dark:hover:bg-slate-300 dark:text-slate-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-500"
            >
              Destroy
            </.link>

            <.link
              :if={update?(@resource)}
              navigate={
                admin_path(@prefix,
                  domain: AshAdmin.Domain.name(@domain),
                  resource: AshAdmin.Resource.name(@resource),
                  action_type: "update",
                  table: @table,
                  primary_key: encode_primary_key(@record)
                )
              }
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-slate-800 hover:bg-slate-700 dark:bg-slate-200 dark:hover:bg-slate-300 dark:text-slate-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-500"
            >
              Update
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Submits the calculation form from an icon at the end of the value box.
  defp calculate_button(assigns) do
    ~H"""
    <button
      type="submit"
      title={@label}
      aria-label={@label}
      data-calculate
      class="flex-none rounded text-slate-500 hover:bg-slate-200 hover:text-slate-700 dark:text-slate-400 dark:hover:bg-slate-700 dark:hover:text-slate-300"
      style="padding: 0.125rem; margin: -0.125rem 0;"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 20 20"
        fill="none"
        stroke="currentColor"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
        class="h-4 w-4"
      >
        <rect x="4" y="2" width="12" height="16" rx="2" stroke-width="1.5" />
        <path d="M7 5.75h6" stroke-width="1.5" />
        <path
          d="M7.5 9.5h.01M10 9.5h.01M12.5 9.5h.01M7.5 12h.01M10 12h.01M12.5 12h.01M7.5 14.5h.01M10 14.5h.01M12.5 14.5h.01"
          stroke-width="2"
        />
      </svg>
    </button>
    """
  end

  @spec render_calculations(any(), any(), any()) :: Phoenix.LiveView.Rendered.t()
  def render_calculations(assigns, record, resource) do
    assigns =
      assign(assigns, record: record, resource: resource, value_box_class: @value_box_class)

    ~H"""
    <div class="grid grid-cols-6 gap-6">
      <div
        :for={{calculation, calculation_form} <- @calculations}
        id={"calculation-#{calculation.name}"}
        class="col-span-6 sm:col-span-3"
      >
        <div class="block text-sm font-medium text-slate-700 dark:text-slate-300">
          {to_name(calculation.name)}
        </div>
        <.form
          :let={form}
          id={"calculation-form-#{calculation.name}"}
          as={calculation.name}
          for={calculation_form}
          phx-change="validate-calculation"
          phx-submit="calculate"
          phx-target={@myself}
        >
          <.input type="hidden" name="calculation" value={calculation.name} />
          <div :if={calculation.arguments != []} class="mb-2">
            {AshAdmin.Components.Resource.Form.render_attributes(
              assigns,
              @resource,
              calculation,
              form
            )}
          </div>
          <div
            :if={!loaded?(@record, calculation.name)}
            class={classes([@value_box_class, "flex items-center justify-end"])}
          >
            {calculate_button(%{label: "Calculate"})}
          </div>
          <div :if={loaded?(@record, calculation.name)}>
            {render_field_value(
              assigns,
              @resource,
              @record,
              calculation,
              nil,
              calculation.arguments != [] && calculate_button(%{label: "Recalculate"})
            )}
          </div>
          <.error :if={@calculation_errors[calculation.name]}>
            {error_message(@calculation_errors[calculation.name])}
          </.error>
        </.form>
      </div>
    </div>
    """
  end

  defp render_relationships(assigns, record, resource) do
    relationships = AshAdmin.Components.Resource.Form.relationships(resource, :show)

    active =
      Enum.find(relationships, &(&1.name == assigns[:active_relationship])) ||
        List.first(relationships)

    assigns =
      assign(assigns,
        record: record,
        resource: resource,
        relationships: relationships,
        active: active
      )

    ~H"""
    <div :if={@active}>
      <div class="flex justify-center mb-4">
        <nav
          role="tablist"
          class="inline-flex flex-wrap gap-1 p-1 rounded-lg shadow-sm ring-1 ring-slate-200 dark:ring-slate-700 bg-white dark:bg-slate-900"
        >
          <button
            :for={relationship <- @relationships}
            id={"relationship-tab-#{relationship.name}"}
            type="button"
            role="tab"
            aria-selected={to_string(relationship.name == @active.name)}
            phx-click="select_relationship"
            phx-value-relationship={relationship.name}
            phx-target={@myself}
            class={
              classes([
                "px-3 py-1.5 text-sm font-medium rounded-md",
                "bg-slate-100 text-slate-900 dark:bg-slate-800 dark:text-slate-100":
                  relationship.name == @active.name,
                "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200":
                  relationship.name != @active.name
              ])
            }
          >
            {to_name(relationship.name)}
          </button>
        </nav>
      </div>
      <div
        id={"relationship-panel-#{@active.name}"}
        role="tabpanel"
        class="shadow-sm ring-1 ring-slate-200 dark:ring-slate-700 overflow-hidden sm:rounded-md bg-white dark:bg-slate-900"
      >
        <div class="flex items-center justify-between gap-4 px-4 py-3 border-b border-slate-200 dark:border-slate-700">
          <h2 class="text-base font-semibold text-slate-900 dark:text-slate-100">
            {to_name(@active.name)}
          </h2>
          <button
            :if={!loaded?(@record, @active.name)}
            phx-click="load"
            phx-target={@myself}
            phx-value-relationship={@active.name}
            type="button"
            class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-slate-800 hover:bg-slate-700 dark:bg-slate-200 dark:hover:bg-slate-300 dark:text-slate-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-500"
          >
            Load
          </button>
          <button
            :if={loaded?(@record, @active.name) && @active.cardinality == :many}
            phx-click="unload"
            phx-target={@myself}
            phx-value-relationship={@active.name}
            type="button"
            class="inline-flex justify-center py-2 px-4 border border-slate-300 dark:border-slate-600 shadow-sm text-sm font-medium rounded-md text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-500"
          >
            Unload
          </button>
        </div>
        <div class="px-4 py-5">
          <.error :if={@load_errors[@active.name]}>
            {error_message(@load_errors[@active.name])}
          </.error>
          <p
            :if={!loaded?(@record, @active.name) && !@load_errors[@active.name]}
            class="text-sm text-slate-500 dark:text-slate-400"
          >
            Not loaded.
          </p>
          <div :if={loaded?(@record, @active.name)}>
            {render_relationship_data(assigns, @record, @active)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(socket) do
    assign =
      socket
      |> assign_new(:load_errors, fn -> %{} end)
      |> assign_new(:calculation_errors, fn -> %{} end)
      |> assign_new(:active_relationship, fn -> nil end)

    {:ok, assign}
  end

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign_new(:calculations, fn %{resource: resource} ->
      calculations =
        AshAdmin.Resource.show_calculations(resource)

      resource
      |> Ash.Resource.Info.calculations()
      |> Enum.filter(&(&1.name in calculations))
      |> Enum.sort_by(
        &Enum.find_index(calculations, fn name ->
          name == &1.name
        end)
      )
      |> Enum.map(fn calculation ->
        form =
          AshPhoenix.FilterForm.Arguments.new(%{}, calculation.arguments)
          |> to_form()

        {calculation, form}
      end)
    end)
    |> then(&{:ok, &1})
  end

  defp render_relationship_data(assigns, record, %{
         cardinality: :one,
         name: name,
         destination: destination,
         context: context,
         domain: destination_domain
       }) do
    case Map.get(record, name) do
      nil ->
        "None"

      record ->
        assigns =
          assign(assigns,
            record: record,
            name: name,
            destination: destination,
            context: context,
            destination_domain: destination_domain,
            fields: AshAdmin.Resource.show_relationship_fields(assigns.resource, name)
          )

        ~H"""
        <div class="mb-10">
          {render_attributes(assigns, @record, @destination, @name, @fields)}
          <div class="px-4 py-3 text-right sm:px-6">
            <.link
              :if={AshAdmin.Resource.show_action(@destination)}
              navigate={
                admin_path(@prefix,
                  domain:
                    AshAdmin.Domain.name(
                      @destination_domain || Ash.Resource.Info.domain(@destination) || @domain
                    ),
                  resource: AshAdmin.Resource.name(@destination),
                  table: @context[:data_layer][:table],
                  primary_key: encode_primary_key(@record),
                  action_type: "read"
                )
              }
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-slate-800 hover:bg-slate-700 dark:bg-slate-200 dark:hover:bg-slate-300 dark:text-slate-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-500"
            >
              Show
            </.link>
          </div>
        </div>
        """
    end
  end

  defp render_relationship_data(assigns, record, %{
         cardinality: :many,
         name: name,
         destination: destination,
         context: context,
         destination_attribute: destination_attribute,
         domain: destination_domain
       }) do
    data = Map.get(record, name)

    assigns =
      assign(assigns,
        data: data,
        destination: destination,
        destination_domain: destination_domain,
        destination_format_fields: AshAdmin.Resource.format_fields(destination),
        context: context,
        destination_attribute: destination_attribute,
        relationship_name: name,
        fields: AshAdmin.Resource.show_relationship_fields(assigns.resource, name)
      )

    ~H"""
    <%!-- Keep each value on one line and scroll sideways instead of squeezing the columns. --%>
    <div class="overflow-x-auto [&_table]:m-0 [&_table]:w-full [&_th]:whitespace-nowrap [&_th]:pr-6 [&_td]:whitespace-nowrap [&_td]:pr-6">
      <Table.table
        data={@data}
        resource={@destination}
        attributes={@fields}
        format_fields={@destination_format_fields}
        domain={@destination_domain || Ash.Resource.Info.domain(@destination) || @domain}
        table={@context[:data_layer][:table]}
        prefix={@prefix}
        skip={[@destination_attribute]}
        relationship_name={@relationship_name}
        actor={@actor}
        tenant={@tenant}
        authorizing={@authorizing}
      />
    </div>
    """
  end

  defp render_attributes(assigns, record, resource, relationship_name \\ nil, fields \\ nil) do
    {attributes, flags, bottom_attributes} =
      case AshAdmin.Components.Resource.Form.attributes(resource, :show) do
        {attributes, flags, bottom_attributes, _} when is_nil(fields) ->
          {attributes, flags, bottom_attributes}

        _ ->
          # An explicit field list keeps the given order in a single grid.
          {Enum.map(fields, &Ash.Resource.Info.attribute(resource, &1)), [], []}
      end

    assigns =
      assign(assigns,
        record: record,
        resource: resource,
        attributes: attributes,
        flags: flags,
        bottom_attributes: bottom_attributes,
        relationship_name: relationship_name
      )

    ~H"""
    <div class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- @attributes}
        class={
          classes([
            "col-span-6",
            "sm:col-span-2": short_text?(@resource, attribute),
            "sm:col-span-3": !long_text?(@resource, attribute)
          ])
        }
      >
        <div class="block text-sm font-medium text-slate-700 dark:text-slate-300">
          {to_name(attribute.name)}
        </div>
        {render_field_value(assigns, @resource, @record, attribute, @relationship_name, nil)}
      </div>
    </div>
    <div :if={!Enum.empty?(@flags)} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-slate-200 dark:border-slate-700" />
      </div>
    </div>
    <div :if={!Enum.empty?(@flags)} class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- @flags}
        class={
          classes([
            "col-span-6",
            "sm:col-span-2": short_text?(@resource, attribute),
            "sm:col-span-3": !long_text?(@resource, attribute)
          ])
        }
      >
        <div class="block text-sm font-medium text-slate-700 dark:text-slate-300">
          {to_name(attribute.name)}
        </div>
        {render_field_value(assigns, @resource, @record, attribute, @relationship_name, nil)}
      </div>
    </div>
    <div :if={!Enum.empty?(@bottom_attributes)} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-slate-200 dark:border-slate-700" />
      </div>
    </div>
    <div :if={!Enum.empty?(@bottom_attributes)} class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- @bottom_attributes}
        class={
          classes([
            "col-span-6",
            "sm:col-span-2": short_text?(@resource, attribute),
            "sm:col-span-3":
              !(long_text?(@resource, attribute) || Ash.Type.embedded_type?(attribute.type))
          ])
        }
      >
        <div class="block text-sm font-medium text-slate-700 dark:text-slate-300">
          {to_name(attribute.name)}
        </div>
        {render_field_value(assigns, @resource, @record, attribute, @relationship_name, nil)}
      </div>
    </div>
    """
  end

  # Renders a field's value. Scalar values sit in a read-only box styled like an
  # input; structured values (maps, embedded resources) keep their own layout.
  # `button`, when given, is rendered at the end of the value.
  defp render_field_value(
         assigns,
         resource,
         record,
         attribute,
         relationship_name,
         button
       ) do
    assigns =
      assign(assigns,
        field_button: button || nil,
        value_box_class: @value_box_class,
        field_resource: resource,
        field_record: record,
        field_attribute: attribute,
        field_relationship_name: relationship_name,
        boxed: boxed?(attribute),
        long: long_text?(resource, attribute)
      )

    ~H"""
    <div
      :if={@boxed}
      data-field={@field_attribute.name}
      class={
        classes([
          @value_box_class,
          "flex items-start justify-between gap-2": @field_button,
          "whitespace-pre-wrap min-h-[5rem]": @long
        ])
      }
    >
      <%= if @field_button do %>
        <span class="min-w-0">
          {render_maybe_sensitive_attribute(
            assigns,
            @field_resource,
            @field_record,
            @field_attribute,
            @field_relationship_name
          )}
        </span>
        {@field_button}
      <% else %>
        {render_maybe_sensitive_attribute(
          assigns,
          @field_resource,
          @field_record,
          @field_attribute,
          @field_relationship_name
        )}
      <% end %>
    </div>
    <div :if={!@boxed}>
      {render_maybe_sensitive_attribute(
        assigns,
        @field_resource,
        @field_record,
        @field_attribute,
        @field_relationship_name
      )}
      {@field_button}
    </div>
    """
  end

  defp boxed?(%{type: type} = attribute),
    do: boxed_type?(type, Map.get(attribute, :constraints) || [])

  defp boxed_type?({:array, type}, constraints), do: boxed_type?(type, constraints[:items] || [])

  defp boxed_type?(Ash.Type.Union, constraints) do
    Enum.all?(constraints[:types] || [], fn {_name, config} ->
      boxed_type?(config[:type], config[:constraints] || [])
    end)
  end

  defp boxed_type?(type, _constraints) when type in [Ash.Type.Map, Ash.Type.Struct], do: false

  defp boxed_type?(type, constraints) do
    cond do
      Ash.Type.NewType.new_type?(type) ->
        boxed_type?(
          Ash.Type.NewType.subtype_of(type),
          Ash.Type.NewType.constraints(type, constraints)
        )

      Ash.Type.embedded_type?(type) ->
        false

      true ->
        true
    end
  end

  defp error_message(error) when is_exception(error), do: Exception.message(error)
  defp error_message(error), do: inspect(error)

  defp render_maybe_sensitive_attribute(
         assigns,
         resource,
         record,
         attribute,
         relationship_name
       ) do
    assigns = assign(assigns, attribute: attribute, relationship_name: relationship_name)
    show_sensitive_fields = AshAdmin.Resource.show_sensitive_fields(resource)

    if attribute.sensitive? && not Enum.member?(show_sensitive_fields, attribute.name) do
      ~H"""
      <.live_component
        id={"#{@relationship_name}_#{AshAdmin.Helpers.encode_primary_key(@record)}-#{@attribute.name}"}
        module={SensitiveAttribute}
        value={Map.get(@record, @attribute.name)}
      >
        {render_attribute(assigns, @resource, @record, @attribute, @relationship_name)}
      </.live_component>
      """
    else
      render_attribute(assigns, resource, record, attribute, relationship_name)
    end
  end

  # Scalar array items, rendered inline and separated by commas.
  defp inline_items(assigns) do
    item_attribute = %{
      assigns.attribute
      | type: assigns.type,
        constraints: assigns.attribute.constraints[:items] || []
    }

    assigns.record
    |> Map.get(assigns.name)
    |> List.wrap()
    |> Enum.map(fn value ->
      render_attribute(
        assigns,
        assigns.resource,
        Map.put(assigns.record, assigns.name, value),
        item_attribute,
        assigns.relationship_name,
        true
      )
    end)
    |> Enum.intersperse(", ")
  end

  defp render_attribute(assigns, resource, record, attribute, relationship_name, nested? \\ false)

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: {:array, type}, name: name} = attribute,
         relationship_name,
         nested?
       ) do
    if Map.get(record, name) in [[], nil] do
      "None"
    else
      assigns =
        assign(assigns,
          resource: resource,
          record: record,
          type: type,
          name: name,
          attribute: attribute,
          relationship_name: relationship_name,
          nested: nested?
        )

      ~H"""
      <%= if boxed?(@attribute) do %>
        <span :for={item <- inline_items(assigns)}>{item}</span>
      <% else %>
        <%= if @nested do %>
          <ul>
            <li :for={value <- List.wrap(Map.get(@record, @name))} class="mb-4 pb-4 shadow-md">
              {render_attribute(
                assigns,
                @resource,
                Map.put(@record, @name, value),
                %{@attribute | type: @type},
                @relationship_name,
                true
              )}
            </li>
          </ul>
        <% else %>
          <div class="shadow-md border mt-4 mb-4 ml-4">
            <ul>
              <li :for={value <- List.wrap(Map.get(@record, @name))} class="my-4 mb-4 pb-4 shadow-md">
                {render_attribute(
                  assigns,
                  @resource,
                  Map.put(@record, @name, value),
                  %{@attribute | type: @type},
                  @relationship_name,
                  true
                )}
              </li>
            </ul>
          </div>
        <% end %>
      <% end %>
      """
    end
  end

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: Ash.Type.Struct} = attribute,
         relationship_name,
         nested?
       ) do
    struct_map =
      record
      |> Map.get(attribute.name)
      |> case do
        nil -> nil
        value -> Map.from_struct(value)
      end

    render_attribute(
      assigns,
      resource,
      Map.put(record, attribute.name, struct_map),
      %{attribute | type: Ash.Type.Map},
      relationship_name,
      nested?
    )
  end

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: {:array, Ash.Type.Map}} = attribute,
         relationship_name,
         nested?
       ) do
    render_attribute(
      assigns,
      resource,
      record,
      %{attribute | type: Ash.Type.Map},
      relationship_name,
      nested?
    )
  end

  defp render_attribute(
         assigns,
         _resource,
         record,
         %{type: Ash.Type.Map} = attribute,
         relationship_name,
         _nested?
       ) do
    encoded = Jason.encode!(Map.get(record, attribute.name))

    assigns =
      assign(assigns,
        record: record,
        attribute: attribute,
        encoded: encoded,
        relationship_name: relationship_name
      )

    ~H"""
    <div
      phx-hook="JsonView"
      data-json={@encoded}
      id={"#{@relationship_name}_#{AshAdmin.Helpers.encode_primary_key(@record)}_#{@attribute.name}_json"}
    />
    """
  rescue
    e ->
      Logger.error("Failed to display value:\n#{Exception.format(:error, e, __STACKTRACE__)}")

      "<display error>"
  end

  defp render_attribute(
         assigns,
         _resource,
         record,
         %{name: name, type: Ash.Type.Boolean},
         _relationship_name,
         _
       ) do
    case Map.get(record, name) do
      true ->
        ~H"""
        <.icon name="hero-check" class="h-4 w-4 text-slate-600 dark:text-slate-400" />
        """

      false ->
        ~H"""
        <.icon name="hero-x-mark" class="h-4 w-4 text-slate-600 dark:text-slate-400" />
        """

      _ ->
        ~H"""
        <.icon name="hero-minus" class="h-4 w-4 text-slate-600 dark:text-slate-400" />
        """
    end
  end

  defp render_attribute(
         assigns,
         _resource,
         record,
         %{name: name, type: Ash.Type.Binary},
         _relationship_name,
         _
       ) do
    if Map.get(record, name) do
      ~H"""
      <span class="italic">(binary data)</span>
      """
    else
      "(empty)"
    end
  end

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: Ash.Type.Union} = attribute,
         relationship_name,
         nested?
       ) do
    case Map.get(record, attribute.name) do
      nil ->
        ""

      %Ash.Union{type: type, value: value} ->
        config = attribute.constraints[:types][type]
        new_attr = %{attribute | type: config[:type], constraints: config[:constraints]}

        render_attribute(
          assigns,
          resource,
          Map.put(record, attribute.name, value),
          new_attr,
          relationship_name,
          nested?
        )
    end
  end

  defp render_attribute(assigns, resource, record, attribute, relationship_name, nested?) do
    if Ash.Type.NewType.new_type?(attribute.type) do
      constraints = Ash.Type.NewType.constraints(attribute.type, attribute.constraints)
      type = Ash.Type.NewType.subtype_of(attribute.type)
      attribute = %{attribute | type: type, constraints: constraints}
      render_attribute(assigns, resource, record, attribute, relationship_name, nested?)
    else
      if Ash.Type.embedded_type?(attribute.type) do
        if Map.get(record, attribute.name) in [nil, []] do
          "None"
        else
          assigns =
            assign(assigns,
              resource: resource,
              record: record,
              attribute: attribute,
              nested: nested?,
              relationship_name: relationship_name
            )

          ~H"""
          <%= if @nested do %>
            <div class="ml-1 pl-2 pr-2">
              {render_attributes(
                assigns,
                Map.get(@record, @attribute.name),
                @attribute.type,
                @relationship_name
              )}
            </div>
          <% else %>
            <div class="shadow-md border mt-4 mb-4 rounded py-2 px-2 ml-1 pl-2 pr-2">
              {render_attributes(
                assigns,
                Map.get(@record, @attribute.name),
                @attribute.type,
                @relationship_name
              )}
            </div>
          <% end %>
          """
        end
      else
        case attribute.type do
          Ash.Type.String ->
            value!(Map.get(record, attribute.name))

          _ ->
            resource
            |> AshAdmin.Resource.format_fields()
            |> FormatHelper.format_attribute(record, attribute)
            |> with_relationship_button(
              relationship_path(
                assigns[:prefix],
                resource,
                attribute.name,
                Map.get(record, attribute.name)
              )
            )
        end
      end
    end
  end

  # Puts a button at the end of the value that opens the related record.
  defp with_relationship_button(value, nil), do: value

  defp with_relationship_button(value, path) do
    assigns = %{value: value, path: path}

    ~H"""
    <span class="flex items-center justify-between gap-2">
      <span class="min-w-0">{@value}</span>
      <.link
        navigate={@path}
        title="Open the related record"
        aria-label="Open the related record"
        data-relationship-link
        class="flex-none rounded text-slate-500 hover:bg-slate-200 hover:text-slate-700 dark:text-slate-400 dark:hover:bg-slate-700 dark:hover:text-slate-300"
        style="padding: 0.125rem; margin: -0.125rem 0;"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
          class="h-4 w-4"
        >
          <path
            fill-rule="evenodd"
            d="M3 10a.75.75 0 0 1 .75-.75h10.638L10.23 5.29a.75.75 0 1 1 1.04-1.08l5.5 5.25a.75.75 0 0 1 0 1.08l-5.5 5.25a.75.75 0 1 1-1.04-1.08l4.158-3.96H3.75A.75.75 0 0 1 3 10Z"
            clip-rule="evenodd"
          />
        </svg>
      </.link>
    </span>
    """
  end

  def handle_event("validate-calculation", %{"calculation" => calculation_name} = params, socket) do
    calculation = Ash.Resource.Info.calculation(socket.assigns.resource, calculation_name)

    arg_form =
      AshPhoenix.FilterForm.Arguments.new(params[calculation_name], calculation.arguments)
      |> to_form()

    show_calculations =
      AshAdmin.Resource.show_calculations(socket.assigns.resource)

    calculations =
      socket.assigns.calculations
      |> Map.new()
      |> Map.put(calculation, arg_form)
      |> Enum.sort_by(fn {calc, _form} ->
        Enum.find_index(show_calculations, fn name ->
          name == calc.name
        end)
      end)

    {:noreply, assign(socket, :calculations, calculations)}
  end

  def handle_event("calculate", %{"calculation" => calculation} = event, socket) do
    record = socket.assigns.record
    domain = socket.assigns.domain

    # Resolve the calculation by matching known calculations by name, and map
    # each submitted argument key to a *declared* argument. Client-supplied keys
    # are never passed to String.to_atom/1, which would mint an atom per unique
    # key and exhaust the atom table (a whole-node DoS).
    calculation =
      Enum.find(
        Ash.Resource.Info.calculations(record.__struct__),
        &(to_string(&1.name) == calculation)
      )

    if calculation do
      arguments =
        event
        |> Map.get(to_string(calculation.name), [])
        |> Enum.flat_map(fn {attr, value} ->
          case Enum.find(calculation.arguments, &(to_string(&1.name) == attr)) do
            nil -> []
            arg -> [{arg.name, value}]
          end
        end)
        |> Enum.reject(fn {_, v} -> v in ["", nil] end)

      case Ash.load(
             record,
             [{calculation.name, arguments}],
             domain: domain,
             actor: socket.assigns[:actor],
             authorize?: socket.assigns[:authorizing]
           ) do
        {:ok, loaded} ->
          {:noreply,
           assign(socket,
             record: loaded,
             calculation_errors: Map.delete(socket.assigns.calculation_errors, calculation.name)
           )}

        {:error, errors} ->
          {:noreply,
           assign(socket,
             calculation_errors:
               Map.put(socket.assigns.calculation_errors, calculation.name, errors)
           )}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("load", %{"relationship" => relationship}, socket) do
    record = socket.assigns.record
    domain = socket.assigns.domain
    relationship = String.to_existing_atom(relationship)

    case Ash.load(
           record,
           relationship,
           domain: domain,
           actor: socket.assigns[:actor],
           authorize?: socket.assigns[:authorizing]
         ) do
      {:ok, loaded} ->
        {:noreply,
         assign(socket,
           record: loaded,
           load_errors: Map.delete(socket.assigns.load_errors, relationship)
         )}

      {:error, errors} ->
        {:noreply,
         assign(socket, load_errors: Map.put(socket.assigns.load_errors, relationship, errors))}
    end
  end

  def handle_event("select_relationship", %{"relationship" => relationship}, socket) do
    # Match against the declared relationships so a client-supplied name never
    # mints a new atom.
    selected =
      socket.assigns.resource
      |> AshAdmin.Components.Resource.Form.relationships(:show)
      |> Enum.find(&(to_string(&1.name) == relationship))

    if selected do
      {:noreply, assign(socket, active_relationship: selected.name)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("unload", %{"relationship" => relationship}, socket) do
    record = socket.assigns.record
    relationship = String.to_existing_atom(relationship)

    unloaded =
      Map.put(record, relationship, Map.get(record.__struct__.__struct__(), relationship))

    {:noreply, assign(socket, record: unloaded)}
  end

  # TODO
  # def handle_event("union-type-changed", %{"_target" => path} = params, socket) do
  # new_type = get_in(params, path)
  # # The last part of the path in this case is the field name
  # path =
  #   socket.assigns.form
  #   |> AshPhoenix.Form.parse_path!(:lists.droplast(path))
  #
  # new_union_types = (socket.assigns[:union_types] || %{}) |> Map.put(path, new_type)
  #
  # if AshPhoenix.Form.has_form?(socket.assigns.form, path) do
  #   nested_form = AshPhoenix.Form.get_form(socket.assigns.form, path)
  #
  #   form =
  #     socket.assigns.form
  #     |> AshPhoenix.Form.remove_form(path)
  #     |> AshPhoenix.Form.add_form(path,
  #       params: %{"_new_union_type" => new_type, "_union_type" => new_type},
  #       type: nested_form.type
  #     )
  #
  #   {:noreply, assign(socket, form: form, union_types: new_union_types)}
  # else
  #   {:noreply, assign(socket, union_types: new_union_types)}
  # end
  # end

  def handle_event(event, %{"path" => path, "field" => field} = params, socket)
      when event in ["add_form", "append_value"] do
    to_append =
      case params["union-type"] do
        nil -> nil
        value when value != "" -> %{"_union_type" => value}
        _ -> nil
      end

    [calc_name | decoded_path] =
      path
      |> Plug.Conn.Query.decode()
      |> decoded_to_list()

    path_to_params = decoded_path ++ [field]

    calculation = Ash.Resource.Info.calculation(socket.assigns.resource, calc_name)

    keyed_calculations = Map.new(socket.assigns.calculations)
    current_params = keyed_calculations[calculation].params

    new_params =
      case get_in(current_params, path_to_params) do
        nil ->
          put_in(current_params, path_to_params, %{"0" => to_append})

        values ->
          to_place =
            values
            |> Map.keys()
            |> Enum.filter(&String.match?(&1, ~r/[[:digit]]/))
            |> Enum.map(&String.to_integer/1)
            |> case do
              [] -> "0"
              keys -> to_string(Enum.max(keys) + 1)
            end

          put_in(current_params, path_to_params ++ [to_place], to_append)
      end

    arg_form =
      AshPhoenix.FilterForm.Arguments.new(new_params, calculation.arguments)
      |> to_form()

    show_calculations =
      AshAdmin.Resource.show_calculations(socket.assigns.resource)

    calculations =
      socket.assigns.calculations
      |> Map.new()
      |> Map.put(calculation, arg_form)
      |> Enum.sort_by(fn {calc, _form} ->
        Enum.find_index(show_calculations, fn name ->
          name == calc.name
        end)
      end)

    {:noreply, assign(socket, :calculations, calculations)}
  end

  def handle_event(event, %{"path" => path} = params, socket)
      when event in ["remove_form", "remove_value"] do
    [calc_name | decoded_path] =
      path
      |> Plug.Conn.Query.decode()
      |> decoded_to_list()

    decoded_path =
      if event == "remove_form" do
        decoded_path
      else
        decoded_path ++ [params["field"], params["index"]]
      end

    calculation = Ash.Resource.Info.calculation(socket.assigns.resource, calc_name)

    keyed_calculations = Map.new(socket.assigns.calculations)
    current_params = keyed_calculations[calculation].params
    new_params = pop_in(current_params, decoded_path) |> elem(1)

    arg_form =
      AshPhoenix.FilterForm.Arguments.new(new_params, calculation.arguments)
      |> to_form()

    show_calculations =
      AshAdmin.Resource.show_calculations(socket.assigns.resource)

    calculations =
      socket.assigns.calculations
      |> Map.new()
      |> Map.put(calculation, arg_form)
      |> Enum.sort_by(fn {calc, _form} ->
        Enum.find_index(show_calculations, fn name ->
          name == calc.name
        end)
      end)

    {:noreply, assign(socket, :calculations, calculations)}
  end

  defp loaded?(record, relationship) do
    case Map.get(record, relationship) do
      %Ash.NotLoaded{} -> false
      _ -> true
    end
  end

  defp value!(%{
         __struct__: Postgrex.Range,
         lower: lower,
         upper: upper,
         lower_inclusive: lower_inclusive,
         upper_inclusive: upper_inclusive
       }) do
    lower_str =
      case lower do
        :unbound -> "-∞"
        %DateTime{} = dt -> DateTime.to_string(dt)
        other -> inspect(other)
      end

    upper_str =
      case upper do
        :unbound -> "+∞"
        %DateTime{} = dt -> DateTime.to_string(dt)
        other -> inspect(other)
      end

    lower_bracket = if lower_inclusive, do: "[", else: "("
    upper_bracket = if upper_inclusive, do: "]", else: ")"

    "#{lower_bracket}#{lower_str}, #{upper_str}#{upper_bracket}"
  end

  defp value!(value) do
    if is_binary(value) and !String.valid?(value) do
      "<binary data>"
    else
      data = Phoenix.HTML.Safe.to_iodata(value)
      {:safe, data}
    end
  rescue
    e ->
      Logger.debug("Failed to display value:\n#{Exception.format(:error, e, __STACKTRACE__)}")
      "<display error>"
  end

  defp short_text?(resource, attribute) do
    case AshAdmin.Resource.field(resource, attribute.name) do
      %{type: :short_text} ->
        true

      _ ->
        false
    end
  end

  defp long_text?(resource, attribute) do
    case AshAdmin.Resource.field(resource, attribute.name) do
      %{type: :long_text} ->
        true

      _ ->
        false
    end
  end

  defp destroy?(resource) do
    case AshAdmin.Resource.destroy_actions(resource) do
      nil ->
        resource
        |> Ash.Resource.Info.actions()
        |> Enum.any?(&(&1.type == :destroy))

      [] ->
        false

      _ ->
        true
    end
  end

  defp update?(resource) do
    case AshAdmin.Resource.update_actions(resource) do
      nil ->
        resource
        |> Ash.Resource.Info.actions()
        |> Enum.any?(&(&1.type == :update))

      [] ->
        false

      _ ->
        true
    end
  end

  defp decoded_to_list(""), do: []

  defp decoded_to_list(value) do
    {key, rest} = Enum.at(value, 0)

    [key | decoded_to_list(rest)]
  end
end
