suite 'Some Feature', ->

  test 'some behaviour', ->
    ok yes
    eq 0, 0

  test 'some other behaviour', ->
    arrayEq [0, 1], [0, 1]

  test 'some async behaviour', (done) ->
    do done
