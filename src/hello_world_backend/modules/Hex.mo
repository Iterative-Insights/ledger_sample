import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";
import Char "mo:base/Char";

module {
  private let base : Nat8 = 16;
  public type Hex = Text;
  public type AccountIdentifier = Blob;

  private let hex : [Char] = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
  ];

  func hexDigit(b : Nat8) : Nat8 {
    switch (b) {
      case (48 or 49 or 50 or 51 or 52 or 53 or 54 or 55 or 56 or 57) { b - 48 };
      case (65 or 66 or 67 or 68 or 69 or 70) { 10 + (b - 65) };
      case (97 or 98 or 99 or 100 or 101 or 102) { 10 + (b - 97) };
      case _ { Prelude.nyi() };
    };
  };

  public func decode(t : Text) : Blob {
    assert (t.size() % 2 == 0);
    let n = t.size() / 2;
    let h = Blob.toArray(Text.encodeUtf8(t));
    var b : [var Nat8] = Array.init(n, Nat8.fromNat(0));
    for (i in Iter.range(0, n - 1)) {
      b[i] := hexDigit(h[2 * i]) << 4 | hexDigit(h[2 * i + 1]);
    };
    Blob.fromArrayMut(b);
  };

  // Converts a byte to its corresponding hexidecimal format.
  public func encodeByte(n : Nat8) : Hex {
    let c0 = hex[Nat8.toNat(n / base)];
    let c1 = hex[Nat8.toNat(n % base)];
    Char.toText(c0) # Char.toText(c1);
  };

  // Converts an array of bytes to their corresponding hexidecimal format.
  public func encode(ns : [Nat8]) : Hex {
    Array.foldRight<Nat8, Hex>(
      ns,
      "",
      func(n : Nat8, acc : Hex) : Hex {
        encodeByte(n) # acc;
      },
    );
  };

  /****Encodes given valid account identifier (no validation performed).***/
  public func encodeAddress(a : AccountIdentifier) : Text {
    encode(Blob.toArray(a));
  };
};
