unit motherless.scraper;

interface
uses
  System.SysUtils, Classes, motherless.types, motherless.HTMLparser,
  Net.HttpClient, Net.HttpClientComponent, Net.URLClient;

type

  TMotherlessScraper = Class(TObject)
    private
      function BuildSearchUrl(const ASearchRequest: string; APage: integer; AMediaType: TMotherlessMediaType; ASort: TMotherLessSort; ASize: TMotherlessMediaSize; AUploadDate: TMotherLessUploadDate): string;
      procedure GetAndAddItems(const AUrl: string; var AItems: TMotherlessItemAr);
    public
      WebClient: TNetHttpClient;
      function Search(ASearchRequest: string; APage: integer; AMediaType: TMotherlessMediaType; ASort: TMotherLessSort = SortRelevance; ASize: TMotherlessMediaSize = SizeAll; AUploadDate: TMotherLessUploadDate = DateAll): TMotherlessItemAr; overload;
      function SearchImages(ASearchRequest: string; APage: integer; ASort: TMotherLessSort = SortRelevance; ASize: TMotherlessMediaSize = SizeAll; AUploadDate: TMotherLessUploadDate = DateAll): TMotherlessItemAr;
      function SearchVideos(ASearchRequest: string; APage: integer; ASort: TMotherLessSort = SortRelevance; ASize: TMotherlessMediaSize = SizeAll; AUploadDate: TMotherLessUploadDate = DateAll): TMotherlessItemAr;
      function FetchFullPost(AUrl: string): TMotherlessPostPage; overload;
      function FetchFullPost(const AItem: TMotherlessItem): TMotherlessPostPage; overload;
      constructor Create;
      destructor Destroy; override;
  End;

implementation

{ TMotherlessScraper }

function TMotherlessScraper.BuildSearchUrl(const ASearchRequest: string; APage: integer;
  AMediaType: TMotherlessMediaType; ASort: TMotherLessSort;
  ASize: TMotherlessMediaSize; AUploadDate: TMotherLessUploadDate): string;
var
  LMedia: string;
begin
  Result := MOTHERLESS_URL;

  if AMediaType = MediaImage then
    LMedia := 'images'
  else
    LMedia := 'videos';

  if (not ASearchRequest.IsEmpty) then begin
    Result := Result + '/term/' + LMedia;
    Result := Result + '/' + ASearchRequest + '?range=' + Ord(AUploadDate).ToString + '&size=' + Ord(ASize).ToString;

    if ASort = SortRelevance then
      Result := Result + '&sort=relevance'
    else
      Result := Result + '&sort=date';

    Result := Result + '&page=' + APage.ToString;
  end else if (ASort = SortLive) then begin
    Result := Result + '/live/' + LMedia;
  end else begin
    Result := Result + '/' + LMedia + '/';

    if ASort in [SortRelevance, SortDate] then
      ASort := SortRecent;

    case ASort of
      SortRecent:        Result := Result + 'recent';
      SortFavorited:     Result := Result + 'favorited';
      SortMostviewed:    Result := Result + 'viewed';
      SortMostcommented: Result := Result + 'commented';
      SortPopular:       Result := Result + 'popular';
      SortArchived:      Result := Result + 'archives';
    end;

    Result := Result + '?page=' + APage.ToString;
  end;
end;

constructor TMotherlessScraper.Create;
begin
  WebCLient := TNetHttpClient.Create(nil);
end;

destructor TMotherlessScraper.Destroy;
begin
  WebCLient.Free;
  inherited;
end;

function TMotherlessScraper.FetchFullPost(
  const AItem: TMotherlessItem): TMotherlessPostPage;
begin
  Result := Self.FetchFullPost(AItem.GetPageUrl);
end;

function TMotherlessScraper.FetchFullPost(AUrl: string): TMotherlessPostPage;
var
  LResponse: IHTTPResponse;
  LContent: string;
begin
  LResponse := Self.WebClient.Get(AUrl);
  LContent := LResponse.ContentAsString;
  LResponse := nil;
  Result := ParsePostPageFromHTML(LContent);
end;

procedure TMotherlessScraper.GetAndAddItems(const AUrl: string;
  var AItems: TMotherlessItemAr);
var
  LResponse: IHTTPResponse;
begin
  LResponse := Self.WebClient.Get(AUrl);
  AItems := AItems + ParseItemsFromHTML(LResponse.ContentAsString);
end;

function TMotherlessScraper.Search(ASearchRequest: string; APage: integer;
  AMediaType: TMotherlessMediaType; ASort: TMotherLessSort;
  ASize: TMotherlessMediaSize;
  AUploadDate: TMotherLessUploadDate): TMotherlessItemAr;
var
  LUrl: string;
begin
  Result := nil;
  LUrl := Self.BuildSearchUrl(ASearchRequest, APage, AMediaType, ASort, ASize, AUploadDate);
  GetAndAddItems(LUrl, Result);
end;

function TMotherlessScraper.SearchImages(ASearchRequest: string; APage: integer;
  ASort: TMotherLessSort; ASize: TMotherlessMediaSize;
  AUploadDate: TMotherLessUploadDate): TMotherlessItemAr;
begin
  Result := Search(ASearchRequest, APage, MediaImage, ASort, ASize, AUploadDate);
end;

function TMotherlessScraper.SearchVideos(ASearchRequest: string; APage: integer;
  ASort: TMotherLessSort; ASize: TMotherlessMediaSize;
  AUploadDate: TMotherLessUploadDate): TMotherlessItemAr;
begin
  Result := Search(ASearchRequest, APage, MediaVideo, ASort, ASize, AUploadDate);
end;

end.