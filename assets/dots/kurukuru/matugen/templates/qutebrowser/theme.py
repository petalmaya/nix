# Matugen template for qutebrowser theme

def apply(c):
    # Palette definition from Matugen
    bg_default = "{{colors.surface.default.hex}}"
    bg_lighter = "{{colors.surface_container.default.hex}}"
    bg_lightest = "{{colors.surface_container_high.default.hex}}"
    bg_highest = "{{colors.surface_container_highest.default.hex}}"
    
    fg_default = "{{colors.on_surface.default.hex}}"
    fg_muted = "{{colors.on_surface_variant.default.hex}}"
    
    primary = "{{colors.primary.default.hex}}"
    on_primary = "{{colors.on_primary.default.hex}}"
    primary_container = "{{colors.primary_container.default.hex}}"
    on_primary_container = "{{colors.on_primary_container.default.hex}}"
    
    secondary = "{{colors.secondary.default.hex}}"
    on_secondary = "{{colors.on_secondary.default.hex}}"
    secondary_container = "{{colors.secondary_container.default.hex}}"
    on_secondary_container = "{{colors.on_secondary_container.default.hex}}"

    error = "{{colors.error.default.hex}}"
    on_error = "{{colors.on_error.default.hex}}"
    error_container = "{{colors.error_container.default.hex}}"
    on_error_container = "{{colors.on_error_container.default.hex}}"

    outline = "{{colors.outline.default.hex}}"

    # Completion menu
    c.colors.completion.category.bg = bg_lighter
    c.colors.completion.category.border.bottom = bg_lighter
    c.colors.completion.category.border.top = bg_lighter
    c.colors.completion.category.fg = primary
    c.colors.completion.even.bg = bg_default
    c.colors.completion.odd.bg = bg_lighter
    c.colors.completion.fg = fg_default

    c.colors.completion.item.selected.bg = primary_container
    c.colors.completion.item.selected.border.bottom = primary_container
    c.colors.completion.item.selected.border.top = primary_container
    c.colors.completion.item.selected.fg = on_primary_container
    c.colors.completion.item.selected.match.fg = primary

    c.colors.completion.match.fg = primary
    c.colors.completion.scrollbar.bg = bg_lighter
    c.colors.completion.scrollbar.fg = fg_muted

    # Downloads bar
    c.colors.downloads.bar.bg = bg_default
    c.colors.downloads.error.bg = error_container
    c.colors.downloads.error.fg = on_error_container
    c.colors.downloads.start.bg = secondary_container
    c.colors.downloads.start.fg = on_secondary_container
    c.colors.downloads.stop.bg = primary_container
    c.colors.downloads.stop.fg = on_primary_container

    # Hints
    c.colors.hints.bg = primary
    c.colors.hints.fg = on_primary
    c.colors.hints.match.fg = secondary_container

    # Keyhint widget
    c.colors.keyhint.bg = bg_lighter
    c.colors.keyhint.fg = fg_default
    c.colors.keyhint.suffix.fg = primary

    # Messages
    c.colors.messages.error.bg = error_container
    c.colors.messages.error.border = error_container
    c.colors.messages.error.fg = on_error_container

    c.colors.messages.info.bg = bg_lighter
    c.colors.messages.info.border = bg_lighter
    c.colors.messages.info.fg = fg_default

    c.colors.messages.warning.bg = error_container
    c.colors.messages.warning.border = error_container
    c.colors.messages.warning.fg = on_error_container

    # Prompts
    c.colors.prompts.bg = bg_lighter
    c.colors.prompts.border = f"1px solid {outline}"
    c.colors.prompts.fg = fg_default
    c.colors.prompts.selected.bg = primary_container
    c.colors.prompts.selected.fg = on_primary_container

    # Statusbar
    c.colors.statusbar.caret.bg = secondary_container
    c.colors.statusbar.caret.fg = on_secondary_container
    c.colors.statusbar.caret.selection.bg = secondary
    c.colors.statusbar.caret.selection.fg = on_secondary

    c.colors.statusbar.command.bg = bg_lighter
    c.colors.statusbar.command.fg = fg_default
    c.colors.statusbar.command.private.bg = bg_highest
    c.colors.statusbar.command.private.fg = fg_default

    c.colors.statusbar.insert.bg = primary
    c.colors.statusbar.insert.fg = on_primary

    c.colors.statusbar.normal.bg = bg_default
    c.colors.statusbar.normal.fg = fg_default
    c.colors.statusbar.passthrough.bg = secondary
    c.colors.statusbar.passthrough.fg = on_secondary
    c.colors.statusbar.private.bg = bg_highest
    c.colors.statusbar.private.fg = fg_default

    c.colors.statusbar.progress.bg = primary

    c.colors.statusbar.url.error.fg = error
    c.colors.statusbar.url.fg = fg_default
    c.colors.statusbar.url.hover.fg = primary
    c.colors.statusbar.url.success.http.fg = fg_muted
    c.colors.statusbar.url.success.https.fg = primary
    c.colors.statusbar.url.warn.fg = error

    # Tab bar
    c.colors.tabs.bar.bg = bg_lighter

    c.colors.tabs.even.bg = bg_lighter
    c.colors.tabs.even.fg = fg_muted
    c.colors.tabs.odd.bg = bg_lighter
    c.colors.tabs.odd.fg = fg_muted

    c.colors.tabs.selected.even.bg = bg_default
    c.colors.tabs.selected.even.fg = primary
    c.colors.tabs.selected.odd.bg = bg_default
    c.colors.tabs.selected.odd.fg = primary

    c.colors.tabs.pinned.even.bg = bg_lighter
    c.colors.tabs.pinned.even.fg = fg_muted
    c.colors.tabs.pinned.odd.bg = bg_lighter
    c.colors.tabs.pinned.odd.fg = fg_muted
    c.colors.tabs.pinned.selected.even.bg = bg_default
    c.colors.tabs.pinned.selected.even.fg = primary
    c.colors.tabs.pinned.selected.odd.bg = bg_default
    c.colors.tabs.pinned.selected.odd.fg = primary

    # Webpage background (for pages without CSS)
    c.colors.webpage.bg = bg_default
