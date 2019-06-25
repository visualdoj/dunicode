// RFC 3629 https://tools.ietf.org/html/rfc3629
{$MODE FPC}
{$MODESWITCH DEFAULTPARAMETERS}
{$MODESWITCH OUT}
{$MODESWITCH RESULT}
unit dutf8;

interface

const
  // Maximum bytes required for a UTF-8 encoded character
  UTF8_MAX_CHARACTER_SIZE = 4;

  // Maximum possible Unicode character for UTF-8 encoding
  UTF8_MAX_CHARACTER = $10FFFF;

//
//  DecodeUTF8Char
//
//      Decodes the UTF-8 sequence, returns Unicode character (code point) and
//      moves the cursor to the next character.
//
//      It does not check if the code point is defined in the Unicode tables.
//
//      DecodeUTF8Char returns False in two cases. One if there is no more data
//      for decoding, that is Cursor>=CursorEnd. Second if Cursor points to
//      invalid UTF-8 sequence, that is Cursor<CursorEnd.
//
//      It is best practice to reject invalid UTF-8 data, but it is not
//      suitable for all cases. There are some other versions of the function
//      with the same interface, but with different approachs on how to deal
//      with invalid data: DecodeUTF8CharIgnore and DecodeUTF8CharReplace.
//
//  DecodeUTF8CharIgnore
//
//      Works like DecodeUTF8Char, but silently ignores all invalid data.
//
//  DecodeUTF8CharReplace
//
//      Works like DecodeUTF8Char, but instead of failing, returns the
//      Replacement character.
//
//  Parameters:
//
//      Cursor: pointer to UTF-8 character
//      CursorEnd: end of valid memory region
//        That is, CursorEnd-Cursor is number of available bytes for decoding
//      Size: number of available bytes for decoding
//      Replacement: the replacement character in DecodeUTF8CharReplace variant
//
//  Returns:
//
//      Result: True if character has been successfuly read, False otherwise
//      U:      Unicode character (code point) if Result=True,
//              0 if Result=False
//      Cursor: pointer to the byte right after decoded character if Result=True
//              unchanged if Result=False
//
//  Examples:
//
//      procedure Example(const S: AnsiString);
//      var
//        Cursor: PAnsiChar;
//        CursorEnd: PAnsiChar;
//        U: Cardinal;
//      begin
//        Cursor := @S[1];
//        CursorEnd := @S[Length(S) + 1];
//        while DecodeUTF8Char(Cursor, CursorEnd, U) do begin
//          // ... do something with character U
//        end;
//        if Cursor < CursorEnd then begin
//          // ... S containts an invalid data and Cursor points to the data
//        end else begin
//          // ... S is correct UTF-8 string
//        end;
//      end;
//
//      For more examples read implementation of the following functions:
//          ValidateUTF8
//          FixUTF8
//
function DecodeUTF8Char(var Cursor: PAnsiChar; CursorEnd: PAnsiChar; out U: Cardinal): Boolean;
function DecodeUTF8Char(var Cursor: PAnsiChar; var Size: SizeInt; out U: Cardinal): Boolean; inline;
function DecodeUTF8CharIgnore(var Cursor: PAnsiChar; CursorEnd: PAnsiChar; out U: Cardinal): Boolean; inline;
function DecodeUTF8CharIgnore(var Cursor: PAnsiChar; var Size: SizeInt; out U: Cardinal): Boolean; inline;
function DecodeUTF8CharReplace(var Cursor: PAnsiChar; CursorEnd: PAnsiChar; out U: Cardinal; Replacement: Cardinal = Ord('?')): Boolean; inline;
function DecodeUTF8CharReplace(var Cursor: PAnsiChar; var Size: SizeInt; out U: Cardinal; Replacement: Cardinal = Ord('?')): Boolean; inline;

//
//  DecodeUTF8CharUnsafe
//
//      Works slightly faster than DecodeUTF8Char (~15%), but assumes Cursor is
//      a pointer to valid UTF-8 code point.
//
//      This function is useful when you validate a UTF-8 string once and
//      iterate over it many times.
//
//      You must ensure the string is valid before use DecodeUTF8CharUnsafe.
//
//  Examples:
//
//      while Cursor < CursorEnd do begin
//        U := DecodeUTF8CharUnsafe(Cursor);
//        // ...
//      end;
//
function DecodeUTF8CharUnsafe(var Cursor: PAnsiChar): Cardinal;

//
//  SkipUTF8BOM
//
//      Checks if S points to "Byte order mark" (BOM) and skips it.
//
//  Parameters:
//
//      S: pointer to the beginning of UTF-8 string
//      SEnd: end of the string
//
//  Returns:
//
//      Result: True if BOM has been found, False otherwise
//      S: the position right after BOM if Result=True
//         unchanged if Result=False
//
//  Examples:
//
//      // Iterating some UTF-8 string with possible BOM
//      SkipUTF8BOM(S, SEnd);
//      while DecodeUTF8Char(S, SEnd, U) do ...;
//
function SkipUTF8BOM(var S: PAnsiChar; SEnd: PAnsiChar): Boolean; inline;

//
//  ScanUTF8
//
//      Searchs for the character U in UTF-8 encoded string.
//
//      Optimized for the case when U is less than 128, which allows to search
//      without full UTF-8 decoding.
//
//  Parameters:
//
//      S: beginning of UTF-8 string
//      SEnd: end of the string
//
//  Returns:
//
//      Result: True if character U found, False otherwise
//      Pos: pointer to found character if Result=True, nil otherwise
//
function ScanUTF8(S, SEnd: PAnsiChar; U: Cardinal; out Pos: PAnsiChar): Boolean;

//
//  GetUTF8CharSize
//
//      Returns number of bytes required for a Unicode character.
//
//  Parameters:
//
//      U: Unicode character (code point).
//
//  Returns:
//
//      Result: 1..UTF8_MAX_CHARACTER_SIZE - number of bytes
//              0 - character U cannot be encoded in utf-8
//
function GetUTF8CharSize(U: Cardinal): SizeInt;

//
//  EncodeUTF8Char
//
//      Encodes unicode character as UTF-8.
//
//  Parameters:
//
//      U: unicode character (code point)
//      S: desination of decoded UTF-8 character
//      SEnd: end of available memory
//
//  Returns:
//
//      Result: True if character has been successfully written, False otherwise
//      S: if Result=True, pointer right after encoded character
//         if Result=False, the value is unchanged
//
function EncodeUTF8Char(U: Cardinal; var S: PAnsiChar; SEnd: PAnsiChar): Boolean;

//
//  ValidateUTF8
//
//      Checks if UTF-8 string between S and SEnd is Valid.
//
//  Parameters:
//
//      S: beginning of UTF-8 string
//      SEnd: end of UTF-8 string
//
//  Returns:
//
//      Result: True if the string is valid, False otherwise
//      Err: if Result=False, Err points to invalid character
//
function ValidateUTF8(S, SEnd: PAnsiChar; out Err: PAnsiChar): Boolean; inline;
function ValidateUTF8(S, SEnd: PAnsiChar): Boolean; inline;

//
//  FixUTF8
//
//      Reads some data that probably contains UTF-8 encoded text and skips any
//      non UTF-8 data or replaces it with the specified replacement character.
//
//      If the function succeeded, destination contains valid UTF-8 string.
//
//      Can be used for in-place fix. That is, you can pass to Dst the same
//      buffer as you pass to S:
//
//          if not FixUTF8(S, SEnd, S, SEnd) then {error};
//
//  Parameters:
//
//      S: pointer to the source string
//      SEnd: the end of the string, that is SEnd-S is string length in bytes
//      Dst: pointer to the destination string
//      DstEnd: the end of the destination string
//      Replacement: replacement character
//
//  Returns:
//
//      Result: True - string successfully fixed
//              False - not enough space in Dst buffer for repaired string
//      DstEnd: end of repaired string
//
//  Examples:
//
//      procedure FixUTF8String(var S: AnsiString);
//      var
//        SEnd: PAnsiChar;
//      begin
//        // We are fixing in place, so ensure we will not change other
//        // references to the string
//        UniqueString(S);
//        // Get end of the string -- it is right after last character
//        SEnd := @S[1] + Length(S);
//        // Try to fix now
//        FixUTF8(@S[1], SEnd, @S[1], SEnd);
//        // alternative: FixUTF8(@S[1], SEnd, @S[1], SEnd, Ord('?'));
//        // Truncate the string to the actual size
//        SetLength(S, SEnd - @S[1]);
//      end;
//
function FixUTF8(S, SEnd: PAnsiChar;
                 Dst: PAnsiChar; var DstEnd: PAnsiChar): Boolean;
function FixUTF8(S, SEnd: PAnsiChar;
                 Dst: PAnsiChar; var DstEnd: PAnsiChar;
                 Replacement: Cardinal): Boolean;

implementation

function DecodeUTF8Char(var Cursor: PAnsiChar; CursorEnd: PAnsiChar; out U: Cardinal): Boolean;
label
  LInvalidData;
var
  B: Byte;
  S: PAnsiChar;
begin
  S := Cursor;
  if S >= CursorEnd then
    goto LInvalidData;
  B := Byte(S^);
  if B and (1 shl 7) = 0 then begin
    // 7-bits code point: 0xxxxxxx
    U := B;
    Cursor := S + 1;
    Exit(True);
  end else if (B shr 5) = $6 then begin
    // 11-bits code point: 110xxxxx 10xxxxxx
    if S + 1 >= CursorEnd then
      goto LInvalidData;
    U := (B shl 6) and $7ff;
    B := Byte(S[1]);
    if (B and %11000000) <> %10000000 then
      goto LInvalidData;
    U := U or (B and $3F);
    if U < $80 then
      goto LInvalidData;
    Cursor := S + 2;
    Exit(True);
  end else if (B shr 4) = $E then begin
    // 16-bits code point: 1110xxxx 10xxxxxx 10xxxxxx
    if S + 2 >= CursorEnd then
      goto LInvalidData;
    U := (B shl 12) and $FFFF;
    B := Byte(S[1]);
    if (B and %11000000) <> %10000000 then
      goto LInvalidData;
    U := U or (Byte(S[1]) and $3F) shl 6;
    B := Byte(S[2]);
    if (B and %11000000) <> %10000000 then
      goto LInvalidData;
    U := U or (Byte(S[2]) and $3F);
    if U < $800 then
      goto LInvalidData;
    Cursor := S + 3;
    Exit(True);
  end else if (B shr 3) = $1E then begin
    // 21-bits code point: 1110xxxx 10xxxxxx 10xxxxxx 10xxxxxx
    if S + 3 >= CursorEnd then
      goto LInvalidData;
    U := (B and $0F) shl 18;
    B := Byte(S[1]);
    if (B and %11000000) <> %10000000 then
      goto LInvalidData;
    U := U or ((Byte(S[1]) and $3F) shl 12);
    B := Byte(S[2]);
    if (B and %11000000) <> %10000000 then
      goto LInvalidData;
    U := U or ((Byte(S[2]) and $3F) shl 6);
    B := Byte(S[3]);
    if (B and %11000000) <> %10000000 then
      goto LInvalidData;
    U := U or (Byte(S[3]) and $3F);
    if U < $10000 then
      goto LInvalidData;
    Cursor := S + 4;
    Exit(True);
  end else begin
    // Invalid first byte
    goto LInvalidData;
  end;
LInvalidData:
  U := 0;
  Cursor := S;
  Exit(False);
end;

function DecodeUTF8Char(var Cursor: PAnsiChar; var Size: SizeInt; out U: Cardinal): Boolean;
var
  CursorEnd: PAnsiChar;
begin
  CursorEnd := Cursor + Size;
  Result := DecodeUTF8Char(Cursor, CursorEnd, U);
  Size := CursorEnd - Cursor;
end;

function DecodeUTF8CharIgnore(var Cursor: PAnsiChar; CursorEnd: PAnsiChar; out U: Cardinal): Boolean;
begin
  while Cursor < CursorEnd do begin
    if DecodeUTF8Char(Cursor, CursorEnd, U) then
      Exit(True);
    Inc(Cursor);
  end;
  Exit(False);
end;

function DecodeUTF8CharIgnore(var Cursor: PAnsiChar; var Size: SizeInt; out U: Cardinal): Boolean;
begin
  while Size > 0 do begin
    if DecodeUTF8Char(Cursor, Size, U) then
      Exit(True);
    Inc(Cursor);
  end;
  Exit(False);
end;

function DecodeUTF8CharReplace(var Cursor: PAnsiChar; CursorEnd: PAnsiChar; out U: Cardinal; Replacement: Cardinal = Ord('?')): Boolean;
begin
  if Cursor < CursorEnd then begin
    if DecodeUTF8Char(Cursor, CursorEnd, U) then begin
      Exit(True);
    end else begin
      U := Replacement;
      Inc(Cursor);
      Exit(True);
    end;
  end else
    Exit(False);
end;

function DecodeUTF8CharReplace(var Cursor: PAnsiChar; var Size: SizeInt; out U: Cardinal; Replacement: Cardinal = Ord('?')): Boolean;
begin
  if Size > 0 then begin
    if DecodeUTF8Char(Cursor, Size, U) then begin
      Exit(True);
    end else begin
      U := Replacement;
      Inc(Cursor);
      Exit(True);
    end;
  end else
    Exit(False);
end;

function DecodeUTF8CharUnsafe(var Cursor: PAnsiChar): Cardinal;
var
  S: PAnsiChar;
  B: Byte;
begin
  S := Cursor;
  B := Byte(S^);
  if B and (1 shl 7) = 0 then begin
    // 7-bits code point: 0xxxxxxx
    Cursor := S + 1;
    Exit(B);
  end else if (B shr 5) = $6 then begin
    // 11-bits code point: 110xxxxx 10xxxxxx
    Cursor := S + 2;
    Exit(((B shl 6) and $7ff)
      or (Byte(S[1]) and $3F));
  end else if (B shr 4) = $E then begin
    // 16-bits code point: 1110xxxx 10xxxxxx 10xxxxxx
    Cursor := S + 3;
    Exit(((B shl 12) and $FFFF)
      or (Byte(S[1]) and $3F) shl 6
      or (Byte(S[2]) and $3F));
  end else if (B shr 3) = $1E then begin
    // 21-bits code point: 1110xxxx 10xxxxxx 10xxxxxx 10xxxxxx
    Cursor := S + 4;
    Exit((B and $0F) shl 18
       + (Byte(S[1]) and $3F) shl 12
       + (Byte(S[2]) and $3F) shl 6
       + (Byte(S[3]) and $3F));
  end else begin
    // Invalid first byte
    // Main assumption to the function is wrong, so try to provide some descent
    // behaviour...
    Cursor := S + 1;
    Exit(Ord('?'));
  end;
end;

function SkipUTF8BOM(var S: PAnsiChar; SEnd: PAnsiChar): Boolean;
var
  T: PAnsiChar;
  U: Cardinal;
begin
  T := S;
  if DecodeUTF8Char(T, SEnd, U) and (U = $FEFF) then begin
    S := T;
    Exit(True);
  end else
    Exit(False);
end;

function _ScanMultiByteUTF8(S, SEnd: PAnsiChar; U: Cardinal; out Pos: PAnsiChar): Boolean; inline;
var
  I: SizeInt;
  Buf: array[0 .. UTF8_MAX_CHARACTER_SIZE - 1] of AnsiChar;
  P: PAnsiChar;
begin
  P := @Buf[0];
  if not EncodeUTF8Char(U, P, @Buf[0] + UTF8_MAX_CHARACTER_SIZE) then begin
    Pos := nil;
    Exit(False);
  end;
  case P - @Buf[0] of
  1: begin
    I := IndexByte(S^, SEnd - S, Byte(Buf[0]));
    if I <> -1 then begin
      Pos := S + I;
      Exit(True);
    end else begin
      Pos := nil;
      Exit(False);
    end;
  end;
  2: begin
    while S < SEnd do begin
      I := IndexByte(S^, SEnd - S, Byte(Buf[0]));
      if I <> -1 then begin
        Pos := S + I;
        if (Pos + 1 < SEnd) and (Pos[1] = Buf[1]) then
          Exit(True);
      end else begin
        Pos := nil;
        Exit(False);
      end;
      Inc(S, I + 1);
    end;
    Pos := nil;
    Exit(False);
  end;
  3: begin
    while S < SEnd do begin
      I := IndexByte(S^, SEnd - S, Byte(Buf[0]));
      if I <> -1 then begin
        Pos := S + I;
        if (Pos + 2 < SEnd) and (PWord(Pos + 1)^ = PWord(@Buf[1])^) then
          Exit(True);
      end else begin
        Pos := nil;
        Exit(False);
      end;
      Inc(S, I + 1);
    end;
    Pos := nil;
    Exit(False);
  end;
  4: begin
    while S < SEnd do begin
      I := IndexByte(S^, SEnd - S, Byte(Buf[0]));
      if I <> -1 then begin
        Pos := S + I;
        if (Pos + 3 < SEnd) and (PDWord(Pos)^ = PDWord(@Buf[0])^) then
          Exit(True);
      end else begin
        Pos := nil;
        Exit(False);
      end;
      Inc(S, I + 1);
    end;
    Pos := nil;
    Exit(False);
  end;
  else
    Pos := nil;
    Exit(False);
  end;
end;

function ScanUTF8(S, SEnd: PAnsiChar; U: Cardinal; out Pos: PAnsiChar): Boolean;
var
  I: SizeInt;
begin
  if U < 128 then begin
    I := IndexByte(S^, SEnd - S, U);
    if I <> -1 then begin
      Pos := S + I;
      Exit(True);
    end else begin
      Pos := nil;
      Exit(False);
    end;
  end else begin
    Exit(_ScanMultiByteUTF8(S, SEnd, U, Pos));
  end;
end;

function GetUTF8CharSize(U: Cardinal): SizeInt;
begin
  if U < $80 then begin
    Exit(1);
  end else if U < $800 then begin
    Exit(2);
  end else if U < $10000 then begin
    Exit(3);
  end else if U <= UTF8_MAX_CHARACTER then begin
    Exit(4);
  end else begin
    Exit(0);
  end;
end;

function EncodeUTF8Char(U: Cardinal; var S: PAnsiChar; SEnd: PAnsiChar): Boolean;
var
  P: PAnsiChar;
begin
  P := S;
  if U < $80 then begin
    if P >= SEnd then
      Exit(False);
    P^ := AnsiChar(U);
    S := P + 1;
    Exit(True);
  end else if U < $800 then begin
    if P + 1 >= SEnd then
      Exit(False);
    P[0] := AnsiChar((U shr 6) or $C0);
    P[1] := AnsiChar((U and $3F) or $80);
    S := P + 2;
    Exit(True);
  end else if U < $10000 then begin
    if P + 2 >= SEnd then
      Exit(False);
    P[0] := AnsiChar((U shr 12) or $E0);
    P[1] := AnsiChar(((U shr 6) and $3F) or $80);
    P[2] := AnsiChar((U and $3F) or $80);
    S := P + 3;
    Exit(True);
  end else if U < $10ffff then begin
    if P + 3 >= SEnd then
      Exit(False);
    P[0] := AnsiChar((U shr 18) or $F0);
    P[1] := AnsiChar(((U shr 12) and $3F) or $80);
    P[2] := AnsiChar(((U shr 6) and $3F) or $80);
    P[3] := AnsiChar((U and $3F) or $80);
    S := P + 4;
    Exit(True);
  end else begin
    Exit(False);
  end;
end;

function ValidateUTF8(S, SEnd: PAnsiChar; out Err: PAnsiChar): Boolean;
var
  U: Cardinal;
begin
  while DecodeUTF8Char(S, SEnd, U) do
    ;
  Err := S;
  Result := S >= SEnd;
end;

function ValidateUTF8(S, SEnd: PAnsiChar): Boolean;
var
  Err: PAnsiChar;
begin
  Exit(ValidateUTF8(S, SEnd, Err));
end;

function FixUTF8(S, SEnd: PAnsiChar;
                 Dst: PAnsiChar; var DstEnd: PAnsiChar): Boolean;
var
  SStart: PAnsiChar;
  U: Cardinal;
begin
  SStart := S;
  while S < SEnd do begin
    while DecodeUTF8Char(S, SEnd, U) do
      ;
    if SStart <> Dst then begin
      U := S - SStart;
      if Dst + U >= DstEnd then begin
        DstEnd := Dst;
        Exit(False);
      end;
      Move(SStart^, Dst^, S - SStart);
    end;
    Inc(Dst, S - SStart);
    Inc(S);
    SStart := S;
  end;
  DstEnd := Dst;
  Exit(True);
end;

function FixUTF8(S, SEnd: PAnsiChar;
                 Dst: PAnsiChar; var DstEnd: PAnsiChar;
                 Replacement: Cardinal): Boolean;
var
  Buf: array[0 .. UTF8_MAX_CHARACTER_SIZE - 1] of AnsiChar;
  Cursor: PAnsiChar;
  BufSize: LongInt;

  SStart: PAnsiChar;
  U: Cardinal;
begin
  Cursor := @Buf[0];
  if not EncodeUTF8Char(Replacement, Cursor, PAnsiChar(@Buf[0]) + Length(Buf)) then
    Exit(False);
  BufSize := Cursor - PAnsiChar(@Buf[0]);

  SStart := S;
  while S < SEnd do begin
    while DecodeUTF8Char(S, SEnd, U) do
      ;
    if SStart <> Dst then begin
      U := S - SStart;
      if Dst + U >= DstEnd then begin
        DstEnd := Dst;
        Exit(False);
      end;
      Move(SStart^, Dst^, S - SStart);
    end;
    Inc(Dst, S - SStart);
    if S < SEnd then begin
      Move(Buf[0], Dst^, BufSize);
      Inc(Dst, BufSize);
    end;
    Inc(S);
    SStart := S;
  end;
  DstEnd := Dst;
  Exit(True);
end;

end.
