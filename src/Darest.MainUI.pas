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
unit Darest.MainUI;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
	System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
	FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
	FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
	FireDAC.Phys, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client,
	Vcl.AppEvnts, Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.Buttons,
	FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.ConnEdit,  Vcl.Themes, Vcl.Styles,
	Darest.Types, Darest.Logic, Darest.ConfigUI,
	Darest.Helpers, Darest.EndPoints;

type
	TfrmMainUI = class(TForm)
		Label1: TLabel;
		btStart: TBitBtn;
		ImageList1: TImageList;
		btConfig: TBitBtn;
		TrayIcon1: TTrayIcon;
		ApplicationEvents1: TApplicationEvents;
		procedure FormShow(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
		procedure btConfigClick(Sender: TObject);
		procedure btStartClick(Sender: TObject);
		procedure ApplicationEvents1Minimize(Sender: TObject);
		procedure TrayIcon1DblClick(Sender: TObject);
	private
		FPermissions: TArray<TTablePermission>;
		FThemeDark: Boolean;
		FDBConnector: TDataBaseConnector;
	public
		procedure AfterConstruction; override;
		procedure BeforeDestruction; override;
	end;

var
	frmMainUI: TForm;

implementation

{$R *.dfm}

procedure TfrmMainUI.AfterConstruction;
begin
	inherited;
	FDBConnector := TDataBaseConnector.Create;
	FConfiguration.ApplicationPath := ExtractFilePath(ParamStr(0));
end;

procedure TfrmMainUI.ApplicationEvents1Minimize(Sender: TObject);
begin
	Hide();
	WindowState := wsMinimized;
	TrayIcon1.Visible := True;
	TrayIcon1.ShowBalloonHint;
end;

procedure TfrmMainUI.BeforeDestruction;
begin
	FDBConnector.Free;
	inherited;
end;

procedure TfrmMainUI.btStartClick(Sender: TObject);
var
	Swagger: string;
	LLoginPrompt: Boolean;
begin
	if FDBConnector.IsRunning then
	begin
		btStart.Caption := 'Start';
		if FThemeDark then
		 btStart.ImageIndex := 5
		else
			btStart.ImageIndex := 2;
		Label1.Caption := 'Server stopped';
		TrayIcon1.Hint := APP_NAME + ' Server stopped';
		FDBConnector.DatabaseConnnection.Close;
		FDBConnector.StopRESTServer;
	end
	else
	begin
		FDBConnector.SetTablesPermissions(FConfiguration.TablePermissions, FPermissions, LLoginPrompt);
		FDBConnector.DatabaseConnnection.LoginPrompt := LLoginPrompt;

		FDBConnector.ConfigureConnection(FDBConnector.DatabaseConnnection.LoginPrompt);
		FDBConnector.DatabaseConnnection.Connected := True;
		FDBConnector.ReloadDatabaseSchema();
		FDBConnector.SetPermissions(FPermissions);
		RegisterDBEndpoints(FDBConnector);

		//
		FDBConnector.StartRESTServer(FConfiguration.ServicePort);

		btStart.Caption := 'Stop';
		if FThemeDark then
		 btStart.ImageIndex := 4
		else
			btStart.ImageIndex := 1;
		Label1.Caption := Format('Server started %s:%d', [FConfiguration.ServiceHost, FConfiguration.ServicePort]);
		TrayIcon1.Hint := APP_NAME + ' ' + Label1.Caption;
	end;
end;

procedure TfrmMainUI.btConfigClick(Sender: TObject);
var
	LLoginPrompt: Boolean;
begin
	frmConfig := TfrmConfig.Create(Self, FDBConnector);
	frmConfig.FreeOnRelease;
	frmConfig.ClientHeight := FConfiguration.UIHeight;
	frmConfig.ClientWidth := FConfiguration.UIWidth;
	frmConfig.ShowModal;
	if frmConfig.ModalResult = mrOk then
	begin
		Label1.Caption := FConfiguration.URI;
		btStart.Enabled := FConfiguration.ServerConfigured;
	end;
	FDBConnector.LoginPrompt := LLoginPrompt;
end;

procedure TfrmMainUI.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
	CanClose := not FDBConnector.IsRunning;
end;

// Another UI can remove this...
function GetStyledButtonColor: TColor;
var
	LDetails: TThemedElementDetails;
	LColor: TColor;
begin
	if StyleServices.Enabled and not StyleServices.IsSystemStyle then
	begin
		LDetails := StyleServices.GetElementDetails(tbPushButtonNormal);
		if not StyleServices.GetElementColor(LDetails, ecFillColor, LColor) then
			LColor := StyleServices.GetStyleColor(scButtonFocused);
	end
	else
	begin
		LColor := GetSysColor(COLOR_BTNFACE);
	end;

	Result := LColor;
end;

procedure TfrmMainUI.FormCreate(Sender: TObject);
begin
	FThemeDark := False;
	Label1.Caption := 'Server stopped';
	TrayIcon1.Hint := APP_NAME + ' ' + Label1.Caption;
	FConfiguration.ServicePort := 8080;
	var BtnColor := GetStyledButtonColor;

	if IsColorDark(BtnColor) then
	begin
    FThemeDark := True;
		btConfig.ImageIndex := 3;
    btStart.ImageIndex := 5;
	end;

end;

procedure TfrmMainUI.FormShow(Sender: TObject);
begin
	LoadConfiguration();
	btStart.Enabled := FConfiguration.ServerConfigured;
	ApplySavedParamsToConnection(FDBConnector.DatabaseConnnection, FConfiguration.DatabaseParams);
	Label1.Caption := FConfiguration.URI;
	if FConfiguration.AutoConnect then
	begin
		try
			FDBConnector.LoginPrompt := FConfiguration.LoginPrompt;
			FDBConnector.Connect;
		except
			raise;
		end;
	end;
end;

procedure TfrmMainUI.TrayIcon1DblClick(Sender: TObject);
begin
	Show();
	WindowState := wsNormal;
	Application.BringToFront();
end;

end.
