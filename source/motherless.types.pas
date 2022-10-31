unit motherless.types;

interface
uses
  Classes, SysUtils;

const
  MOTHERLESS_URL = 'https://motherless.com';

type
  TMotherlessMediaType = (MediaImage, MediaVideo);

  TMotherlessMediaSize = (SizeAll{0}, SizeSmall{1}, SizeMedium{2}, SizeBig{3});

//  TMotherLessSearchSort = (SortRelevance, SortDate);

  TMotherLessUploadDate = (DateAll{0},
                           Date24Hours{1},
                           DateThisWeek{2},
                           DateThisMonth{3},
                           DateThisYear{4});

  TMotherLessSort = (SortRecent, { SortRelevance, SortDate }
                     SortLive,
                     SortFavorited,
                     SortMostviewed,
                     SortMostcommented,
                     SortPopular,
                     SortArchived,
                     SortRelevance, { With text request only }
                     SortDate);     { With text request only }

  TMotherlessItem = record
    public
      Id: string; // post or content unique id
      MediaType: TMotherlessMediaType;
      Size: string;   // like 'medium', 'small'
      Author: string; // post author
      Caption: string;
      PageURL: string;
      ThumbnailUrl: string;
      function GetPageUrl: string;
      constructor Create(AId: string);
  end;

  TMotherlessItemAr = TArray<TMotherlessItem>;

  TMotherlessComment = record
    public
      Author: string;
      AvatarURL: string;
      UnsafeTimeStr: string; // like 3h ago
      Text: string;
      constructor Create(AAuthor: string);
  end;

  TMotherlessCommentsAr = TArray<TMotherlessComment>;

  TMotherlessPostPage = record
    public
      Item: TMotherlessItem;
      Comments: TMotherlessCommentsAr;
      Tags: TArray<string>;
      ContentURL: string;
      Quality: string;
      constructor Create(AId: string);
  end;



implementation

{ TMotherlessItem }

constructor TMotherlessItem.Create(AId: string);
begin
  Self.Id := AId;
  Self.Author := '';
  Self.Caption := '';
  Self.PageURL := '';
  Self.ThumbnailUrl := '';
  Self.MediaType := TMotherlessMediaType.MediaImage;
  Self.Size := '';
end;

function TMotherlessItem.GetPageUrl: string;
begin
  if not Self.PageURL.StartsWith('https://') then
    Result := MOTHERLESS_URL + Self.PageURL
  else
    Result := Self.PageURL;
end;

{ TMotherlessComment }

constructor TMotherlessComment.Create(AAuthor: string);
begin
  Self.Author := '';
  Self.AvatarURL := '';
  Self.UnsafeTimeStr := '';
  Self.Text := '';
end;

{ TMotherlessPostPage }

constructor TMotherlessPostPage.Create(AId: string);
begin
  Self.Item := TMotherlessItem.Create(AId);
  Self.Comments := [];
  Self.Tags := [];
  Self.ContentURL := '';
  Self.Quality := '';
end;

end.