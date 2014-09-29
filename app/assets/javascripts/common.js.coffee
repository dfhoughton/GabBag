# Created by david on 9/25/14.
$ ->
    $('[data-toggle=tooltip]').tooltip()
    f = -> $('#messages').fadeOut()
    setTimeout f, 5000
