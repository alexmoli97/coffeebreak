object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'CoffeeBreak'
  ClientHeight = 720
  ClientWidth = 1180
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 900
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu
  Position = poScreenCenter
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 20
  object PanelHeader: TPanel
    Left = 0
    Top = 0
    Width = 1180
    Height = 100
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      1180
      100)
    object LabelTitle: TLabel
      Left = 24
      Top = 14
      Width = 300
      Height = 41
      Caption = 'ITDevCon 2026'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -30
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object LabelSubtitle: TLabel
      Left = 26
      Top = 60
      Width = 300
      Height = 20
      Caption = 'Agenda'
    end
    object ButtonDay19: TSpeedButton
      Left = 740
      Top = 30
      Width = 200
      Height = 40
      Anchors = [akTop, akRight]
      GroupIndex = 1
      Down = True
      Caption = '19'
      OnClick = DayButtonClick
    end
    object ButtonDay20: TSpeedButton
      Tag = 1
      Left = 948
      Top = 30
      Width = 200
      Height = 40
      Anchors = [akTop, akRight]
      GroupIndex = 1
      Caption = '20'
      OnClick = DayButtonClick
    end
  end
  object PanelBreak: TPanel
    Left = 0
    Top = 100
    Width = 1180
    Height = 84
    Margins.Left = 16
    Margins.Top = 0
    Margins.Right = 16
    Margins.Bottom = 12
    Align = alTop
    AlignWithMargins = True
    BevelOuter = bvNone
    Color = 3046112
    ParentBackground = False
    StyleElements = []
    TabOrder = 3
    object LabelBreak: TLabel
      Left = 0
      Top = 0
      Width = 1148
      Height = 84
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Caption = 'Coffee break'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -35
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      StyleElements = []
    end
  end
  object PanelKirk: TPanel
    Left = 0
    Top = 196
    Width = 590
    Height = 597
    Align = alLeft
    BevelOuter = bvNone
    Padding.Left = 16
    Padding.Right = 8
    Padding.Bottom = 12
    TabOrder = 1
    object LabelKirk: TLabel
      Left = 16
      Top = 0
      Width = 566
      Height = 36
      Align = alTop
      AutoSize = False
      Caption = 'Sala Kirk'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object ListKirk: TListView
      Left = 16
      Top = 36
      Width = 566
      Height = 549
      Align = alClient
      Columns = <
        item
          Caption = 'Ora'
          Width = 120
        end
        item
          AutoSize = True
          Caption = 'Titolo'
        end
        item
          Caption = 'Speaker'
          Width = 170
        end>
      ReadOnly = True
      RowSelect = True
      SmallImages = ImageListRowHeight
      TabOrder = 0
      ViewStyle = vsReport
      OnCustomDrawItem = ListCustomDrawItem
      OnCustomDrawSubItem = ListCustomDrawSubItem
    end
  end
  object PanelSpock: TPanel
    Left = 590
    Top = 196
    Width = 590
    Height = 597
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Right = 16
    Padding.Bottom = 12
    TabOrder = 2
    object LabelSpock: TLabel
      Left = 8
      Top = 0
      Width = 566
      Height = 36
      Align = alTop
      AutoSize = False
      Caption = 'Sala Spock'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object ListSpock: TListView
      Left = 8
      Top = 36
      Width = 566
      Height = 549
      Align = alClient
      Columns = <
        item
          Caption = 'Ora'
          Width = 120
        end
        item
          AutoSize = True
          Caption = 'Titolo'
        end
        item
          Caption = 'Speaker'
          Width = 170
        end>
      ReadOnly = True
      RowSelect = True
      SmallImages = ImageListRowHeight
      TabOrder = 0
      ViewStyle = vsReport
      OnCustomDrawItem = ListCustomDrawItem
      OnCustomDrawSubItem = ListCustomDrawSubItem
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 697
    Width = 1180
    Height = 23
    Panels = <
      item
        Width = 220
      end
      item
        Width = 50
      end>
  end
  object MainMenu: TMainMenu
    Left = 400
    Top = 24
    object MenuHelp: TMenuItem
      Caption = '&?'
      object MenuAbout: TMenuItem
        Caption = '&Informazioni su CoffeeBreak...'
        OnClick = MenuAboutClick
      end
    end
  end
  object ImageListRowHeight: TImageList
    Height = 34
    Width = 1
    Left = 480
    Top = 24
  end
  object TimerRefresh: TTimer
    Interval = 30000
    OnTimer = TimerRefreshTimer
    Left = 560
    Top = 24
  end
  object TimerScreenshot: TTimer
    Enabled = False
    Interval = 800
    OnTimer = TimerScreenshotTimer
    Left = 640
    Top = 24
  end
end
