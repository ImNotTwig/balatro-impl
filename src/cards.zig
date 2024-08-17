const std = @import("std");
const rand = @import("std").crypto.random;

pub const Rank = enum { None, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace };
pub const Suit = enum { None, Diamond, Club, Spade, Heart };
pub const CardType = enum { Playing, Joker, Consumable, Voucher };

pub const HandTypes = enum {
    HighCard,
    Pair,
    TwoPair,
    ThreeOak,
    Straight,
    Flush,
    FullHouse,
    FourOak,
    StraightFlush,

    // Made Up Hands below

    TwoPairPlus, // a multiple of a two pair, eg four Aces and four Kings

    FlushHouse, // a full house, except all cards are the same suit
    FlushFive, // 5 cards with the same suit and rank
    FlushOther, // 6+ cards with the same suit and rank

    MultiHouse, // a hand with only 2 different ranks, with a 2/3rds ratio between them, 10n cards
    MultiFlushHouse, // MultiHouse, except all cards are the same suit

    DoubleStraight, // a straight with 2 aces
    DoubleStraightFlush, // a straight flush with 2 aces

    FiveOak, // 5 cards with the same rank
    OtherOak, // 6+ cards with the same rank
};

pub fn containsStraight(crdList: []Card, all: std.mem.Allocator) !bool {
    // if the hand played is less than 5 cards, its not possible to be a straight
    if (crdList.len < 5) return false;

    var ranksInHand = std.AutoHashMap(Rank, struct { amountInHand: i32, indexes: std.ArrayList(usize) }).init(all);
    defer ranksInHand.deinit();
    defer {
        var iterator = ranksInHand.iterator();
        while (iterator.next()) |i| {
            i.value_ptr.indexes.deinit();
        }
    }

    for (0.., crdList) |i, v| {
        var val = try ranksInHand.getOrPut(v.rank);
        if (val.found_existing) {
            val.value_ptr.amountInHand += 1;
        } else {
            val.value_ptr.amountInHand = 1;
            val.value_ptr.indexes = std.ArrayList(usize).init(all);
        }
        try val.value_ptr.indexes.append(i);
    }

    // after taking all the duplicates out of the played hand, check if there is a valid straight
    // (a straight physically cannot contain two of the same card, except aces, in the case of a doubleStraight)
    var iterator = ranksInHand.iterator();
    var tmpCrdList = std.ArrayList(Card).init(all);
    defer tmpCrdList.deinit();

    while (iterator.next()) |i| {
        try tmpCrdList.append(crdList[i.value_ptr.indexes.items[0]]);
    }
    if (tmpCrdList.items.len < 5) return false;

    const newCrdList = try tmpCrdList.toOwnedSlice();
    defer all.free(newCrdList);

    // sort the list of cards by rank value
    std.mem.sort(Card, newCrdList, {}, struct {
        pub fn inner(_: void, a: Card, b: Card) bool {
            return getRankValue(a) < getRankValue(b);
        }
    }.inner);

    for (0.., newCrdList) |i, _| {
        if (newCrdList.len <= i + 1) break;
        if (getRankValue(newCrdList[i]) + 1 != getRankValue(newCrdList[i + 1])) {
            if (newCrdList[0].rank != Rank.Two and newCrdList[i + 1].rank != Rank.Ace) {
                return false;
            }
        }
    }

    return true;
}

pub const Edition = enum {
    None,
    Foil,
    Holo,
    Poly,
    Neg,
};
pub const Enhancement = enum {
    None,
    Bonus,
    Mult,
    Wild,
    Glass,
    Stone,
    Gold,
    Lucky,
};
pub const Seal = enum {
    None,
    Gold,
    Red,
    Blue,
    Purple,
};
pub const Sticker = enum {
    None,
    Eternal,
    Perishable,
    Rental,
};

pub const Card = struct {
    suit: Suit,
    rank: Rank,
    type: CardType,
    enhancement: Enhancement = Enhancement.None,
    edition: Edition = Edition.None,
    seal: Seal = Seal.None,
    stickers: []Sticker = &[_]Sticker{},
    other: struct {
        baseValueBonus: i32 = 0,
    } = .{},
};

pub fn getRankValue(crd: Card) i32 {
    return (switch (crd.rank) {
        .Ace => 14,
        .King => 13,
        .Queen => 12,
        .Jack => 11,
        else => @intFromEnum(crd.rank) + 1,
    });
}

///Debug Function: Printing the Suit and Rank of a Playing Card
pub fn printVanillaCardData(card: Card) void {
    std.debug.print("{s} of {s}\n", .{
        std.enums.tagName(Rank, card.Rank) orelse "",
        std.enums.tagName(Suit, card.Suit) orelse "",
    });
}

pub const Deck = struct {
    totalCards: std.ArrayList(Card),
    cardsLeft: std.ArrayList(Card),
    pub fn shuffleDeck(self: *Deck) !void {
        for (8) |_| {
            for (self.totalCards.items) |_| {
                const i = rand.intRangeAtMost(usize, 0, 51);
                const top_card = self.totalCards.pop();
                try self.totalCards.insert(i, top_card);
            }
        }
    }
};

pub fn createDeck(alc: std.mem.Allocator) !Deck {
    var d: Deck = Deck{ .totalCards = std.ArrayList(Card).init(alc), .cardsLeft = std.ArrayList(Card).init(alc) };

    inline for (@typeInfo(Suit).Enum.fields) |i| {
        if (@as(Suit, @enumFromInt(i.value)) == Suit.None) {
            continue;
        }

        inline for (@typeInfo(Rank).Enum.fields) |j| {
            if (@as(Rank, @enumFromInt(j.value)) == Rank.None) {
                continue;
            }

            try d.totalCards.append(Card{
                .type = CardType.Playing,
                .rank = @enumFromInt(j.value),
                .suit = @enumFromInt(i.value),
            });
        }
    }
    d.cardsLeft = d.totalCards;
    return d;
}
