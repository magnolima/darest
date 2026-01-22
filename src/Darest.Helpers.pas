(*
================================================================================
  Darest - Auto-generated REST API from your database schema

  Copyright (c) 2026 Magno Lima - Magnum Labs
  Website: www.magnumlabs.com.br

  Licensed under the MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
================================================================================
*)
unit Darest.Helpers;

interface

uses
	System.Classes, System.JSON, System.SysUtils, FireDAC.Stan.Intf,
	FireDAC.Stan.Option, System.Types, Vcl.Graphics, System.UITypes,
	FireDAC.Stan.Error, FireDAC.UI.Intf,
	FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
	FireDAC.Phys, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
	FireDAC.DApt, Data.DB;

function RowToJSONObject(Q: TFDQuery): TJSONObject;
function BuildPagedSelect(const BaseSQL, DriverID, OrderBy: string): string;
procedure GetDriverParams(const ADriverID: string; AParams: TStrings);
function IsColorDark(AColor: TColor): Boolean;

implementation

function ColorToRGBChannels(AColor: TColor; out R, G, B: Byte): Boolean;
var
  C: TColor;
begin
  C := ColorToRGB(AColor); // resolve clXXX e cores de tema

  R := Byte(C);
  G := Byte(C shr 8);
  B := Byte(C shr 16);

  Result := True;
end;

function IsColorDark(AColor: TColor): Boolean;
var
  R, G, B: Byte;
  Luminance: Double;
begin
  ColorToRGBChannels(AColor, R, G, B);

  Luminance :=
    0.2126 * R +
    0.7152 * G +
    0.0722 * B;

  Result := Luminance < 128;
end;

function JSONValueFromField(F: TField): TJSONValue;
begin
	if F.IsNull then
		Exit(TJSONNull.Create);
	case F.DataType of
		ftInteger, ftSmallint, ftWord, ftLargeint:
			Exit(TJSONNumber.Create(F.AsLargeInt));
		ftFloat, ftCurrency, ftBCD, ftFMTBcd:
			Exit(TJSONNumber.Create(F.AsFloat));
		ftBoolean:
			Exit(TJSONBool.Create(F.AsBoolean));
		ftDate, ftTime, ftDateTime, ftTimeStamp:
			Exit(TJSONString.Create(FormatDateTime('yyyy-mm-dd"T"hh:nn:ss',
				 F.AsDateTime)));
	else
		Exit(TJSONString.Create(F.AsString));
	end;
end;

function BuildPagedSelect(const BaseSQL, DriverID, OrderBy: string): string;
begin
	if SameText(DriverID, 'MSSQL') or SameText(DriverID, 'Ora') then
		Result := Format('%s %s OFFSET :_offset ROWS FETCH NEXT :_limit ROWS ONLY',
			 [BaseSQL, OrderBy])
	else if SameText(DriverID, 'PG') or SameText(DriverID, 'MySQL') or
		 SameText(DriverID, 'SQLite') then
		Result := Format('%s %s LIMIT :_limit OFFSET :_offset', [BaseSQL, OrderBy])
	else if SameText(DriverID, 'IB') or SameText(DriverID, 'FB') then
		Result := Format('%s %s ROWS :_start TO :_end', [BaseSQL, OrderBy])
	else
		Result := Format('%s %s LIMIT :_limit OFFSET :_offset', [BaseSQL, OrderBy]);
end;

function RowToJSONObject(Q: TFDQuery): TJSONObject;
var
	i: Integer;
begin
	Result := TJSONObject.Create;
	for i := 0 to Q.Fields.Count - 1 do
		Result.AddPair(Q.Fields[i].FieldName, JSONValueFromField(Q.Fields[i]));
end;

procedure GetDriverParams(const ADriverID: string; AParams: TStrings);
begin
	AParams.Clear;

	if SameText(ADriverID, 'SQLite') then
	begin
		AParams.AddPair('Database','');
		AParams.AddPair('Pooled', 'false');
		AParams.AddPair('Database', '');
		AParams.AddPair('User_Name', '');
		AParams.AddPair('Password', '');
		AParams.AddPair('MonitorBy', '');
		AParams.AddPair('OpenMode', 'CreateUTF8');
		AParams.AddPair('Encrypt', 'No');
		AParams.AddPair('BusyTimeout', '10000');
		AParams.AddPair('CacheSize', '10000');
		AParams.AddPair('SharedCache', 'True');
		AParams.AddPair('LockingMode', 'Exclusive');
		AParams.AddPair('Synchronous', 'Off');
		AParams.AddPair('JournalMode', 'Delete');
		AParams.AddPair('ForeignKeys', 'On');
		AParams.AddPair('StringFormat', 'Choose');
		AParams.AddPair('GUIDFormat', 'String');
		AParams.AddPair('DateTimeFormat', 'String');
		AParams.AddPair('Extensions', 'False');
		AParams.AddPair('SQLiteAdvanced', '');
		AParams.AddPair('MetaDefCatalog', 'MAIN');
		AParams.AddPair('MetaCurCatalog', '*');
	end
	else if SameText(ADriverID, 'MySQL') then
	begin
		AParams.AddPair('Pooled', 'False');
		AParams.AddPair('Database', '');
		AParams.AddPair('User_Name', '');
		AParams.AddPair('Password', '');
		AParams.AddPair('MonitorBy', '');
		AParams.AddPair('Server', '<LOCAL>');
		AParams.AddPair('Port', '3306');
		AParams.AddPair('Compress', 'True');
		AParams.AddPair('UseSSL', 'False');
		AParams.AddPair('LoginTimeout', '');
		AParams.AddPair('ReadTimeout', '');
		AParams.AddPair('WriteTimeout', '');
		AParams.AddPair('ResultMode', 'Store');
		AParams.AddPair('CharacterSet', '');
		AParams.AddPair('TinyIntFormat', 'Boolean');
		AParams.AddPair('MetaDefCatalog', '');
		AParams.AddPair('MetaCurCatalog', '');
	end
	else if SameText(ADriverID, 'PG') or SameText(ADriverID, 'PostgreSQL') then
	begin
		AParams.AddPair('Pooled', 'False');
		AParams.AddPair('Database', '');
		AParams.AddPair('User_Name', '');
		AParams.AddPair('Password', '');
		AParams.AddPair('MonitorBy', '<LOCAL>');
		AParams.AddPair('Server', '<LOCAL>');
		AParams.AddPair('Port', '5432');
		AParams.AddPair('LoginTimeout', '0');
		AParams.AddPair('CharacterSet', '');
		AParams.AddPair('GUIDEndian', 'Little');
		AParams.AddPair('ExtendedMetadata', 'False');
		AParams.AddPair('OIdAsBlob', 'Choose');
		AParams.AddPair('UnknownFormat', 'Error');
		AParams.AddPair('ArrayScanSample', '0;5');
		AParams.AddPair('FastFetchMode', 'Choose');
		AParams.AddPair('ApplicationName', '');
		AParams.AddPair('PGAdvanced', '');
		AParams.AddPair('MetaDefSchema', 'public');
		AParams.AddPair('MetaCurSchema', '');
	end
	else if SameText(ADriverID, 'MSSQL') or SameText(ADriverID, 'MSSQLDriver')
	then
	begin
		AParams.AddPair('Server', 'localhost');
		AParams.AddPair('Database', '');
		AParams.AddPair('User_Name', '');
		AParams.AddPair('Password', '');
		AParams.AddPair('OSAuthent', 'No');
		AParams.AddPair('Pooled', 'False');
		AParams.AddPair('Port', '1433'); // Default MSSQL port
		AParams.AddPair('LoginTimeout', '0');
		AParams.AddPair('CharacterSet', ''); // May vary based on your setup
		AParams.AddPair('MonitorBy', '<LOCAL>');
		AParams.AddPair('ExtendedMetadata', 'False');
		AParams.AddPair('ApplicationName', '');
	end
	else if SameText(ADriverID, 'FB') or SameText(ADriverID, 'Firebird') then
	begin
		AParams.AddPair('Pooled', 'False');
		AParams.AddPair('Database', '');
		AParams.AddPair('User_Name', '');
		AParams.AddPair('Password', '');
		AParams.AddPair('MonitorBy', '');
		AParams.AddPair('OSAuthent', '');
		AParams.AddPair('Protocol', 'Local');
		AParams.AddPair('Server', '');
		AParams.AddPair('Port', '3');
		AParams.AddPair('SQLDialect', '3');
		AParams.AddPair('RoleName', '');
		AParams.AddPair('CharacterSet', 'NONE');
		AParams.AddPair('GUIDEndian', 'Little');
		AParams.AddPair('ExtendedMetadata', 'False');
		AParams.AddPair('OpenMode', 'Open');
		AParams.AddPair('IBAdvanced', '');
		AParams.AddPair('CharLenMode', 'Chars');
	end
	else if SameText(ADriverID, 'Ora') or SameText(ADriverID, 'Oracle') then
	begin
		AParams.AddPair('Database', ''); // TNS Name ou EZConnect
		AParams.AddPair('User_Name', 'system');
		AParams.AddPair('Password', '');
		AParams.AddPair('Server', 'localhost');
		AParams.AddPair('OSAuthent', 'No');
		AParams.AddPair('Pooled', 'False');
		AParams.AddPair('Server', 'localhost'); // Or your TNS alias/service name
		AParams.AddPair('Database', ''); // Or your SID/Service Name
		AParams.AddPair('User_Name', 'system');
		AParams.AddPair('Password', '');
		AParams.AddPair('Port', '1521'); // Default Oracle port
		AParams.AddPair('LoginTimeout', '0');
		AParams.AddPair('CharacterSet', 'AL32UTF8');
		AParams.AddPair('MonitorBy', '<LOCAL>');
		AParams.AddPair('ExtendedMetadata', 'False');
		AParams.AddPair('ApplicationName', '');
	end
	else if SameText(ADriverID, 'IB') then
	begin
		AParams.AddPair('Pooled', 'False');
		AParams.AddPair('Database', '');
		AParams.AddPair('User_Name', '');
		AParams.AddPair('Password', '');
		AParams.AddPair('MonitorBy', '');
		AParams.AddPair('OSAuthent', '');
		AParams.AddPair('Protocol', 'Local');
		AParams.AddPair('Server', '');
		AParams.AddPair('Port', '');
		AParams.AddPair('SQLDialect', '3');
		AParams.AddPair('RoleName', 'NONE');
		AParams.AddPair('CharacterSet', 'NONE');
		AParams.AddPair('GUIDEndian', 'Little');
		AParams.AddPair('ExtendedMetadata', 'False');
		AParams.AddPair('OpenMode', 'Open');
		AParams.AddPair('IBAdvanced', '');
		AParams.AddPair('InstanceName', '');
		AParams.AddPair('SEPassword', '');
	end
	else if SameText(ADriverID, 'MSAcc') then
	begin
		AParams.AddPair('Pooled', 'False');
		AParams.AddPair('Database', '');
		AParams.AddPair('User_Name', '');
		AParams.AddPair('Password', '');
		AParams.AddPair('MonitorBy', '');
		AParams.AddPair('ODBCAdvanced', '');
		AParams.AddPair('LoginTimeout', '');
		AParams.AddPair('SystemDB', '');
		AParams.AddPair('ReadOnly', 'Choose');
		AParams.AddPair('StringFormat', 'Choose');
	end
	else if SameText(ADriverID, 'IBLite') then
	begin
		AParams.AddPair('Database', '');
		AParams.AddPair('User_Name', '');
		AParams.AddPair('Password', '');
		AParams.AddPair('MonitorBy', '');
		AParams.AddPair('CharacterSet', 'NONE');
		AParams.AddPair('GUIDEndian', 'Little');
		AParams.AddPair('ExtendedMetadata', 'False');
		AParams.AddPair('OpenMode', 'Open');
		AParams.AddPair('IBAdvanced', '');
	end
	else
	begin
		// Driver não mapeado ainda
		AParams.AddPair('Database', '');
		AParams.AddPair('User_Name', '');
		AParams.AddPair('Password', '');
	end;
end;

end.
