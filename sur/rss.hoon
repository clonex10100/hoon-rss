^?
|%
+$  action
  $%  [%add-feed =feed]
      [%fetch ~]
  ==

+$  feed  ::Feed needs to have a list of link-store wires and a date that it was last checked
  $:  url=cord
      link-group=path
  ==

+$  rss-item
  $:  title=tape
      url=tape
      pubdate=tape
  ==
--
