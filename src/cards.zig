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
        .Ace => 11,
        .King, .Queen, .Jack => 10,
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
