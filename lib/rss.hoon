/-  sur=rss
^?
=<  [. sur]
=,  sur
|%
++  rss-parse
  |=  [xml=cord]
  |^  ^-  (list rss-item)
  (rash xml root)

  ++  root
    ;~  sfix
      ;~  pfix
        (trash '<channel>')
        channel
      ==
      %-  star  cha
    ==

  ++  channel
    %+  ifix  (tagjest "channel")
    ;~  sfix
      %-  star
      ;~  pfix
        (trash '<item>')
        item
      ==
      (trash '</channel>')
    ==

  ++  item
    ::^-  rss-item
    |^  %+  ifix  (tagjest "item")
    ;~  sfix
      ;~(plug ;~(pfix (trash '<title>') title) ;~(pfix (trash '<link>') link) ;~(pfix (trash '<pubDate>') pubdate))
      (trash '</item>')
    ==
    ++  title
      %+  ifix  (tagjest "title")
      %-  star
      ;~(less (jest '</title>') cha)

    ++  link
      %+  ifix  (tagjest "link")
      %-  star
      ;~(less (jest '</link>') cha)

    ++  pubdate
      ::^-  date
      ::[[& year] month [day hour minute second (list ux)]
      ::Sun, 30 Aug 2020 10:51:10 +0000
      ::X  , day mon  year h m s   x
      %+  ifix  (tagjest "pubDate")
      %-  star
      ;~(less (jest '</pubDate>') cha)
    --

  ++  trash  ::Trash characters until pattern match input cord
    |=  [str=cord]
    %-  star
    ;~(less (jest str) cha)

  ++  tagjest  ::Generate wrapping rules for ifix with input of tag name
    |=  [tag=tape]
    [(jest (crip (weld ['<' tag] ">"))) (jest (crip (weld ['<' '/' tag] ">")))]

  ++  cha  ::Match printable or whitespace
    ;~(pose prn (mask ~[' ' `@`0x9 `@`0xa `@`0xd `@`'\\' `@`'"']))
  --
--
