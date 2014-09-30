# page initialization
body = $ 'body'
subW = filterMaker = friendDiv = friends = last = filterTable = favoritesTable = clickedAnagram = results = source = form = undefined
anagrams = []
filters = []
acquaintances = {} # map from email addresses to friend information
context = {} # must be initialized by controller

# stuff to do on page loading
init = ->
  filterTable = $ '#filter_table'
  favoritesTable = $ '#favorites_table'
  results = $ '#results'
  form = $ '#trial'
  $('#trial > input').first().keypress (e) ->
    if e.which == 13
      e.preventDefault()
      $('#trial').submit()
      $('#full input').first().attr 'disabled', 'disabled'
      body.css 'cursor', 'progress'
  $('#clear').click ->
    filters.splice 0, filters.length
    filterTable.find('tr').remove()
    filterTable.hide()
    applyAllFilters()
  $('#filter').click ->
    addFilter()
  $('#friend').click ->
    findFriend()
  filterTable.hide()

  # wire up the question marks
  for e in $ '.explanation'
    do (e) ->
      e = $ e
      s = $ '<span class="qmark">?</span>'
      s.insertBefore(e);
      e.remove()
      e.removeClass("explanation")
      for c in e.attr('class').split /\s+/
        s.addClass(c)
      s.click ->
        e.dialog(
          open: (e, ui) ->
            last.dialog 'close' if last
            last = $ this
            $(this.parentNode).find('button').focus()
          dialogClass: "no-close"
          buttons: [
            text: "OK"
            click: ->
              $(this).dialog "close";
              last = undefined
          ]
        )
  # ajax anagram generation
  form.submit ->
    f = $ '#full_text'
    source = f.val()
    $.ajax(
      type: 'GET'
      url: form.attr 'action'
      data: form.serialize()
      success: (data) ->
        f.removeAttr 'disabled'
        body.css 'cursor', 'default'
        if data.error
          f.notify data.error
        else
          anagrams = data.anagrams
          showAnagrams()
    )
    return false

## definitions of the functions employed above

# code for adding anagrams to the list
showAnagrams = ->
  results.empty()
  if anagrams.length
    for i in [ 0..anagrams.length - 1 ]
      li = handleAnagram i
      results.append li
      applyFilters li
  else
    form.find('input').notify 'No anagrams found!'
# create a list item and its associated click handler
handleAnagram = (i) ->
  a = anagrams[i]
  li = $ '<li/>'
  li.text a.join ' '
  li.click ->
    widget = anaWidget anagrams[i], source
    showWidget widget, li, results
  return li
# returns whether there is anyone with whom you can share anagrams
canShare = ->
  for own email, data of acquaintances
    return true if data.mutual
  return false
# returns a list of acquaintances with whom one can share anagrams
sharers = ->
  s = []
  for own email, data of acquaintances
    s.push data if data.mutual
  return s
# pops up the sharing thing
share = (ana, div) ->
  recipients = {}
  d = $ '<div class="sharees"/>'
  h = $ '<h5>select recipients</h5>'
  d.append h
  div.append d
  t = $ '<table/>'
  d.append t
  for s in sharers()
    do (s) ->
      r = $ '<tr><td></td><td><input type="checkbox"></td></tr>'
      t.append r
      r.find('td:first').text s.email
      i = r.find 'input'
      included = false
      i.click (e) ->
        e.stopPropagation()
        if included
          recipients[s.id] = undefined
        else
          recipients[s.id] = true
  b = $ '<div class="buttonbox"><button>share anagram</button></div>'
  d.append b
  b.find('button').click (e) ->
    shared = []
    for own i of recipients
      shared.push i
    if shared.length
      data = recipients: shared, source: ana.source, anagram: ana.anagram
      $.ajax(
        type: context.anagrams.share.method
        url: context.anagrams.share.url
        data: data
        success: (data) ->
          if data.error
            b.notify data.error
          else
            b.notify data.message, 'info'
      )
  return d
# saves a favorite to the anagrams table and, upon success, displays it in the favorites table
makeFavorite = (ana) ->
  $.ajax(
    type: context.favorites.create.method
    url: context.favorites.create.url
    data: ana
    success: (data) ->
      insertAna data if data.anagram
      # TODO handle errors
  )
# hide the first few cells in the favorites section so only the first anagram from a particular source has them
hideFirst = (row) ->
  row.find('td span:not([class=X])').hide()
# adjusts the visibility of the first cells in the rows of the favorites table so the arrows and sources appear in
# the right places
adjustHidden = (text) ->
  same = $.grep(
    favoritesTable.find('tr'),
  (e) ->
    s = $(e).find 'td:first span'
    return s.html() == text
  )
  first = true
  for row in same
    if first
      $(row).find('td span:not([class=X])').show()
      first = false
    else
      hideFirst $(row)
# insert an anagram into the favorites tables
insertAna = (ana) ->
  [ s, a ] = [ ana.source, ana.anagram ]
  row = $ "<tr><td><span>#{s}</span></td><td><span>&rarr;</span></td><td>#{a}</td><td><span class='X'>X</span></td></tr>"
  siblings = $.grep(
    favoritesTable.find('tr'),
    (e, i) ->
      sp = $(e).find 'td:first span'
      return sp.html() == s
  )
  if siblings.length == 0
    favoritesTable.append row
  else
    same = $.grep(
      siblings,
    (e, i) ->
      return $(e).find('td:nth-of-type(3)').text() == a
    )
    return if same.length > 0
    last = siblings[siblings.length - 1]
    $(last).after row
    hideFirst row
  sp = row.find 'span[class=X]'
  row.click (e) ->
    e.stopPropagation()
    widget = anaWidget a.split(/\s+/), s
    showWidget widget, row, row
  sp.click (e) ->
    e.stopPropagation()
    $.ajax(
      type: context.favorites.delete.method
      url: context.favorites.delete.url
      data: ana
      success: (data) ->
        if data.error
          sp.notify data.error
        else
          row.remove()
          adjustHidden s
    )
# generates the struct used to represent an anagram client side
makeAna = (ul, s) ->
  texts = for li in ul.find('li')
    $(li).text()
  return { source: s, anagram: texts.join ' ' }
# hide the anagram sharing/favoring widget
yankWidget = ->
  if clickedAnagram?
    clickedAnagram.remove()
    clickedAnagram = undefined
# puts the anagram widget in the right place on the page
showWidget = (widget, container, centerer) ->
  yankWidget()
  clickedAnagram = widget
  locate container, widget
  container.append widget
  centerUnder widget, centerer
# generates the round thingy that lets you mess about with an anagram and share or store it
anaWidget = (words, src) ->
  div = roundDiv cz: 'rearranger'
  sharer = undefined
  div.click (e) ->
    e.stopPropagation()
  ul = $ '<ul class="rearrangeable"/>'
  div.append(ul)
  for w in words
    li = $ '<li/>'
    li.text w
    ul.append li
  ul.sortable { revert: true }
  ul.disableSelection()
  ul.find('li').disableSelection()
  fb = $ '<button>fav</button>'
  sb = $ '<button>share</button>'
  ob = xButton 'submit'
  bb = $('<div class="buttonbox"/>').append(fb).append(sb).append(ob)
  ob.click (e) ->
    e.stopPropagation()
    div.remove()
  fb.click (e) ->
    e.stopPropagation()
    ana = makeAna ul, src
    makeFavorite ana
    ob.focus()
  sb.click (e) ->
    e.stopPropagation()
    sharer.remove() if sharer
    if canShare()
      ana = makeAna ul, src
      # recreate sharing widget in case the user has gained or lost friends
      sharer = share ana, div
      ob.focus()
    else
      sb.notify "You can only share anagrams with someone you've befriended and who has befriended you."
  div.append(bb)
  return div
# locate one absolutely positioned element relative to another element
# the code related to this could be refactored and consolidated
centerUnder = (move, fixed) ->
  p1 = fixed.position()
  x1 = fixed.outerWidth()
  x2 = move.outerWidth()
  finalX = p1.left + x1 / 2 - x2 / 2
  move.css 'left', finalX
# filter code; pops up the filter maker widget
addFilter = ->
  return if filterMaker?
  filterMaker = div = roundDiv cz: 'filter_maker'
  ti = $ '<label>word <input/></label>'
  text = ti.find('input')
  ba = $ '<input type="radio" name="when" value="always" checked="true">always</input>'
  bn = $ '<input type="radio" name="when" value="never">never</input>'
  bc = $ '<button>Create</button>'
  bx = xButton()
  div.append(ti).append(ba).append(bn).append(bc).append(bx)
  div.children().addClass('in_maker') # force specificity in CSS
  done = ->
    div.remove()
    filterMaker = undefined
  bx.click (e) ->
    e.stopPropagation()
    done()
  doit = (e) ->
    t = $.trim text.val()
    if t.length == 0
      text.notify 'There is no word to filter on.'
      return
    if /\s/.test t
      text.notify 'Only type a single word.'
      return
    if /\W/.test t
      text.notify 'The word to filter on should contain only word characters.'
      return
    try
      f = makeFilter ba.prop('checked'), t
    catch error
      text.notify error
      return
    insertFilter f, t
    done()
  ti.keypress (e) ->
    doit() if e.which == 13
  bc.click doit
  f = $ '#filter'
  locate f, div, f.outerHeight() + 10
  f.after(div)
  centerUnder div, f
  ti.focus()
locate = (over, under, v) ->
  p = over.position()
  v ||= 0
  under.css(
    zIndex: over.zIndex() + 1
    position: 'absolute'
    left: p.left + 'px'
    top: p.top + v + 'px'
  )
# wire up the always/never cell in a filter row
# this should probably be refactored; it shows the symptoms of unplanned organic growth
makeInverter = (an, f, x, row) ->
  m = if f.m then 'always' else 'never'
  s = "#{f.x}"
  an.text m
  an.click (e) ->
    e.stopPropagation()
    inverted = { x: f.x, m: !f.m }
    for fi, i in filters
      if "#{fi.x}" == s
        filters[i] = inverted
        break
    makeInverter an, inverted, x, row
    applyAllFilters()
  x.unbind 'click'
  x.click (e) ->
    e.stopPropagation()
    for fi, i in filters
      if "#{fi.x}" == s
        filters.splice i, 1
        break
    row.remove()
    if filters.length == 0
      filterTable.hide()
    applyAllFilters()
# generates the frequently-used cancel button -- just the node, not the code
xButton = (type) ->
  b = $ '<button class="X">X</button>'
  b.attr 'type', type if type?
  return b
# makes the base of the round widget that pops up all over the place
roundDiv = (opts) ->
  opts ||= {}
  d = $ '<div/>'
  d.attr 'class', opts.cz if opts.cz?
  d.attr 'id', opts.id if opts.id?
  return d
# inject a filter into the filters list
insertFilter = (f, t) ->
  filters.push f
  m = if f.m then 'always' else 'never'
  row = $ "<tr><td>&ldquo;#{t}&rdquo;</td><td class='an'></td><td><span class='X'/></td></tr>"
  an = row.find 'td[class=an]'
  x = row.find 'span'
  makeInverter an, f, x, row
  x.text 'X'
  x.attr 'title', 'Delete filter.'
  x.tooltip()
  filterTable.append(row)
  filterTable.show()
  applyAllFilters()
# convert the stuff entered into the filter maker widget into something we can push into the filters list
makeFilter = (must, text) ->
  rx = new RegExp '\\b' + text + '\\b', 'i'
  s = "#{rx}"
  for f in filters
    throw "You already have a filter based on '#{text}'" if s == "#{f.x}"
  return { m: must, x: rx }
# filter all results
applyAllFilters = ->
  body.css 'cursor', 'progress'
  yankWidget()
  h = filterTable.find 'tr:has(th)'
  setTimeout( # force this to be rendered separately
    ->
      $('#results li').hide()
      hidden = 0
      for li in $ '#results li'
        hidden += applyFilters $(li)
      h.find('span').text hidden
      h.show()
      body.css 'cursor', 'default'
    1
  )
# applies all existing filters to a given li in the results
applyFilters = (li) ->
  li.show()
  t = li.text()
  for f in filters
    if f.x.test t
      if !f.m
        li.hide()
        return 1
    else if f.m
      li.hide()
      return 1
  return 0
# friend code
# add a friend to the friend list in alphabetical order
addRelClass = (span, data) ->
  c = 'theirs'
  if data.mutual
    c = 'mutual'
  else if data.own
    c = 'mine'
  span.addClass c
# puts the arrow, or lack thereof, into the relationship box
addRelSymbol = (span, data) ->
  [ me, them ] = [ data.subscribed_to_me, data.subscribed_to_them ]
  if me || them
    t = ''
    if me && them
      t = context.relSymbols.mutual
    else if me
      t = context.relSymbols.themToMe
    else
      t = context.relSymbols.meToThem
    span.html t
# makes the little widget that lets you subscribe/unsubscribe
subWidget = (rs, data) ->
  subW.remove if subW?
  subW = div = roundDiv cz: 'subscribe'
  h = $ '<h5/>'
  t = if data.subscribed_to_them then 'Unsubscribe?' else 'Subscribe?'
  h.text t
  div.append h
  bb = $ '<div class="buttonbox"/>'
  div.append bb
  b = $ '<button>OK</button>'
  b.click (e) ->
    e.stopPropagation()
    $.ajax(
      type: context.friends.subscribe.method
      url: context.friends.subscribe.url.replace /\bid$/, data.id
      success: (d) ->
        if d.error
          b.notify d.e
          return
        div.remove()
        subW = undefined
        data.subscribed_to_them = !data.subscribed_to_them
        addFriend data
    )
  bb.append b
  xb = xButton()
  bb.append xb
  xb.click (e) ->
    e.stopPropagation()
    div.remove()
    subW = undefined
  locate rs, div
  rs.append div
  centerUnder div, rs
# takes friend data and adds it to the friends table
addFriend = (data) ->
  acquaintances[data.email] = data
  ft = $ '#friend_table'
  rows = ft.find 'tr'
  if rows.length
    for r in rows
      r = $ r
      if r.find('td:first').text() == data.email
        r.remove()
        break
  row = $ '<tr><td></td><td><span class="R"></span></td><td><span class="X"></span></td></tr>'
  row.find('td:first').text data.email
  rs = row.find 'span[class=R]'
  addRelClass rs, data
  addRelSymbol rs, data
  if data.own
    rs.click (e) ->
      e.stopPropagation()
      subWidget rs, data
    span = row.find 'span[class=X]'
    span.text 'X'
    span.click (e) ->
      acquaintances[data.email] = undefined
      e.stopPropagation()
      $.ajax(
        type: context.friends.delete.method || 'DELETE'
        url: context.friends.delete.url.replace /\bid$/, data.id
        data: data.id
        success: (newData) ->
          row.remove()
          if data.mutual
            data.mutual = false
            data.own = false
            data.id = data.other_id
            data.subscribed_to_them = undefined
            addFriend data
      )
  if rows.length
    where = undefined
    for r in rows # linear search should be good enough
      r = $ r
      name = r.find('td:first').text()
      if name > data.email
        where = r
        break
    if where?
      where.before row
    else
      ft.append row
  else
    ft.append row
# show potential friends
listProspects = (prospects, div) ->
  ul = div.find 'ul'
  if ul.length > 0
    h = div.find 'h5'
    ul.empty()
  else
    h = $ '<h5/>'
    div.append h
    ul = $ '<ul/>'
    div.append ul
  unless prospects.length
    h.text 'No one like that'
    return
  h.text 'Click to befriend'
  for person in prospects
    do (person) ->
      [ email, id ] = [ person.email, person.id ]
      li = $ '<li/>'
      ul.append li
      li.text email
      li.click (e) ->
        e.stopPropagation()
        $.ajax(
          type: context.friends.create.method || 'POST'
          url: context.friends.create.url
          data: { id: id }
          success: (data) ->
            addFriend data
            li.remove()
            h.text 'All befriended' unless ul.find('li').length
        )
# generate the friend finder widget
findFriend = ->
  return if friendDiv?
  friendDiv = div = roundDiv id: 'find_friend'
  div.append $ "<label>who? <input/></label><div class='buttonbox'></div>"
  ip = div.find 'input'
  bb = div.find('[class=buttonbox]');
  fb = $ "<button>Find</button>"
  xb = xButton()
  bb.append(fb).append(xb)
  xb.click (e) ->
    e.stopPropagation()
    div.remove()
    friendDiv = undefined
  search = (e) ->
    e.stopPropagation()
    $.ajax(
      type: context.friends.search.method || 'GET'
      url: context.friends.search.url
      data: { query: ip.val() }
      success: (data) ->
        if data.error?
          ip.notify data.error
        else
          prospects = data.prospects
          listProspects prospects, div
    )
  fb.click search
  ip.keypress (e) ->
    search e if e.which == 13
  $('#friend').after div
  ip.focus()
# look for fresh notices
poll = (url, method) ->
  url ||= context.notifications.recent.url
  method ||= context.notifications.recent.method
  $.ajax(
    type: method
    url: url
    success: (notifications) ->
      for n in notifications
        switch n.type
          when 'share'
            console.log 'share', n
          when 'friend'
            f = acquaintances[n.email]
            if f?
              f.mutual = n.change == 1
              addFriend f
            else
              data = email: n.email, own: false, mutual: false, id: n.id, other_id: n.other_id
              addFriend data
          when 'subscribe'
            f = acquaintances[n.email]
            if f?
              f.subscribed_to_me = n.change == 1
              addFriend f
            else # we should never get here
              data = email: n.email, own: true, mutual: true, id: n.id, other_id: n.other_id
              data.subscribed_to_me = n.change == 1
              addFriend data
          else throw new Error("unhandled notification type: #{n.type}")
  )
# makes sure the relationship symbols in the explanatory text match the generated doodads
insertSymbolDefinitions = () ->
  terms = $ '#symbol_definitions dt'
  for own k, v of context.relSymbols
    dt = ( $.grep terms, (e,i) -> $(e).text() == k )[0]
    $(dt).html v
# all the stuff to do as soon as we have the page's contextual information (really just app information)
postInit = () ->
  insertSymbolDefinitions()
  init()
  # begin poller
  setInterval poll, context.notifications.interval
  # fill up the friends table
  $.ajax(
    type: context.friends.mine.method
    url: context.friends.mine.url
    success: (data) ->
      for d in data.friends
        addFriend d
  )
  $.ajax(
    type: context.favorites.mine.method
    url: context.favorites.mine.url
    success: (data) ->
      for a in data.favorites
        insertAna a
  )
  poll(context.notifications.unread.url, context.notifications.unread.method)

# the template should call this, filling in the page context
# TODO: document the expected values
window.initializeContext = (obj) ->
  context = obj
  postInit()