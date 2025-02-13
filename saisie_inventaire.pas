unit Saisie_Inventaire;

{$mode objfpc}{$H+}

interface

uses
Classes, SysUtils, IBConnection, sqldb, odbcconn, db, csvdataset, SdfData,
Forms, Controls, Graphics, Dialogs, DBGrids, DBCtrls, StdCtrls, ComCtrls,
ExtCtrls, Grids, MMSystem;

type

{ TForm1 }

TForm1 = class(TForm)
  Button1: TButton;
  Button_Importer: TButton;
  cbCategorie: TComboBox;
  cbUA: TComboBox;
  CSVDataset1: TCSVDataset;
  DataSource1: TDataSource;
  DataSource2: TDataSource;
  eCoteInferieure: TEdit;
  eCoteSuperieure: TEdit;
  eCoteDebutantPar: TEdit;
  eCodeExemplaireSaisi: TEdit;
  GroupBox1: TGroupBox;
  IBConnection1: TIBConnection;
  Label1: TLabel;
  Label10: TLabel;
  Label11: TLabel;
  Label12: TLabel;
  Label_Fichier_CSV: TLabel;
  lProgressionInventaire: TLabel;
  lTitre: TLabel;
  Label2: TLabel;
  Label3: TLabel;
  Label4: TLabel;
  Label5: TLabel;
  Label6: TLabel;
  Label7: TLabel;
  Label8: TLabel;
  Label9: TLabel;
  lAuteur: TLabel;
  mRemarques: TMemo;
  OpenDialog1: TOpenDialog;
  PageControl1: TPageControl;
  Panel1: TPanel;
  pbProgressionInventaire: TProgressBar;
  SQLSelect: TSQLQuery;
  SQLUpdate: TSQLQuery;
  SQLTransaction1: TSQLTransaction;
  StringGrid1: TStringGrid;
  TabSheet1: TTabSheet;
  TabSheet2: TTabSheet;
  TabSheet3: TTabSheet;
  procedure Button1Click(Sender: TObject);
  procedure Button_ImporterClick(Sender: TObject);
  procedure eCodeExemplaireSaisiKeyPress(Sender: TObject; var Key: char);
  procedure eCoteDebutantParKeyPress(Sender: TObject; var Key: char);
  procedure eCoteInferieureKeyPress(Sender: TObject; var Key: char);
  procedure eCoteSuperieureKeyPress(Sender: TObject; var Key: char);
  procedure FormActivate(Sender: TObject);
  procedure PageControl1Change(Sender: TObject);
  procedure TabSheet2Show(Sender: TObject);
private
public

end;

var
Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

//PROCÉDURE QUI ÉMET UN SON EN CAS DE PROBLÈME
procedure SonErreur(sErreur : string);
var sChemin : string;
begin
  sChemin := 'c:\inventaire\' + sErreur + '.wav';
  sndPlaySound(pchar(sChemin), snd_Async or snd_NoDefault);
end;

// PROCÉDURE QUI AJOUTE UNE LIGNE DANS UN FICHIER TEXTE
procedure AjouterLigneAuFichier(sLigne : string);
  Var fichier : text;
  Var sNomFichier :string;
begin
  //  Format ('Today is: %s',[DateToStr(Date)])
  sNomFichier := 'c:/inventaire/Inventaire.txt';
  Assign (fichier,sNomFichier);
  Append(fichier); //le fichier est ouvert pour ajout
  Writeln (fichier,sLigne);
  close (fichier);
end;

// PROCÉDURE QUI MET À JOUR LA PROGRESSION DE L'INVENTAIRE
procedure MiseAJourProgression;
var iMax, iPosition : integer;
begin
  //iPosition = Nombre d'exemplaires déjà inventoriés
  Form1.SQLSelect.Active := False;
  Form1.SQLSelect.SQL.Clear;
  Form1.SQLSelect.SQL.Add('select COUNT(ID_EXEMPLAIRE) C from EXEMPLAIRES WHERE DATEINVENTAIRE IS NOT NULL;');
  Form1.SQLSelect.Active := True;
  iPosition := Form1.SQLSelect.FieldByName('C').AsInteger ;

  //iMax = Nombre d'exemplaires total à inventorier
  Form1.SQLSelect.Active := False;
  Form1.SQLSelect.SQL.Clear;
  Form1.SQLSelect.SQL.Add('select COUNT(ID_EXEMPLAIRE) C from EXEMPLAIRES;');
  Form1.SQLSelect.Active := True;
  iMax := Form1.SQLSelect.FieldByName('C').AsInteger ;

  with Form1.pbProgressionInventaire do
  begin
    Min := 0;
    Max := iMax;
    Position := iPosition;
  end;
  Form1.lProgressionInventaire.Caption := 'Progression globale : '+ inttostr(iPosition) + ' exemplaires inventoriés sur ' + inttostr(iMax);
end;

// PROCÉDURE QUI INVENTORIE L'EXEMPLAIRE ET SIGNALANT UN ÉVENTUEL PROBLÈME
procedure Inventorier(sCodeExemplaire : String);
var
sCategorie, sUA, sTitre, sAuteur, sRemarques, sRemarque, sStatut, sCote : String;
begin
Form1.SQLSelect.Active := False;
Form1.SQLSelect.SQL.Clear;  
Form1.mRemarques.Lines.Clear;
sRemarques := '';
Form1.SQLSelect.SQL.Add('select  N.CATEGORIE, N.UA, N.TITRE, N.AUTEUR, N.COTE, E.STATUT, E.DATEINVENTAIRE from notices N JOIN EXEMPLAIRES E ON N.ID_NOTICE = E.ID_NOTICE where E.ID_EXEMPLAIRE = '''+sCodeExemplaire+''';');
Form1.SQLSelect.Active := True;
if Form1.SQLSelect.EOF then
begin
  // Dans le cas où le code exemplaire n'est pas trouvé dans la base de donnée
  sTitre := '.............';
  sAuteur := '.............';
  sRemarque := 'CODE NON TROUVÉ';
  Form1.mRemarques.Lines.Add(sRemarque);
  sRemarques := sRemarques + sRemarque;
  SonErreur('Code_non_trouve');
end
else
begin
  // Dans le cas où le code exemplaire a été trouvé
  sTitre := Form1.SQLSelect.FieldByName('TITRE').AsString;
  sAuteur := Form1.SQLSelect.FieldByName('AUTEUR').AsString;

  // TEST DE LA CATÉGORIE DE LA NOTICE
  if Form1.SQLSelect.FieldByName('CATEGORIE').IsNull then
  begin
    // Cas où la catégorie de la notice n'est pas définie
    sRemarque := 'CATÉGORIE NON DÉFINIE';
    Form1.mRemarques.Lines.Add(sRemarque);
    sRemarques := sRemarques + ' * ' + sRemarque;
    SonErreur('Categorie_non_definie');
  end
  else
  begin
    // Cas où la catégorie de la notice est définie
    // Il faut comparer cette catégorie avec celle choisie dans les options
    sCategorie := Form1.SQLSelect.FieldByName('CATEGORIE').AsString;
    if sCategorie <> Form1.cbCategorie.Text then
    begin
      // Cas où la catégorie de la notice est différente de celle des options
      sRemarque := 'Catégorie=«'+ sCategorie + '»';
      Form1.mRemarques.Lines.Add(sRemarque);
      sRemarques := sRemarques + ' * ' + sRemarque;
      SonErreur('Mauvaise_categorie');
    end;
  end;

  // TEST DE L'UNITÉ ADMINISTRATIVE DE LA NOTICE
  if Form1.SQLSelect.FieldByName('UA').IsNull then
  begin
    // Cas où l'Unité Administrative de la notice n'est pas définie
    sRemarque := 'Unité administrative NON DÉFINIE';
    Form1.mRemarques.Lines.Add(sRemarque);
    sRemarques := sRemarques + ' * ' + sRemarque;
    SonErreur('UA_non_definie');
  end
  else
  begin
    // Cas où l'Unité Administrative de la notice est définie
    // Il faut comparer cette UA avec celle choisie dans les options
    sUA := Form1.SQLSelect.FieldByName('UA').AsString;
    if sUA <> Form1.cbUA.Text then
    begin
      // Cas où l'Unité Administrative de la notice est différente de celle des options
      sRemarque := 'UA=«'+ sUA + '»';
      Form1.mRemarques.Lines.Add(sRemarque);
      sRemarques := sRemarques + ' * ' + sRemarque;
      SonErreur('Mauvaise_UA');
    end;
  end;

  // TEST DE LA COTE DE CLASSIFICATION
  if Form1.SQLSelect.FieldByName('COTE').IsNull then
  begin
    // Cas où la cote de classification de la notice n'est pas définie
    sRemarque := 'Cote NON DÉFINIE';
    Form1.mRemarques.Lines.Add(sRemarque);
    sRemarques := sRemarques + ' * ' + sRemarque;
    SonErreur('COTE_non_definie');
  end
  else
  begin
    // Cas où la cote de classification de la notice est définie
    // Il faut comparer cette cote avec celle choisie dans les options
    sCote := Form1.SQLSelect.FieldByName('COTE').AsString;
    if pos(Form1.eCoteDebutantPar.Text, sCote) <> 1 then
    begin
      // Cas où la cote de la notice ne commence pas par la valeur du champ «eCoteDebutantPar»
      if (sCote < Form1.eCoteInferieure.Text) or (sCote > Form1.eCoteSuperieure.Text) then
      begin
        // Cas où la cote de la notice est PLUS PETITE que la cote inférieur attendue 
        // ou bien PLUS GRANDE que la cote supérieure attendue
        sRemarque := 'Cote=«'+ sCote + '»';
        Form1.mRemarques.Lines.Add(sRemarque);
        sRemarques := sRemarques + ' * ' + sRemarque;
        SonErreur('Mauvaise_COTE');
      end;
    end;
  end;

  // TEST DU STATUT DE L'EXEMPLAIRE
  if not Form1.SQLSelect.FieldByName('STATUT').IsNull then
  begin
    // Cas où le statut est défini :
    // L'exemplaire est supposé être prêté ou perdu
    if Form1.SQLSelect.FieldByName('STATUT').AsString > '0' then
    begin
      sRemarque := 'PRÊTÉ ou PERDU';
      Form1.mRemarques.Lines.Add(sRemarque);
      sRemarques := sRemarques + ' * ' + sRemarque;
      SonErreur('Prete_ou_perdu');
    end;
  end;

  //ON VÉRIFIE SI L'EXEMPLAIRE N'A PAS ÉTÉ DÉJÀ INVENTORIÉ
  if not Form1.SQLSelect.FieldByName('DATEINVENTAIRE').IsNull then
  begin
    // Cas où l'exemplaire à déjà été inventorié
    sRemarque := 'DÉJÀ INVENTORIÉ';
    Form1.mRemarques.Lines.Add(sRemarque);
    sRemarques := sRemarques + ' * ' + sRemarque;
    SonErreur('Deja_inventorie');
  end
  else
  begin
    Form1.SQLSelect.Active := False;
    Form1.SQLUpdate.Active := False;
    Form1.SQLUpdate.SQL.Clear;
    Form1.SQLUpdate.SQL.Text:= 'UPDATE EXEMPLAIRES SET DATEINVENTAIRE = :dDATEINVENTAIRE, REMARQUE = :sREMARQUE where ID_EXEMPLAIRE = '''+sCodeExemplaire+''';';
    Form1.SQLUpdate.ParamByName('dDATEINVENTAIRE').AsDate:=Date;
    Form1.SQLUpdate.ParamByName('sREMARQUE').AsString := AnsiToUTF8(trim(leftstr(sRemarques, 250)));
    Form1.SQLUpdate.ExecSQL;
    Form1.SQLTransaction1.Commit;
    //AJOUT DU CODE BARRE SAISIE À UN FICHIER TEXTE À LA DATE DU JOUR
    AjouterLigneAuFichier(sCodeExemplaire);
  end;

  if sRemarques = '' then
  begin
    sRemarques := 'RAS';
    Form1.mRemarques.Lines.Add(sRemarques);
  end;
end;

if sRemarques = 'RAS' then Beep;// else sndPlaySound(pchar('C:\inventaire\tuxok.wav'), snd_Async or snd_NoDefault); ;
Form1.lTitre.Caption := sTitre;
Form1.lAuteur.Caption := sAuteur;
end;
//FIN DE LA PROCÉDURE «INVENTORIER»

procedure TForm1.FormActivate(Sender: TObject);
var
sCategorie : String;
begin                       
SQLSelect.Active := False;
SQLSelect.SQL.Text := 'select distinct categorie from notices where categorie is not null';
SQLSelect.Active := True;
cbCategorie.Items.Clear;
while not SQLSelect.EOF do
begin
  sCategorie := SQLSelect.FieldValues['CATEGORIE'];
  cbCategorie.Items.Add(sCategorie);
  cbCategorie.Text := sCategorie;
  SQLSelect.Next;
end;
SQLSelect.Active := False;
SQLSelect.SQL.Text := 'select distinct ua from notices where ua is not null';
SQLSelect.Active := True;
cbUA.Items.Clear;
while not SQLSelect.EOF do
begin
  sCategorie := SQLSelect.FieldValues['UA'];
  cbUA.Items.Add(sCategorie);
  cbUA.Text := sCategorie;
  SQLSelect.Next;
end;
SQLSelect.Active := False;
MiseAJourProgression;
Form1.Left := (Screen.Width - Form1.Width) div 2;
Form1.Top := (Screen.Height - Form1.Height) div 2;
PageControl1.ActivePage := TabSheet2;
eCodeExemplaireSaisi.SetFocus;
end;

procedure TForm1.PageControl1Change(Sender: TObject);
begin
  if PageControl1.TabIndex = 0 then
    eCoteInferieure.SetFocus
  else if PageControl1.TabIndex = 1 then
    eCodeExemplaireSaisi.SetFocus;
end;

procedure TForm1.TabSheet2Show(Sender: TObject);
begin
  eCodeExemplaireSaisi.SetFocus;
end;



procedure TForm1.eCodeExemplaireSaisiKeyPress(Sender: TObject; var Key: char);
begin
if Key = #13 then
Begin
  // La touche retour est entrée, on va inventorier l'exemplaire si ce n'est pas déjà fait
  Inventorier(eCodeExemplaireSaisi.Text);
  MiseAJourProgression;
end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var i, j, Temp, Longest : integer;
begin
  if OpenDialog1.Execute then
  begin
    CSVDataset1.Active:= False;
    CSVDataset1.FileName := OpenDialog1.FileName;
    Label_Fichier_CSV.Caption := OpenDialog1.FileName;
    StringGrid1.LoadFromCSVFile(CSVDataset1.FileName);
    //CSVDataset1.Active := True;
    Button_Importer.Visible := True;
  end;
end;

procedure TForm1.Button_ImporterClick(Sender: TObject);
var i, j, Temp, Longest, iNbCol, iCol, iRow : integer;
    tsListeTables : TStringlist;
    sNomTable : String;
begin         
    Button_Importer.Visible := False;

    // Création d'une nouvelle table avec le même nombre de colonnes
    // que le fichier CVS sélectionné,via StringGrid1
    iNbCol := StringGrid1.colcount; // Liste des tables dans la base de données
    try
      tsListeTables := TStringlist.Create;
      IBConnection1.GetTableNames(tsListeTables, False);
      tsListeTables.Sorted:= True;
      tsListeTables.Sort;
      i := 1;
      sNomTable := 'Import' + IntToStr(i);
      // Parcours des noms de tables Import1, Import2, ...
      while tsListeTables.Find(sNomTable, j) do
      begin
        i := i + 1;
        sNomTable := 'Import' + IntToStr(i);
      end;
      // sNomTable devrait être 'Importi' avec i le plus petit entier tel que Importi ne soit pas déjà dans la BD
      Form1.SQLSelect.Active := False;
      Form1.SQLUpdate.Active := False;
      Form1.SQLUpdate.SQL.Clear;
      Form1.SQLUpdate.SQL.Text:= 'create table ' + sNomTable + ' (DataCol1 char(250)';
      for i := 2 to iNbCol do
      begin
        Form1.SQLUpdate.SQL.Text := Form1.SQLUpdate.SQL.Text +  ', DataCol'+IntToStr(i) + ' char(250)'
      end;
      Form1.SQLUpdate.SQL.Text := Form1.SQLUpdate.SQL.Text + ')';
      Form1.SQLUpdate.ExecSQL;
      Form1.SQLTransaction1.Commit;
    finally
      tsListeTables.Destroy;
    end;

    // Insertion des données dans la table créée à partir de StringGrid1
    for iRow := 0 to StringGrid1.RowCount - 1  do
    begin
      Form1.SQLUpdate.Active := False;
      Form1.SQLUpdate.SQL.Clear;
      Form1.SQLUpdate.SQL.Text := 'INSERT INTO ' + sNomTable + ' VALUES (:dDataCol0';
      for iCol := 1 to StringGrid1.ColCount - 1  do
      begin
        Form1.SQLUpdate.SQL.Text := Form1.SQLUpdate.SQL.Text + ', :dDataCol' + IntToStr(iCol);
      end;
      Form1.SQLUpdate.SQL.Text := Form1.SQLUpdate.SQL.Text + ')';
      Form1.SQLUpdate.Prepare;
      for iCol := 0 to StringGrid1.ColCount - 1  do
      begin
        Form1.SQLUpdate.ParamByName('dDataCol'+IntToStr(iCol)).AsString := AnsiToUTF8(trim(leftstr(StringGrid1.Cells[iCol, iRow], 250)));
      end;
      Form1.SQLUpdate.ExecSQL;
      Form1.SQLTransaction1.Commit;
    end;
end;

procedure TForm1.eCoteDebutantParKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  Begin
    PageControl1.TabIndex := 1;
    eCodeExemplaireSaisi.SetFocus;
  end;
end;

procedure TForm1.eCoteInferieureKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  Begin
    PageControl1.TabIndex := 1;
    eCodeExemplaireSaisi.SetFocus;
  end;
end;


procedure TForm1.eCoteSuperieureKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  Begin
    PageControl1.TabIndex := 1;
    eCodeExemplaireSaisi.SetFocus;
  end;
end;

end.

