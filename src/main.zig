const std = @import("std");
const cards = @import("cards.zig");
const game = @import("game.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var d = try cards.createDeck(allocator);
    try d.shuffleDeck();
    defer d.Cards.deinit();

    // std.debug.print("{s} - {s} - {s}\n", .{ deck.getVanillaCardData(d.Cards.items[0]), deck.getVanillaCardData(d.Cards.items[25]), deck.getVanillaCardData(d.Cards.items[51]) });

    for (0..7) |i| {
        cards.printVanillaCardData(d.Cards.items[i]);
    }

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
