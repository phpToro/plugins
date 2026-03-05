#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#include "notification.h"
#include <stdlib.h>
#include <string.h>

static NSString *json_string(const char *json, const char *key) {
    NSData *data = [NSData dataWithBytes:json length:strlen(json)];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    id val = dict[[NSString stringWithUTF8String:key]];
    return [val isKindOfClass:[NSString class]] ? val : nil;
}

static BOOL ensure_permission(void) {
    __block BOOL granted = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    [[UNUserNotificationCenter currentNotificationCenter]
        requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
        completionHandler:^(BOOL g, NSError *error) {
            granted = g;
            dispatch_semaphore_signal(sem);
        }];

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return granted;
}

static char *handle_send(const char *json) {
    if (!ensure_permission()) {
        return strdup("{\"error\":\"notification permission denied\"}");
    }

    NSString *title = json_string(json, "title") ?: @"Notification";
    NSString *body  = json_string(json, "body")  ?: @"";

    __block char *result = NULL;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = body;
    content.sound = [UNNotificationSound defaultSound];

    NSString *identifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *request = [UNNotificationRequest
        requestWithIdentifier:identifier content:content trigger:nil];

    [[UNUserNotificationCenter currentNotificationCenter]
        addNotificationRequest:request withCompletionHandler:^(NSError *error) {
            if (error) {
                char *buf = malloc(256);
                snprintf(buf, 256, "{\"error\":\"%s\"}", [error.localizedDescription UTF8String]);
                result = buf;
            } else {
                result = strdup("{\"ok\":true}");
            }
            dispatch_semaphore_signal(sem);
        }];

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return result ?: strdup("{\"ok\":true}");
}

static char *handle_permission(const char *json) {
    return ensure_permission()
        ? strdup("{\"granted\":true}")
        : strdup("{\"granted\":false}");
}

static char *notification_handle(const char *command, const char *json) {
    if (strcmp(command, "send") == 0)       return handle_send(json);
    if (strcmp(command, "permission") == 0) return handle_permission(json);
    return strdup("{\"error\":\"unknown notification command\"}");
}

phptoro_plugin phptoro_notification_plugin(void) {
    return (phptoro_plugin){ .ns = "notification", .handle = notification_handle };
}
