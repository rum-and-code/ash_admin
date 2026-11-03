# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Themes.AshAdminTheme do
  @moduledoc """
  Cinder theme for AshAdmin's resource tables.

  The table sits edge to edge inside a card (see `AshAdmin.Components.Resource.DataTable`):
  rows span the full card width, so the row hover covers the whole line, and the
  cells carry the horizontal padding. Neutral slate palette, slate-900 for the
  active state, like the rest of AshAdmin.
  """
  use Cinder.Theme

  @input "aa-input !py-1.5"

  # Table
  set :container_class, ""
  set :controls_class, "border-b border-slate-200 dark:border-white/10"
  set :table_wrapper_class, "overflow-x-auto"
  set :table_class, "w-full text-left text-sm tabular-nums"
  set :thead_class, "border-b border-slate-200 dark:border-white/10"
  set :header_row_class, ""

  set :th_class,
      "px-3 py-3 first:pl-6 last:pr-6 align-middle font-semibold leading-5 text-slate-900 dark:text-slate-100 whitespace-nowrap [&_.cursor-pointer]:inline-flex [&_.cursor-pointer]:items-center"

  set :tbody_class, "divide-y divide-slate-100 dark:divide-white/5"

  set :row_class,
      "transition-colors duration-75 hover:bg-slate-100/60 dark:hover:bg-white/[0.04]"

  set :selected_row_class, "bg-primary-50/60 dark:bg-primary-500/10"
  set :td_class, "px-3 py-3 first:pl-6 last:pr-6 whitespace-nowrap text-slate-700 dark:text-slate-300"
  set :empty_class, "px-6 py-12 text-center text-sm text-slate-500 dark:text-slate-400"
  set :error_container_class, "px-6 py-12 text-center"
  set :error_message_class, "text-sm text-rose-600 dark:text-rose-400"

  # Pagination
  set :pagination_wrapper_class, "border-t border-slate-200 dark:border-white/10 px-6 py-3"
  set :pagination_container_class, "flex flex-wrap items-center justify-between gap-3"
  set :pagination_info_class, "text-sm text-slate-500 dark:text-slate-400"
  set :pagination_count_class, "text-slate-500 dark:text-slate-400"

  set :pagination_nav_class,
      "inline-flex overflow-hidden rounded-lg bg-white dark:bg-white/5 shadow-sm ring-1 ring-slate-200 dark:ring-white/10 divide-x divide-slate-200 dark:divide-white/10"

  set :pagination_button_class,
      "inline-flex min-w-[2.25rem] items-center justify-center px-3 py-1.5 text-sm text-slate-600 dark:text-slate-400 transition-colors hover:bg-slate-50 hover:text-slate-900 dark:hover:bg-slate-800 dark:hover:text-slate-100"

  set :pagination_current_class,
      "inline-flex min-w-[2.25rem] items-center justify-center px-3 py-1.5 text-sm font-semibold text-primary-600 dark:text-primary-400 bg-slate-50 dark:bg-white/5"

  set :page_size_container_class, "flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400"
  set :page_size_label_class, "text-sm text-slate-500 dark:text-slate-400"

  set :page_size_dropdown_class,
      "inline-flex items-center rounded-lg bg-white dark:bg-slate-900 px-3 py-1.5 text-sm text-slate-900 dark:text-slate-100 shadow-sm ring-1 ring-slate-200 dark:ring-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800"

  set :page_size_dropdown_container_class,
      "min-w-full rounded-lg bg-white dark:bg-slate-800 py-1 shadow-lg ring-1 ring-slate-200 dark:ring-slate-700"

  set :page_size_option_class,
      "block w-full px-3 py-1.5 text-left text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"

  set :page_size_selected_class, "font-semibold text-slate-900 dark:text-white"

  # Sorting
  set :sort_indicator_class, "ml-1 inline-flex align-middle"
  set :sort_arrow_wrapper_class, "text-slate-400 dark:text-slate-500"
  set :sort_asc_icon_class, "h-4 w-4 text-slate-900 dark:text-slate-100"
  set :sort_asc_icon_name, "hero-chevron-up-mini"
  set :sort_desc_icon_class, "h-4 w-4 text-slate-900 dark:text-slate-100"
  set :sort_desc_icon_name, "hero-chevron-down-mini"
  set :sort_none_icon_class, "h-4 w-4 text-slate-300 dark:text-slate-600"
  set :sort_none_icon_name, "hero-chevron-up-down-mini"

  # Search
  set :search_input_class, "w-full " <> @input <> " pl-9"
  set :search_icon_class, "h-4 w-4 text-slate-400"

  # Filters
  set :filter_container_class, "px-6 py-4"
  set :filter_header_class, "hidden"
  set :filter_title_class, "hidden"
  set :filter_count_class, "hidden"

  set :filter_clear_all_class,
      "text-sm font-medium text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100"

  set :filter_inputs_class, "flex flex-wrap gap-x-6 gap-y-4 items-end"
  set :filter_input_wrapper_class, "flex-none space-y-1.5"
  set :filter_label_class, "block text-sm font-medium text-slate-700 dark:text-slate-300"

  set :filter_placeholder_class,
      "text-sm text-slate-400 dark:text-slate-500 italic px-3 py-1.5 rounded-lg ring-1 ring-inset ring-slate-200 dark:ring-slate-700"

  set :filter_clear_button_class,
      "ml-2 text-sm text-slate-400 dark:text-slate-500 hover:text-slate-600 dark:hover:text-slate-300"

  set :filter_text_input_class, "w-48 " <> @input
  set :filter_select_input_class, "w-48 " <> @input
  set :filter_date_input_class, @input
  set :filter_number_input_class, "w-28 " <> @input

  set :filter_range_container_class, "flex items-center gap-2"
  set :filter_range_input_group_class, ""
  set :filter_range_separator_class, "text-xs text-slate-400 dark:text-slate-500"

  set :filter_select_container_class, "relative"

  set :filter_select_dropdown_class,
      "absolute z-10 mt-1 w-full max-h-48 overflow-auto rounded-lg bg-white dark:bg-slate-800 py-1 shadow-lg ring-1 ring-slate-200 dark:ring-slate-700"

  set :filter_select_option_class,
      "flex cursor-pointer items-center px-3 py-1.5 text-sm hover:bg-slate-50 dark:hover:bg-slate-700"

  set :filter_select_label_class,
      "flex-1 cursor-pointer select-none text-sm text-slate-700 dark:text-slate-300"

  set :filter_select_empty_class, "px-3 py-1.5 text-sm italic text-slate-500 dark:text-slate-400"
  set :filter_select_placeholder_class, "text-slate-400 dark:text-slate-500"
  set :filter_select_arrow_class, "h-4 w-4 text-slate-400 dark:text-slate-500"

  set :filter_boolean_container_class, "flex h-8 items-center space-x-3"
  set :filter_boolean_option_class, "flex items-center space-x-1.5"

  set :filter_boolean_radio_class,
      "h-3.5 w-3.5 text-primary-600 focus:ring-1 focus:ring-primary-500"

  set :filter_boolean_label_class, "cursor-pointer text-sm text-slate-600 dark:text-slate-400"

  # Loading
  set :loading_overlay_class,
      "absolute inset-0 flex items-center justify-center bg-white/75 dark:bg-slate-900/75"

  set :loading_container_class, "flex flex-col items-center"
  set :loading_class, "mt-2 text-sm text-slate-500 dark:text-slate-400"
  set :loading_spinner_class, "h-6 w-6 animate-spin text-slate-500 dark:text-slate-400"
  set :loading_spinner_circle_class, "opacity-25"
  set :loading_spinner_path_class, "opacity-75"
end
