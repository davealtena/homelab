---
name: unifi-ops
description: "How to use the two-step UniFi Network MCP (tool_index -> execute) for client, device, WiFi, firewall and alert questions, and when a change needs confirmation."
version: 1.0.0
author: dave
license: MIT
metadata:
  hermes:
    tags: [unifi, network, mcp]
---

# UniFi Network via unifi-network-mcp

The server exposes a small meta-API with prefix `unifi-network-mcp_`:

1. `unifi_tool_index(query)` - search the catalogue of UniFi tools by keyword (e.g. "clients", "wlan", "firewall", "alarms", "devices", "dpi"). Read the returned tool name and argument schema.
2. `unifi_execute(tool, arguments)` - run that tool. Pass arguments exactly as the schema says (site is usually `default`).
3. `unifi_batch([...])` + `unifi_batch_status(id)` - run several read-only queries in parallel and collect them.
4. `unifi_load_tools(group)` - loads a whole tool family when you need many calls in one area.

## Common questions

| Question | Index query | Typical tool |
|----------|-------------|--------------|
| Who is online, on which AP/switch port | "clients" | list clients, filter `is_wired`, `ap_mac`, `essid` |
| Device health, uptime, firmware | "devices" | list devices / device detail |
| WiFi networks and their settings | "wlan" | list wlanconf |
| Recent alerts / events | "alarms", "events" | list alarms (unarchived) |
| Top applications / traffic | "dpi", "traffic" | DPI stats per client or site |
| Firewall / traffic rules | "firewall" | list rules (read); changes only after confirmation |

## Rules

- Everything read-only is fine. Create/update/delete/block/kick/reboot tools need an explicit confirmation from Dave in this conversation; state the exact change first.
- Never touch the VLAN, port profile or firewall rule of the homelab host `phobos` or the LB range 192.168.1.128-133.
- Report MACs only when asked; prefer hostnames and IPs.
