const std = @import("std");
const util = @import("util.zig");
// const Map = std.StaticStringMap([]const u8);

const URIError = error{InvalidProtocol};

pub const URI = struct {
    secure: bool,
    host: []const u8,
    port: u16,
    path: []const u8,
    query_str: ?[]const u8,
    // query: Map,

    pub fn init(
        // allocator: std.mem.Allocator,
        text: []const u8,
    ) anyerror!@This() {
        // _ = allocator;

        var start: usize = 0;
        var end: ?usize = 0;

        // determine if secure or not
        end = util.index_of(u8, text, ':', 1);
        if (end == null) return URIError.InvalidProtocol;
        const protocol = text[0..end.?];

        var secure = false;
        if (std.mem.eql(u8, "wss", protocol)) {
            secure = true;
        }

        // pull the host
        start = end.? + 3; // advance past scheme separator
        end = util.index_of(u8, text, '/', 3);
        if (end == null or end.? < start) end = text.len;
        var host = text[start..end.?];

        // grab the port from the host string
        const port_idx: ?usize = util.index_of(u8, host, ':', 1);
        const port: u16 =
            if (port_idx == null)
                switch (secure) {
                    true => 443,
                    false => 80,
                }
            else
                try std.fmt.parseInt(u16, host[port_idx.? + 1 ..], 10);
        if (port_idx != null) host = host[0..port_idx.?];

        // everything after host is path and query
        start = end.?;
        var path = text[start..];

        // strip the query string
        const query_str_idx = util.index_of(u8, path, '?', 1);
        const query_str = if (query_str_idx == null) null else path[query_str_idx.?..];
        if (query_str_idx != null) {
            path = path[0..query_str_idx.?];
        }

        return .{
            .secure = secure,
            .host = host,
            .port = port,
            .path = path,
            .query_str = query_str,
        };
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("{s}://{s}:{d}{s}{s}", .{
            self.fmt_protocol(),
            self.host,
            self.port,
            self.path,
            self.fmt_query(),
        });
    }

    fn fmt_protocol(self: @This()) []const u8 {
        return if (self.secure) "wss" else "ws";
    }

    fn fmt_query(self: @This()) []const u8 {
        return self.query_str orelse "";
    }
};

test "print URI secure" {
    const test_uri = "wss://example.com:5050/foo/bar?foobar=blah";
    const uri: URI = try .init(test_uri);

    const io = std.testing.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try uri.format(stdout_writer);
    const result = stdout_writer.buffered();

    try stdout_writer.flush();

    try std.testing.expectEqualStrings(test_uri, result);
}
