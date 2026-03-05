#ifndef PHPTORO_PLUGIN_CLIPBOARD_H
#define PHPTORO_PLUGIN_CLIPBOARD_H

#include "phptoro_plugin.h"

phptoro_plugin phptoro_clipboard_plugin(void);

/*
 * Commands:
 *   clipboard.read   — Read text from system clipboard
 *     {} → { "text": "..." }
 *
 *   clipboard.write  — Write text to system clipboard
 *     { "text": "..." } → { "ok": true }
 */

#endif
