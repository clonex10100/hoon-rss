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
        (match-to '<channel>')
        channel
      ==
      %-  star  cha
    ==

  ++  channel
    %+  ifix  (tagjest "channel")
    ;~  sfix
      %-  star
      ;~  pfix
        (match-to '<item>')
        item
      ==
      (match-to '</channel>')
    ==

  ++  item
    |^  %+  ifix  (tagjest "item")
    ;~  sfix
      ;~  plug
        ;~(pfix (match-to '<title>') title)
        ;~(pfix (match-to '<link>') link)
        ;~(pfix (match-to '<pubDate>') pubdate)
      ==
      (match-to '</item>')
    ==
    ++  title
      %+  ifix  (tagjest "title")
      |^
        ;~  pose
          cdata
          (match-to '</title>')
        ==
        ++  cdata  ::Extract title from CDATA tag if it exists
          %+  ifix  [(jest '<![CDATA[') (jest ']]>')]
          (match-to ']]>')
      --

    ++  link
      %+  ifix  (tagjest "link")
      (match-to '</link>')

    ++  pubdate
      ::[[& year] month [day hour minute second (list ux)]
      ::Sun, 30 Aug 2020 10:51:10 +0000
      %+  ifix  (tagjest "pubDate")
      %+  cook  ::Turn parse results into a @d
        |=  [d=@ m=@ y=@ h=@ mi=@ s=@]  ^-  @d
        %-  year
        [[& y] m [d h m s ~]]
      ;~  sfix
        ;~  pfix
          ;~(plug alf alf alf com ace) ::Throw away Sun,(ace)
          ;~  plug  ::[day month year hour minute second]
            dem  ::Day

            ;~  pfix  ::Month
              (just ' ')
              ;~  pose
                (cold 1 (jest 'Jan'))
                (cold 2 (jest 'Feb'))
                (cold 3 (jest 'Mar'))
                (cold 4 (jest 'Apr'))
                (cold 5 (jest 'May'))
                (cold 6 (jest 'Jun'))
                (cold 7 (jest 'Jul'))
                (cold 8 (jest 'Aug'))
                (cold 9 (jest 'Sep'))
                (cold 10 (jest 'Oct'))
                (cold 11 (jest 'Nov'))
                (cold 12 (jest 'Dec'))
              ==
            ==

            ;~(pfix ace dem)  ::Year

            ;~  pfix  ace  ::Time
              ;~((glue col) dem dem dem)
            ==
          ==
        ==
      (match-to '</pubDate>')
      ==
    --

  ++  match-to  ::match characters until str
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
