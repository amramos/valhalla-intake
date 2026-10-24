class_name HuginnAsk
extends RefCounted
## Asking Huginn about a grey thread (D29, D30, matrix A4): a free answer while today's last, then
## one bought for feathers. Pure glue over DeskCommands; the desk system shows the result.


## Asks about `thread_index`, buying the answer when today's are spent. Returns the caption line
## ("Huginn takes 2 feathers. {answer}" when bought), or "" when nothing was answered.
static func ask(commands: DeskCommands, thread_index: int) -> String:
	var bought: bool = false
	if commands.thread_answer(thread_index) == "" and commands.huginn_left() <= 0:
		if not commands.buy_huginn_answer():
			return ""
		bought = true
	var answer: String = commands.ask_huginn(thread_index)
	if answer == "" or not bought:
		return answer
	return commands.slice_rules().text.huginn_bought_format % answer


## True when asking about `thread_index` now buys the answer: today's answers are spent and the
## thread has none yet. A thread already answered is asked again for free (ask()).
static func charges(commands: DeskCommands, thread_index: int) -> bool:
	return (
		thread_index >= 0
		and commands.thread_answer(thread_index) == ""
		and commands.huginn_left() <= 0
	)
