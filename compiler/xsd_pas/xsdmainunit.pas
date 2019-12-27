unit XSDMainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, DOM, EditBtn,
  ComCtrls, XsdElementTypesUnit, SynEdit, SynHighlighterPas, RxIniPropStorage;

type

  { TXSDMainForm }

  TXSDMainForm = class(TForm)
    Button1: TButton;
    FileNameEdit1: TFileNameEdit;
    Label1: TLabel;
    Memo1: TMemo;
    PageControl1: TPageControl;
    RxIniPropStorage1: TRxIniPropStorage;
    SynEdit1: TSynEdit;
    SynFreePascalSyn1: TSynFreePascalSyn;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure Button1Click(Sender: TObject);
  private
    FXSDModule:TXSDModule;
    procedure DumpSchema(ANode:TDOMNode);
    procedure ProcessElement(ANode:TDOMNode);
    procedure ProcessComplexElement(ANode, AContext:TDOMNode; AComplexType: TXSDComplexType);
    function GetAnnotation(AContext:TDOMNode):string;

    procedure DoMakePas;
  public
    procedure WriteLog(S:string);
  end;

var
  XSDMainForm: TXSDMainForm;

implementation
uses XMLRead, xmliconv, XsdPasCodegenUnit, LazFileUtils;

{$R *.lfm}

function IsSimpleType(ATypeName:string):Boolean;
begin
  Result:=
    (ATypeName = 'xs:string') or
    (ATypeName = 'xs:decimal') or
    (ATypeName = 'xs:integer') or
    (ATypeName = 'xs:boolean') or
    (ATypeName = 'xs:date') or
    (ATypeName = 'xs:time');
end;

{ TXSDMainForm }

procedure TXSDMainForm.Button1Click(Sender: TObject);
var
  FDoc: TXMLDocument;
  S: String;
  i: Integer;
begin
  FXSDModule:=TXSDModule.Create;
  Memo1.Lines.Clear;
  ReadXMLFile(FDoc, FileNameEdit1.FileName);
  if Assigned(FDoc) then
  begin
    for i:=0 to FDoc.ChildNodes.Count-1 do
    begin
      S:=FDoc.ChildNodes[i].NodeName;
      WriteLog(S);
      if S = 'xs:schema' then
        DumpSchema(FDoc.ChildNodes[i]);
    end;
    FDoc.Free;
  end;
  DoMakePas;
  FXSDModule.Free;
end;

procedure TXSDMainForm.DumpSchema(ANode: TDOMNode);
var
  i, j: Integer;
  S: String;
  R, N: TDOMNode;
begin
  if not Assigned(ANode) then Exit;
  for i:=0 to ANode.ChildNodes.Count - 1 do
  begin
    N:=ANode.ChildNodes[i];
    S:=N.NodeName;
    WriteLog(S);
    if (S = 'xs:element')  then
      ProcessElement(N)
    else
    if (S = 'xs:complexType') then
    begin
      R:=N.Attributes.GetNamedItem('name');
        WriteLog(R.NodeName +':'+ R.NodeValue);
      ProcessComplexElement( R, R, FXSDModule.ComplexTypes.Add(R.NodeValue));
    end;
  end;
end;

procedure TXSDMainForm.ProcessElement(ANode: TDOMNode);
var
  R, RName: TDOMNode;
  FComplexType: TXSDComplexType;
begin
  RName:=ANode.Attributes.GetNamedItem('name');
  if Assigned(RName) then
    WriteLog(RName.NodeName +':'+ RName.NodeValue);

  R:=ANode.Attributes.GetNamedItem('type');
  if Assigned(R) then
    WriteLog(R.NodeName +':'+ R.NodeValue)
  else
  begin
    R:=ANode.FindNode('xs:complexType');
    if Assigned(R) then
    begin
      FComplexType:=FXSDModule.ComplexTypes.Add(RName.NodeValue);
      ProcessComplexElement(ANode, R, FComplexType)
    end;
  end;
end;

procedure TXSDMainForm.ProcessComplexElement(ANode, AContext: TDOMNode;
  AComplexType: TXSDComplexType);
var
  RAll, FA, R: TDOMNode;
  i: Integer;
  S, S1: DOMString;
  Prop: TPropertyItem;
begin
  WriteLog('Process object : ' + ANode.NodeValue);
  WriteLog('Process atrubutes : ' + ANode.NodeValue);
  AComplexType.Description:=GetAnnotation(AContext);

  for i:=0 to AContext.ChildNodes.Count-1 do
  begin
    FA:=AContext.ChildNodes[i];
    S:=FA.NodeName;
    if S = 'xs:attribute' then
    begin
      Prop:=AComplexType.Propertys.Add(pitAttribute);
      S1:=FA.Attributes.GetNamedItem('name').NodeValue;
      Prop.Name:=S1;
      Prop.Description:=GetAnnotation(FA);
      R:=FA.Attributes.GetNamedItem('type');
      if Assigned(R) then
        Prop.BaseType:=R.NodeValue;
    end
  end;


  RAll:=AContext.FindNode('xs:sequence');
  if not Assigned(RAll) then
    RAll:=AContext.FindNode('xs:all');

  for i:=0 to RAll.ChildNodes.Count-1 do
  begin
    FA:=RAll.ChildNodes[i];
    S:=FA.NodeName;
    if S = 'xs:element' then
    begin
      S1:=FA.Attributes.GetNamedItem('name').NodeValue;
      R:=FA.Attributes.GetNamedItem('type');
      if Assigned(R) then
      begin
        if IsSimpleType(R.NodeValue) then
          Prop:=AComplexType.Propertys.Add(pitAttribute)
        else
          Prop:=AComplexType.Propertys.Add(pitClass);
        Prop.BaseType:=R.NodeValue;
        Prop.Name:=S1;
        Prop.Description:=GetAnnotation(FA);
      end;
    end;
  end;
end;

function TXSDMainForm.GetAnnotation(AContext: TDOMNode): string;
var
  R: TDOMNode;
begin
  Result:='';
  R:=AContext.FindNode('xs:annotation');
  if Assigned(R) then
    R:=R.FindNode('xs:documentation');
  if Assigned(R) then
    //Result:=R.NodeValue;
    Result:=R.TextContent;
end;

procedure TXSDMainForm.DoMakePas;
var
  FCodegen: TXsdPasCodegen;
begin
  FCodegen:=TXsdPasCodegen.Create(FXSDModule);
  FCodegen.PasUnitName:=ExtractFileNameOnly(FileNameEdit1.FileName);
  SynEdit1.Lines.Text:=FCodegen.GeneratePasCode;
  FCodegen.Free;
end;

procedure TXSDMainForm.WriteLog(S: string);
begin
  Memo1.Lines.Add(S);
end;

end.

