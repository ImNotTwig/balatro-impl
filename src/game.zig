const std = @import("std");
const cards = @import("cards.zig");

const SELECT_SIZE = 5;

const Player = struct {
    deck: cards.Deck = undefined,
    currentHand: struct {
        notSelected: std.ArrayList(cards.Card) = undefined,
        selected: std.AutoHashMap(usize, cards.Card) = undefined,
    } = .{},
    handSize: i32 = 7,
    discards: [2]u32 = [2]u32{ 5, 5 },
    hands: [2]u32 = [2]u32{ 4, 4 },

    money: i32 = 7,

    currentChips: i32 = 0,
    currentMult: i32 = 0,

    jokers: struct {
        slots: [2]u32 = [2]u32{ 5, 5 },
        inventory: std.ArrayList(cards.Card) = undefined,
    } = .{},
    consumables: struct {
        slots: [2]u32 = [2]u32{ 2, 2 },
        inventory: std.ArrayList(cards.Card) = undefined,
    } = .{},

    fn selectCardInHand(self: *Player, index: usize) !void {
        var iterator = self.currentHand.selected.iterator();
        var selectedLen: u32 = 0;
        while (iterator.next()) |_| {
            selectedLen += 1;
        }

        const ix: i32 = @as(i32, @intCast(index - selectedLen)) - 1;

        var adjustedIndex: usize = 0;
        if (ix < 0) {
            adjustedIndex = 0;
        } else if (ix == 0) {
            adjustedIndex = index;
            if (ix + 1 > 0) adjustedIndex = 1;
        } else {
            adjustedIndex = if (index <= selectedLen) index - selectedLen - 1 else index - selectedLen;
        }

        if (self.currentHand.notSelected.items.len == 0)
            return;
        if (selectedLen <= SELECT_SIZE and adjustedIndex > self.currentHand.notSelected.items.len)
            return;

        if (selectedLen <= SELECT_SIZE or self.currentHand.notSelected.items[adjustedIndex].edition == cards.Edition.Neg)
            try self.currentHand.selected.put(index, self.currentHand.notSelected.orderedRemove(adjustedIndex));
    }

    fn deselectCardInHand(self: *Player, index: usize) !void {
        const len = self.currentHand.notSelected.items.len;
        const crd = self.currentHand.selected.fetchRemove(index).?.value;
        if (index > len) {
            try self.currentHand.notSelected.insert(len, crd);
        } else {
            try self.currentHand.notSelected.insert(index, crd);
        }
    }

    fn drawHand(self: *Player) !void {
        while (self.currentHand.notSelected.items.len + self.currentHand.selected.keyIterator().len < self.handSize) {
            try self.currentHand.notSelected.append(self.deck.cardsLeft.pop());
        }
    }

    fn playHand(self: *Player, all: std.mem.Allocator) !void {
        try self.doScoring(all);
        self.currentHand.selected.clearRetainingCapacity();
        try self.drawHand();
        std.debug.print("{any}\n", .{self.currentChips});
    }

    fn doScoring(self: *Player, all: std.mem.Allocator) !void {
        try self.judgeHandType(all);

        var iterator = self.currentHand.selected.iterator();
        while (iterator.next()) |i| {
            const crd = i.value_ptr;
            self.currentChips += (switch (crd.rank) {
                .Ace => 11 + crd.other.baseValueBonus,
                .King, .Queen, .Jack => 10 + crd.other.baseValueBonus,
                else => @intFromEnum(crd.rank) + 1 + crd.other.baseValueBonus,
            });
            _ = self.currentHand.selected.remove(i.key_ptr.*);
        }
    }

    fn judgeHandType(self: *Player, all: std.mem.Allocator) !void {
        var crdArrayList = std.ArrayList(cards.Card).init(all);

        var iterator = self.currentHand.selected.iterator();
        while (iterator.next()) |i| {
            try crdArrayList.append(i.value_ptr.*);
        }

        const crdList = try crdArrayList.toOwnedSlice();
        defer all.free(crdList);

        // var handType = cards.HandTypes.HighCard;
        const canStraight = try cards.containsStraight(crdList, all);
        // var canDoubleStraight: i32 = 0;
        // var canFlush = true;
        // var canFullHouse = false;
        // var canTwoPair = false;
        var canOak = std.AutoHashMap(cards.Rank, i32).init(all);
        defer canOak.deinit();
    }
};

const Game = struct {
    Player: Player = .{},
};

test "Card Selection" {
    var p = Player{
        .deck = try cards.createDeck(std.testing.allocator),
        .currentHand = .{
            .selected = std.AutoHashMap(usize, cards.Card).init(std.testing.allocator),
            .notSelected = std.ArrayList(cards.Card).init(std.testing.allocator),
        },
    };
    defer p.deck.totalCards.deinit();
    defer p.currentHand.notSelected.deinit();
    defer p.currentHand.selected.deinit();

    try p.deck.shuffleDeck();
    try p.currentHand.notSelected.append(cards.Card{ .rank = cards.Rank.Ace, .suit = cards.Suit.Club, .type = cards.CardType.Playing });
    try p.currentHand.notSelected.append(cards.Card{ .rank = cards.Rank.King, .suit = cards.Suit.Club, .type = cards.CardType.Playing });
    try p.currentHand.notSelected.append(cards.Card{ .rank = cards.Rank.Queen, .suit = cards.Suit.Club, .type = cards.CardType.Playing });
    try p.currentHand.notSelected.append(cards.Card{ .rank = cards.Rank.Jack, .suit = cards.Suit.Club, .type = cards.CardType.Playing });
    try p.currentHand.notSelected.append(cards.Card{ .rank = cards.Rank.Ten, .suit = cards.Suit.Club, .type = cards.CardType.Playing });

    try p.drawHand();
    try std.testing.expect(p.currentHand.notSelected.items.len == 7);
    // try p.CurrentHand.Contents.append(cards.Card{ .Rank = cards.Rank.Three, .Suit = cards.Suit.Club, .Type = cards.CardType.Playing });
    try p.selectCardInHand(0);
    try p.selectCardInHand(1);
    try p.selectCardInHand(2);
    try p.selectCardInHand(3);
    try p.selectCardInHand(4);
    // try p.selectCardInHand(5);
    // try p.selectCardInHand(6);

    for (p.currentHand.notSelected.items) |i| {
        std.debug.print("{any} - ", .{i.rank});
        std.debug.print("{any} | Contents\n", .{i.suit});
    }
    std.debug.print("\n\n", .{});
    var iterator = p.currentHand.selected.iterator();
    while (iterator.next()) |i| {
        std.debug.print("{any} - ", .{i.value_ptr.rank});
        std.debug.print("{any} - ", .{i.value_ptr.suit});
        std.debug.print("{any} | Selected\n", .{i.key_ptr.*});
    }

    try p.playHand(std.testing.allocator);
}
