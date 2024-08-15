const std = @import("std");
const rand = @import("std").crypto.random;

pub const Rank = enum { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace };
pub const Suit = enum { Diamond, Club, Spade, Heart };
pub const CardType = enum { Playing, Joker, Consumable, Voucher };

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
    Suit: ?Suit, // A Joker or Consumable card would not have a Suit
    Rank: ?Rank, // Nor would it have a Rank, at least normally
    Type: CardType,
    Enhancement: Enhancement = Enhancement.None,
    Edition: Edition = Edition.None,
    Seal: Seal = Seal.None,
    Sticker: Sticker = Sticker.None,
};

///Debug Function: Printing the Suit and Rank of a Playing Card
pub fn printVanillaCardData(card: Card) void {
    std.debug.print("{s} of {s}\n", .{
        std.enums.tagName(Rank, card.Rank orelse undefined) orelse "",
        std.enums.tagName(Suit, card.Suit orelse undefined) orelse "",
    });
}

pub const Deck = struct {
    Cards: std.ArrayList(Card),
    CardsLeft: std.ArrayList(Card),
    pub fn shuffleDeck(self: *Deck) !void {
        for (8) |_| {
            for (self.Cards.items) |_| {
                const i = rand.intRangeAtMost(usize, 0, 51);
                const top_card = self.Cards.pop();
                try self.Cards.insert(i, top_card);
            }
        }
    }
};

pub fn createDeck(alc: std.mem.Allocator) !Deck {
    var d: Deck = Deck{ .Cards = std.ArrayList(Card).init(alc), .CardsLeft = std.ArrayList(Card).init(alc) };

    inline for (@typeInfo(Suit).Enum.fields) |i| {
        inline for (@typeInfo(Rank).Enum.fields) |j| {
            try d.Cards.append(Card{
                .Type = CardType.Playing,
                .Rank = @enumFromInt(j.value),
                .Suit = @enumFromInt(i.value),
            });
        }
    }
    d.CardsLeft = d.Cards;
    return d;
}

// export fn add(a: i32, b: i32) i32 {
//     return a + b;
// }
