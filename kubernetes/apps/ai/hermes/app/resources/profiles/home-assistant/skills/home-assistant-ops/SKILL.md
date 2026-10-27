---
name: home-assistant-ops
description: "Which hass-mcp tool to use for which Home Assistant task: entity lookup, state and history, device control, automations, dashboards, troubleshooting."
version: 1.0.0
author: dave
license: MIT
metadata:
  hermes:
    tags: [home-assistant, smart-home, mcp]
---

# Home Assistant via hass-mcp

All tools are prefixed `hass-mcp_`. Start broad, then narrow.

| Task | Tool |
|------|------|
| What is in the house / overall health | `system_overview`, `get_version` |
| Find an entity by words ("woonkamer lamp") | `search_entities_tool(query)` then `get_entity(entity_id)` |
| Everything in a room | `get_entities_by_area(area)` |
| All lights / climate / sensors of one kind | `domain_summary_tool(domain)` or `list_entities(domain=...)` |
| Current value with few fields | `get_entity(entity_id, fields=[...])` |
| What happened recently | `get_history(entity_id)`; exact window `get_history_range`; aggregates `get_statistics`/`get_statistics_range` |
| Turn on/off/toggle | `entity_action(entity_id, action)` |
| Anything else (set temperature, scene, script, notify) | `call_service_tool(domain, service, data)` |
| Automations | `list_automations` (read) |
| Dashboards | `list_dashboards`, `get_dashboard_config`, `list_view_sections`; edits via `add_card`/`update_card`/`move_card`/`remove_card`, `add_view`/`update_view`/`remove_view`; `list_dashboard_backups` + `restore_dashboard` to undo |
| Something is broken | `get_error_log(filter=...)` |

## Rules of thumb

- Confirm the entity_id with a read before writing; never guess an id.
- `call_service_tool` on `climate`, `lock`, `alarm_control_panel`, `cover`, and `restart_ha`, `set_dashboard_config`, `remove_view`, `remove_card` need Dave's explicit yes in this conversation.
- Dashboard edits are live: take a backup (`list_dashboard_backups` shows the automatic ones) and tell Dave how to restore.
- Report values with units and the entity's `last_changed` when it matters.
