unit motherless.HTMLparser;

interface
uses
  Classes, SysUtils, motherless.types,
  { HTMLp - https://github.com/RomanYankovsky/HTMLp }
  HTMLp.Entities,
  HTMLp.DOMCore,
  HTMLp.HtmlTags,
  HTMLp.HtmlReader,
  HTMLp.HtmlParser,
  HTMLp.Formatter;


  function ParseItemsFromNodes(ANodes: TNodeList): TMotherlessItemAr;
  function ParseItemFromNode(ANode: TElement): TMotherlessItem;
  function ParseItemsFromHTML(const AContent: string): TMotherlessItemAr;

  function ParseCommentFromNode(ANode: TElement): TMotherlessComment;
  function ParseCommentsFromNodes(ANodes: TNodeList): TMotherlessCommentsAr;

  function ParsePostPageFromHTML(const AContent: string): TMotherlessPostPage;

implementation

function ParseItemFromNode(ANode: TElement): TMotherlessItem;
begin
  Result := TMotherlessItem.Create('');
  var LDesktopThumb := ANode.GetElementByClass('desktop-thumb', True);
  if Assigned(LDesktopThumb) then begin
    Result.Size := LDesktopThumb.GetAttribute('data-size');

    { parse Media type }
    var LTypeStr: string := LDesktopThumb.GetAttribute('data-mediatype');
    if (LTypeStr = 'video') then
      Result.MediaType := TMotherlessMediaType.MediaVideo
    else
      Result.MediaType := TMotherlessMediaType.MediaImage;

    Result.Author := LDesktopThumb.GetAttribute('data-username');
    Result.Id := LDesktopThumb.GetAttribute('data-codename');

    if Result.Id.IsEmpty then begin
      var LMagIconWrapper := LDesktopThumb.GetElementByClass('mag-icon-wrapper');
      if Assigned(LMagIconWrapper) then
        Result.Id := LMagIconWrapper.GetAttribute('data-image-view-modal-codename');
    end;

    var LImgContainer := LDesktopThumb.GetElementByClass('img-container');
    if Assigned(LImgContainer) then
      Result.PageURL := LImgContainer.GetAttribute('href');

    var LStatic := LDesktopThumb.GetElementByClass('static');
    if Assigned(LStatic) then begin
      Result.ThumbnailUrl := LStatic.GetAttribute('src');
      Result.Caption := LStatic.GetAttribute('alt');
    end;

  end;
end;

function ParseItemsFromNodes(ANodes: TNodeList): TMotherlessItemAr;
var
  I: integer;
begin
  Result := [];
  for I := 0 to ANodes.Count - 1 do begin
    Result := Result + [ParseItemFromNode(ANodes.Items[I] as TElement)];
  end;
end;

function ParseItemsFromHTML(const AContent: string): TMotherlessItemAr;
var
  LParser: THTMLParser;
  LDoc: TDocument;
  LNodes: TNodeList;
  LContent: TElement;
begin
  Result := [];
  LParser := THTMLParser.Create;

  try
    LDoc := LParser.ParseString(AContent);
    LContent := LDoc.DocumentElement.GetElementByClass('content-inner', True);
    LNodes := LContent.GetElementsByClass('thumb-container', True);
    Result := ParseItemsFromNodes(LNodes);
  finally
    LDoc.Free;
    LParser.Free;
  end;
end;

function ParseCommentFromNode(ANode: TElement): TMotherlessComment;
begin
  Result := TMotherlessComment.Create('');
  Result.Author := ANode.GetAttribute('rev'); { Author name }
  Result.AvatarURL := ANode.GetElementByClass('avatar', True).GetAttribute('src'); { Author avatar URL }
  Result.UnsafeTimeStr := Trim(ANode.GetElementByClass('media-comment-meta', True).GetInnerText); { UnsafeTimeStr }
  Result.Text := Trim(ANode.GetElementByClass('media-comment-text').GetInnerText); { Comment text }
end;

function ParseCommentsFromNodes(ANodes: TNodeList): TMotherlessCommentsAr;
var
  I: integer;
begin
  Result := [];
  for I := 0 to ANodes.Count - 1 do begin
    Result := Result + [ParseCommentFromNode(ANodes.Items[I] as TElement)];
  end;
end;

function ParsePostPageFromHTML(const AContent: string): TMotherlessPostPage;
var
  LParser: THTMLParser;
  LDoc: TDocument;
  LContentSplitView: TElement;
  I: integer;
begin
  Result := TMotherlessPostPage.Create('');
  LParser := THTMLParser.Create;

  try
    LDoc := LParser.ParseString(AContent);
    LContentSplitView  := LDoc.DocumentElement.GetElementByClass('content', True);

    var LContent := LContentSplitView.GetElementByClass('content', True);
    begin
      var LMediaMedia := LContent.GetElementById('media-media', True);
      var LImage := LMediaMedia.GetElementById('mediaspace-image-wrapper', True);

      if Assigned(LImage) then begin
        { Image content }
        Result.Item.MediaType := TMotherlessMediaType.MediaImage;
        var LMediaImage :=  Limage.GetElementByID('motherless-media-image', True);
        if Assigned(LMediaImage) then begin
          Result.ContentURL := LMediaImage.GetAttribute('src'); { Full content }
          Result.Item.Caption := LMediaImage.GetAttribute('alt'); { Caption }
        end;

      end else begin
        { Video content }
        Result.Item.MediaType := TMotherlessMediaType.MediaVideo;;
        var LVideo := LMediaMedia.GetElementByClass('mediaspace-video-wrapper', True);
        LVideo := LVideo.GetElementByTagName('video', 9);
//        LVideo := LVideo.GetElementByClass('ml-main-video_html5_api', True);
        Result.Item.ThumbnailUrl := LVideo.GetAttribute('data-poster'); { Thumbnail poster }
        Result.Quality := LVideo.GetAttribute('data-quality');
        Result.ContentURL := LVideo.GetElementByTagName('source', 2).GetAttribute('src');
      end;

      var MediaAboutWrapper := LContentSplitView.GetElementByClass('media-about-wrapper-inner', True);
      var LMediaMeta := MediaAboutWrapper.GetElementByClass('media-meta', True);

      { Tags }
      var LMediaMetaTags := LMediaMeta.GetElementByClass('media-meta-tags', True);
      if Assigned(LMediaMetaTags) then begin
        var LTagElements := LMediaMetaTags.GetElementsByClass('pop', True);
        if Assigned(LTagElements) then begin
          for I := 0 to LTagElements.Count - 1 do begin
            var LTagStr: string := LTagElements[I].GetInnerText;
            LTagStr := Copy(LTagStr, Low(LTagStr) + 1, Length(LTagStr) -1); { Getting tag without # symbol }
            Result.Tags := Result.Tags + [LTagStr];
          end;
        end;
      end;
  
      { Caption }
      if Result.Item.Caption.IsEmpty then begin
        var LMediaMetaTitle := LMediaMeta.GetElementByClass('media-meta-title', True)
          .GetElementByTagName('h1');
        Result.Item.Caption := LMediaMetaTitle.GetInnerText;
      end;

      { Author }
      Result.Item.Author := Trim(MediaAboutWrapper.GetElementByClass('username', True).GetInnerText);

      { Comments }
      var LMediaCommentsWrapper := LContentSplitView.GetElementByID('media-comments-wrapper', True);
      if Assigned(LMediaCommentsWrapper) then begin
        var LComments := LMediaCommentsWrapper.GetElementsByClass('media-comment', FALSE);
        Result.Comments := ParseCommentsFromNodes(LComments);
      end;

    end;

  finally
    LDoc.Free;
    LParser.Free;
  end;
end;

end.
