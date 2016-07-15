# Description:
#   Drafty Bot

module.exports = (robot) ->
    robot.brain.data.heroes ?= []
    robot.brain.data.draft ?= {blue: [], red: []}
    robot.brain.data.votes ?= {}

    voteFor = (choice) ->
        robot.brain.data.votes[choice] ?= 0
        robot.brain.data.votes[choice]++

    reset = () ->
        resetVotes()
        resetDraft()

    resetDraft = () ->
        robot.brain.data.draft = {blue: [], red: []}

    resetVotes = () ->
        robot.brain.data.votes = {}

    robot.http('http://heroesjson.com/heroes.json')
    .get() (err, res, body) ->
        if !err
            data = JSON.parse(body)

            for hero in data
                robot.brain.data.heroes.push(hero.name)
                robot.hear new RegExp('^!(' + hero.name + ')$', 'i'), id: 'hero.vote', (res) ->
                    voteFor(res.match[1].toLowerCase())

    robot.router.get '/hubot/draft/reset', (req, res) ->
        reset()
        res.json robot.brain.data.draft

    robot.router.get '/hubot/draft/data', (req, res) ->
        res.json robot.brain.data.draft

    robot.router.get '/hubot/draft/votedata', (req, res) ->
        res.json robot.brain.data.votes

    robot.router.get '/hubot/draft/heroes', (req, res) ->
        res.json robot.brain.data.heroes

    robot.router.get '/hubot/draft/next', (req, res) ->
        maxv = 0
        winner = ''

        for k,v of robot.brain.data.votes
            unless k in robot.brain.data.draft.blue || k in robot.brain.data.draft.red
                if v > maxv
                    maxv = v
                    winner = k

        unless winner == ''
            team = ''
            if robot.brain.data.draft.blue.length > robot.brain.data.draft.red.length
                robot.brain.data.draft.red.push(winner)
                team = 'RED'
            else
                robot.brain.data.draft.blue.push(winner)
                team = 'BLUE'

            resetVotes()

            if robot.brain.data.draft.blue.length == 5 && robot.brain.data.draft.red.length == 5
                res.send res.send team + ': ' + winner + "\n" + 'FINISHED'
            else
                res.send team + ': ' + winner
        else
            res.send 'NO WINNER YET'


