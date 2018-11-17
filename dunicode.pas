// RFC 5198 https://tools.ietf.org/html/rfc5198
{$MODE FPC}
{$MODESWITCH OUT}
{$MODESWITCH RESULT}
unit dunicode;

interface

const
  // Highest possible code point
  HIGH_UNICODE_CODE_POINT = $0010FFFF;

  // Some constants for unicode characters
  U_BOM                 = $FEFF;
  U_CR                  = $0D;
  U_LF                  = $0A;
  U_NEL                 = $85;
  U_LINE_SEPARATOR      = $2028;
  U_PARAGRAPH_SEPARATOR = $2029;

//
//  IsUnicodeNewLineFunction
//
//      Checks if specified Unicode character is NLF.
//
//      It returns True if U is one of:
//        U+000D CR  - CARRIAGE RETURN
//        U+000A LF  - LINE FEED
//        U+0085 NEL - NEXT LINE
//        U+2028 LS  - LINE SEPARATOR
//        U+2029 PS  - PARAGRAPH SEPARATOR
//
function IsUnicodeNewLineFunction(U: Cardinal): Boolean; inline;

//
//  GetUnicodePlane
//
//      Returns plane of specified Unicode character
//
function GetUnicodePlane(U: Cardinal): Cardinal; inline;

//
//  IsUnicodeBMP
//
//      Checks if U is in Unicode BMP
//
function IsUnicodeBMP(U: Cardinal): Boolean; inline;

implementation

function IsUnicodeNewLineFunction(U: Cardinal): Boolean;
begin
  if U < 128 then begin
    Exit(U in [10, 13, $85]);
  end else begin
    Exit((U = $2028) or (U = $2029));
  end;
end;

function GetUnicodePlane(U: Cardinal): Cardinal;
begin
  Result := U shr 16;
end;

function IsUnicodeBMP(U: Cardinal): Boolean;
begin
  Result := (U shr 16) = 0;
end;

end.
