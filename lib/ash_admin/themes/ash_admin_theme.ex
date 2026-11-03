# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Themes.AshAdminTheme do
  @moduledoc """
  Cinder theme for AshAdmin's resource tables.

  The table sits edge to edge inside a card (see `AshAdmin.Components.Resource.DataTable`):
  rows span the full card width, so the row hover covers the whole line, and the
  cells carry the horizontal padding. Neutral palette in the style of shadcn/ui,
  like the rest of AshAdmin.
  """
  use Cinder.Theme

  @input "aa-input !py-1.5"

  # Table
  set :container_class, ""
  set :controls_class, "border-b border-neutral-200 dark:border-white/10"
  set :table_wrapper_class, "overflow-x-auto"
  set :table_class, "w-full text-left text-sm tabular-nums"

  set :thead_class,
      "border-b border-neutral-200 bg-neutral-50 dark:border-white/10 dark:bg-white/[0.03]"

  set :header_row_class, ""

  set :th_class,
      "h-10 px-3 py-2 first:pl-6 last:pr-6 align-middle font-medium leading-5 text-neutral-900 dark:text-neutral-100 whitespace-nowrap [&_.cursor-pointer]:inline-flex [&_.cursor-pointer]:items-center"

  set :tbody_class, "divide-y divide-neutral-200 dark:divide-white/10"

  set :row_class,
      "transition-colors duration-75 hover:bg-neutral-100/50 dark:hover:bg-white/[0.04]"

  set :selected_row_class, "bg-neutral-100 dark:bg-white/5"

  set :td_class,
      "px-3 py-2.5 first:pl-6 last:pr-6 whitespace-nowrap text-neutral-900 dark:text-neutral-50"

  set :empty_class, "px-6 py-12 text-center text-sm text-neutral-500 dark:text-neutral-400"
  set :error_container_class, "px-6 py-12 text-center"
  set :error_message_class, "text-sm text-red-600 dark:text-red-400"

  # Pagination
  set :pagination_wrapper_class, "border-t border-neutral-200 dark:border-white/10 px-6 py-3"
  set :pagination_container_class, "flex flex-wrap items-center justify-between gap-3"
  set :pagination_info_class, "text-sm text-neutral-500 dark:text-neutral-400"
  set :pagination_count_class, "text-neutral-500 dark:text-neutral-400"

  set :pagination_nav_class,
      "inline-flex items-center gap-1"

  set :pagination_button_class,
      "inline-flex h-8 min-w-[2rem] items-center justify-center rounded-lg px-2.5 text-sm font-medium text-neutral-900 dark:text-neutral-50 transition-colors hover:bg-neutral-100 dark:hover:bg-white/10"

  set :pagination_current_class,
      "inline-flex h-8 min-w-[2rem] items-center justify-center rounded-lg px-2.5 text-sm font-medium text-neutral-900 dark:text-neutral-50 bg-white dark:bg-white/5 border border-neutral-200 dark:border-white/[0.15] shadow-sm"

  set :page_size_container_class,
      "flex items-center gap-2 text-sm text-neutral-500 dark:text-neutral-400"

  set :page_size_label_class, "text-sm text-neutral-500 dark:text-neutral-400"

  set :page_size_dropdown_class,
      "inline-flex h-8 items-center rounded-lg border border-neutral-200 bg-white px-3 text-sm text-neutral-900 shadow-sm hover:bg-neutral-100 dark:border-white/[0.15] dark:bg-white/5 dark:text-neutral-50 dark:hover:bg-white/10"

  set :page_size_dropdown_container_class,
      "min-w-full rounded-lg border border-neutral-200 bg-white p-1 shadow-md dark:border-white/10 dark:bg-neutral-900"

  set :page_size_option_class,
      "block w-full rounded-md px-2 py-1.5 text-left text-sm text-neutral-900 dark:text-neutral-50 hover:bg-neutral-100 dark:hover:bg-white/10"

  set :page_size_selected_class, "font-medium bg-neutral-100 dark:bg-white/10"

  # Sorting
  set :sort_indicator_class, "ml-1 inline-flex align-middle"
  set :sort_arrow_wrapper_class, "text-neutral-400 dark:text-neutral-500"
  set :sort_asc_icon_class, "h-4 w-4 text-neutral-900 dark:text-neutral-100"
  set :sort_asc_icon_name, "hero-chevron-up-mini"
  set :sort_desc_icon_class, "h-4 w-4 text-neutral-900 dark:text-neutral-100"
  set :sort_desc_icon_name, "hero-chevron-down-mini"
  set :sort_none_icon_class, "h-4 w-4 text-neutral-300 dark:text-neutral-600"
  set :sort_none_icon_name, "hero-chevron-up-down-mini"

  # Search
  set :search_input_class, "w-full " <> @input <> " pl-9"
  set :search_icon_class, "h-4 w-4 text-neutral-400"

  # Filters
  set :filter_container_class, "px-6 py-4"
  set :filter_header_class, "hidden"
  set :filter_title_class, "hidden"
  set :filter_count_class, "hidden"

  set :filter_clear_all_class,
      "text-sm font-medium text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-neutral-100"

  set :filter_inputs_class, "flex flex-wrap gap-x-6 gap-y-4 items-end"
  set :filter_input_wrapper_class, "flex-none space-y-1.5"
  set :filter_label_class, "block text-sm font-medium text-neutral-900 dark:text-neutral-50"

  set :filter_placeholder_class,
      "text-sm text-neutral-400 dark:text-neutral-500 italic px-3 py-1.5 rounded-lg border border-dashed border-neutral-200 dark:border-white/[0.15]"

  set :filter_clear_button_class,
      "ml-2 text-sm text-neutral-400 dark:text-neutral-500 hover:text-neutral-600 dark:hover:text-neutral-300"

  set :filter_text_input_class, "w-48 " <> @input
  set :filter_select_input_class, "w-48 " <> @input
  set :filter_date_input_class, @input
  set :filter_number_input_class, "w-28 " <> @input

  set :filter_range_container_class, "flex items-center gap-2"
  set :filter_range_input_group_class, ""
  set :filter_range_separator_class, "text-xs text-neutral-400 dark:text-neutral-500"

  set :filter_select_container_class, "relative"

  set :filter_select_dropdown_class,
      "absolute z-10 mt-1 w-full max-h-48 overflow-auto rounded-lg border border-neutral-200 bg-white p-1 shadow-md dark:border-white/10 dark:bg-neutral-900"

  set :filter_select_option_class,
      "flex cursor-pointer items-center rounded-md px-2 py-1.5 text-sm hover:bg-neutral-100 dark:hover:bg-white/10"

  set :filter_select_label_class,
      "flex-1 cursor-pointer select-none text-sm text-neutral-700 dark:text-neutral-300"

  set :filter_select_empty_class,
      "px-3 py-1.5 text-sm italic text-neutral-500 dark:text-neutral-400"

  set :filter_select_placeholder_class, "text-neutral-400 dark:text-neutral-500"
  set :filter_select_arrow_class, "h-4 w-4 text-neutral-400 dark:text-neutral-500"

  set :filter_boolean_container_class, "flex h-8 items-center space-x-3"
  set :filter_boolean_option_class, "flex items-center space-x-1.5"

  set :filter_boolean_radio_class,
      "h-3.5 w-3.5 text-neutral-900 focus:ring-1 focus:ring-neutral-400"

  set :filter_boolean_label_class, "cursor-pointer text-sm text-neutral-600 dark:text-neutral-400"

  # Loading
  set :loading_overlay_class,
      "absolute inset-0 flex items-center justify-center bg-white/75 dark:bg-neutral-900/75"

  set :loading_container_class, "flex flex-col items-center"
  set :loading_class, "mt-2 text-sm text-neutral-500 dark:text-neutral-400"
  set :loading_spinner_class, "h-6 w-6 animate-spin text-neutral-500 dark:text-neutral-400"
  set :loading_spinner_circle_class, "opacity-25"
  set :loading_spinner_path_class, "opacity-75"
end
