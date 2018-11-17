{$CODEPAGE UTF-8}
{$MODE FPC}
{$MODESWITCH DEFAULTPARAMETERS}
{$MODESWITCH OUT}
{$MODESWITCH RESULT}
uses
  strings,
  dunicode,
  dutf8;

// Test compilation of examples
      procedure Example(const S: AnsiString);
      var
        Cursor: PAnsiChar;
        CursorEnd: PAnsiChar;
        U: Cardinal;
      begin
        Cursor := @S[1];
        CursorEnd := @S[Length(S) + 1];
        while DecodeUTF8Char(Cursor, CursorEnd, U) do begin
          // ... do something with character U
        end;
        if Cursor < CursorEnd then begin
          // ... S containts an invalid data and Cursor points to the data
        end else begin
          // ... S is correct UTF-8 string
        end;
      end;

      procedure FixUTF8String(var S: AnsiString);
      var
        SEnd: PAnsiChar;
      begin
        // We are fixing in place, so ensure we will not change other
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

procedure MarkusKuhnSample;
var
  F: File of Byte;
  S: AnsiString;
  P, E, P2, E2: PAnsiChar;
  Size: SizeInt;
  U, U2: Cardinal;
  procedure SetupIterators;
  begin
    P := @S[1];
    E := P + Length(S);
    P2 := @S[1];
    E2 := P2 + Length(S);
    Size := Length(S);
  end;
  procedure TestScan(U: Cardinal);
  begin
    if ScanUTF8(@S[1], @S[1] + Length(S), U, P) then begin
      Writeln('First \u', HexStr(U, 6), ' at: ', P - @S[1]);
    end else
      Writeln('No \u', HexStr(U, 6), ' found');
  end;
begin
  Assign(F, 'UTF-8-sample.html');
  {$I-}
  Reset(F);
  {$I+}
  SetLength(S, FileSize(F));
  BlockRead(F, S[1], Length(S));
  P := @S[1];
  E := P + Length(S);
  // Print content for regression test
  while DecodeUTF8CharIgnore(P, E, U) do begin
    if IsUnicodeNewLineFunction(U) then begin
      if U <> 10 then
        Writeln;
    end else if (U >= 32) and (U < 128) then begin
      Write(AnsiChar(U));
    end else
      Write('\u', HexStr(U, 6));
  end;
  Writeln;

  // The file is supposed to be valid
  Assert(ValidateUTF8(@S[1], @S[1] + Length(S)), 'UTF-8-sample.html must be treated as valid!');

  // Check that all versions of DecodeUTF8Char do the same thing for valid utf-8
  Size := 0; P2 := nil; E2 := nil; // <- make compiler happy
  SetupIterators;
  while DecodeUTF8Char(P, E, U) do begin
    if not Assert(DecodeUTF8Char(P2, Size, U2) and (U = U2), 'DecodeUTF8Char and DecodeUTF8Char(Size) differs!') then
      break;
  end;
  SetupIterators;
  while DecodeUTF8Char(P, E, U) do begin
    if not Assert(DecodeUTF8CharIgnore(P2, E2, U2) and (U = U2), 'DecodeUTF8Char and DecodeUTF8CharIgnore differs!') then
      break;
  end;
  SetupIterators;
  while DecodeUTF8Char(P, E, U) do begin
    if not Assert(DecodeUTF8CharIgnore(P2, Size, U2) and (U = U2), 'DecodeUTF8Char and DecodeUTF8CharIgnore(Size) differs!') then
      break;
  end;
  SetupIterators;
  while DecodeUTF8Char(P, E, U) do begin
    if not Assert(DecodeUTF8CharReplace(P2, E2, U2) and (U = U2), 'DecodeUTF8Char and DecodeUTF8CharReplace differs!') then
      break;
  end;
  SetupIterators;
  while DecodeUTF8Char(P, E, U) do begin
    if not Assert(DecodeUTF8CharReplace(P2, Size, U2) and (U = U2), 'DecodeUTF8Char and DecodeUTF8CharReplace(Size) differs!') then
      break;
  end;
  SetupIterators;
  while DecodeUTF8Char(P, E, U) do begin
    if not Assert(U = DecodeUTF8CharUnsafe(P2), 'DecodeUTF8Char and DecodeUTF8CharUnsafe differs!') then
      break;
  end;

  // Test scan
  TestScan(Ord('U'));
  TestScan(Ord('-'));
  TestScan(Ord('З'));
  TestScan(0);
  TestScan(UTF8_MAX_CHARACTER);

  Close(F);
end;

procedure MarkusKuhnStress;
var
  F: File of Byte;
  S, Temp: AnsiString;
  P, E: PAnsiChar;
  U: Cardinal;
  Count: LongInt;
begin
  Assign(F, 'UTF-8-stress.txt');
  {$I-}
  Reset(F);
  {$I+}
  SetLength(S, FileSize(F));
  BlockRead(F, S[1], Length(S));
  P := @S[1];
  E := P + Length(S);
  Count := 0;
  while P < E do begin
    if DecodeUTF8Char(P, E, U) then begin
      Inc(Count);
      if IsUnicodeNewLineFunction(U) then begin
        Writeln(' (', Count, ')');
        Count := 0;
      end else if (U >= 32) and (U < 128) then begin
        Write(AnsiChar(U));
      end else
        Write('\u', HexStr(U, 6));
    end else begin
      Write('\h', HexStr(Byte(P^), 2));
      Inc(P);
      Inc(Count);
    end;
  end;

  // Check FixUTF8 and ValidateUTF8
  Temp := S;
  UniqueString(Temp);
  P := @Temp[1] + Length(Temp);
  Assert(FixUTF8(@Temp[1], @Temp[1] + Length(Temp), @Temp[1], P), 'In-place fixing must be always success');
  SetLength(Temp, P - @Temp[1]);
  Assert(ValidateUTF8(@Temp[1], @Temp[1] + Length(Temp)), 'String after FixUTF8 must be valid');

  Temp := S;
  UniqueString(Temp);
  P := @Temp[1] + Length(Temp);
  Assert(FixUTF8(@Temp[1], @Temp[1] + Length(Temp), @Temp[1], P, Ord('?')), 'In-place fixing must be always success');
  SetLength(Temp, P - @Temp[1]);
  Assert(ValidateUTF8(@Temp[1], @Temp[1] + Length(Temp)), 'String after FixUTF8 must be valid');

  Close(F);
end;

procedure TestCharSize;
var
  I: Cardinal;
begin
  for I := 0 to $7F do
    Assert(GetUTF8CharSize(I) = 1, 'GetUTF8CharSize is incorrect');
  for I := $80 to $7FF do
    Assert(GetUTF8CharSize(I) = 2, 'GetUTF8CharSize is incorrect');
  for I := $800 to $FFFF do
    Assert(GetUTF8CharSize(I) = 3, 'GetUTF8CharSize is incorrect');
  for I := $10000 to $10FFFF do
    Assert(GetUTF8CharSize(I) = 4, 'GetUTF8CharSize is incorrect');
  for I := $10FFFF + 1 to $10FFFF + 10000 do
    Assert(GetUTF8CharSize(I) = 0, 'GetUTF8CharSize is incorrect');
  Assert(GetUTF8CharSize(High(Cardinal)) = 0, 'GetUTF8CharSize is incorrect');
end;

procedure TestBOM;
const
  BOM: array[0..2] of Byte = ($ef, $bb, $bf);
  NO_BOM: array[0..2] of Byte = ($ef, $bb, $be);
var
  P: PAnsiChar;
begin
  P := @BOM[0];
  Assert(SkipUTF8BOM(P, @BOM[0] + 3) and (P = @BOM[0] + 3), 'SkipUTF8BOM didn''t skip BOM or incorrect incremented cursor');
  P := @NO_BOM[0];
  Assert((not SkipUTF8BOM(P, @NO_BOM[0] + 3)) and (P = @NO_BOM[0]), 'SkipUTF8BOM false detected BOM or incremented cursor');
end;

procedure TestEncoding;
var
  F: File of Byte;
  S, Encoded: AnsiString;
  Src, SrcEnd: PAnsiChar;
  Dst, DstEnd: PAnsiChar;
  U: Cardinal;
begin
  Assign(F, 'UTF-8-sample.html');
  {$I-}
  Reset(F);
  {$I+}
  SetLength(S, FileSize(F));
  BlockRead(F, S[1], Length(S));

  SetLength(Encoded, Length(S));
  Src := @S[1];
  SrcEnd := @S[1] + Length(S);
  Dst := @Encoded[1];
  DstEnd := @Encoded[1] + Length(Encoded);
  while DecodeUTF8Char(Src, SrcEnd, U) do begin
    Assert(EncodeUTF8Char(U, Dst, DstEnd), 'Failed encoding');
  end;
  Assert((DstEnd - @Encoded[1] = SrcEnd - @S[1]) and (CompareByte(S[1], Encoded[1], Length(S)) = 0), 'Data has been changed after decoding-encoding');

  Close(F);
end;

procedure TestFix(Src, Dst: AnsiString; U: Cardinal = $FFFFFF);
var
  SrcCursor, SrcEnd, DstCursor, DstEnd: PAnsiChar;
begin
  UniqueString(Src); 
  SrcCursor := @Src[1];
  SrcEnd := @Src[1] + Length(Src);
  if U <> $FFFFFF then begin
    Assert(FixUTF8(SrcCursor, SrcEnd, SrcCursor, SrcEnd, U), 'In place fixing must always be succesful');
  end else
    Assert(FixUTF8(SrcCursor, SrcEnd, SrcCursor, SrcEnd), 'In place fixing must always be succesful');
  SetLength(Src, SrcEnd - SrcCursor);
  Assert(Src = Dst, 'FixUTF8 returned unexpected result');
end;

procedure TestFixUTF8;
begin
  TestFix('aabb', 'aabb');
  TestFix(#$ff'aabb', 'aabb');
  TestFix(#$ff'aa'#$ff'bb'#$ff, 'aabb');
  TestFix(#$ff'aabb', '?aabb', Ord('?'));
  TestFix(#$ff'aa'#$ff'bb'#$ff, '_aa_bb_', Ord('_'));
end;

begin
  Write(stderr, PLATFORM_STRING);
  Writeln(stderr);
  MarkusKuhnSample;
  MarkusKuhnStress;
  TestCharSize;
  TestBOM;
  TestEncoding;
  TestFixUTF8;
end.
