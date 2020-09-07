Messages sent to/from the mod if the Web-API is configured (with `beerchat.url`)

# Web API Messages

## Ingame to Web

Messages sent via POST to `beerchat.url`

### Channel message

Sent if a player talks on a channel

```json
{
	"type": "message",
	"channel": "main",
	"username": "somedude",
	"message": "give me diamonds!"
}
```

*NOTE*: `username` and `channel` can be empty, in this
case the message is a system-message like "Player somedude joined the game"
or "Minetest started"

*NOTE2*: if the channel is `audit` then the `username` will be empty
and the `message` contanins audit-related infos, for example:
* `Player 'somedude' triggered anticheat: 'interact_while_dea' at position: 1,2,3`

### "me" message

Sent if a player uses the /me command

```json
{
	"type": "me",
	"channel": "main",
	"username": "somedude",
	"message": "is bored"
}
```

## Web to Ingame

Messages received via GET (and longpoll) to `beerchat.url`

### Normal chat message

```json
{
	"username": "SomeDudeXXL",
	"message": "hi, i'm on IRC",
	"name": "IRC",
	"channel": "main"
}
```

### Ingame command

```json
{
	"username": "SomeDudeXXL",
	"message": "status",
	"name": "IRC",
	"target_name": "minetest"
}
```
