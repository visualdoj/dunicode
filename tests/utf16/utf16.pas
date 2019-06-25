{$CODEPAGE UTF-8}
{$MODE FPC}
{$MODESWITCH DEFAULTPARAMETERS}
{$MODESWITCH OUT}
{$MODESWITCH RESULT}
uses
  strings,
  dunicode,
  dutf8,
  dutf16;

// Test compilation of examples

function Assert(B: Boolean; Msg: PAnsiChar): Boolean;
begin
  Result := B;
  if not B then
    Writeln(Msg);
end;

function DumpLineToStr(P: PByte; Size: LongInt): AnsiString;
var
  I: LongInt;
begin
  Result := '';
  for I := 0 to 15 do begin
    if Size > I then begin
      Result := Result + HexStr(P[I], 2);
    end else
      Result := Result + '  ';
    if I mod 4 = 3 then
      Result := Result + '  ';
  end;
  Result := Result + '| ';
  for I := 0 to 15 do begin
    if Size <= I then
      break;
    if (P[I] >= 32) and (P[I] < 127) then begin
      Result := Result + Char(P[I])
    end else
      Result := Result + '?';
  end;
end;

function DumpToStr(P: Pointer; Size: LongInt): AnsiString;
begin
  Result := '';
  while Size > 0 do begin
    if Size >= 16 then begin
      Result := Result + DumpLineToStr(P, 16) + LineEnding;
      Size := Size - 16;
      Inc(P, 16);
    end else begin
      Result := Result + DumpLineToStr(P, Size) + LineEnding;
      Break;
    end;
  end;
end;

procedure Dump(P: Pointer; Size: LongInt);
begin
  Write(DumpToStr(P, Size));
end;

const
  CPU_STRING = {$IF Defined(CPUARM)} 'arm'
               {$ELSEIF Defined(CPUAVR)} 'avr'
               {$ELSEIF Defined(CPUAMD64) or Defined(CPUX86_64)} 'intel-64'
               {$ELSEIF Defined(CPU68) or Defined(CPU86K) or Defined(CPUM68K)} 'Motorola 680x0'
               {$ELSEIF Defined(CPUPOWERPC) or Defined(CPUPOWERPC32) or Defined(CPUPOWERPC64)} 'PowerPC'
               {$ELSEIF Defined(CPU386) or Defined(CPUi386)} 'i386'
               {$ELSE} 'uknown arch'
               {$ENDIF};
  ENDIAN_STRING = {$IF Defined(ENDIAN_LITTLE)}{$IF Defined(ENDIAN_BIG)}'little/big endian'{$ELSE}'little endian'{$ENDIF}
                  {$ELSE}{$IF Defined(ENDIAN_BIG)}'big endian'{$ELSE}'unknown endian'{$ENDIF}{$ENDIF};
  BITS_STRING = {$IF Defined(CPU64)}'64'{$ELSEIF Defined(CPU32)}'32'{$ELSEIF Defined(CPU16)}'16'{$ELSE}'?'{$ENDIF};
  OS_STRING = {$IF Defined(AMIGA)} 'amiga'
              {$ELSEIF Defined(ATARI)} 'Atari'
              {$ELSEIF Defined(GO32V2) or Defined(DPMI)} 'MS-DOS go32v2'
              {$ELSEIF Defined(MACOS)} 'Classic Macintosh'
              {$ELSEIF Defined(MSDOS)} 'MS-DOS'
              {$ELSEIF Defined(OS2)} 'OS2'
              {$ELSEIF Defined(EMX)} 'EMX'
              {$ELSEIF Defined(PALMOS)} 'PalmOS'
              {$ELSEIF Defined(BEOS)} 'BeOS'
              {$ELSEIF Defined(DARWIN)} 'MacOS or iOS'
              {$ELSEIF Defined(FREEBSD)} 'FreeBSD'
              {$ELSEIF Defined(NETBSD)} 'NetBSD'
              {$ELSEIF Defined(SUNOS)} 'SunOS'
              {$ELSEIF Defined(SOLARIS)} 'Solaris'
              {$ELSEIF Defined(QNX)} 'QNX RTP'
              {$ELSEIF Defined(LINUX)} 'Linux'
              {$ELSEIF Defined(UNIX)} 'Unix'
              {$ELSEIF Defined(WIN32)} '32-bit Windows'
              {$ELSEIF Defined(WIN64)} '64-bit Windows'
              {$ELSEIF Defined(WINCE)} 'Windows CE or Windows Mobile'
              {$ELSEIF Defined(WINDOWS)} 'Windows'
              {$ELSE} 'Unknown OS'
              {$ENDIF};
  PLATFORM_STRING = CPU_STRING + ' ' + BITS_STRING + '-bits (' + ENDIAN_STRING + '), ' + OS_STRING;

const
  TEST_STRING = #$0024#$20AC#$D801#$DC37#$D852#$DF62;

procedure TestDecode;
var
  S: WideString;
  Cursor, CursorEnd: PWideChar;
  U: Cardinal;
begin
  Cursor := @TEST_STRING[1];
  CursorEnd := PWideChar(@TEST_STRING[1]) + Length(TEST_STRING);
  Assert(DecodeUTF16Char(Cursor, CursorEnd, U) and (U = $24), 'Decoding of TEST_STRING is invalid');
  Assert(DecodeUTF16Char(Cursor, CursorEnd, U) and (U = $20AC), 'Decoding of TEST_STRING is invalid');
  Assert(DecodeUTF16Char(Cursor, CursorEnd, U) and (U = $10437), 'Decoding of TEST_STRING is invalid');
  Assert(DecodeUTF16Char(Cursor, CursorEnd, U) and (U = $24B62), 'Decoding of TEST_STRING is invalid');
  Assert(not DecodeUTF16Char(Cursor, CursorEnd, U), 'Decoding of TEST_STRING is invalid');

  S := TEST_STRING;
  UniqueString(S);
  SwapEndianUTF16(@S[1], PWideChar(@S[1]) + Length(S));
  Cursor := @S[1];
  CursorEnd := PWideChar(@S[1]) + Length(S);
  Assert(DecodeUTF16Char(Cursor, CursorEnd, U, not UTF16_IS_SYSTEM_ENDIAN_BIG) and (U = $24), 'Decoding of TEST_STRING is invalid');
  Assert(DecodeUTF16Char(Cursor, CursorEnd, U, not UTF16_IS_SYSTEM_ENDIAN_BIG) and (U = $20AC), 'Decoding of TEST_STRING is invalid');
  Assert(DecodeUTF16Char(Cursor, CursorEnd, U, not UTF16_IS_SYSTEM_ENDIAN_BIG) and (U = $10437), 'Decoding of TEST_STRING is invalid');
  Assert(DecodeUTF16Char(Cursor, CursorEnd, U, not UTF16_IS_SYSTEM_ENDIAN_BIG) and (U = $24B62), 'Decoding of TEST_STRING is invalid');
  Assert(not DecodeUTF16Char(Cursor, CursorEnd, U, not UTF16_IS_SYSTEM_ENDIAN_BIG), 'Decoding of TEST_STRING is invalid');
end;

procedure TestEncode;
var
  W: WideString;
  Cursor, CursorEnd: PWideChar;
begin
  SetLength(W, Length(TEST_STRING));
  Cursor := @W[1];
  CursorEnd := Cursor + Length(W);
  Assert(EncodeUTF16Char($24, Cursor, CursorEnd) and
         EncodeUTF16Char($20AC, Cursor, CursorEnd) and
         EncodeUTF16Char($10437, Cursor, CursorEnd) and
         EncodeUTF16Char($24B62, Cursor, CursorEnd) and
         (W = TEST_STRING), 'Encoding failed');
  Cursor := @W[1];
  CursorEnd := Cursor + Length(W);
  Assert(EncodeUTF16Char($24, Cursor, CursorEnd, not UTF16_IS_SYSTEM_ENDIAN_BIG) and
         EncodeUTF16Char($20AC, Cursor, CursorEnd, not UTF16_IS_SYSTEM_ENDIAN_BIG) and
         EncodeUTF16Char($10437, Cursor, CursorEnd, not UTF16_IS_SYSTEM_ENDIAN_BIG) and
         EncodeUTF16Char($24B62, Cursor, CursorEnd, not UTF16_IS_SYSTEM_ENDIAN_BIG), 'Encoding failed 1');
  SwapEndianUTF16(@W[1], PWideChar(@W[1]) + Length(W));
  Assert(W = TEST_STRING, 'Encoding failed 2');
end;

procedure TestCharSize;
var
  U: Cardinal;
begin
  for U := 0 to $10000 - 1 do
    Assert(GetUTF16CharSize(U) = 2, 'Wrong size of character');
  for U := $10000 to $10FFFF do
    Assert(GetUTF16CharSize(U) = 4, 'Wrong size of character');
  for U := $10FFFF + 1 to $10FFFF + $FFFF do
    Assert(GetUTF16CharSize(U) = 0, 'Wrong size of character');
  Assert(GetUTF16CharSize(High(Cardinal)) = 0, 'Wrong size of character');
end;

procedure TestBOM;
const
  BOM1 = #$FE#$FF;
  BOM2 = #$FF#$FE;
  BOM3 = #$FE#$FE;
  BOM4 = #$FF#$FF;
var
  Cursor, CursorEnd: PWideChar;
begin
  Cursor := PWideChar(@BOM1[1]);
  CursorEnd := Cursor + 1;
  Assert((SkipUTF16BOM(Cursor, CursorEnd) = UTF16_BE) and (Cursor = CursorEnd), 'Wrong BOM (big endian expected)');
  Cursor := PWideChar(@BOM2[1]);
  CursorEnd := Cursor + 1;
  Assert((SkipUTF16BOM(Cursor, CursorEnd) = UTF16_LE) and (Cursor = CursorEnd), 'Wrong BOM (little endian expected)');
  Cursor := PWideChar(@BOM3[1]);
  CursorEnd := Cursor + 1;
  Assert((SkipUTF16BOM(Cursor, CursorEnd) = UTF16_NOBOM) and (Cursor = CursorEnd - 1), 'Wrong BOM (no bom expected)');
  Cursor := PWideChar(@BOM4[1]);
  CursorEnd := Cursor + 1;
  Assert((SkipUTF16BOM(Cursor, CursorEnd) = UTF16_NOBOM) and (Cursor = CursorEnd - 1), 'Wrong BOM (no bom expected)');
end;

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

//
//  Converts UTF-16 encoded string to UTF-8 encoded.
//
//  Tries to detec BOM to determine endian. If no BOM found,
//  assumes big endian (UTF-16BE).
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
  // At a first pass determine the size of resulting string.
  while DecodeUTF16CharReplace(WCursor, WCursorEnd, U, Ord('?'), BigEndian) do
    Inc(L, GetUTF8CharSize(U));
  // At a second pass encode resulting UTF-8 string.
  SetLength(Result, L);
  WCursor := @W[1];
  WCursorEnd := WCursor + Length(W);
  SCursor := @Result[1];
  SCursorEnd := SCursor + Length(Result);
  SkipUTF16BOM(WCursor, WCursorEnd);
  while DecodeUTF16CharReplace(WCursor, WCursorEnd, U, Ord('?'), BigEndian) do
    EncodeUTF8Char(U, SCursor, SCursorEnd);
end;

begin
  Write(stderr, PLATFORM_STRING);
  Writeln(stderr);
  TestDecode;
  TestEncode;
  TestCharSize;
  TestBOM;
  Assert(ConvertUTF8ToUTF16(ConvertUTF16ToUTF8(TEST_STRING)) = TEST_STRING, 'Convert functions do not work');
end.
