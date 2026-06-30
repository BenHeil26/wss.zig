//! This module provides support for a websocket connection
const std = @import("std");
const URI = @import("uri.zig").URI;

pub const ConnectionState = enum {
    /// The initial state for every connection
    CONNECTING,
    /// A successfully created connection
    ESTABLISHED,
    /// A connection that has been gracefully closed
    CLOSED,
    /// A connection that was not gracefully closed
    RESET,
};

pub const Connection = struct {
    /// The URI for the request (ex. wss://example.com:5050/foo/bar?baz=boo)
    uri: *URI,
    /// The current state of the connection
    state: ConnectionState,
    /// An array of sub-protocols specified by the client
    protocols: *std.ArrayList([]const u8),
    /// An array of extensions specified by the client
    extensions: *std.ArrayList([]const u8),

    pub fn init(
        uri: *URI,
        protocols: *std.ArrayList([]const u8),
        extensions: *std.ArrayList([]const u8),
    ) @This() {
        return .{
            .uri = uri,
            .state = ConnectionState.CONNECTING,
            .protocols = protocols,
            .extensions = extensions,
        };
    }
};
