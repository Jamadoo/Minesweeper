unit Minesweeper;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, System.Generics.Collections, System.Math,
  Vcl.StdCtrls, pngimage;

type
  TForm1 = class(TForm)
    procedure FormActivate(Sender: TObject);
    procedure BlockClick(Sender: TObject);
    procedure ShowBlock(BlockIndex : integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    BlockSize : integer;
    MineChance : double;
    BlockAmount : integer;
    Digging : boolean;
    Grid : TList<TPanel>;
    CIndex : integer;
    GameInProgress : boolean;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// Functions
function Clamp(Number : integer): integer;
begin
     // Clamp To Grid
     if (Number < 0) or (Number > Form1.Grid.Count - 1) then
     begin
       Result := Form1.CIndex;
     end
     else
     begin
       Result := Number;
     end;
end;
function GetBlockNumber(Index : integer; Block : TPanel): integer;
begin
     var MineCount := 0;
     var BlockAmount := Form1.BlockAmount;
     var Grid := Form1.Grid;
     // Get Blocks
     var SurrBlocks := TList<TPanel>.Create();
     Form1.CIndex := Index;
     SurrBlocks.AddRange([Grid[Clamp(Index - 1)], Grid[Clamp(Index + 1)],
            Grid[Clamp(Index + BlockAmount)], Grid[Clamp(Index - BlockAmount)],
            Grid[Clamp(Index + BlockAmount + 1)], Grid[Clamp(Index - BlockAmount + 1)],
            Grid[Clamp(Index + BlockAmount - 1)], Grid[Clamp(Index - BlockAmount - 1)]]);
     // Check Blocks
     for var CBlock in SurrBlocks do
     begin
          if (CBlock.Tag = 1) and (Abs(CBlock.Top - Block.Top) <= Form1.BlockSize) and (Abs(CBlock.Left - Block.Left) <= Form1.BlockSize) then
          begin
            MineCount := MineCount + 1;
          end;
     end;

     Result := MineCount;
end;

// Procedures
procedure ShowSurrBlocks(Index : integer);
begin
      // Vars
     var BlockAmount := Form1.BlockAmount;
     var Grid := Form1.Grid;
     var Block := Grid[Index];
     // Get Surr Blocks
     var SurrBlocks := TList<integer>.Create();
     Form1.CIndex := Index;
     SurrBlocks.AddRange([Clamp(Index - 1), Clamp(Index + 1),
            Clamp(Index + BlockAmount), Clamp(Index - BlockAmount),
            Clamp(Index + BlockAmount + 1), Clamp(Index - BlockAmount + 1),
            Clamp(Index + BlockAmount - 1), Clamp(Index - BlockAmount - 1)]);
     // Show Blocks
     for var SBIndex in SurrBlocks do
     begin
          var SBlock := Grid[SBIndex];
          if (SBlock.Tag = 0) and (Abs(SBlock.Top - Block.Top) <= Form1.BlockSize) and (Abs(SBlock.Left - Block.Left) <= Form1.BlockSize) then
          begin
            // Show
            Form1.ShowBlock(SBIndex);
          end;
     end;
end;
procedure TForm1.ShowBlock(BlockIndex : integer);
begin
    var Block := Form1.Grid[BlockIndex];
    var BlockNumber := GetBlockNumber(BlockIndex, Block);
    Block.Tag := 2;
    Block.Color := clWhite;
    if BlockNumber = 0 then
    begin
         Block.Caption := '';
         ShowSurrBlocks(BlockIndex);
    end
    else
    begin
        Block.Caption := BlockNumber.ToString();
    end;
    for var i := 0 to Block.ControlCount - 1 do
    begin
      FreeAndNil(Block.Controls[i]);
    end;
end;
procedure RestartGame();
begin
    var Top := Form1.Top;
    var Left := Form1.Left;
    FreeAndNil(Form1);
    Form1 := TForm1.Create(Application.Owner);
    Form1.Top := Top;
    Form1.Left := Left;
    Form1.Show();
end;
procedure GameOver();
begin
    // Show Mines
    for var Block in Form1.Grid do
    begin
        if Block.Tag = 1 then
        begin
             Block.Color := clRed;
        end;
    end;
    ShowMessage('Game Over');
    // Restart
    RestartGame();
end;
procedure CheckForWin();
begin
    // Check Won
    var Won := true;
    for var Block in Form1.Grid do
    begin
         // Check if Mines Correct
         if (Block.Tag = 1) and (Block.ControlCount = 0) then
         begin
           Won := false;
         end;
         // Check Normal
         if Block.Tag = 0 then
         begin
           Won := false;
         end;
    end;
    // Reward
    if Won then
    begin
        for var Block in Form1.Grid do
        begin
            if Block.Tag = 1 then
            begin
                 Block.Color := clGreen;
            end;
        end;
        ShowMessage('You Won!');
        RestartGame();
    end;
end;

// Events
procedure TForm1.BlockClick(Sender: TObject);
begin
      // Check Game Status
      if not GameInProgress then
      begin
        exit;
      end;
      // Get Block
      var Block := TPanel(Sender);
      // Check If Not Already Clicked
      if Block.Tag = 2 then
      begin
        exit;
      end;
      // Get Index
      var BlockIndex := -1;
      for var GBlock in Grid do
      begin
          BlockIndex := BlockIndex + 1;
          if GBlock = Block then
          begin
               break;
          end;
      end;
      // Check If Digging
      if (Digging) and (Block.ControlCount = 0) then
      begin
          // Check For Mine
          if (Block.Tag = 1) then
          begin
            GameOver();
            exit;
          end;
          if (Block.Tag = 0) then
          begin
              // Show Block
              ShowBlock(BlockIndex);
          end;
      end
      else if not Digging then
      begin
          if Block.ControlCount = 0 then
          begin
              var Image := TImage.Create(Self);
              Image.Picture.LoadFromFile('D:\Saves\Delphi Saves\Minesweeper\Images\Flag.png');
              Image.Stretch := true;
              Image.Parent := Block;
              Image.Align := TAlign.alClient;
              Image.Transparent := true;
              Image.Enabled := false;
          end
          else
          begin
              for var i := 0 to Block.ControlCount - 1 do
              begin
                FreeAndNil(Block.Controls[i]);
              end;
          end;
      end;
      CheckForWin();
end;
procedure TForm1.FormActivate(Sender: TObject);
begin
     // Vars
     Screen.Cursor := crDefault;
     Grid := TList<TPanel>.Create();
     BlockSize := 60;
     MineChance := 0.15;
     BlockAmount := 8;
     GameInProgress := true;
     Digging := true;
     var FormSize := BlockAmount * BlockSize;
     // Set Form Size
     Form1.Width := FormSize;
     Form1.Height := FormSize;
     Form1.ClientHeight := FormSize;
     Form1.ClientWidth := FormSize;
     // Create Grid
     for var Width := 0 to BlockAmount - 1 do
     begin
          for var Height := 0 to BlockAmount - 1 do
          begin
              var Block := TPanel.Create(Self);
              Block.Width := BlockSize;
              Block.Height := BlockSize;
              Block.Left := Width * BlockSize;
              Block.Top := Height * BlockSize;
              Block.Parent := Form1;
              Block.ParentColor := false;
              Block.ParentBackground := false;
              Block.OnClick := BlockClick;
              Block.Color := $00DBDBDB;
              Block.Tag := 0;
              Grid.Add(Block);
          end;
     end;
     // Set Mines
     var MineAmount := Round(Grid.Count * MineChance);
     for var MineN := 1 to MineAmount do
     begin
          var FoundBlock := true;
          var ChosenIndex := 0;
          repeat
               FoundBlock := true;
               ChosenIndex := Random(Grid.Count);
               if Grid[ChosenIndex].Tag = 1 then
               begin
                 FoundBlock := false;
               end;
          until (FoundBlock);
          var ChosenBlock := Grid[ChosenIndex];
          ChosenBlock.Tag := 1;
          ChosenBlock.ParentColor := false;
          ChosenBlock.ParentBackground := false;
     end;
end;
procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
     if Key = 't' then
     begin
       Digging := not Digging;
       if Digging then
       begin
          Screen.Cursor := crDefault;
       end
       else
       begin
          Screen.Cursor := crHandPoint;
       end;
     end;
end;

end.
