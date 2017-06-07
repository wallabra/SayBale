nicked = false
nick = null

connect = (again) ->
    if not again?
        again = false

    if again
        nick = window.prompt("Already used! Use another nickname:", "default_user1").replace("&", "&amp;").replace("<", "&lt;").replace("\"", "&quot;").replace("'", "&apos;")

    else
        nick = window.prompt("Set your nickname:", "default_user").replace("&", "&amp;").replace("<", "&lt;").replace("\"", "&quot;").replace("'", "&apos;")

    $.ajax(
        "../connect", {
            type: "POST"
            data: JSON.stringify({ nick: nick })
            success: (data, status, req) ->
                if not data.continue
                    connect(true)

            contentType: 'application/json'
        }
    )

sendText = ->
    if not nicked
        return false

    inputBox = document.getElementById("textArea")
    data = inputBox.value

    if data == ""
        return false

    inputBox.value = ""

    $.ajax(
        "../sendchat", {
            type: "POST"
            data: JSON.stringify({ text: data, nick: nick })
            success: null
            contentType: 'application/json'
        }
    )

    true

validateSendText = (event) ->
    sendText() if event.keyCode == 13

parse = (logs) ->
    for d in logs
        if d.text? and d.text != ""
            if d.text.indexOf(nick) != -1 and d.highlight and d.nick != nick
                new Audio("../highlight.wav").play()
                d.text = d.text.replace(new RegExp(nick, "g"), '<span class="highlight"><span id="nick" /></span>').replace('<span id="nick" />', nick)

            console.log("1. " + d.text)
            d.text = d.text.replace(new RegExp("[a-zA-Z1-9]+\\:\\/\\/[^ \\)]+", "ig"), (x) -> "<turl>#{x}</turl>" )
            console.log("2. " + d.text)
            d.text = d.text.replace(new RegExp("img\\(\\<turl\\>[a-zA-Z1-9]+\\:\\/\\/[^\\<]+\\<\\/turl\\>\\)", "ig"), (x) ->
                url = x.slice(10, x.length - 8)
                "<a href=\"#{url}\"><img src=\"#{url}\"></a>"
            )
            console.log("3. " + d.text)
            d.text = d.text.replace(new RegExp("\\<turl\\>([^\\<]+)\\<\\/turl\\>", "ig"), (x) ->
                x.slice(5, x.length - 5)
            )
            console.log("4. " + d.text)

            document.getElementById("logs").innerHTML += "</br>#{d.text}"

mainLoop = ->
    scroll = document.getElementById("logs").scrollTop == (document.getElementById("logs").scrollHeight - document.getElementById("logs").offsetHeight)

    $.ajax(
        "../getchat", {
            type: "POST"
            data: JSON.stringify({ nick: nick })
            success: (data, status, req) ->
                if data.continue?
                    if data.logs?
                        parse(data.logs)
                        window.setTimeout(mainLoop, data.next * 1000)

                    else
                        window.setTimeout(mainLoop, 5000)
                
                else
                    disconnect()

                document.getElementById("logs").scrollTop = (document.getElementById("logs").scrollHeight - document.getElementById("logs").offsetHeight) if scroll

            contentType: 'application/json'
        }
    )

disconnect = ->
    document.getElementById("inputs").parentNode.removeChild(document.getElementById("inputs"))

    $.ajax(
        "../disconnect", {
            type: "POST"
            data: JSON.stringify({ nick: nick })
            success: null
            contentType: 'application/json'
        }
    )

    document.getElementById("logs").innerHTML += "</br>--- Disconnected."

window.onload = ->
    connect()

    nicked = true
    window.setTimeout(mainLoop, 1000)