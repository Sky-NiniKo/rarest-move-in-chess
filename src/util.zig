const std = @import("std");

pub fn megabytes(n: u64) u64 {
    return n * 1024 * 1024;
}

pub fn readUntilDelimiter(s: *[]u8) ?[]u8 {
    if (s.*.len == 0) return null;

    var i: u32 = 0;
    while (i < s.*.len - 1 and s.*[i] != '\n') {
        i += 1;
    }
    i += 1;

    const r = s.*[0..i];
    s.*.ptr += i;
    s.*.len -= i;
    return r;
}

test "readUntilDelimiter" {
    const allocator = std.testing.allocator;
    const orig = try allocator.dupe(u8, "abc\nd\n\n");
    defer allocator.free(orig);
    var s = orig;

    try std.testing.expectEqualSlices(u8, readUntilDelimiter(&s).?, "abc\n");
    try std.testing.expectEqualSlices(u8, readUntilDelimiter(&s).?, "d\n");
    try std.testing.expectEqualSlices(u8, readUntilDelimiter(&s).?, "\n");
    const final = readUntilDelimiter(&s);
    try std.testing.expect(final == null);
}

const esc = "\x1B";
const csi = esc ++ "[";
pub fn clearCurrentLine() void {
    std.debug.print(csi ++ "2K" ++ csi ++ "1G", .{});
}

// Why did you bother making such a complicated progress bar for a completely unrelated chess program? good question
fn FormatProgressImpl() type {
    return struct {
        pub fn f(
            progress: f32,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            const WIDTH = 20; // Yo this should really come from options
            const filled = "█";
            const empty = " ";
            // That's right, SUB-CHARACTER progress rendering
            // "██▉▊▋▌▍▎▏ ";
            const partialChars = [_]*const [3:0]u8{ "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█" };

            var i: usize = 0;
            const fillTill: i64 = @intFromFloat(std.math.floor(progress * WIDTH));

            try writer.writeAll("▐");

            // fill the filled part
            while (i < fillTill) : (i += 1) {
                try writer.writeAll(filled);
            }

            // fill the last character (the sub-character part)
            if (fillTill != WIDTH) {
                const subpixelFillLevel = (progress * WIDTH) - std.math.floor(progress * WIDTH);
                const subpixelIndex = @as(u64, @intFromFloat(std.math.floor(subpixelFillLevel * (@as(f32, @floatFromInt(partialChars.len))))));
                i += 1;
                try writer.writeAll(partialChars[subpixelIndex]);
            }

            // fill the unfilled part
            while (i < WIDTH) : (i += 1) {
                try writer.writeAll(empty);
            }

            try writer.writeAll("▌ ");

            // write percentage
            try std.fmt.format(writer, "{d:.1}%", .{100.0 * progress});
        }
    };
}

const formatProgress = FormatProgressImpl().f;
pub fn fmtProgress(current: anytype, outOf: anytype) std.fmt.Formatter(formatProgress) {
    const progress = @as(f32, @floatFromInt(current)) / @as(f32, @floatFromInt(outOf));
    return .{ .data = progress };
}

fn FormatCommaImpl() type {
    return struct {
        pub fn f(
            number: i64,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            const MAX_NUMBER_SIZE = 30;
            var buf: [MAX_NUMBER_SIZE]u8 = undefined;
            var printedNumberBuf: [MAX_NUMBER_SIZE]u8 = undefined;

            const absNumber = @abs(number);

            const written = std.fmt.formatIntBuf(&printedNumberBuf, absNumber, 10, .lower, .{});

            //   i         written
            //   v         v
            //  [1000000000          ]
            //  [       1,000,000,000]
            //          ^
            //          j
            var i: u32 = 0;
            var j: u32 = 0;
            const end = MAX_NUMBER_SIZE - 1;
            while (i < written) {
                buf[end - j] = printedNumberBuf[written - 1 - i];
                i += 1;
                j += 1;
                if (i >= written) break;
                buf[end - j] = printedNumberBuf[written - 1 - i];
                i += 1;
                j += 1;
                if (i >= written) break;
                buf[end - j] = printedNumberBuf[written - 1 - i];
                i += 1;
                j += 1;
                if (i >= written) break;
                buf[end - j] = ',';
                j += 1;
            }

            const towrite = buf[end + 1 - j .. MAX_NUMBER_SIZE];
            var size = towrite.len;
            if (number < 0) size += 1;

            if (options.width) |width| {
                var toFill = @as(i64, @intCast(width)) - @as(i64, @intCast(size));
                while (toFill > 0) : (toFill -= 1) {
                    // TODO: should write options.fill
                    try writer.writeAll("x");
                }
            }

            if (number < 0) try writer.writeAll("-");
            try writer.writeAll(towrite);
        }
    };
}

test "formatProgress" {
    var j: u32 = 0;
    std.debug.print("\n", .{});
    while (j <= 100) : (j += 1) {
        std.debug.print("Doing stuff.... {}\r", .{fmtProgress(@as(u32, j), @as(u32, 100))});
        std.time.sleep(40 * std.time.ns_per_ms);
    }

    var buf: [200]u8 = undefined;
    var written = try std.fmt.bufPrint(&buf, "{}", .{fmtProgress(@as(u32, 5), @as(u32, 10))});
    try std.testing.expectEqualStrings(written, "▐██████████▏         ▌ 50.0%");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtProgress(@as(u32, 0), @as(u32, 10))});
    try std.testing.expectEqualStrings(written, "▐▏                   ▌ 0.0%");

    const expected =
        \\▐▏                   ▌ 0.0%
        \\▐▎                   ▌ 1.0%
        \\▐▌                   ▌ 2.0%
        \\▐▋                   ▌ 3.0%
        \\▐▉                   ▌ 4.0%
        \\▐█▏                  ▌ 5.0%
        \\▐█▎                  ▌ 6.0%
        \\▐█▌                  ▌ 7.0%
        \\▐█▋                  ▌ 8.0%
        \\▐█▉                  ▌ 9.0%
        \\▐██▏                 ▌ 10.0%
        \\▐██▎                 ▌ 11.0%
        \\▐██▌                 ▌ 12.0%
        \\▐██▋                 ▌ 13.0%
        \\▐██▉                 ▌ 14.0%
        \\▐███▏                ▌ 15.0%
        \\▐███▎                ▌ 16.0%
        \\▐███▌                ▌ 17.0%
        \\▐███▋                ▌ 18.0%
        \\▐███▉                ▌ 19.0%
        \\▐████▏               ▌ 20.0%
        \\▐████▎               ▌ 21.0%
        \\▐████▌               ▌ 22.0%
        \\▐████▋               ▌ 23.0%
        \\▐████▉               ▌ 24.0%
        \\▐█████▏              ▌ 25.0%
        \\▐█████▎              ▌ 26.0%
        \\▐█████▌              ▌ 27.0%
        \\▐█████▋              ▌ 28.0%
        \\▐█████▉              ▌ 29.0%
        \\▐██████▏             ▌ 30.0%
        \\▐██████▎             ▌ 31.0%
        \\▐██████▌             ▌ 32.0%
        \\▐██████▋             ▌ 33.0%
        \\▐██████▉             ▌ 34.0%
        \\▐███████▏            ▌ 35.0%
        \\▐███████▎            ▌ 36.0%
        \\▐███████▌            ▌ 37.0%
        \\▐███████▋            ▌ 38.0%
        \\▐███████▉            ▌ 39.0%
        \\▐████████▏           ▌ 40.0%
        \\▐████████▎           ▌ 41.0%
        \\▐████████▌           ▌ 42.0%
        \\▐████████▋           ▌ 43.0%
        \\▐████████▉           ▌ 44.0%
        \\▐█████████▏          ▌ 45.0%
        \\▐█████████▎          ▌ 46.0%
        \\▐█████████▌          ▌ 47.0%
        \\▐█████████▋          ▌ 48.0%
        \\▐█████████▉          ▌ 49.0%
        \\▐██████████▏         ▌ 50.0%
        \\▐██████████▎         ▌ 51.0%
        \\▐██████████▌         ▌ 52.0%
        \\▐██████████▋         ▌ 53.0%
        \\▐██████████▉         ▌ 54.0%
        \\▐███████████▏        ▌ 55.0%
        \\▐███████████▎        ▌ 56.0%
        \\▐███████████▌        ▌ 57.0%
        \\▐███████████▋        ▌ 58.0%
        \\▐███████████▉        ▌ 59.0%
        \\▐████████████▏       ▌ 60.0%
        \\▐████████████▎       ▌ 61.0%
        \\▐████████████▌       ▌ 62.0%
        \\▐████████████▋       ▌ 63.0%
        \\▐████████████▉       ▌ 64.0%
        \\▐█████████████▏      ▌ 65.0%
        \\▐█████████████▎      ▌ 66.0%
        \\▐█████████████▌      ▌ 67.0%
        \\▐█████████████▋      ▌ 68.0%
        \\▐█████████████▉      ▌ 69.0%
        \\▐██████████████▏     ▌ 70.0%
        \\▐██████████████▎     ▌ 71.0%
        \\▐██████████████▌     ▌ 72.0%
        \\▐██████████████▋     ▌ 73.0%
        \\▐██████████████▉     ▌ 74.0%
        \\▐███████████████▏    ▌ 75.0%
        \\▐███████████████▎    ▌ 76.0%
        \\▐███████████████▌    ▌ 77.0%
        \\▐███████████████▋    ▌ 78.0%
        \\▐███████████████▉    ▌ 79.0%
        \\▐████████████████▏   ▌ 80.0%
        \\▐████████████████▎   ▌ 81.0%
        \\▐████████████████▌   ▌ 82.0%
        \\▐████████████████▋   ▌ 83.0%
        \\▐████████████████▉   ▌ 84.0%
        \\▐█████████████████▏  ▌ 85.0%
        \\▐█████████████████▎  ▌ 86.0%
        \\▐█████████████████▌  ▌ 87.0%
        \\▐█████████████████▋  ▌ 88.0%
        \\▐█████████████████▉  ▌ 89.0%
        \\▐██████████████████▏ ▌ 90.0%
        \\▐██████████████████▎ ▌ 91.0%
        \\▐██████████████████▌ ▌ 92.0%
        \\▐██████████████████▋ ▌ 93.0%
        \\▐██████████████████▉ ▌ 94.0%
        \\▐███████████████████▏▌ 95.0%
        \\▐███████████████████▎▌ 96.0%
        \\▐███████████████████▌▌ 97.0%
        \\▐███████████████████▋▌ 98.0%
        \\▐███████████████████▉▌ 99.0%
        \\▐████████████████████▌ 100.0%
    ;

    var linesIterator = std.mem.splitSequence(u8, expected, "\n");
    var i: u32 = 0;
    while (linesIterator.next()) |expect| {
        written = try std.fmt.bufPrint(&buf, "{}", .{fmtProgress(i, @as(u32, 100))});
        try std.testing.expectEqualStrings(written, expect);
        i += 1;
    }
}

const formatComma = FormatCommaImpl().f;
pub fn fmtComma(number: anytype) std.fmt.Formatter(formatComma) {
    return .{ .data = @as(i64, @intCast(number)) };
}

test "formatComma" {
    var buf: [100]u8 = undefined;
    var written = try std.fmt.bufPrint(&buf, "{}", .{fmtComma(@as(u32, @intCast(1)))});
    try std.testing.expectEqualStrings(written, "1");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtComma(@as(i32, @intCast(-1)))});
    try std.testing.expectEqualStrings(written, "-1");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtComma(@as(u32, @intCast(789)))});
    try std.testing.expectEqualStrings(written, "789");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtComma(@as(u32, @intCast(1_000)))});
    try std.testing.expectEqualStrings(written, "1,000");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtComma(@as(u32, @intCast(123_456_789)))});
    try std.testing.expectEqualStrings(written, "123,456,789");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtComma(@as(i32, @intCast(-123_456_789)))});
    try std.testing.expectEqualStrings(written, "-123,456,789");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtComma(@as(i64, @intCast(9_223_372_036_854_775_807)))});
    try std.testing.expectEqualStrings(written, "9,223,372,036,854,775,807");

    written = try std.fmt.bufPrint(&buf, "{:x>5}", .{fmtComma(@as(u32, @intCast(789)))});
    try std.testing.expectEqualStrings(written, "xx789");

    written = try std.fmt.bufPrint(&buf, "{:x>5}", .{fmtComma(@as(u32, @intCast(1789)))});
    try std.testing.expectEqualStrings(written, "1,789");
}

fn FormatTimeSecImpl() type {
    return struct {
        pub fn f(
            seconds: u64,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;

            if (seconds < 60) {
                try std.fmt.formatInt(seconds, 10, .lower, .{}, writer);
                try writer.writeAll("s");
                return;
            }
            const mins = (seconds + 30) / 60;
            if (seconds < 60 * 60) {
                try std.fmt.formatInt(mins, 10, .lower, .{}, writer);
                try writer.writeAll("m");
                return;
            }

            const hrs = (mins + 30) / 60;
            try std.fmt.formatInt(hrs, 10, .lower, .{}, writer);
            try writer.writeAll("hr");

            // TODO: days? weeks? months? years?
        }
    };
}

const formatTimeSec = FormatTimeSecImpl().f;
pub fn fmtTimeSec(seconds: anytype) std.fmt.Formatter(formatTimeSec) {
    return .{ .data = @as(u64, @intCast(seconds)) };
}

test "formatTimeSec" {
    var buf: [100]u8 = undefined;
    var written = try std.fmt.bufPrint(&buf, "{}", .{fmtTimeSec(@as(u32, @intCast(1)))});
    try std.testing.expectEqualStrings(written, "1s");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtTimeSec(@as(u32, @intCast(59)))});
    try std.testing.expectEqualStrings(written, "59s");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtTimeSec(@as(u32, @intCast(60)))});
    try std.testing.expectEqualStrings(written, "1m");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtTimeSec(@as(u32, @intCast(89)))});
    try std.testing.expectEqualStrings(written, "1m");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtTimeSec(@as(u32, @intCast(90)))});
    try std.testing.expectEqualStrings(written, "2m");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtTimeSec(@as(u32, @intCast(3540)))});
    try std.testing.expectEqualStrings(written, "59m");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtTimeSec(@as(u32, @intCast(3600)))});
    try std.testing.expectEqualStrings(written, "1hr");

    written = try std.fmt.bufPrint(&buf, "{}", .{fmtTimeSec(@as(u32, @intCast(5401)))});
    try std.testing.expectEqualStrings(written, "2hr");
}

pub fn sortMovesByFrequency(map: *std.StringArrayHashMap(u64)) void {
    // Sort moves by frequency (works because std.StringArrayHashMap is ordered by insertion order)
    const C = struct {
        values: []u64,
        pub fn lessThan(ctx: @This(), a_index: usize, b_index: usize) bool {
            return ctx.values[a_index] > ctx.values[b_index];
        }
    };
    map.*.sort(C{ .values = map.*.values() });
}
