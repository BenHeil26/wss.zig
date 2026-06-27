//! This module contains helpful utilities needed by this project

const std = @import("std");

/// Finds the index of a value in a slice
///
/// # Parameters
/// - `T`: The type of the slice
/// - `slice`: The slice to search
/// - `value`: The value to search for
/// - `occ`: Which occurrence to search for, 1 for first, 2 for second, etc
///
/// # Returns
/// The Nth index of a value when present in a slice, null otherwise
pub fn index_of(
    comptime T: type,
    slice: []const T,
    value: T,
    occ: u8,
) ?usize {
    var count: u8 = 0;
    for (slice, 0..) |item, i| {
        if (item == value) {
            count += 1;
            if (count == occ) return i;
        }
    }
    return null;
}

test "index_of char[] contains thing" {
    const string = "This is a test string";
    const index = 4;

    const result = index_of(u8, string, ' ', 1);

    try std.testing.expectEqual(index, result);
}

test "index_of char[] doesn't contain thing" {
    const string = "This is a test string";
    const index = null;

    const result = index_of(u8, string, '/', 1);

    try std.testing.expectEqual(index, result);
}

test "index_of char[] doesn't contain 2 occurences of thing" {
    const string = "This is a test string";
    const index = null;

    const result = index_of(u8, string, 'a', 2);

    try std.testing.expectEqual(index, result);
}

test "index_of int[] contains thing" {
    const ints = [_]u8{ 2, 4, 6, 8, 10 };
    const index = 2;

    const result = index_of(u8, &ints, 6, 1);

    try std.testing.expectEqual(index, result);
}

test "index_of int[] doesn't contain thing" {
    const ints = [_]u8{ 2, 4, 6, 8, 10 };
    const index = null;

    const result = index_of(u8, &ints, 7, 1);

    try std.testing.expectEqual(index, result);
}
