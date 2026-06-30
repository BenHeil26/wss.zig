const std = @import("std");
const URI = @import("uri.zig").URI;

const ConnectionState = enum {
    CONNECTING,
    ESTABLISHED,
    DESTROYED,
    RESET,
};

pub const Connection = struct {
    uri: *URI,
    state: ConnectionState,
    protocols: *std.ArrayList([]const u8),
    extensions: *std.ArrayList([]const u8),

    pub fn init(
        uri: *URI,
    ) @This() {
        return .{
            .uri = uri,
            .state = ConnectionState.CONNECTING,
        };
    }
};
