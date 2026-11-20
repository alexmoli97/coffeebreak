unit MainForm;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Types,
  System.ImageList,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Buttons,
  Vcl.Menus,
  Vcl.Dialogs,
  Vcl.ImgList,
  Agenda.Model;

type
  TFormMain = class(TForm)
    PanelHeader: TPanel;
    LabelTitle: TLabel;
    LabelSubtitle: TLabel;
    PanelBreak: TPanel;
    LabelBreak: TLabel;
    ButtonDay19: TSpeedButton;
    ButtonDay20: TSpeedButton;
    PanelKirk: TPanel;
    LabelKirk: TLabel;
    ListKirk: TListView;
    PanelSpock: TPanel;
    LabelSpock: TLabel;
    ListSpock: TListView;
    StatusBar: TStatusBar;
    MainMenu: TMainMenu;
    MenuHelp: TMenuItem;
    MenuAbout: TMenuItem;
    ImageListRowHeight: TImageList;
    TimerRefresh: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure DayButtonClick(Sender: TObject);
    procedure ListCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
      var DefaultDraw: Boolean);
    procedure ListCustomDrawSubItem(Sender: TCustomListView; Item: TListItem; SubItem: Integer;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure MenuAboutClick(Sender: TObject);
    procedure TimerRefreshTimer(Sender: TObject);
  private
    FAgenda: TArray<TSession>;
    FDays: TArray<TDate>;
    FDay: TDate;
    FClockOffset: TDateTime;
    FSimulated: Boolean;
    FVersion: string;
    FCurrent: array [Boolean] of Integer; // indice in FAgenda della sessione in corso: False = Kirk, True = Spock
    function CurrentNow: TDateTime;
    procedure FillList(const AList: TListView; const ARoom: string);
    procedure FillDay;
    procedure RefreshClock;
    procedure StyleItem(const AList: TCustomListView; const AItem: TListItem);
    procedure AboutHyperlinkClicked(Sender: TObject);
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  System.DateUtils,
  Winapi.ShellAPI,
  Vcl.Themes,
  App.Options;

// non dichiarata in Winapi.Windows
function RegisterApplicationRestart(ACommandLine: PWideChar; AFlags: DWORD): HRESULT; stdcall; external kernel32;

const
  // flag di RegisterApplicationRestart (WinBase.h), anche loro non dichiarati
  RESTART_NO_CRASH = 1;
  RESTART_NO_HANG = 2;
  RESTART_NO_REBOOT = 8;
  RepoUrl = 'https://github.com/alexmoli97/coffeebreak';
  Accent = TColor($002E7AE0); // arancio caffè #E07A2E
  DayNames: array [1 .. 7] of string = ('Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica');

function DayCaption(const ADay: TDate): string;
begin
  // mese in italiano come i giorni, anche su Windows in un'altra lingua
  Result := DayNames[DayOfTheWeek(ADay)] + ' ' + FormatDateTime('d mmmm', ADay, TFormatSettings.Create('it-IT'));
end;

function AppVersion: string;
var
  LMajor, LMinor, LBuild: Cardinal;
begin
  if GetProductVersion(ParamStr(0), LMajor, LMinor, LBuild) then
    Result := Format('%d.%d.%d', [LMajor, LMinor, LBuild])
  else
    Result := '?';
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  LArgs: TArray<string>;
  LNow: TDateTime;
begin
  SetLength(LArgs, ParamCount);
  for var I: Integer := 1 to ParamCount do
    LArgs[I - 1] := ParamStr(I);
  // con --now l'orologio parte dall'ora indicata e poi avanza normalmente
  LNow := Now;
  FClockOffset := ResolveNow(LArgs, LNow) - LNow;
  FSimulated := ResolveNow(LArgs, 0) <> 0;
  // permette al Restart Manager (usato dall'installer durante un aggiornamento) di riaprire l'app dopo averla chiusa;
  // l'esito non si controlla: senza registrazione l'app resta chiusa dopo l'aggiornamento, come qualsiasi altra
  // shortcut: argomenti senza spazi (oggi solo --now), virgolette se ne arriva uno con spazi
  // riavvio solo dopo un aggiornamento: non dopo crash, blocchi o riavvii di Windows
  RegisterApplicationRestart(PChar(string.Join(' ', LArgs)), RESTART_NO_CRASH or RESTART_NO_HANG or RESTART_NO_REBOOT);

  FAgenda := LoadEmbeddedAgenda;
  for var LSession in FAgenda do
    if (Length(FDays) = 0) or (FDays[High(FDays)] <> LSession.Day) then
      FDays := FDays + [LSession.Day];
  // un pulsante per giorno, nel .dfm
  Assert(Length(FDays) = 2, 'L''agenda incorporata deve avere due giorni');
  FVersion := AppVersion;

  Caption := 'CoffeeBreak ' + FVersion;
  LabelTitle.Caption := 'ITDevCon 2026 · Roma';
  ButtonDay19.Caption := DayCaption(FDays[0]);
  ButtonDay20.Caption := DayCaption(FDays[1]);
  StatusBar.Panels[0].Text := 'CoffeeBreak ' + FVersion;

  FDay := DefaultDay(FAgenda, CurrentNow);
  ButtonDay20.Down := FDay = FDays[1];
  ButtonDay19.Down := not ButtonDay20.Down;
  FillDay;
  RefreshClock;
end;

function TFormMain.CurrentNow: TDateTime;
begin
  Result := Now + FClockOffset;
end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  PanelKirk.Width := ClientWidth div 2;
end;

procedure TFormMain.DayButtonClick(Sender: TObject);
begin
  // Tag 0 e 1 nel .dfm
  FDay := FDays[(Sender as TComponent).Tag];
  FillDay;
end;

procedure TFormMain.FillDay;
begin
  FillList(ListKirk, 'Kirk');
  FillList(ListSpock, 'Spock');
end;

procedure TFormMain.FillList(const AList: TListView; const ARoom: string);
begin
  AList.Items.BeginUpdate;
  try
    AList.Items.Clear;
    for var I: Integer := 0 to Integer(Length(FAgenda)) - 1 do
    begin
      var LSession := FAgenda[I];
      if (LSession.Day <> FDay) or (LSession.Room <> ARoom) then
        Continue;
      var LItem := AList.Items.Add;
      LItem.Caption := FormatDateTime('hh:nn', LSession.StartAt) + ' - ' + FormatDateTime('hh:nn', LSession.EndAt);
      if LSession.Title = '-' then
        LItem.SubItems.Add('')
      else
        LItem.SubItems.Add(LSession.Title);
      LItem.SubItems.Add(LSession.Speaker);
      // l'indice in FAgenda, non un puntatore: StyleItem lo rilegge da Data
      LItem.Data := Pointer(NativeInt(I));
    end;
  finally
    AList.Items.EndUpdate;
  end;
end;

procedure TFormMain.RefreshClock;
var
  LNow: TDateTime;
  LMinutes: Integer;
begin
  LNow := CurrentNow;
  LabelBreak.Caption := BreakBannerText(NextBreak(FAgenda, LNow, LMinutes), LMinutes);
  if IsLastTalk(FAgenda, LNow) then
  begin
    LabelSubtitle.Caption := 'Grazie per essere rimasti fino all''ultimo talk!';
    LabelSubtitle.Font.Style := [fsBold];
    LabelSubtitle.Font.Color := Accent;
    LabelSubtitle.StyleElements := [];
  end
  else
  begin
    LabelSubtitle.Caption := 'L''agenda della conferenza, sala per sala';
    LabelSubtitle.Font.Style := [];
    LabelSubtitle.StyleElements := [seFont, seClient, seBorder];
  end;
  FCurrent[False] := CurrentSessionIndex(FAgenda, 'Kirk', LNow);
  FCurrent[True] := CurrentSessionIndex(FAgenda, 'Spock', LNow);
  if FSimulated then
    StatusBar.Panels[1].Text := 'Ora simulata: ' + FormatDateTime('dd/mm/yyyy hh:nn', LNow)
  else
    StatusBar.Panels[1].Text := '';
  ListKirk.Invalidate;
  ListSpock.Invalidate;
end;

procedure TFormMain.TimerRefreshTimer(Sender: TObject);
begin
  RefreshClock;
end;

procedure TFormMain.StyleItem(const AList: TCustomListView; const AItem: TListItem);
var
  LIndex: NativeInt;
begin
  LIndex := NativeInt(AItem.Data);
  if LIndex = FCurrent[AList = ListSpock] then
  begin
    AList.Canvas.Brush.Color := Accent;
    AList.Canvas.Font.Color := clWhite;
    AList.Canvas.Font.Style := [fsBold];
    Exit;
  end;
  // in custom draw il canvas parte dai colori del controllo, non da quelli dello stile VCL
  AList.Canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
  AList.Canvas.Font.Color := StyleServices.GetSystemColor(clWindowText);
  case FAgenda[LIndex].Kind of
    skBreak, skLunch:
      AList.Canvas.Font.Style := [fsItalic];
    skPlenary:
      AList.Canvas.Font.Style := [fsBold];
    skFree:
      begin
        AList.Canvas.Font.Style := [];
        AList.Canvas.Font.Color := StyleServices.GetSystemColor(clGrayText);
      end;
  else
    AList.Canvas.Font.Style := [];
  end;
end;

procedure TFormMain.ListCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
  var DefaultDraw: Boolean);
begin
  StyleItem(Sender, Item);
end;

procedure TFormMain.ListCustomDrawSubItem(Sender: TCustomListView; Item: TListItem; SubItem: Integer;
  State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  StyleItem(Sender, Item);
end;

procedure TFormMain.MenuAboutClick(Sender: TObject);
var
  LDialog: TTaskDialog;
begin
  // senza owner: lo libera il finally, non il form
  LDialog := TTaskDialog.Create(nil);
  try
    LDialog.Caption := 'Informazioni su CoffeeBreak';
    LDialog.Title := 'CoffeeBreak ' + FVersion;
    LDialog.Text := 'L''agenda di ITDevCon 2026, sala per sala.' + sLineBreak + sLineBreak +
      'Questa app non contiene codice di aggiornamento: installazione e aggiornamenti passano da WinGet.';
    LDialog.Flags := [tfEnableHyperlinks, tfAllowDialogCancellation];
    LDialog.CommonButtons := [tcbOk];
    LDialog.FooterIcon := tdiInformation;
    LDialog.FooterText := '<a href="' + RepoUrl + '">' + RepoUrl + '</a>';
    LDialog.OnHyperlinkClicked := AboutHyperlinkClicked;
    LDialog.Execute;
  finally
    LDialog.Free;
  end;
end;

procedure TFormMain.AboutHyperlinkClicked(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar((Sender as TTaskDialog).URL), nil, nil, SW_SHOWNORMAL);
end;

end.
