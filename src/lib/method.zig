//! This module provides support for HTTP request methods
//! as defined by https://www.rfc-editor.org/info/rfc2616/
const std = @import("std");

const MethodErrors = error{MethodNotSupported};

const method_map: std.StaticStringMap(Method) = .initComptime(.{
    .{ "GET", Method.GET },
    .{ "PUT", Method.PUT },
    .{ "POST", Method.POST },
    .{ "PATCH", Method.PATCH },
    .{ "DELETE", Method.DELETE },
    .{ "OPTIONS", Method.OPTIONS },
});

pub const Method = enum {
    GET,
    PUT,
    POST,
    PATCH,
    DELETE,
    OPTIONS,

    pub fn init(method: []const u8) !@This() {
        return method_map.get(method) orelse MethodErrors.MethodNotSupported;
    }
};
