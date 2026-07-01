//! This module provides support for standard HTTP requests
//! HTTP Requests are defined as https://www.rfc-editor.org/info/rfc2616/
const std = @import("std");
const Method = @import("method.zig").Method;

pub const ProtocolVersions = enum {
    @"1.1",
    @"2",
    @"3",
};

pub const HttpRequest = struct {
    method: Method,
    resource: []const u8,
    protocol: ProtocolVersions,
    headers: std.StringHashMap([]const u8),
    body: []const u8,
};
