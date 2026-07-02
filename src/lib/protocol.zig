//! This module provides support for HTTP request protocols
const std = @import("std");

const ProtocolErrors = error{ProtocolNotSupported};

const protocol_map: std.StaticStringMap(Protocol) = .initComptime(.{
    .{ "HTTP/1.1", Protocol.@"HTTP/1.1" },
    .{ "HTTP/2", Protocol.@"HTTP/2" },
    .{ "HTTP/3", Protocol.@"HTTP/3" },
});

pub const Protocol = enum {
    @"HTTP/1.1",
    @"HTTP/2",
    @"HTTP/3",

    pub fn init(protocol: []const u8) !@This() {
        return protocol_map.get(protocol) orelse ProtocolErrors.ProtocolNotSupported;
    }
};
