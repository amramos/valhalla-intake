class_name DecreeData
extends Resource
## One decree of Odin's Law, word for word as D32.

@export var id: String = ""
@export_multiline var text: String = ""


func to_core() -> EvidenceItem:
	return EvidenceItem.make(id, EvidenceItem.Group.LAW, text)
