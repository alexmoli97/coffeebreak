program CoffeeBreak;

{$R CoffeeBreak.res}

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  MainForm in 'MainForm.pas' {FormMain};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'CoffeeBreak';
  // Vcl.Themes registra da solo gli stili incorporati come risorse VCLSTYLE: qui c'è solo quello dell'app
  for var LStyleName in TStyleManager.StyleNames do
    if LStyleName <> 'Windows' then
      TStyleManager.TrySetStyle(LStyleName);
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
