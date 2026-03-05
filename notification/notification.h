#ifndef PHPTORO_PLUGIN_NOTIFICATION_H
#define PHPTORO_PLUGIN_NOTIFICATION_H

#include "phptoro_plugin.h"

/* Returns the notification plugin. Register with phptoro_register_plugin(). */
phptoro_plugin phptoro_notification_plugin(void);

/*
 * Commands:
 *   notification.send   — Send a local notification
 *     { "title": "...", "body": "..." }
 *
 *   notification.permission  — Check/request permission
 *     {}
 */

#endif
