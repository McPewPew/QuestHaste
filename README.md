# QuestHaste

## Intro:

QuestHaste is a small Addon for vanilla World of Warcraft (1.12), it allows fast turn in of quests, especially useful for repeatable quests (e.g. Alterac Valley quests)

## Usage:

### Quest (active and available) opening/progress modifiers

| Modifier      | Action
| :---:         | ---
| Control       | auto complete/accept and save
| Alt           | forget
| Shift         | complete/accept if not saved, hold if saved
| None          | complete/accept if saved

### Gossip opening modifiers

| Modifier      | Action
| :---:         | ---
| Shift         | auto complete/accept quest in gossip  
|               | (priority: completed, available saved,  
|               | active saved, available, active)

### Chat commands (/qhaste, /questhaste)
| Command   | Action
| :---:     |   ---
| usage     | display usage instructions
| add       | saves current quest
| list      | list all saved quests
| pause     | disable QuestHaste
| resume    | activate QuestHaste
| complete  | complete/accept current quest
| reset     | clears all saved quests


## Thanks to:

JuuJuu

## Change Log:

### Version 0.4
* Added missing NPC dialog type.
* Now scans QuestLog for completed quests when opening a NPC dialog.
* Fixed error message for quests with reward choice.
