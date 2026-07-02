//! This module provides support for standard HTTP requests
//! HTTP Requests are defined as https://www.rfc-editor.org/info/rfc2616/
const std = @import("std");
const Method = @import("method.zig").Method;
const Protocol = @import("protocol.zig").Protocol;
const util = @import("util.zig");

const RequestError = error{MalformedStartline};

/// Parses an HTTP request string into an object
///   and HTTP request is defined here
///   https://www.rfc-editor.org/info/rfc2616/#section-4
///
/// This function does not provide any serialization beyond tokenizing
/// the request startline and headers
///
/// # Parameters
/// - `allocator`: the allocator to use
/// - `text`: a string containing the raw HTTP request
///
/// # Returns
/// An HttpRequest object or an error
pub fn parse_request(
    allocator: std.mem.Allocator,
    text: []const u8,
) !Request {
    var start: usize = 0;
    var end: usize = util.index_of(u8, text, ' ', 1) orelse return RequestError.MalformedStartline;

    // parse method
    const method = try Method.init(text[start..end]);

    // parse resource
    start += end + 1;
    end = util.index_of(u8, text[start..], ' ', 1) orelse return RequestError.MalformedStartline;
    const resource = text[start .. end + start];

    // parse protocol
    start += end + 1;
    end = util.index_of(u8, text[start..], '\n', 1) orelse return RequestError.MalformedStartline;
    const protocol = try Protocol.init(text[start .. end + start]);

    return .{
        .method = method,
        .resource = resource,
        .protocol = protocol,
        .headers = &std.StringHashMap([]const u8).init(allocator),
        .body = "",
    };
}

fn parse_headers() *std.StringHashMap([]const u8) {}

pub const Request = struct {
    method: Method,
    resource: []const u8,
    protocol: Protocol,
    headers: *const std.StringHashMap([]const u8),
    body: []const u8,

    pub fn init(
        method: Method,
        resource: []const u8,
        protocol: Protocol,
        headers: std.StringHashMap([]const u8),
        body: []const u8,
    ) @This() {
        return .{
            .method = method,
            .resource = resource,
            .protocol = protocol,
            .headers = headers,
            .body = body,
        };
    }

    pub fn deinit(self: @This()) void {
        self.headers.deinit();
    }
};

const test_request =
    \\GET / HTTP/1.1
    \\Host: api.example.com
    \\Origin: site.example.com
    \\Foo: bar
    \\
    \\{}
;

test "parse requests" {
    const allocator = std.debug.getDebugInfoAllocator();

    const request = try parse_request(allocator, test_request);

    try std.testing.expectEqual(Method.GET, request.method);
    try std.testing.expectEqualStrings("/", request.resource);
    try std.testing.expectEqual(Protocol.@"HTTP/1.1", request.protocol);
}
