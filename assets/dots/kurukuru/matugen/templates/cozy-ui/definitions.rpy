################################################################################
#
# Copyright (c) 2020-2021 Dominus Iniquitatis <zerosaiko@gmail.com>
# Copyright (c) 2026 Friends of Monika
#
# See LICENSE file for the licensing information
#
################################################################################
define cozy_ui.common.font_regular     = cozy_ui.expand_path("%SUBMOD_DIR%/fonts/Asap-Medium.ttf")
define cozy_ui.common.font_italic      = cozy_ui.expand_path("%SUBMOD_DIR%/fonts/Asap-MediumItalic.ttf")
define cozy_ui.common.font_bold        = cozy_ui.expand_path("%SUBMOD_DIR%/fonts/Asap-Bold.ttf")
define cozy_ui.common.font_bold_italic = cozy_ui.expand_path("%SUBMOD_DIR%/fonts/Asap-BoldItalic.ttf")
define cozy_ui.common.font             = FontGroup().add(
    cozy_ui.common.font_regular                 , 0x0020, 0x00ff).add( # Main
    "mod_assets/font/SourceHanSansK-Regular.otf" , 0xac00, 0xd7a3).add( # Korean
    "mod_assets/font/SourceHanSansSC-Regular.otf", 0x4e00, 0x9faf).add( # Simplified chinese
    "mod_assets/font/mplus-2p-regular.ttf"       , 0x3000, 0x4dff).add( # Japanese and others
    "gui/font/Aller_Rg.ttf"                      , 0x0000, 0xffff)      # Fallback
define cozy_ui.common.font_kerning     = 0
define cozy_ui.common.font_size        = 24

define cozy_ui.menu_font         = cozy_ui.expand_path("%SUBMOD_DIR%/fonts/Nunito-SemiBold.ttf")
define cozy_ui.menu_font_kerning = 0.0

define cozy_ui.menu_title.font_size      = 38
define cozy_ui.menu_title.light.color    = "#ffffff"
define cozy_ui.menu_title.light.outlines = [(6, "{{colors.primary.light.hex}}", 0, 0), (3, "{{colors.primary.light.hex}}", 2, 2)]
define cozy_ui.menu_title.dark.color     = "{{colors.primary_container.dark.hex}}"
define cozy_ui.menu_title.dark.outlines  = [(6, "{{colors.primary.dark.hex}}", 0, 0), (3, "{{colors.primary.dark.hex}}", 2, 2)]

define cozy_ui.menu_label.font_size      = 24
define cozy_ui.menu_label.light.color    = "#ffffff"
define cozy_ui.menu_label.light.outlines = [(3, "{{colors.primary.light.hex}}", 0, 0), (1, "{{colors.primary.light.hex}}", 1, 1)]
define cozy_ui.menu_label.dark.color     = "{{colors.primary_container.dark.hex}}"
define cozy_ui.menu_label.dark.outlines  = [(3, "{{colors.primary.dark.hex}}", 0, 0), (1, "{{colors.primary.dark.hex}}", 1, 1)]

define cozy_ui.menu_text.font_size      = 16
define cozy_ui.menu_text.light.color    = "{{colors.on_surface.light.hex}}"
define cozy_ui.menu_text.light.outlines = []
define cozy_ui.menu_text.dark.color     = "{{colors.primary.dark.hex}}"
define cozy_ui.menu_text.dark.outlines  = []

define cozy_ui.menu_button_text.font_size                  = 24
define cozy_ui.menu_button_text.light.color                = "#ffffff"
define cozy_ui.menu_button_text.light.idle_outlines        = [(4, "{{colors.primary.light.hex}}", 0, 0), (2, "{{colors.primary.light.hex}}", 2, 2)]
define cozy_ui.menu_button_text.light.hover_outlines       = [(4, "{{colors.secondary.light.hex}}", 0, 0), (2, "{{colors.secondary.light.hex}}", 2, 2)]
define cozy_ui.menu_button_text.light.insensitive_outlines = [(4, "{{colors.outline_variant.light.hex}}", 0, 0), (2, "{{colors.outline_variant.light.hex}}", 2, 2)]
define cozy_ui.menu_button_text.dark.color                 = "{{colors.primary_container.dark.hex}}"
define cozy_ui.menu_button_text.dark.idle_outlines         = [(4, "{{colors.primary.dark.hex}}", 0, 0), (2, "{{colors.primary.dark.hex}}", 2, 2)]
define cozy_ui.menu_button_text.dark.hover_outlines        = [(4, "{{colors.secondary.dark.hex}}", 0, 0), (2, "{{colors.secondary.dark.hex}}", 2, 2)]
define cozy_ui.menu_button_text.dark.insensitive_outlines  = [(4, "{{colors.outline_variant.dark.hex}}", 0, 0), (2, "{{colors.outline_variant.dark.hex}}", 2, 2)]

define cozy_ui.music_menu_button_text.font                       = "mod_assets/font/mplus-2p-regular.ttf"
define cozy_ui.music_menu_button_text.font_kerning               = 0.0
define cozy_ui.music_menu_button_text.font_size                  = 24
define cozy_ui.music_menu_button_text.light.color                = "#ffffff"
define cozy_ui.music_menu_button_text.light.idle_outlines        = [(3, "{{colors.primary.light.hex}}", 0, 0), (1, "{{colors.primary.light.hex}}", 1, 1)]
define cozy_ui.music_menu_button_text.light.hover_outlines       = [(3, "{{colors.secondary.light.hex}}", 0, 0), (1, "{{colors.secondary.light.hex}}", 1, 1)]
define cozy_ui.music_menu_button_text.light.insensitive_outlines = [(3, "{{colors.outline_variant.light.hex}}", 0, 0), (1, "{{colors.outline_variant.light.hex}}", 1, 1)]
define cozy_ui.music_menu_button_text.dark.color                 = "{{colors.primary_container.dark.hex}}"
define cozy_ui.music_menu_button_text.dark.idle_outlines         = [(3, "{{colors.primary.dark.hex}}", 0, 0), (1, "{{colors.primary.dark.hex}}", 1, 1)]
define cozy_ui.music_menu_button_text.dark.hover_outlines        = [(3, "{{colors.secondary.dark.hex}}", 0, 0), (1, "{{colors.secondary.dark.hex}}", 1, 1)]
define cozy_ui.music_menu_button_text.dark.insensitive_outlines  = [(3, "{{colors.outline_variant.dark.hex}}", 0, 0), (1, "{{colors.outline_variant.dark.hex}}", 1, 1)]

define cozy_ui.confirm_prompt_text.light.color    = "{{colors.on_surface.light.hex}}"
define cozy_ui.confirm_prompt_text.light.outlines = []
define cozy_ui.confirm_prompt_text.dark.color     = "{{colors.secondary.dark.hex}}"
define cozy_ui.confirm_prompt_text.dark.outlines  = []

define cozy_ui.dialogue_text.vertical_offset = -3
define cozy_ui.dialogue_text.line_spacing    = -1
define cozy_ui.dialogue_text.color           = "#f8f8f8"
define cozy_ui.dialogue_text.outlines        = [(2, "#1a1a1a", 0, 0)]

define cozy_ui.history_name.color    = "#f8f8f8"
define cozy_ui.history_name.outlines = [(2, "#1a1a1a", 0, 0)]

define cozy_ui.history_text.color    = "#ffffff"
define cozy_ui.history_text.outlines = [(2, "#1a1a1a", 0, 0)]

define cozy_ui.quick_button_text.font_size               = 14
define cozy_ui.quick_button_text.light.idle_color        = "{{colors.on_surface_variant.light.hex}}"
define cozy_ui.quick_button_text.light.hover_color       = "{{colors.primary.light.hex}}"
define cozy_ui.quick_button_text.light.selected_color    = "#ffffff"
define cozy_ui.quick_button_text.light.insensitive_color = "{{colors.outline_variant.light.hex}}"
define cozy_ui.quick_button_text.light.outlines          = []
define cozy_ui.quick_button_text.dark.idle_color         = "{{colors.primary.dark.hex}}"
define cozy_ui.quick_button_text.dark.hover_color        = "{{colors.primary_container.dark.hex}}"
define cozy_ui.quick_button_text.dark.selected_color     = "{{colors.on_primary_container.dark.hex}}"
define cozy_ui.quick_button_text.dark.insensitive_color  = "{{colors.outline_variant.dark.hex}}"
define cozy_ui.quick_button_text.dark.outlines           = []

define cozy_ui.button.height_adjustment = -4

define cozy_ui.button_text.vertical_offset         = 1
define cozy_ui.button_text.light.idle_color        = "{{colors.on_surface.light.hex}}"
define cozy_ui.button_text.light.hover_color       = "{{colors.primary.light.hex}}"
define cozy_ui.button_text.light.selected_color    = "{{colors.secondary.light.hex}}"
define cozy_ui.button_text.light.insensitive_color = "{{colors.outline_variant.light.hex}}7f"
define cozy_ui.button_text.light.outlines          = []
define cozy_ui.button_text.dark.idle_color         = "{{colors.primary.dark.hex}}"
define cozy_ui.button_text.dark.hover_color        = "{{colors.primary_container.dark.hex}}"
define cozy_ui.button_text.dark.selected_color     = "{{colors.secondary.dark.hex}}"
define cozy_ui.button_text.dark.insensitive_color  = "{{colors.outline_variant.dark.hex}}7f"
define cozy_ui.button_text.dark.outlines           = []

define cozy_ui.option_button_text.font                    = cozy_ui.expand_path("gui/font/Halogen.ttf")
define cozy_ui.option_button_text.font_kerning            = 0.0
define cozy_ui.option_button_text.font_size               = 24
define cozy_ui.option_button_text.light.idle_color        = "{{colors.outline.light.hex}}"
define cozy_ui.option_button_text.light.hover_color       = "{{colors.primary.light.hex}}"
define cozy_ui.option_button_text.light.selected_color    = "{{colors.primary.light.hex}}"
define cozy_ui.option_button_text.light.insensitive_color = "{{colors.outline_variant.light.hex}}7f"
define cozy_ui.option_button_text.dark.idle_color         = "{{colors.outline.dark.hex}}"
define cozy_ui.option_button_text.dark.hover_color        = "{{colors.primary.dark.hex}}"
define cozy_ui.option_button_text.dark.selected_color     = "{{colors.primary.dark.hex}}"
define cozy_ui.option_button_text.dark.insensitive_color  = "{{colors.outline_variant.dark.hex}}7f"

define cozy_ui.fancy_check_button_text.light.idle_color     = "{{colors.outline.light.hex}}"
define cozy_ui.fancy_check_button_text.light.hover_color    = "{{colors.on_surface.light.hex}}"
define cozy_ui.fancy_check_button_text.light.selected_color = "{{colors.on_surface.light.hex}}"
define cozy_ui.fancy_check_button_text.dark.idle_color      = "{{colors.outline.dark.hex}}"
define cozy_ui.fancy_check_button_text.dark.hover_color     = "{{colors.on_surface.dark.hex}}"
define cozy_ui.fancy_check_button_text.dark.selected_color  = "{{colors.on_surface.dark.hex}}"

define cozy_ui.scrollable_menu_button_spacing = 6
define cozy_ui.choice_button_spacing          = 12
define cozy_ui.talk_button_spacing            = 16
define cozy_ui.hotkey_button_spacing          = 5

define cozy_ui.input_caret_color = "{{colors.primary.default.hex}}"
