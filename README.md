# dunicode
Unicode, UTF-8 and UTF-16 units for Free Pascal

## Overview

The main goal of this library is to provide primitives for work with UTF-8 strings in simple, fast and flexible way. Instead of conventional for Free Pascal way of converting UTF-8 strings into WideString, the library is supposed to use UTF-8 encoded strings without converting. The library follows the [UTF-8 Everywhere](http://utf8everywhere.org/) manifesto.

The library is cross platform, it does not require any other libraries, does not use dynamic allocations, does not raise exceptions and does not produce any side effects like changing global managers.

## Validation

```
var
  S: AnsiString;

...

if ValidateUTF8(@S[1], @S[1] + Length(S)) then begin
  // .. the string is UTF-8
end else begin
  // .. the string is invalid
end;
```

See [dutf8.pas](dutf8.pas) for detailed documentation for `ValidateUTF8`.

## Iteration

Here is an example of general iteration over code points in UTF-8 string:

```
var
  S: AnsiString;
  Cursor, CursorEnd: PAnsiChar;
  U: Cardinal;

...
 
Cursor := @S[1];
CursorEnd := @S[1] + Length(S);
while DecodeUTF8Char(Cursor, CursorEnd, U) do begin
  // ... U is current Unicode code point
end;

if Cursor >= CursorEnd then begin
  // ... the string is successfully iterated
end else begin
  // ... the string is invalid, Cursor points to the invalid data
end;
```

As you can see the loop immediatly stops on invalid data. There are two more handy functions for iterating with similar interface: `DecodeUTF8CharIgnore` ignores all invalid data, `DecodeUTF8CharReplace` returns specified character instead of stop on invalid data.

`DecodeUTF8CharUnsafe` works slightly faster than `DecodeUTF8Char`, but assumes input string is valid UTF-8 string.

See [dutf8.pas](dutf8.pas) for detailed documentation for mentioned functions.

## BOM (Byte order mark)

If a string may contain the BOM, use SkipUTF8BOM to detect or skip it:

```
var
  S: AnsiString;
  Cursor, CursorEnd: PAnsiChar;

...

Cursor := @S[1];
CursorEnd := @S[1] + Length(S);
if SkipUTF8BOM(Cursor, CursorEnd) then begin
  // ... BOM found and skipped
end else begin
  // ... BOM was not found, Cursor is unchanged
end;
```

See [dutf8.pas](dutf8.pas) for detailed documentation for `SkipUTF8BOM`.

## Fix

Sometimes it is good idea to remove all invalid data from a string and make valid UTF-8 string. Use `FixUTF8` function for that:

```
procedure FixUTF8String(var S: AnsiString);
var
  SEnd: PAnsiChar;
begin
  // We are fixing in place, so ensure we will not break other
  // references to the string
  UniqueString(S);
  // Get end of the string -- it is right after last character
  SEnd := @S[1] + Length(S);
  // Try to fix now
  FixUTF8(@S[1], SEnd, @S[1], SEnd);
  // alternative: FixUTF8(@S[1], SEnd, @S[1], SEnd, Ord('?'));
  // Truncate the string to the actual size
  SetLength(S, SEnd - @S[1]);
end;
```

See [dutf8.pas](dutf8.pas) for detailed documentation for `FixUTF8`.

## Encode

Use `EncodeUTF8Char` function to encode a Unicode code point:

```
var
  U: Cardinal;
  Buffer, BufferEnd: PAnsiChar;

...

if EncodeUTF8Char(U, Buffer, BufferEnd) then begin
  // ... the character has been successfully encoded and Buffer has been advanced 
end else begin
  // ... not enough space in buffer or U cannot be encoded
end;
```

See [dutf8.pas](dutf8.pas) for detailed documentation for `EncodeUTF8Char`.

## Convert UTF-8 to UTF-16

```
uses
  dutf8,
  dutf16;

...

//
//  Converts UTF-8 string to UTF-16BE (by default) or UTF-16LE.
//
//  Replaces all malformed data in S to '?'.
//
function ConvertUTF8ToUTF16(const S: AnsiString; BigEndian: Boolean = True): WideString;
var
  L: SizeUInt;
  U: Cardinal;
  SCursor, SCursorEnd: PAnsiChar;
  WCursor, WCursorEnd: PWideChar;
begin
  // In the first pass determine the size of resulting string.
  L := 0;
  SCursor := @S[1];
  SCursorEnd := SCursor + Length(S);
  while DecodeUTF8CharReplace(SCursor, SCursorEnd, U, Ord('?')) do
    Inc(L, GetUTF16CharSize(U));
  // GetUTF16CharSize returns number of bytes.
  // But we want to compute number of WideChars. SizeOf(WideChar) = 2.
  L := L div 2;
  // In the second pass encode resulting UTF-16 string.
  SetLength(Result, L);
  SCursor := @S[1];
  SCursorEnd := SCursor + Length(S);
  WCursor := @Result[1];
  WCursorEnd := WCursor + Length(Result);
  while DecodeUTF8CharReplace(SCursor, SCursorEnd, U, Ord('?')) do
    EncodeUTF16BEChar(U, WCursor, WCursorEnd);
end;
```

## Convert UTF-16 to UTF-8

```
uses
  dutf8,
  dutf16;

...

//
//  Converts UTF-16 encoded string to UTF-8 encoded.
//
//  Tries to detect BOM to determine endian. If no BOM found,
//  uses BigEndian (assumes UTF16-BE if the parameter ommited).
//
//  Replaces all malformed data in W to '?'.
//
function ConvertUTF16ToUTF8(const W: WideString; BigEndian: Boolean = True): AnsiString;
var
  L: SizeUInt;
  U: Cardinal;
  SCursor, SCursorEnd: PAnsiChar;
  WCursor, WCursorEnd: PWideChar;
begin
  // From the RFC:
  //
  // >  All applications that process text with the "UTF-16" charset label MUST
  // >  be able to read at least the first two octets of the text and be able
  // >  to process those octets in order to determine the serialization order
  // >  of the text. Applications that process text with the "UTF-16" charset
  // >  label MUST NOT assume the serialization without first checking the
  // >  first two octets to see if they are a big-endian BOM, a little-endian
  // >  BOM, or not a BOM. All applications that process text with the "UTF-16"
  // >  charset label MUST be able to interpret both big- endian and
  // >  little-endian text.
  L := 0;
  WCursor := @W[1];
  WCursorEnd := WCursor + Length(W);
  case SkipUTF16BOM(WCursor, WCursorEnd) of
    UTF16_LE: BigEndian := False;
    UTF16_BE: BigEndian := True;
    UTF16_NOBOM: ; // stay default
  end;
  // At the first pass determine the size of resulting string.
  while DecodeUTF16CharReplace(WCursor, WCursorEnd, U, Ord('?'), BigEndian) do
    Inc(L, GetUTF8CharSize(U));
  // At the second pass encode resulting UTF-8 string.
  SetLength(Result, L);
  WCursor := @W[1];
  WCursorEnd := WCursor + Length(W);
  SCursor := @Result[1];
  SCursorEnd := SCursor + Length(Result);
  SkipUTF16BOM(WCursor, WCursorEnd);
  while DecodeUTF16CharReplace(WCursor, WCursorEnd, U, Ord('?'), BigEndian) do
    EncodeUTF8Char(U, SCursor, SCursorEnd);
end;
```
