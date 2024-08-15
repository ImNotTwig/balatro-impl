const std = @import("std");
const cards = @import("cards.zig");

const SELECT_SIZE = 5;

const Player = struct {
    Deck: cards.Deck = undefined,
    CurrentHand: struct {
        Contents: std.ArrayList(cards.Card) = undefined,
        Selected: std.AutoHashMap(usize, cards.Card) = undefined,
    } = .{},
    HandSize: i32 = 7,
    Discards: [2]u32 = [2]u32{ 5, 5 },
    Hands: [2]u32 = [2]u32{ 4, 4 },

    Money: i32 = 7,

    CurrentChips: i32 = 0,
    CurrentMult: i32 = 0,

    Jokers: struct {
        Slots: [2]u32 = [2]u32{ 5, 5 },
        Inventory: std.ArrayList(cards.Card) = undefined,
    } = .{},
    Consumables: struct {
        Slots: [2]u32 = [2]u32{ 2, 2 },
        Inventory: std.ArrayList(cards.Card) = undefined,
    } = .{},

    fn selectCardInHand(self: *Player, index: usize) !void {
        var iterator = self.CurrentHand.Selected.iterator();
        var i: u32 = 0;
        while (iterator.next()) |_| {
            i += 1;
        }

        if (i < SELECT_SIZE) {
            try self.CurrentHand.Selected.put(index, self.CurrentHand.Contents.orderedRemove(index - i));
        }
    }
    fn deselectCardInHand(self: *Player, index: usize) !void {
        if (index > self.CurrentHand.Contents.items.len) {
            try self.CurrentHand.Contents.insert(self.CurrentHand.Contents.items.len, self.CurrentHand.Selected.fetchRemove(index).?.value);
        } else {
            try self.CurrentHand.Contents.insert(index, self.CurrentHand.Selected.fetchRemove(index).?.value);
        }
    }

    fn drawHand(self: *Player) !void {
        while (self.CurrentHand.Contents.items.len + self.CurrentHand.Selected.keyIterator().len < self.HandSize) {
            try self.CurrentHand.Contents.append(self.Deck.CardsLeft.pop());
        }
    }

    fn playHand(self: *Player) !void {
        var iterator = self.CurrentHand.Selected.iterator();
        while (iterator.next()) |i| {
            self.CurrentChips += (switch (i.value_ptr.*.Rank.?) {
                .Ace => 11,
                .King, .Queen, .Jack => 10,
                else => @intFromEnum(i.value_ptr.*.Rank.?) + 2,
            });
            _ = self.CurrentHand.Selected.remove(i.key_ptr.*);
        }
        std.debug.print("{any}\n", .{self.CurrentChips});
    }
};

const Game = struct {
    Player: Player = .{},
};

test "Card Selection" {
    var p = Player{
        .Deck = try cards.createDeck(std.testing.allocator),
        .CurrentHand = .{
            .Selected = std.AutoHashMap(usize, cards.Card).init(std.testing.allocator),
            .Contents = std.ArrayList(cards.Card).init(std.testing.allocator),
        },
    };
    defer p.Deck.Cards.deinit();
    defer p.CurrentHand.Contents.deinit();
    defer p.CurrentHand.Selected.deinit();

    try p.Deck.shuffleDeck();
    try p.drawHand();

    for (p.CurrentHand.Contents.items) |i| {
        std.debug.print("{?} - ", .{i.Rank});
        std.debug.print("{?} | Contents\n", .{i.Suit});
    }
    std.debug.print("\n\n", .{});
    var iterator = p.CurrentHand.Selected.iterator();
    while (iterator.next()) |i| {
        std.debug.print("{any} - ", .{i.value_ptr.*.Rank});
        std.debug.print("{any} | Selected\n", .{i.value_ptr.*.Suit});
    }

    try p.selectCardInHand(0);
    try p.selectCardInHand(1);
    try p.selectCardInHand(2);
    try p.selectCardInHand(3);
    try p.selectCardInHand(4);
    try p.selectCardInHand(5);
    try p.selectCardInHand(6);

    for (p.CurrentHand.Contents.items) |i| {
        std.debug.print("{?} - ", .{i.Rank});
        std.debug.print("{?} | Contents\n", .{i.Suit});
    }
    std.debug.print("\n\n", .{});
    iterator = p.CurrentHand.Selected.iterator();
    while (iterator.next()) |i| {
        std.debug.print("{any} - ", .{i.value_ptr.*.Rank});
        std.debug.print("{any} | Selected\n", .{i.value_ptr.*.Suit});
    }

    try p.deselectCardInHand(2);

    try p.playHand();

    for (p.CurrentHand.Contents.items) |i| {
        std.debug.print("{?} - ", .{i.Rank});
        std.debug.print("{?} | Contents\n", .{i.Suit});
    }
    std.debug.print("\n\n", .{});
    iterator = p.CurrentHand.Selected.iterator();
    while (iterator.next()) |i| {
        std.debug.print("{any} - ", .{i.value_ptr.*.Rank});
        std.debug.print("{any} | Selected\n", .{i.value_ptr.*.Suit});
    }
}
