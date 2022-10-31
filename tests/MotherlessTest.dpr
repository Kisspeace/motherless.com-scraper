program MotherlessTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, XSuperObject, Classes, Net.HttpClient,
  motherless.HTMLparser in '..\source\motherless.HTMLparser.pas',
  motherless.scraper in '..\source\motherless.scraper.pas',
  motherless.types in '..\source\motherless.types.pas';

{ ------- Settings --------- }
var PrintObjects: boolean = FALSE;
var JsonIndent: boolean = TRUE;
var TestScraper: boolean = TRUE;
var TestParseFromFile: boolean = FALSE;
{ -------------------------- }

var
  Client: TMotherlessScraper;

procedure PrintItem(AItem: TMotherlessItem);
begin
  Writeln(TJson.Stringify<TMotherlessItem>(AItem, JsonIndent));
//  WriteLn(AItem.GetPageUrl);
end;

procedure PrintPostPage(AItem: TMotherlessPostPage);
begin
  Writeln(TJson.Stringify<TMotherlessPostPage>(AItem, JsonIndent));
end;

procedure PrintItems(const AItems: TMotherlessItemAr);
var
  I: integer;
begin
  for I := low(AItems) to High(AItems) do begin
    Write('[' + I.ToString + ']: ');
    PrintItem(AItems[I]);
  end;
end;

procedure GoTestParser;
var
  LStrings: TStrings;
  LItems: TMotherlessItemAr;
  LPage: TMotherlessPostPage;
begin
  LStrings := TStringList.Create;
  LStrings.LoadFromFile('..\..\web\images\post-page.html');
  LPage := ParsePostPageFromHTML(LStrings.Text);
  PrintPostPage(LPage);
end;

procedure GoTestScraper;

  function SortToStr(ASort: TMotherlessSort): string;
  begin
    case ASort of
      SortRecent:        Result := 'recent';
      SortLive:          Result := 'live';
      SortFavorited:     Result := 'favorited';
      SortMostviewed:    Result := 'viewed';
      SortMostcommented: Result := 'commented';
      SortPopular:       Result := 'popular';
      SortArchived:      Result := 'archives';
      SortRelevance:     Result := 'relevance';
      SortDate:          Result := 'date';
    end;
  end;

  function TypeToStr(AType: TMotherlessMediaType): string;
  begin
    case AType of
      MediaImage: Result := 'image';
      MediaVideo: Result := 'video';
    end;
  end;

  function TestSearch(ASearchRequest: string; APage: integer; AMediaType: TMotherlessMediaType; ASort: TMotherLessSort = SortRelevance; ASize: TMotherlessMediaSize = SizeAll; AUploadDate: TMotherLessUploadDate = DateAll): TMotherLessItemAr;
  var
    Msg: string;
  begin
    Msg := 'Test Search ' + ASearchRequest + ' ' + SortToStr(ASort) + ' ' + TypeToStr(AMediaType)  + ': ';
    try
      Result := Client.Search(ASearchRequest, APage, AMediaType, ASort, ASize, AUploadDate);
      Msg := Msg + Length(Result).ToString;
    except
      on E: Exception do
        Msg := Msg + E.ToString;
    end;
    Writeln(Msg);

    if PrintObjects then
      PrintItems(Result);
  end;

  function TestFetchFull(AItem: TMotherlessItem): TMotherlessPostPage;
  var
    Msg: string;
  begin
    Msg := 'Test fetch full: ' + AItem.GetPageUrl + ' - ';
    try
      Result := Client.FetchFullPost(AItem);
      Msg := Msg + Result.ContentURL;
    except
      on E: Exception do
        Msg := Msg + E.ToString;
    end;
    Writeln(Msg);

    if PrintObjects then
      PrintPostPage(Result);
  end;

var
  I: Integer;
  LItems: TMotherlessItemAr;
begin

  for I := 0 to ord(TMotherLessSort.SortArchived) do begin
    TestSearch('', 1, MediaVideo, TMotherLessSort(I));
  end;

  LItems := TestSearch('dickgirl', 1, MediaImage, SortRelevance, SizeAll, DateAll);
  if length(LItems) > 0 then
    TestFetchFull(LItems[0]);

  LItems := TestSearch('Trans ass', 1, MediaVideo, SortRelevance, SizeAll, DateAll);
  if length(LItems) > 0 then
    TestFetchFull(LItems[0]);

  TestSearch('lesbian trans', 10, MediaVideo, SortRelevance, SizeAll, DateAll);
  TestSearch('Trans cum', 1, MediaImage, SortDate, SizeSmall, DateThisYear);
  TestSearch('', 1, MediaImage, SortDate, SizeAll, DateAll);

  Writeln('ScraperTest: FIN.');
end;

begin
  try
    Client := TMotherlessScraper.Create;
    with Client.WebClient do begin
      CustomHeaders['User-Agent'] := 'Mozilla/5.0 (Windows NT 10.0; rv:105.0) Gecko/20100101 Firefox/105.0';
      Asynchronous := false;
      AutomaticDecompression := [THttpCompressionMethod.Any];
      AllowCookies := false;
      Customheaders['Accept']          := 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8';
      CustomHeaders['Accept-Language'] := 'en-US,en;q=0.5';
      CustomHeaders['Accept-Encoding'] := 'gzip, deflate';
      CustomHeaders['DNT']             := '1';
      CustomHeaders['Connection']      := 'keep-alive';
      CustomHeaders['Upgrade-Insecure-Requests'] := '1';
      CustomHeaders['Sec-Fetch-Dest']  := 'document';
      CustomHeaders['Sec-Fetch-Mode']  := 'navigate';
      CustomHeaders['Sec-Fetch-Site']  := 'same-origin';
      CustomHeaders['Pragma']          := 'no-cache';
      CustomHeaders['Cache-Control']   := 'no-cache';
//      CustomHeaders[''] := '';
    end;

    if TestParseFromFile then
      GoTestParser;

    if TestScraper then
      GoTestScraper;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
