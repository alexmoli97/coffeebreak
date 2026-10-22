unit MainForm;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, Vcl.Menus, Vcl.Dialogs, System.ImageList, Vcl.ImgList,
  Agenda.Model;

type
  TFormMain = class(TForm)
    PanelHeader: TPanel;
    LabelTitle: TLabel;
    LabelSubtitle: TLabel;
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
    TimerScreenshot: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure DayButtonClick(Sender: TObject);
    procedure ListCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
      var DefaultDraw: Boolean);
    procedure ListCustomDrawSubItem(Sender: TCustomListView; Item: TListItem; SubItem: Integer;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure MenuAboutClick(Sender: TObject);
    procedure TimerRefreshTimer(Sender: TObject);
    procedure TimerScreenshotTimer(Sender: TObject);
  private
    FAgenda: TArray<TSession>;
    FDays: TArray<TDate>;
    FDay: TDate;
    FClockOffset: TDateTime;
    FSimulated: Boolean;
    FVersion: string;
    FScreenshotPath: string;
    FCurrent: array [Boolean] of Integer; // indice in FAgenda della sessione in corso: False = Kirk, True = Spock
    function CurrentNow: TDateTime;
    procedure FillList(AList: TListView; const ARoom: string);
    procedure FillDay;
    procedure RefreshClock;
    procedure StyleItem(AList: TCustomListView; AItem: TListItem);
    procedure AboutHyperlinkClicked(Sender: TObject);
    procedure SaveScreenshot(const AFileName: string);
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  System.DateUtils, Winapi.ShellAPI, Winapi.Dwmapi, Vcl.Themes, Vcl.Imaging.pngimage, App.Options;

// non dichiarata in Winapi.Windows
function RegisterApplicationRestart(ACommandLine: PWideChar; AFlags: DWORD): HRESULT; stdcall; external kernel32;

const
  RepoUrl = 'https://github.com/alexmoli97/coffeebreak';
  Accent = TColor($002E7AE0); // arancio caffè #E07A2E
  DayNames: array [1 .. 7] of string = ('Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica');

function DayCaption(const ADay: TDate): string;
begin
  Result := DayNames[DayOfTheWeek(ADay)] + ' ' + FormatDateTime('d mmmm', ADay);
end;

function AppVersion: string;
var
  Major, Minor, Build: Cardinal;
begin
  if GetProductVersion(ParamStr(0), Major, Minor, Build) then
    Result := Format('%d.%d.%d', [Major, Minor, Build])
  else
    Result := '?';
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  Args: TArray<string>;
begin
  SetLength(Args, ParamCount);
  for var I := 1 to ParamCount do
    Args[I - 1] := ParamStr(I);
  // con --now l'orologio parte dall'ora indicata e poi avanza normalmente
  FClockOffset := ResolveNow(Args, Now) - Now;
  FSimulated := ResolveNow(Args, 0) <> 0;
  FScreenshotPath := ScreenshotPath(Args);
  // permette al Restart Manager (usato dall'installer durante un aggiornamento) di riaprire l'app dopo averla chiusa
  if FScreenshotPath = '' then
    RegisterApplicationRestart(PChar(string.Join(' ', Args)), 0);

  FAgenda := LoadEmbeddedAgenda;
  for var S in FAgenda do
    if (Length(FDays) = 0) or (FDays[High(FDays)] <> S.Day) then
      FDays := FDays + [S.Day];
  FVersion := AppVersion;

  Caption := 'CoffeeBreak ' + FVersion;
  LabelTitle.Caption := 'ITDevCon 2026 · Roma';
  LabelSubtitle.Caption := 'L''agenda della conferenza, sala per sala';
  ButtonDay19.Caption := DayCaption(FDays[0]);
  ButtonDay20.Caption := DayCaption(FDays[1]);
  StatusBar.Panels[0].Text := 'CoffeeBreak ' + FVersion;

  FDay := DefaultDay(FAgenda, CurrentNow);
  ButtonDay20.Down := FDay = FDays[1];
  ButtonDay19.Down := not ButtonDay20.Down;
  FillDay;
  RefreshClock;
  TimerScreenshot.Enabled := FScreenshotPath <> '';
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
  FDay := FDays[TComponent(Sender).Tag];
  FillDay;
end;

procedure TFormMain.FillDay;
begin
  FillList(ListKirk, 'Kirk');
  FillList(ListSpock, 'Spock');
end;

procedure TFormMain.FillList(AList: TListView; const ARoom: string);
begin
  AList.Items.BeginUpdate;
  try
    AList.Items.Clear;
    for var I := 0 to High(FAgenda) do
    begin
      var S := FAgenda[I];
      if (S.Day <> FDay) or (S.Room <> ARoom) then
        Continue;
      var Item := AList.Items.Add;
      Item.Caption := FormatDateTime('hh:nn', S.StartAt) + ' - ' + FormatDateTime('hh:nn', S.EndAt);
      if S.Title = '-' then
        Item.SubItems.Add('')
      else
        Item.SubItems.Add(S.Title);
      Item.SubItems.Add(S.Speaker);
      Item.Data := Pointer(NativeInt(I));
    end;
  finally
    AList.Items.EndUpdate;
  end;
end;

procedure TFormMain.RefreshClock;
var
  T: TDateTime;
begin
  T := CurrentNow;
  FCurrent[False] := CurrentSessionIndex(FAgenda, 'Kirk', T);
  FCurrent[True] := CurrentSessionIndex(FAgenda, 'Spock', T);
  if FSimulated then
    StatusBar.Panels[1].Text := 'Ora simulata: ' + FormatDateTime('dd/mm/yyyy hh:nn', T)
  else
    StatusBar.Panels[1].Text := '';
  ListKirk.Invalidate;
  ListSpock.Invalidate;
end;

procedure TFormMain.TimerRefreshTimer(Sender: TObject);
begin
  RefreshClock;
end;

procedure TFormMain.StyleItem(AList: TCustomListView; AItem: TListItem);
var
  Index: Integer;
begin
  Index := NativeInt(AItem.Data);
  if Index = FCurrent[AList = ListSpock] then
  begin
    AList.Canvas.Brush.Color := Accent;
    AList.Canvas.Font.Color := clWhite;
    AList.Canvas.Font.Style := [fsBold];
    Exit;
  end;
  AList.Canvas.Font.Color := StyleServices.GetSystemColor(clWindowText);
  case FAgenda[Index].Kind of
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
  Dialog: TTaskDialog;
begin
  Dialog := TTaskDialog.Create(Self);
  try
    Dialog.Caption := 'Informazioni su CoffeeBreak';
    Dialog.Title := 'CoffeeBreak ' + FVersion;
    Dialog.Text := 'L''agenda di ITDevCon 2026, sala per sala.' + sLineBreak + sLineBreak +
      'Questa app non contiene codice di aggiornamento: installazione e aggiornamenti passano da WinGet.';
    Dialog.Flags := [tfEnableHyperlinks, tfAllowDialogCancellation];
    Dialog.CommonButtons := [tcbOk];
    Dialog.FooterIcon := tdiInformation;
    Dialog.FooterText := '<a href="' + RepoUrl + '">' + RepoUrl + '</a>';
    Dialog.OnHyperlinkClicked := AboutHyperlinkClicked;
    Dialog.Execute;
  finally
    Dialog.Free;
  end;
end;

procedure TFormMain.AboutHyperlinkClicked(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(TTaskDialog(Sender).URL), nil, nil, SW_SHOWNORMAL);
end;

procedure TFormMain.TimerScreenshotTimer(Sender: TObject);
begin
  TimerScreenshot.Enabled := False;
  SaveScreenshot(FScreenshotPath);
  Application.Terminate;
end;

// copia dallo schermo: PrintWindow non disegna i TGraphicControl (TLabel, TSpeedButton) dentro i pannelli
procedure TFormMain.SaveScreenshot(const AFileName: string);
var
  Bounds: TRect;
  Bitmap: TBitmap;
  ScreenDC: HDC;
  Png: TPngImage;
begin
  SetForegroundWindow(Handle);
  Repaint;
  DwmFlush;
  // i bordi estesi escludono la cornice invisibile di DWM
  if DwmGetWindowAttribute(Handle, DWMWA_EXTENDED_FRAME_BOUNDS, @Bounds, SizeOf(Bounds)) <> S_OK then
    GetWindowRect(Handle, Bounds);
  Bitmap := TBitmap.Create(Bounds.Width, Bounds.Height);
  Png := TPngImage.Create;
  try
    ScreenDC := GetDC(0);
    try
      BitBlt(Bitmap.Canvas.Handle, 0, 0, Bounds.Width, Bounds.Height, ScreenDC, Bounds.Left, Bounds.Top, SRCCOPY);
    finally
      ReleaseDC(0, ScreenDC);
    end;
    Png.Assign(Bitmap);
    Png.SaveToFile(AFileName);
  finally
    Png.Free;
    Bitmap.Free;
  end;
end;

end.
