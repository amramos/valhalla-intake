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


## The control's hover: "Select a grey thread first." with none selected, "Extra answer: 2
## feathers." once today's answers are spent, nothing otherwise.
static func hover_text(commands: DeskCommands, thread_index: int) -> String:
	var text: DeskText = commands.slice_rules().text
	if thread_index < 0:
		return text.huginn_select_hover
	if commands.huginn_left() <= 0:
		return text.huginn_extra_hover
	return ""
