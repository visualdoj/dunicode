// RFC 2781 https://tools.ietf.org/html/rfc2781
{$MODE FPC}
{$MODESWITCH DEFAULTPARAMETERS}
{$MODESWITCH OUT}
{$MODESWITCH RESULT}
unit dutf16;

interface

const
  //
  //  UTF16_IS_SYSTEM_ENDIAN_BIG
  //
  //      Returns True whenever system is big endian.
  //
  //      Can be used as a BigEndian parameter if encoding of utf-16 strings
  //      your program deals with is in sync with system endian.
  //
  UTF16_IS_SYSTEM_ENDIAN_BIG = {$IFDEF ENDIAN_BIG}True{$ELSE}False{$ENDIF};

//
//  DecodeUTF16Char
//  DecodeUTF16LEChar
//  DecodeUTF16BEChar
//
//      Decodes 16-bit value sequence and returns Unicode character (code
//      point).
//
//      DecodeUTF16Char uses current system endian.
//
//  DecodeUTF16CharIgnore
//
//      Works like DecodeUTF16Char, but silently ignores all invalid data.
//
//  DecodeUTF16CharReplace
//
//      Works like DecodeUTF16Char, but instead of failing, returns the
//      Replacement character.
//
//  Parameters:
//
//      Cursor: pointer to utf-16 character
//      CursorEnd: end of the string
//      BigEndian: True - UTF-16BE, False - UTF-16LE, system endian by default
//      Replacement: the replacement character in DecodeUTF16CharReplace variant
//
//  Returns:
//
//      Result: True if character has been succesfully decoded
//      U: decoded Unicode character (code point)
//      WNext: pointer to next character
//
function DecodeUTF16Char(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean; inline;
function DecodeUTF16LEChar(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal): Boolean;
function DecodeUTF16BEChar(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal): Boolean;
function DecodeUTF16CharIgnore(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean; inline;
function DecodeUTF16CharReplace(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal; Replacement: Cardinal; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean; inline;

//
//  SkipUTF16BOM
//
//      Skips "Byte order mark" (BOM) and detects endian.
//
//  Parameters:
//
//      WStr: beginning of utf-16 string
//      WEnd: end of utf-16 string
//
//  Returns:
//
//      Result=UTF16_NOBOM: BOM was not found, WNext=WStr
//          RFC 2781 4.3: "If the first two octets of the text is not 0xFE
//          followed by 0xFF, and is not 0xFF followed by 0xFE, then the text
//          SHOULD be interpreted as being big-endian."
//      Result=UTF16_LE: BOM has been found and text is UTF16-LE
//      Result=UTF16_BE: BOM has been found and text is UTF16-BE
//
type
  TUtf16BOM = (UTF16_NOBOM, UTF16_LE, UTF16_BE);
function SkipUTF16BOM(var WStr: PWideChar; WEnd: PWideChar): TUtf16BOM;

//
//  GetUTF16CharSize
//
//      Returns number of bytes required for UTF-16 encoding of specified
//      character.
//
//  Parameters:
//
//      U: Unicode character (code point)
//
//  Returns:
//
//     Result: 2 or 4 - number of bytes
//             0 - the character cannot be encoded
//
function GetUTF16CharSize(U: Cardinal): SizeInt; inline;

//
//  ValidateUTF16
//
//      Checks if UTF-16 string is Valid.
//
function ValidateUTF16(Cursor, CursorEnd: PWideChar; out Err: PWideChar; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean;
function ValidateUTF16(Cursor, CursorEnd: PWideChar; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean;

//
//  SwapEndianUTF16
//
//      Swaps endian of specified UTF-16 string in place. Does not do any
//      validation.
//
procedure SwapEndianUTF16(Cursor, CursorEnd: PWideChar); inline;

//
//  EncodeUTF16Char
//  EncodeUTF16LEChar
//  EncodeUTF16BEChar
//
//      Encodes UTF-16 character.
//
function EncodeUTF16Char(U: Cardinal; var Cursor: PWideChar; CursorEnd: PWideChar; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean; inline;
function EncodeUTF16LEChar(U: Cardinal; var Cursor: PWideChar; CursorEnd: PWideChar): Boolean;
function EncodeUTF16BEChar(U: Cardinal; var Cursor: PWideChar; CursorEnd: PWideChar): Boolean;

implementation

function DecodeUTF16Char(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean; inline;
begin
  if BigEndian then begin
    Result := DecodeUTF16BEChar(PWideChar(Cursor), PWideChar(CursorEnd), U);
  end else
    Result := DecodeUTF16LEChar(PWideChar(Cursor), PWideChar(CursorEnd), U);
end;

function DecodeUTF16LEChar(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal): Boolean;
var
  W: Word;
  S: PWideChar;
begin
  S := Cursor;
  if S >= CursorEnd then begin
    U := 0;
    Exit(False);
  end;
  W := {$IFDEF ENDIAN_BIG}SwapEndian{$ENDIF}(Word(Ord(S[0])));
  if (W < $D800) or (W > $DFFF) then begin
    U := W;
    Cursor := S + 1;
    Exit(True);
  end else begin
    if W > $DBFF then begin
      U := W;
      Exit(False);
    end else begin
      if S + 1 >= CursorEnd then
        Exit(False);
      U := (W and %1111111111) shl 10 + $10000;
      W := {$IFDEF ENDIAN_BIG}SwapEndian{$ENDIF}(Word(Ord(S[1])));
      if (W < $DC00) or (W > $DFFF) then
        Exit(False);
      U := U or (W and %1111111111);
      Cursor := S + 2;
      Exit(True);
    end;
  end;
end;

function DecodeUTF16BEChar(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal): Boolean;
var
  W: Word;
  S: PWideChar;
begin
  S := Cursor;
  if S >= CursorEnd then begin
    U := 0;
    Exit(False);
  end;
  W := {$IFDEF ENDIAN_LITTLE}SwapEndian{$ENDIF}(Word(Ord(S[0])));
  if (W < $D800) or (W > $DFFF) then begin
    U := W;
    Cursor := S + 1;
    Exit(True);
  end else begin
    if W > $DBFF then begin
      U := W;
      Exit(False);
    end else begin
      if S + 1 >= CursorEnd then
        Exit(False);
      U := (W and %1111111111) shl 10 + $10000;
      W := {$IFDEF ENDIAN_LITTLE}SwapEndian{$ENDIF}(Word(Ord(S[1])));
      if (W < $DC00) or (W > $DFFF) then
        Exit(False);
      U := U or (W and %1111111111);
      Cursor := S + 2;
      Exit(True);
    end;
  end;
end;

function DecodeUTF16CharIgnore(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean; inline;
begin
  if BigEndian then begin
    while Cursor < CursorEnd do begin
      if DecodeUTF16BEChar(PWideChar(Cursor), PWideChar(CursorEnd), U) then
        Exit(True);
      Inc(Cursor);
    end;
  end else begin
    while Cursor < CursorEnd do begin
      if DecodeUTF16LEChar(PWideChar(Cursor), PWideChar(CursorEnd), U) then
        Exit(True);
      Inc(Cursor);
    end;
  end;
  Exit(False);
end;

function DecodeUTF16CharReplace(var Cursor: PWideChar; CursorEnd: PWideChar; out U: Cardinal; Replacement: Cardinal; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean; inline;
begin
  if BigEndian then begin
    if Cursor < CursorEnd then begin
      if DecodeUTF16BEChar(PWideChar(Cursor), PWideChar(CursorEnd), U) then begin
        Exit(True);
      end else begin
        U := Replacement;
        Inc(Cursor);
        Exit(True);
      end;
    end;
  end else begin
    if Cursor < CursorEnd then begin
      if DecodeUTF16LEChar(PWideChar(Cursor), PWideChar(CursorEnd), U) then begin
        Exit(True);
      end else begin
        U := Replacement;
        Inc(Cursor);
        Exit(True);
      end;
    end;
  end;
  Exit(False);
end;

function SkipUTF16BOM(var WStr: PWideChar; WEnd: PWideChar): TUtf16BOM;
begin
  if WStr >= WEnd then begin
    Exit(UTF16_NOBOM);
  end;
  case Ord(WStr^) of
  ($FE shl 8) + $FF: begin
    Inc(WStr);
    Exit(UTF16_LE);
  end;
  ($FF shl 8) + $FE: begin
    Inc(WStr);
    Exit(UTF16_BE);
  end;
  else
    Exit(UTF16_NOBOM);
  end;
end;

function GetUTF16CharSize(U: Cardinal): SizeInt;
begin
  if U < $10000 then begin
    Exit(2);
  end else if U > $10FFFF then begin
    Exit(0);
  end else
    Exit(4);
end;

function ValidateUTF16(Cursor, CursorEnd: PWideChar; out Err: PWideChar; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean;
var
  U: Cardinal;
begin
  while DecodeUTF16Char(Cursor, CursorEnd, U, BigEndian) do
    ;
  Err := Cursor;
  Result := Cursor >= CursorEnd;
end;

function ValidateUTF16(Cursor, CursorEnd: PWideChar; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean;
var
  U: Cardinal;
begin
  while DecodeUTF16Char(Cursor, CursorEnd, U, BigEndian) do
    ;
  Result := Cursor >= CursorEnd;
end;

procedure SwapEndianUTF16(Cursor, CursorEnd: PWideChar); inline;
var
  T: Word;
begin
  while Cursor < CursorEnd do begin
    Word(Cursor^) := SwapEndian(Word(Cursor^));
    Inc(Cursor);
  end;
end;

function EncodeUTF16Char(U: Cardinal; var Cursor: PWideChar; CursorEnd: PWideChar; BigEndian: Boolean = UTF16_IS_SYSTEM_ENDIAN_BIG): Boolean;
begin
  if BigEndian then begin
    Result := EncodeUTF16BEChar(U, PWideChar(Cursor), PWideChar(CursorEnd));
  end else begin
    Result := EncodeUTF16LEChar(U, PWideChar(Cursor), PWideChar(CursorEnd));
  end;
end;

function EncodeUTF16LEChar(U: Cardinal; var Cursor: PWideChar; CursorEnd: PWideChar): Boolean;
begin
  if U < $10000 then begin
    if Cursor >= CursorEnd then
      Exit(False);
    Word(Cursor^) := {$IFDEF ENDIAN_BIG}SwapEndian{$ENDIF}(U);
    Inc(Cursor);
    Exit(True);
  end else if U <= $10FFFF then begin
    if Cursor + 1 >= CursorEnd then
      Exit(False);
    Dec(U, $10000);
    Word(Cursor[0]) := {$IFDEF ENDIAN_BIG}SwapEndian{$ENDIF}(Word(%1101100000000000 or (U shr 10)));
    Word(Cursor[1]) := {$IFDEF ENDIAN_BIG}SwapEndian{$ENDIF}(Word(%1101110000000000 or (U and %1111111111)));
    Inc(Cursor, 2);
    Exit(True);
  end else
    Exit(False);
end;

function EncodeUTF16BEChar(U: Cardinal; var Cursor: PWideChar; CursorEnd: PWideChar): Boolean;
begin
  if U < $10000 then begin
    if Cursor >= CursorEnd then
      Exit(False);
    Word(Cursor^) := {$IFDEF ENDIAN_LITTLE}SwapEndian{$ENDIF}(Word(U));
    Inc(Cursor);
    Exit(True);
  end else if U <= $10FFFF then begin
    if Cursor + 1 >= CursorEnd then
      Exit(False);
    Dec(U, $10000);
    Word(Cursor[0]) := {$IFDEF ENDIAN_LITTLE}SwapEndian{$ENDIF}(Word(%1101100000000000 or (U shr 10)));
    Word(Cursor[1]) := {$IFDEF ENDIAN_LITTLE}SwapEndian{$ENDIF}(Word(%1101110000000000 or (U and %1111111111)));
    Inc(Cursor, 2);
    Exit(True);
  end else
    Exit(False);
end;

end.
