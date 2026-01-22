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
unit Darest.ConfigUI;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
	Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.CheckLst,
	Dialogs, Vcl.ComCtrls, Vcl.Graphics,
	FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
	FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
	FireDAC.Phys, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client,
	FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.ConnEdit,
	FireDAC.Phys.MySQL, // For MySQL
	FireDAC.Phys.PG, // For PostgreSQL
	FireDAC.Phys.SQLite, // For SQLite
	FireDAC.Phys.FB, // For Firebird
	// FireDAC.Phys.MSSQL, // For SQL Server
	// FireDAC.Phys.Oracle, // For Oracle
	// FireDAC.Phys.DB2, // For DB2
	FireDAC.Phys.IB, // For InterBase
	// FireDAC.Phys.ADS,       // For Advantage Database Server
	Vcl.Grids, System.JSON, REST.JSON, System.IOUtils,
	System.Generics.Collections, Vcl.ExtCtrls,
	Darest.Types, Darest.Helpers, Darest.Logic;

const
	CHECK_BOX_SIZE = 26;
	UIWIDTH_MIN = 940;
	UIHEIGHT_MIN = 740;

type
	TfrmConfig = class(TForm)
		btnConnect: TButton;
		btnSave: TButton;
		btnSettings: TButton;
		cbLoginPrompt: TCheckBox;
		sgPermissions: TStringGrid;
		Panel1: TPanel;
		Label1: TLabel;
		btnCancel: TButton;
		edtServicePort: TEdit;
		Label2: TLabel;
    cbAutoConnect: TCheckBox;
    edUri: TEdit;
    Label3: TLabel;
		procedure btnConnectClick(Sender: TObject);
		procedure btnSaveClick(Sender: TObject);
		procedure btnSettingsClick(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure sgPermissionsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
		procedure sgPermissionsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
		procedure btnCancelClick(Sender: TObject);
		procedure FormShow(Sender: TObject);
		procedure FormResize(Sender: TObject);
	private
		FPermissions: TArray<TTablePermission>;
		FDatabaseConnector: TDataBaseConnector;
		procedure LoadTablesPermissions(const AURI: String);
		procedure ConnectDatabase;
		procedure SaveTablesPermission;
    function TablesPermissionToJsonString(const APermissions: TArray<TTablePermission>): string;
	public
		constructor Create(AOwner: TComponent; AConnector: TDataBaseConnector); reintroduce;
	end;

var
	frmConfig: TfrmConfig;

implementation

{$R *.dfm}

{ TConfigForm }

constructor TfrmConfig.Create(AOwner: TComponent; AConnector: TDataBaseConnector);
begin
	inherited Create(AOwner);
	FDatabaseConnector := AConnector;
end;

procedure TfrmConfig.FormCreate(Sender: TObject);
begin
	Self.Constraints.MinHeight := UIHEIGHT_MIN;
	Self.Constraints.MinWidth := UIWIDTH_MIN;
	sgPermissions.RowCount := 2;
	sgPermissions.Cells[0, 0] := 'Table Name';
	sgPermissions.Cells[1, 0] := 'Visible';
	sgPermissions.Cells[2, 0] := 'Select';
	sgPermissions.Cells[3, 0] := 'Insert';
	sgPermissions.Cells[4, 0] := 'Update';
	sgPermissions.Cells[5, 0] := 'Delete';

	sgPermissions.ColWidths[0] := FConfiguration.ColTableNameWidth;
	sgPermissions.ColWidths[1] := 70;
	sgPermissions.ColWidths[2] := 70;
	sgPermissions.ColWidths[3] := 70;
	sgPermissions.ColWidths[4] := 70;
	sgPermissions.ColWidths[5] := 70;
end;

procedure TfrmConfig.FormResize(Sender: TObject);
begin
	FConfiguration.UIWidth := Self.ClientWidth;
	FConfiguration.UIHeight := Self.ClientHeight;
end;

procedure TfrmConfig.FormShow(Sender: TObject);
begin
	btnConnect.Enabled := False;
	ConnectDatabase();
	cbLoginPrompt.Checked := FConfiguration.LoginPrompt;
	edtServicePort.Text := FConfiguration.ServicePort.ToString;
end;

procedure TfrmConfig.ConnectDatabase();
var
	lLogin: boolean;
begin
	if FDatabaseConnector.DatabaseConnnection.Params.Text.IsEmpty then
		Exit;

	btnConnect.Enabled := true;
	FDatabaseConnector.ConnectDatabase(FPermissions);
	FConfiguration.URI := FDatabaseConnector.DatabaseConnnection.DriverName + '/' +
		 FDatabaseConnector.DatabaseConnnection.Params.Values['database'];
	Label1.Caption := FConfiguration.URI;
	LoadTablesPermissions(FConfiguration.URI);
end;

procedure TfrmConfig.btnConnectClick(Sender: TObject);
begin
	try
		ConnectDatabase();
	except
		on E: Exception do
			ShowMessage('Connection error: ' + E.Message);
	end;
end;

procedure TfrmConfig.LoadTablesPermissions(const AURI: String);
var
	I: Integer;
	APromptLogin: boolean;
	LoadedPermissions: TArray<TTablePermission>;

	procedure SetDefaults;
	var
		I: Integer;
	begin
		for I := 0 to sgPermissions.RowCount - 1 do
		begin
			sgPermissions.Cells[0, I + 1] := '';
			sgPermissions.Cells[1, I + 1] := '';
			sgPermissions.Cells[2, I + 1] := '';
			sgPermissions.Cells[3, I + 1] := '';
			sgPermissions.Cells[4, I + 1] := '';
			sgPermissions.Cells[5, I + 1] := '';
		end;
		FPermissions := Default (TArray<TTablePermission>);
	end;
begin

	SetDefaults;

	SetLength(FPermissions, FDatabaseConnector.SchemePermissions.Count);
	I := 0;

	sgPermissions.RowCount := Length(FPermissions) + 1;
	for var Pair in FDatabaseConnector.SchemePermissions do
	begin
		// Default permission
		FPermissions[I].Name := Pair.Value.Name;
		FPermissions[I].IsView := Pair.Value.IsView;
		FPermissions[I].Perm.Visible := true;
		FPermissions[I].Perm.Select := true;
		FPermissions[I].Perm.Insert := False;
		FPermissions[I].Perm.Update := False;
		FPermissions[I].Perm.Delete := False;

		// Grid
		sgPermissions.Cells[0, I + 1] := FPermissions[I].Name;
		sgPermissions.Cells[1, I + 1] := BoolToStr(true, true);
		sgPermissions.Cells[2, I + 1] := BoolToStr(False, true);
		sgPermissions.Cells[3, I + 1] := BoolToStr(False, true);
		sgPermissions.Cells[4, I + 1] := BoolToStr(False, true);
		sgPermissions.Cells[5, I + 1] := BoolToStr(False, true);
		Inc(I);
	end;

	if FDatabaseConnector.SetTablesPermissions(FConfiguration.TablePermissions, LoadedPermissions,
		 APromptLogin)  then
	begin
		FPermissions := LoadedPermissions;
		cbLoginPrompt.Checked := APromptLogin;
	end;

	for I := 0 to High(FPermissions) do
	begin
		sgPermissions.Cells[0, I + 1] := FPermissions[I].Name;
		sgPermissions.Cells[1, I + 1] := BoolToStr(FPermissions[I].Perm.Visible, true);
		sgPermissions.Cells[2, I + 1] := BoolToStr(FPermissions[I].Perm.Select, true);
		sgPermissions.Cells[3, I + 1] := BoolToStr(FPermissions[I].Perm.Insert, true);
		sgPermissions.Cells[4, I + 1] := BoolToStr(FPermissions[I].Perm.Update, true);
		sgPermissions.Cells[5, I + 1] := BoolToStr(FPermissions[I].Perm.Delete, true);
	end;

end;

function IfThenInt(const ACondition: boolean; AResultTrue, AResultFalse: Integer): Integer;
begin
	if ACondition then
		Result := AResultTrue
	else
		Result := AResultFalse
end;

function StrToBoolTest(const ABoolStr: String): boolean;
begin
	if ABoolStr.IsEmpty then
		Exit;
	Result := StrToBool(ABoolStr);
end;

procedure TfrmConfig.sgPermissionsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
	CheckState: boolean;
	CheckRect: TRect;
begin
	if Length(FPermissions) = 0 then
		Exit;

	if (ACol > 0) and (ARow > 0) then
	begin
		case ACol of
			1:
				CheckState := FPermissions[ARow - 1].Perm.Visible;
			2:
				CheckState := FPermissions[ARow - 1].Perm.Select;
			3:
				CheckState := FPermissions[ARow - 1].Perm.Insert;
			4:
				CheckState := FPermissions[ARow - 1].Perm.Update;
			5:
				CheckState := FPermissions[ARow - 1].Perm.Delete;
		else
			CheckState := False;
		end;

		sgPermissions.Canvas.FillRect(Rect);

		CheckRect := Rect;
		CheckRect.Left := Rect.Left + (Rect.Width - CHECK_BOX_SIZE) div 2;
		CheckRect.Top := Rect.Top + (Rect.Height - CHECK_BOX_SIZE) div 2;
		CheckRect.Right := CheckRect.Left + CHECK_BOX_SIZE;
		CheckRect.Bottom := CheckRect.Top + CHECK_BOX_SIZE;

		// Checkbox
		DrawFrameControl(sgPermissions.Canvas.Handle, CheckRect, DFC_BUTTON, DFCS_BUTTONCHECK or IfThenInt(CheckState,
			 DFCS_CHECKED, 0));

	end;

	if gdFocused in State then
	begin
		FConfiguration.ColTableNameWidth := sgPermissions.ColWidths[0];
		sgPermissions.Canvas.DrawFocusRect(Rect);
	end;
end;

procedure TfrmConfig.sgPermissionsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	ACol, ARow: Integer;
begin
	sgPermissions.MouseToCell(X, Y, ACol, ARow);
	if (ARow > 0) and (ACol > 0) and (ACol <= MAX_PERM_COLS) then
	begin
		case ACol of
			1:
				FPermissions[ARow - 1].Perm.Visible := not FPermissions[ARow - 1].Perm.Visible;
			2:
				FPermissions[ARow - 1].Perm.Select := not FPermissions[ARow - 1].Perm.Select;
			3:
				FPermissions[ARow - 1].Perm.Insert := not FPermissions[ARow - 1].Perm.Insert;
			4:
				FPermissions[ARow - 1].Perm.Update := not FPermissions[ARow - 1].Perm.Update;
			5:
				FPermissions[ARow - 1].Perm.Delete := not FPermissions[ARow - 1].Perm.Delete;
		end;
		sgPermissions.Repaint;
	end;
end;

function TfrmConfig.TablesPermissionToJsonString(const APermissions: TArray<TTablePermission>): string;
var
	I: Integer;
	RootObject: TJSONObject;
	PermissionsArray: TJSONArray;
	JSONStr: string;
	JSONObject: TJSONObject;
begin

	RootObject := TJSONObject.Create;
	try

		RootObject.AddPair('PromptLogin', TJSONBool.Create(FDatabaseConnector.LoginPrompt));
		PermissionsArray := TJSONArray.Create;

		for I := 0 to High(APermissions) do
		begin
			JSONObject := TJSONObject.Create;
			JSONObject.AddPair('Name', APermissions[I].Name);

			// Permission sub-object for 'Perm'
			var
			PermObj := TJSONObject.Create;
			PermObj.AddPair('Visible', TJSONBool.Create(APermissions[I].Perm.Visible));
			PermObj.AddPair('Select', TJSONBool.Create(APermissions[I].Perm.Select));
			PermObj.AddPair('Insert', TJSONBool.Create(APermissions[I].Perm.Insert));
			PermObj.AddPair('Update', TJSONBool.Create(APermissions[I].Perm.Update));
			PermObj.AddPair('Delete', TJSONBool.Create(APermissions[I].Perm.Delete));
			JSONObject.AddPair('Perm', PermObj);
			PermissionsArray.AddElement(JSONObject);
		end;
		RootObject.AddPair('Permissions', PermissionsArray);
		JSONStr := RootObject.ToJSON;

	finally
		RootObject.Free;
	end;

	Result := JSONStr;

	FConfiguration.TablePermissions := JSONStr;
end;

procedure TfrmConfig.SaveTablesPermission;
var
	Pair: TPair<string, TTablePermission>;
	I: Integer;
begin
	FDatabaseConnector.SetPermissions(FPermissions);
	FDatabaseConnector.LoginPrompt := cbLoginPrompt.Checked;
	FConfiguration.TablePermissions := TablesPermissionToJsonString(FPermissions);
	// apply to DB connector
	FDatabaseConnector.SetPermissions(FPermissions);
end;

procedure TfrmConfig.btnSaveClick(Sender: TObject);
begin

	SaveTablesPermission();

	FConfiguration.ServicePort := StrToIntDef(edtServicePort.Text, 8080);
	FConfiguration.DatabaseParams := ParamsToBase64(FDatabaseConnector.DatabaseConnnection.Params);
	FConfiguration.AutoConnect := cbAutoConnect.Checked;
	SaveConfiguration();
  Self.ModalResult := mrOk;
end;

procedure TfrmConfig.btnSettingsClick(Sender: TObject);
var
	ConnEditor: TfrmFDGUIxFormsConnEdit;
begin
	ConnEditor := TfrmFDGUIxFormsConnEdit.Create(Self);
	try
		if ConnEditor.Execute(FDatabaseConnector.DatabaseConnnection, 'Select your Database Connection', nil) then
		begin
			btnConnect.Enabled := not FDatabaseConnector.DatabaseConnnection.Params.Text.IsEmpty;
			FDatabaseConnector.DatabaseConnnection.Close;
			ConnectDatabase();
		end;
	finally
		ConnEditor.Free;
	end;
end;

procedure TfrmConfig.btnCancelClick(Sender: TObject);
begin
	Self.ModalResult := mrNone;
	Close;
end;

end.
