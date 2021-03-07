sub init()
  m.top.functionName = "loadItems"
end sub

sub loadItems()

  results = []

  sort_field = m.top.sortField

  if m.top.sortAscending = true then
    sort_order = "Ascending"
  else
    sort_order = "Descending"
  end if

  params = {
    limit: m.top.limit,
    StartIndex: m.top.startIndex,
    parentid: m.top.itemId,
    SortBy: sort_field,
    SortOrder: sort_order,
    recursive: m.top.recursive,
    Fields: "Overview"
  }

  filter = m.top.filter
  if filter = "All" or filter = "all" then
    ' do nothing
  else if filter = "Favorites" then
    params.append({ Filters: "IsFavorite"})
  end if

  if m.top.ItemType <> "" then
    params.append({ IncludeItemTypes: m.top.ItemType})
  end if

  if m.top.ItemType = "LiveTV" then
    url = "LiveTv/Channels"
  else
    url = Substitute("Users/{0}/Items/", get_setting("active_user"))
  end if
  resp = APIRequest(url, params)
  data = getJson(resp)

  if data.TotalRecordCount <> invalid then
    m.top.totalRecordCount = data.TotalRecordCount
  end if

  for each item in data.Items

    tmp = invalid
    if item.Type = "Movie" then
      tmp = CreateObject("roSGNode", "MovieData")
    else if item.Type = "Series" then
      tmp = CreateObject("roSGNode", "SeriesData")
    else if item.Type = "BoxSet" then
      tmp = CreateObject("roSGNode", "CollectionData")
    else if item.Type = "TvChannel" then
      tmp = CreateObject("roSGNode", "ChannelData")
    else if item.Type = "Folder" then
      tmp = CreateObject("roSGNode", "FolderData")
    else if item.Type = "Video" then
      tmp = CreateObject("roSGNode", "VideoData")
    else
      print "Unknown Type: " item.Type
    end if

    if tmp <> invalid then
      tmp.SortFieldData = GetSortFieldData(item, sort_field)
      tmp.json = item
      results.push(tmp)

    end if
  end for

  m.top.content = results

end sub

sub GetSortFieldData(item, sort_field) as string
  if sort_field = "SortName" then
    return ""
  else if sort_field = "CommunityRating" then
    if item.DoesExist("CommunityRating") then
      return str(item.CommunityRating)
    else
      return ""
    end if
  else if sort_field = "CriticRating" then
    if item.DoesExist("CriticRating") then
      return str(item.CriticRating)
    else
      return ""
    end if
  else if sort_field = "DateCreated" then
    return ""
  else if sort_field = "DatePlayed" then
    return ""
  else if sort_field = "OfficialRating" then
    if item.DoesExist("OfficialRating") then
      return item.OfficialRating
    else
      return ""
    end if
  else if sort_field = "PlayCount" then
    return ""
  else if sort_field = "PremiereDate" then
    if item.DoesExist("PremiereDate") then
      date = CreateObject("roDateTime")
      date.FromISO8601String(item.PremiereDate)
      return date.AsDateString("short-month-no-weekday")
    else if item.DoesExist("ProductionYear") then
      return str(item.ProductionYear)
    else
      return ""
    end if
  else if sort_field = "Runtime" then
    return str(round(item.RunTimeTicks / 600000000.0)) + " min"
  end if
end sub

function round(f as float) as integer
  ' BrightScript only has a "floor" round
  ' This compares floor to floor + 1 to find which is closer
  m = int(f)
  n = m + 1
  x = abs(f - m)
  y = abs(f - n)
  if y > x
    return m
  else
    return n
  end if
end function
