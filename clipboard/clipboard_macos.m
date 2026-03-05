#import <Cocoa/Cocoa.h>
#include "clipboard.h"
#include <stdlib.h>
#include <string.h>

/* Escape a string for JSON output */
static char *json_escape(const char *str) {
    if (!str) return strdup("");
    size_t len = strlen(str);
    /* Worst case: every char needs escaping → 6× (for \uXXXX) */
    char *out = malloc(len * 6 + 1);
    char *p = out;
    for (size_t i = 0; i < len; i++) {
        unsigned char c = str[i];
        switch (c) {
            case '"':  *p++ = '\\'; *p++ = '"';  break;
            case '\\': *p++ = '\\'; *p++ = '\\'; break;
            case '\n': *p++ = '\\'; *p++ = 'n';  break;
            case '\r': *p++ = '\\'; *p++ = 'r';  break;
            case '\t': *p++ = '\\'; *p++ = 't';  break;
            default:
                if (c < 0x20) {
                    p += sprintf(p, "\\u%04x", c);
                } else {
                    *p++ = c;
                }
        }
    }
    *p = '\0';
    return out;
}

static char *handle_read(const char *json) {
    NSString *text = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
    const char *utf8 = text ? [text UTF8String] : "";
    char *escaped = json_escape(utf8);
    char *result = malloc(strlen(escaped) + 32);
    sprintf(result, "{\"text\":\"%s\"}", escaped);
    free(escaped);
    return result;
}

static char *handle_write(const char *json) {
    NSData *data = [NSData dataWithBytes:json length:strlen(json)];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *text = dict[@"text"];

    if (!text || ![text isKindOfClass:[NSString class]]) {
        return strdup("{\"error\":\"missing text field\"}");
    }

    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb setString:text forType:NSPasteboardTypeString];
    return strdup("{\"ok\":true}");
}

static char *clipboard_handle(const char *command, const char *json) {
    if (strcmp(command, "read") == 0)  return handle_read(json);
    if (strcmp(command, "write") == 0) return handle_write(json);
    return strdup("{\"error\":\"unknown clipboard command\"}");
}

phptoro_plugin phptoro_clipboard_plugin(void) {
    return (phptoro_plugin){ .ns = "clipboard", .handle = clipboard_handle };
}
