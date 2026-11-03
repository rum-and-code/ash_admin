# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.PageHeader do
  @moduledoc false
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :resource, :any, default: nil
  attr :domain, :any, default: nil
  attr :action, :any, default: nil
  attr :action_type, :atom, default: nil
  attr :record, :any, default: nil
  attr :table, :any, default: nil
  attr :prefix, :any, required: true

  @doc """
  Page header shown above the content: breadcrumb and title on the left, the
  other actions and the create button on the right.
  """
  def page_header(assigns) do
    assigns =
      assigns
      |> assign(:menu_align, :right)
      |> assign(:breadcrumb, breadcrumb_items(assigns))

    ~H"""
    <div class="mx-4 md:mx-16 pt-4 md:pt-8">
      <.breadcrumb :if={@breadcrumb != []} items={@breadcrumb} />
      <div class="mt-2 flex flex-wrap items-center gap-3">
        <button
          type="button"
          phx-click="toggle_sidebar"
          class="md:hidden -ml-1 p-1.5 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
        >
          <AshAdmin.CoreComponents.icon name="hero-bars-3" class="h-5 w-5" />
        </button>
        <h1 class="text-2xl md:text-3xl font-semibold text-slate-900 dark:text-slate-100 truncate">
          {if @resource, do: AshAdmin.Resource.name(@resource), else: AshAdmin.title()}
        </h1>
        <div class="flex-1" />
        <div :if={@resource} class="flex items-center gap-1">
          {read_action_switcher(assigns)}
          {generic_actions_dropdown(assigns)}
        </div>
        <div :if={@resource}>
          {create_action_button(assigns)}
        </div>
      </div>
    </div>
    """
  end

  # Resource (plural) > record primary key > current action.
  # The list page ends with its read action instead of a record.
  defp breadcrumb_items(%{resource: nil}), do: []

  defp breadcrumb_items(assigns) do
    list_action =
      if assigns.action && assigns.action.type == :read do
        assigns.action
      else
        assigns.resource |> get_read_actions() |> List.first()
      end

    resource_item = {
      assigns.resource |> AshAdmin.Resource.name() |> pluralize(),
      list_action && read_action_path(assigns, list_action)
    }

    record =
      case assigns.record do
        {:ok, %_{} = record} -> record
        _ -> nil
      end

    action = assigns.action

    rest =
      cond do
        is_nil(action) ->
          []

        record && action.type == :read ->
          [{record_label(record), nil}]

        record ->
          [{record_label(record), show_path(assigns, record)}, {action_label(action), nil}]

        true ->
          [{action_label(action), nil}]
      end

    [resource_item | rest]
  end

  defp record_label(record) do
    record.__struct__
    |> Ash.Resource.Info.primary_key()
    |> Enum.map_join(", ", &to_string(Map.get(record, &1)))
  end

  defp show_path(assigns, record) do
    "#{assigns.prefix}?domain=#{AshAdmin.Domain.name(assigns.domain)}&resource=#{AshAdmin.Resource.name(assigns.resource)}&table=#{assigns.table}&primary_key=#{AshAdmin.Helpers.encode_primary_key(record)}&action_type=read"
  end

  # Simple English plural for the breadcrumb: "User" -> "Users",
  # "Category" -> "Categories", "Address" -> "Addresses".
  defp pluralize(name) do
    cond do
      Regex.match?(~r/[^aeiou]y$/i, name) -> String.slice(name, 0..-2//1) <> "ies"
      Regex.match?(~r/(s|x|z|ch|sh)$/i, name) -> name <> "es"
      true -> name <> "s"
    end
  end

  attr :items, :list,
    required: true,
    doc: "A list of `{label, path}`. A `nil` path renders plain text."

  def breadcrumb(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb">
      <ol class="flex flex-wrap items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400">
        <li :for={{{label, path}, index} <- Enum.with_index(@items)} class="flex items-center gap-1.5">
          <AshAdmin.CoreComponents.icon
            :if={index > 0}
            name="hero-chevron-right-mini"
            class="h-4 w-4 text-slate-400 dark:text-slate-500"
          />
          <.link
            :if={path}
            navigate={path}
            class="hover:text-slate-700 dark:hover:text-slate-200 transition-colors"
          >
            {label}
          </.link>
          <span :if={!path}>{label}</span>
        </li>
      </ol>
    </nav>
    """
  end

  defp read_action_path(assigns, action) do
    "#{assigns.prefix}?domain=#{AshAdmin.Domain.name(assigns.domain)}&resource=#{AshAdmin.Resource.name(assigns.resource)}&action_type=read&action=#{action.name}&table=#{assigns.table}"
  end

  defp menu_position(assigns) do
    if assigns[:menu_align] == :right, do: "right-0", else: "left-0"
  end

  defp read_action_switcher(assigns) do
    case get_read_actions(assigns.resource) do
      [] ->
        ~H""

      [single] ->
        assigns = assign(assigns, :single, single)

        ~H"""
        <div class="relative">
          <.link
            navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=read&action=#{@single.name}&table=#{@table}"}
            class={[
              "inline-flex items-center px-2.5 py-1 text-sm rounded-md transition-colors",
              if(@action && @action.type == :read,
                do: "bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100 font-medium",
                else: "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              )
            ]}
          >
            {action_label(@single)}
          </.link>
        </div>
        """

      read_actions ->
        assigns = assign(assigns, :read_actions, read_actions)

        ~H"""
        <div class="relative">
          <button
            type="button"
            phx-click={JS.toggle(to: "#read-actions-dropdown")}
            class={[
              "inline-flex items-center gap-1 px-2.5 py-1 text-sm rounded-md transition-colors",
              if(@action && @action.type == :read,
                do: "bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100 font-medium",
                else: "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              )
            ]}
          >
            {if @action && @action.type == :read, do: action_label(@action), else: "Read"}
            <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
          </button>
          <div
            id="read-actions-dropdown"
            class={"hidden absolute #{menu_position(assigns)} top-full mt-1 w-48 bg-white dark:bg-slate-800 rounded-md shadow-lg ring-1 ring-slate-200 dark:ring-slate-700 py-1 z-30"}
            phx-click-away={JS.hide(to: "#read-actions-dropdown")}
          >
            <.link
              :for={action <- @read_actions}
              navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=read&action=#{action.name}&table=#{@table}"}
              class={[
                "block px-3 py-1.5 text-sm transition-colors",
                if(@action && @action.name == action.name && @action.type == :read,
                  do: "bg-slate-100 dark:bg-slate-700 text-slate-900 dark:text-slate-100",
                  else: "text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"
                )
              ]}
            >
              {action_label(action)}
            </.link>
          </div>
        </div>
        """
    end
  end

  defp generic_actions_dropdown(assigns) do
    generic_actions = get_generic_actions(assigns.resource)
    assigns = assign(assigns, :generic_actions, generic_actions)

    ~H"""
    <div :if={@generic_actions != []} class="relative">
      <button
        type="button"
        phx-click={JS.toggle(to: "#generic-actions-dropdown")}
        class={[
          "inline-flex items-center gap-1 px-2.5 py-1 text-sm rounded-md transition-colors",
          if(@action && @action.type == :action,
            do: "bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100 font-medium",
            else: "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
          )
        ]}
      >
        {if @action && @action.type == :action, do: action_label(@action), else: "Actions"}
        <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
      </button>
      <div
        id="generic-actions-dropdown"
        class={"hidden absolute #{menu_position(assigns)} top-full mt-1 w-48 bg-white dark:bg-slate-800 rounded-md shadow-lg ring-1 ring-slate-200 dark:ring-slate-700 py-1 z-30"}
        phx-click-away={JS.hide(to: "#generic-actions-dropdown")}
      >
        <.link
          :for={action <- @generic_actions}
          navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=action&action=#{action.name}&table=#{@table}"}
          class={[
            "block px-3 py-1.5 text-sm transition-colors",
            if(@action && @action.name == action.name && @action.type == :action,
              do: "bg-slate-100 dark:bg-slate-700 text-slate-900 dark:text-slate-100",
              else: "text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"
            )
          ]}
        >
          {action_label(action)}
        </.link>
      </div>
    </div>
    """
  end

  defp create_action_button(assigns) do
    case get_create_actions(assigns.resource) do
      [] ->
        ~H""

      [single] ->
        assigns = assign(assigns, :single, single)

        ~H"""
        <.link
          navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=create&action=#{@single.name}&table=#{@table}"}
          class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-md bg-slate-800 hover:bg-slate-700 dark:bg-slate-200 dark:hover:bg-slate-300 text-white dark:text-slate-900 transition-colors"
        >
          <AshAdmin.CoreComponents.icon name="hero-plus-mini" class="h-4 w-4" /> New
        </.link>
        """

      create_actions ->
        assigns = assign(assigns, :create_actions, create_actions)

        ~H"""
        <div class="relative">
          <button
            type="button"
            phx-click={JS.toggle(to: "#create-actions-dropdown")}
            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-md bg-slate-800 hover:bg-slate-700 dark:bg-slate-200 dark:hover:bg-slate-300 text-white dark:text-slate-900 transition-colors"
          >
            <AshAdmin.CoreComponents.icon name="hero-plus-mini" class="h-4 w-4" /> New
            <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
          </button>
          <div
            id="create-actions-dropdown"
            class="hidden absolute right-0 top-full mt-1 w-48 bg-white dark:bg-slate-800 rounded-md shadow-lg ring-1 ring-slate-200 dark:ring-slate-700 py-1 z-30"
            phx-click-away={JS.hide(to: "#create-actions-dropdown")}
          >
            <.link
              :for={action <- @create_actions}
              navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=create&action=#{action.name}&table=#{@table}"}
              class="block px-3 py-1.5 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
            >
              {action_label(action)}
            </.link>
          </div>
        </div>
        """
    end
  end

  defp get_read_actions(resource) do
    read_actions = AshAdmin.Resource.read_actions(resource)

    resource
    |> Ash.Resource.Info.actions()
    |> Enum.filter(&(&1.type == :read && (is_nil(read_actions) || &1.name in read_actions)))
  end

  defp get_generic_actions(resource) do
    generic_actions = AshAdmin.Resource.generic_actions(resource)

    resource
    |> Ash.Resource.Info.actions()
    |> Enum.filter(
      &(&1.type == :action && (is_nil(generic_actions) || &1.name in generic_actions))
    )
  end

  defp get_create_actions(resource) do
    case AshAdmin.Resource.create_actions(resource) do
      nil ->
        resource
        |> Ash.Resource.Info.actions()
        |> Enum.filter(&(&1.type == :create))

      [] ->
        []

      action_names ->
        resource
        |> Ash.Resource.Info.actions()
        |> Enum.filter(&(&1.type == :create && &1.name in action_names))
    end
  end

  defp action_label(action) do
    action.name
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
