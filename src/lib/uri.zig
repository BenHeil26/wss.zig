const std = @import("std");
const util = @import("util.zig");

const URIError = error{InvalidProtocol};

fn parse_query(
    map: *std.StringHashMap([]const u8),
    query_str: []const u8,
) !void {
    var b: usize = 0;
    for (query_str, 0..) |c, i| {
        if (c == '&') {
            try parse_query_segment(map, query_str[b + 1 .. i]);
            b = i;
        }
    }
    if (b < query_str.len) {
        try parse_query_segment(map, query_str[b + 1 .. query_str.len]);
    }
}

fn parse_query_segment(
    map: *std.StringHashMap([]const u8),
    query_segment: []const u8,
) !void {
    const sidx = util.index_of(u8, query_segment, '=', 1);
    if (sidx != null) {
        try map.put(query_segment[0..sidx.?], query_segment[sidx.? + 1 ..]);
    } else {
        try map.put(query_segment, query_segment);
    }
}

pub const URI = struct {
    secure: bool,
    host: []const u8,
    port: u16,
    path: []const u8,
    query_str: ?[]const u8,
    query: ?std.StringHashMap([]const u8),

    pub fn init(
        allocator: std.mem.Allocator,
        text: []const u8,
    ) anyerror!@This() {
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

        if (path.len == 0) {
            path = "/";
        }

        // strip the query string
        const query_str_idx = util.index_of(u8, path, '?', 1);
        const query_str = if (query_str_idx == null) null else path[query_str_idx.?..];
        if (query_str_idx != null) {
            path = path[0..query_str_idx.?];
        }

        // tokenize each {k, v} in the query string as a map
        var query: ?std.StringHashMap([]const u8) = null;
        if (query_str != null) {
            query = std.StringHashMap([]const u8).init(allocator);
            try parse_query(&query.?, query_str.?[0..]);
        }

        return .{
            .secure = secure,
            .host = host,
            .port = port,
            .path = path,
            .query_str = query_str,
            .query = query,
        };
    }

    pub fn deinit(self: @This()) void {
        if (self.query != null) self.query.?.deinit();
    }

    pub fn get_query(
        self: @This(),
        key: []const u8,
    ) ?[]const u8 {
        return self.query.?.get(key);
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

const tests_cases = [_]struct { []const u8, []const u8 }{
    .{
        "wss://example.com:5050/foo/bar?baz=boo&foo=blah",
        "wss://example.com:5050/foo/bar?baz=boo&foo=blah",
    },
    .{
        "ws://localhost:430",
        "ws://localhost:430/",
    },
    .{
        "wss://127.0.0.1/?foo=bar&baz=boo&pop=drop",
        "wss://127.0.0.1:443/?foo=bar&baz=boo&pop=drop",
    },
};
test "parse URI" {
    const io = std.testing.io;
    const allocator = std.debug.getDebugInfoAllocator();

    for (tests_cases) |test_case| {
        const test_uri = test_case.@"0";
        const expected = test_case.@"1";
        const uri: URI = try .init(allocator, test_uri);
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
        const stdout_writer = &stdout_file_writer.interface;

        try uri.format(stdout_writer);
        const result = stdout_writer.buffered();

        try stdout_writer.flush();

        try std.testing.expectEqualStrings(expected, result);
    }
}

test "get query parameters" {
    const results = [_]?[]const u8{
        "blah",
        null,
        "bar",
    };
    const allocator = std.debug.getDebugInfoAllocator();

    for (tests_cases, 0..) |test_case, i| {
        const test_uri = test_case.@"0";
        const uri: URI = try .init(allocator, test_uri);

        if (results[i] != null) {
            try std.testing.expectEqualStrings(results[i].?, uri.get_query("foo").?);
        } else {
            try std.testing.expectEqual(results[i], null);
        }
    }
}
