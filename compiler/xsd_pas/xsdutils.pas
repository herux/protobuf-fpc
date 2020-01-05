{ XSD files compiler to FPC class

  Copyright (C) 2019 Lagunov Aleksey alexs@yandex.ru

  This source is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
  License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later
  version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web at
  <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing to the Free Software Foundation, Inc., 51
  Franklin Street - Fifth Floor, Boston, MA 02110-1335, USA.
}

unit xsdutils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;
type
  TXSDStdType = class
    PascalName:string;
  end;

function IsSimpleType(ATypeName:string):Boolean;
function GetSimpleType(ATypeName:string):string;
function IsKeyword(const AKeyword: string): boolean;

function GenerateTypeDescription(ADescription:string; ASpacing:integer = 2):string;
implementation
uses StrUtils;

type
  TStdTypeDef = record
    StdName:string;
    PasName:string;
  end;

const
  RESERVED_WORDS_TP: array [1..54] of String = (
    'absolute', 'and', 'array', 'asm',
    'begin',
    'case', 'const', 'constructor',
    'destructor', 'div', 'do', 'downto',
    'else', 'end',
    'file', 'for', 'function',
    'goto',
    'if', 'implementation', 'in', 'inherited', 'inline', 'interface',
    'label',
    'mod',
    'nil', 'not',
    'object', 'of', 'on', 'operator', 'or',
    'packed', 'procedure', 'program',
    'record', 'reintroduce', 'repeat',
    'self', 'set', 'shl', 'shr', 'string',
    'then', 'to', 'type',
    'unit', 'until', 'uses',
    'var',
    'while', 'with',
    'xor'
  );

  RESERVED_WORDS_DELPHI: array [1..15] of String = (
    'as',
    'class',
    'except', 'exports',
    'finalization', 'finally',
    'initialization', 'is',
    'library',
    'on', 'out',
    'property',
    'raise',
    'threadvar',
    'try'
  );

  RESERVED_WORDS_FPC: array [1..5] of String = (
    'dispose', 'exit', 'false', 'new', 'true'
  );

  StdTypesArray : array [1..45] of TStdTypeDef = (
    (StdName: 'xs:ENTITIES'; PasName:'String'),
    (StdName: 'xs:ENTITY'; PasName:'String'),
    (StdName: 'xs:ID'; PasName:'String'),                  // Строка, представляющая идентификационный атрибут (используется только с атрибутами схемы
    (StdName: 'xs:IDREF'; PasName:'String'),               // Строка, представляющая IDREF атрибут (используется только с атрибутами схемы)
    (StdName: 'xs:IDREFS'; PasName:'String'),              //
    (StdName: 'xs:language'; PasName:'String'),            // Строка, содержащая корректный идентификатор языка
    (StdName: 'xs:Name'; PasName:'String'),                // Строка, содержащая корректное XML имя
    (StdName: 'xs:NCName'; PasName:'String'),              //
    (StdName: 'xs:NMTOKEN'; PasName:'String'),             // Строка, представляющая NMTOKEN атрибут (используется только с атрибутами схемы)
    (StdName: 'xs:NMTOKENS'; PasName:'String'),            //
    (StdName: 'xs:normalizedString'; PasName:'String'),    //	Строка, которая не содержит символы перевода строки, переноса каретки или табуляции
    (StdName: 'xs:QName'; PasName:'String'),               //
    (StdName: 'xs:string'; PasName:'String'),              // Любая строка
    (StdName: 'xs:token'; PasName:'String'),               // Строка, которая не содержит символы перевода строки, переноса каретки, табуляции, начального и конечного пробелов или множественные пробелы

    (StdName: 'xs:byte'; PasName:'Shortint'),                // 8-битное целочисленное значение со знаком
    (StdName: 'xs:decimal'; PasName:'Double'),             // Десятичное значение
    (StdName:'xs:int'; PasName:'Longint'),                 // 32-битное целочисленное значение со знаком
    (StdName:'xs:integer'; PasName:'Longint'),             // Целочисленное значение
    (StdName:'xs:long'; PasName:'Int64'),                // 64-битное целочисленное значение со знаком
    (StdName:'xs:negativeInteger'; PasName:'integer'),     // Целочисленное, содержащее только отрицательные значения (..,-2,-1)
    (StdName:'xs:nonNegativeInteger'; PasName:'integer'),  // Целочисленное, содержащее только не-отрицательные значения (0,1,2,..)
    (StdName:'xs:nonPositiveInteger'; PasName:'integer'),  // Целочисленное, содержащее только не-положительные значения (..,-2,-1,0)
    (StdName:'xs:positiveInteger'; PasName:'integer'),     // Целочисленное, содержащее только положительные значения (1,2,..)
    (StdName:'xs:short'; PasName:'Smallint'),               // 16-битное целочисленное значение со знаком
    (StdName:'xs:unsignedLong'; PasName:'QWord'),        // 64-битное целочисленное значение без знака
    (StdName:'xs:unsignedInt'; PasName:'Longword'),         // 32-битное целочисленное значение без знака
    (StdName:'xs:unsignedShort'; PasName:'Word'),       // 16-битное целочисленное значение без знака
    (StdName:'xs:unsignedByte'; PasName:'Byte'),        // 8-битное целочисленное значение без знака    ;

    (StdName:'xs:date'; PasName:'TDate'),                // Определяет дату
    (StdName:'xs:time'; PasName:'TTime'),                // Определяет время
    (StdName:'xs:dateTime'; PasName:'TDateTime'),            // Определяет дату и время
    (StdName:'xs:duration'; PasName:'TDateTime'),            // Определяет интервал времени
    (StdName:'xs:gDay'; PasName:'Byte'),                // Определяет часть даты - день (ДД)
    (StdName:'xs:gMonth'; PasName:'Byte'),              // Определяет часть даты - месяц (MM)
    (StdName:'xs:gMonthDay'; PasName:'Word'),           // Определяет часть даты — месяц и день (MM-ДД)      //TODO:add new type - record with fields MM DD
    (StdName:'xs:gYear'; PasName:'Word'),               // Определяет часть даты - год (ГГГГ)
    (StdName:'xs:gYearMonth'; PasName:'Longword'),          // Определяет часть даты — год и месяц (ГГГГ-MM) //TODO:add new type - record with fields YYYY MM

    (StdName:'xs:boolean'; PasName:'Boolean'),             // Логический тип данных

    (StdName:'xs:base64Binary'; PasName:'String'),        // бинарные данные в кодировке Base64
    (StdName:'xs:hexBinary'; PasName:'String'),           // бинарные данные в шестнадцатеричной кодировке

    (StdName:'anyURI'; PasName:'String'),                 // Тип данных anyURI используется для определения URI

    (StdName:'float'; PasName:'Double'),                  //
    (StdName:'double'; PasName:'Double'),                 //
    (StdName:'Qname'; PasName:'String'),                  //
    (StdName:'NOTATION'; PasName:'String')                  //
    );



var
  KeywordsList: TStringList = nil;
  StdTypesList: TStringList = nil;

function IsKeyword(const AKeyword: string): boolean;
var
  i: integer;
begin
  if not Assigned(KeywordsList) then
  begin
    KeywordsList := TStringList.Create;
    for i := 1 to High(RESERVED_WORDS_TP) do
      KeywordsList.Add(RESERVED_WORDS_TP[i]);
    for i := 1 to High(RESERVED_WORDS_DELPHI) do
      KeywordsList.Add(RESERVED_WORDS_DELPHI[i]);
    for i := 1 to High(RESERVED_WORDS_FPC) do
      KeywordsList.Add(RESERVED_WORDS_FPC[i]);
    KeywordsList.Sorted := true;
  end;
  Result := KeywordsList.Find(LowerCase(AKeyword), i);
end;

function GenerateTypeDescription(ADescription: string; ASpacing:integer = 2): string;
var
  ST: TStringList;
  S: String;
begin
  Result:='';
  if Trim(ADescription) = '' then Exit;

  ST:=TStringList.Create;
  ST.Text:=ADescription;
  for S in ST do
    if Trim(S)<>'' then
      Result:=Result + DupeString(' ', ASpacing) + '//'+Trim(S) + LineEnding;
  ST.Free;
end;

procedure InitStdTypes;
var
  D: TXSDStdType;
  R: TStdTypeDef;
begin
  if Assigned(StdTypesList) then Exit;
  StdTypesList:=TStringList.Create;
  for R in StdTypesArray do
  begin
    D:=TXSDStdType.Create;
    D.PascalName:=R.PasName;
    StdTypesList.AddObject(R.StdName, D);
  end;
  StdTypesList.Sorted:=true;
end;

procedure DoneStdTypes;
var
  i: Integer;
begin
  if not Assigned(StdTypesList) then Exit;
  for i:=0 to StdTypesList.Count-1 do
    TXSDStdType(StdTypesList.Objects[i]).Free;
  FreeAndNil(StdTypesList);
end;

function IsSimpleType(ATypeName:string):Boolean;
var
  I: Integer;
begin
  if not Assigned(StdTypesList) then
    InitStdTypes;

  Result:=StdTypesList.Find(ATypeName, I);
end;

function GetSimpleType(ATypeName:string):string;
var
  I: Integer;
begin
  if not Assigned(StdTypesList) then
    InitStdTypes;

  if StdTypesList.Find(ATypeName, I) then
    Result:=TXSDStdType(StdTypesList.Objects[i]).PascalName
  else
    Result:='';
end;

finalization
  if Assigned(KeywordsList) then
    FreeAndNil(KeywordsList);
  DoneStdTypes;

end.

