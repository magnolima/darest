program Darest;

uses
  Vcl.Forms,
  Darest.MainUI in 'Darest.MainUI.pas' {frmMainUI},
  Darest.Logic in 'Darest.Logic.pas',
  Darest.ConfigUI in 'Darest.ConfigUI.pas' {frmConfig},
  Darest.EndPoints in 'Darest.EndPoints.pas',
  Darest.Helpers in 'Darest.Helpers.pas',
  Darest.Types in 'Darest.Types.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
	Application.CreateForm(TfrmMainUI, frmMainUI);
  Application.Run;
end.
