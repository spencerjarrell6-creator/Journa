import Foundation

class BotActionExecutor {
    static let shared = BotActionExecutor()
    
    func execute(_ actions: [BotAction]) async -> String {
        var results: [String] = []
        for action in actions {
            let result = await executeAction(action)
            results.append(result)
        }
        return results.joined(separator: "\n")
    }
    
    private func executeAction(_ action: BotAction) async -> String {
        switch action.type {
            
        // MARK: - Logs
        case .createLog:
            let text = action.newValue ?? ""
            let title = action.targetName ?? "New Log"
            let log = LogStore.shared.saveLog(rawText: text, segments: [])
            await MainActor.run {
                if let index = LogStore.shared.logs.firstIndex(where: { $0.id == log.id }) {
                    LogStore.shared.logs[index].title = title
                }
            }
            return "Created log: \(title)"
            
        case .editLog:
            guard let idStr = action.targetID,
                  let uuid = UUID(uuidString: idStr) else {
                if let name = action.targetName,
                   let index = LogStore.shared.logs.firstIndex(where: {
                       $0.title.lowercased().contains(name.lowercased())
                   }) {
                    await MainActor.run {
                        if let newText = action.newValue {
                            LogStore.shared.logs[index].rawText = newText
                        }
                        if let newTitle = action.secondaryValue {
                            LogStore.shared.logs[index].title = newTitle
                        }
                    }
                    return "Edited log: \(LogStore.shared.logs[index].title)"
                }
                return "Could not find log to edit"
            }
            if let index = LogStore.shared.logs.firstIndex(where: { $0.id == uuid }) {
                await MainActor.run {
                    if let newText = action.newValue {
                        LogStore.shared.logs[index].rawText = newText
                    }
                    if let newTitle = action.secondaryValue {
                        LogStore.shared.logs[index].title = newTitle
                    }
                }
                return "Edited log: \(LogStore.shared.logs[index].title)"
            }
            return "Log not found"
            
        case .deleteLog:
            if let idStr = action.targetID,
               let uuid = UUID(uuidString: idStr) {
                await MainActor.run {
                    LogStore.shared.logs.removeAll { $0.id == uuid }
                }
                return "Deleted log"
            } else if let name = action.targetName {
                await MainActor.run {
                    LogStore.shared.logs.removeAll {
                        $0.title.lowercased().contains(name.lowercased())
                    }
                }
                return "Deleted log: \(name)"
            }
            return "Could not find log to delete"
            
        // MARK: - Calendar
        case .createEvent:
            let title = action.newValue ?? action.targetName ?? "New Event"
            let dateStr = action.secondaryValue ?? ""
            let date = CalendarService.shared.parseDate(from: dateStr.isEmpty ? title : dateStr)
            await CalendarService.shared.saveEvent(title: title, date: date, type: .date)
            return "Created event: \(title)"
            
        case .editEvent:
            if let name = action.targetName,
               let index = CalendarService.shared.journaEvents.firstIndex(where: {
                   $0.title.lowercased().contains(name.lowercased())
               }) {
                await MainActor.run {
                    if let newTitle = action.newValue {
                        CalendarService.shared.journaEvents[index].title = newTitle
                    }
                    if let newDateStr = action.secondaryValue {
                        let newDate = CalendarService.shared.parseDate(from: newDateStr)
                        CalendarService.shared.journaEvents[index].date = newDate
                    }
                }
                return "Edited event: \(CalendarService.shared.journaEvents[index].title)"
            }
            return "Could not find event to edit"
            
        case .deleteEvent:
            if let name = action.targetName {
                await MainActor.run {
                    CalendarService.shared.journaEvents.removeAll {
                        $0.title.lowercased().contains(name.lowercased())
                    }
                }
                return "Deleted event: \(name)"
            }
            return "Could not find event to delete"
            
        // MARK: - Notes
        case .createNote:
            guard let personName = action.targetName else { return "No person specified" }
            let noteText = action.newValue ?? ""
            if let person = ContactsService.shared.people.first(where: {
                $0.name.lowercased().contains(personName.lowercased())
            }) {
                await ContactsService.shared.savePerson(
                    name: person.name,
                    notes: noteText,
                    contactID: person.contactID,
                    logID: nil
                )
                return "Added note to \(person.name)"
            }
            return "Could not find person: \(personName)"
            
        case .editNote:
            guard let personName = action.targetName,
                  let newText = action.newValue else { return "Missing info to edit note" }
            if let personIndex = ContactsService.shared.people.firstIndex(where: {
                $0.name.lowercased().contains(personName.lowercased())
            }) {
                let searchText = action.secondaryValue ?? ""
                if let noteIndex = ContactsService.shared.people[personIndex].notes.firstIndex(where: {
                    $0.text.lowercased().contains(searchText.lowercased())
                }) ?? ContactsService.shared.people[personIndex].notes.indices.last {
                    await MainActor.run {
                        ContactsService.shared.people[personIndex].notes[noteIndex].text = newText
                    }
                    return "Edited note for \(ContactsService.shared.people[personIndex].name)"
                }
            }
            return "Could not find note to edit"
            
        case .deleteNote:
            guard let personName = action.targetName else { return "No person specified" }
            if let personIndex = ContactsService.shared.people.firstIndex(where: {
                $0.name.lowercased().contains(personName.lowercased())
            }) {
                let searchText = action.secondaryValue ?? ""
                await MainActor.run {
                    if searchText.isEmpty {
                        ContactsService.shared.people[personIndex].notes.removeAll()
                    } else {
                        ContactsService.shared.people[personIndex].notes.removeAll {
                            $0.text.lowercased().contains(searchText.lowercased())
                        }
                    }
                }
                return "Deleted note for \(ContactsService.shared.people[personIndex].name)"
            }
            return "Could not find person: \(personName)"
            
        // MARK: - Groups
        case .createGroup:
            let name = action.newValue ?? action.targetName ?? "New Group"
            let colorHex = action.secondaryValue
            await MainActor.run {
                _ = GroupStore.shared.createGroup(name: name, colorHex: colorHex)
            }
            return "Created group: \(name)"
            
        case .deleteGroup:
            // Try by ID first, then by name
            if let idStr = action.targetID,
               let uuid = UUID(uuidString: idStr) {
                await MainActor.run {
                    GroupStore.shared.remove(uuid)
                }
                return "Deleted group"
            } else if let name = action.targetName,
                      let group = GroupStore.shared.groups.first(where: {
                          $0.name.lowercased().contains(name.lowercased())
                      }) {
                await MainActor.run {
                    GroupStore.shared.remove(group.id)
                }
                return "Deleted group: \(name)"
            }
            return "Could not find group to delete"
            
        case .renameGroup:
            let newName = action.newValue ?? ""
            guard !newName.isEmpty else { return "No new name provided" }
            // Try by ID first, then by name
            if let idStr = action.targetID,
               let uuid = UUID(uuidString: idStr) {
                await MainActor.run {
                    GroupStore.shared.renameGroup(uuid, to: newName)
                }
                return "Renamed group to \(newName)"
            } else if let name = action.targetName,
                      let group = GroupStore.shared.groups.first(where: {
                          $0.name.lowercased().contains(name.lowercased())
                      }) {
                await MainActor.run {
                    GroupStore.shared.renameGroup(group.id, to: newName)
                }
                return "Renamed '\(name)' to '\(newName)'"
            }
            return "Could not find group to rename"
            
        case .recolorGroup:
            let colorHex = action.newValue ?? "8FA8A8"
            // Try by ID first, then by name
            if let idStr = action.targetID,
               let uuid = UUID(uuidString: idStr) {
                await MainActor.run {
                    GroupStore.shared.recolorGroup(uuid, colorHex: colorHex)
                }
                return "Updated group color"
            } else if let name = action.targetName,
                      let group = GroupStore.shared.groups.first(where: {
                          $0.name.lowercased().contains(name.lowercased())
                      }) {
                await MainActor.run {
                    GroupStore.shared.recolorGroup(group.id, colorHex: colorHex)
                }
                return "Updated color for group '\(name)'"
            }
            return "Could not find group to recolor"
            
        case .addToGroup:
            guard let groupName = action.targetName,
                  let itemName = action.newValue,
                  let group = GroupStore.shared.groups.first(where: {
                      $0.name.lowercased().contains(groupName.lowercased())
                  }) else { return "Could not find group" }
            if let log = LogStore.shared.logs.first(where: {
                $0.title.lowercased().contains(itemName.lowercased())
            }) {
                await MainActor.run { GroupStore.shared.addLog(log.id, to: group.id) }
                return "Added log '\(log.title)' to group '\(group.name)'"
            }
            if let person = ContactsService.shared.people.first(where: {
                $0.name.lowercased().contains(itemName.lowercased())
            }) {
                await MainActor.run { GroupStore.shared.addPerson(person.id, to: group.id) }
                return "Added \(person.name) to group '\(group.name)'"
            }
            if let event = CalendarService.shared.journaEvents.first(where: {
                $0.title.lowercased().contains(itemName.lowercased())
            }) {
                await MainActor.run { GroupStore.shared.addEvent(event.id, to: group.id) }
                return "Added event '\(event.title)' to group '\(group.name)'"
            }
            return "Could not find item: \(itemName)"
            
        case .removeFromGroup:
            guard let groupName = action.targetName,
                  let itemName = action.newValue,
                  let groupIndex = GroupStore.shared.groups.firstIndex(where: {
                      $0.name.lowercased().contains(groupName.lowercased())
                  }) else { return "Could not find group" }
            if let log = LogStore.shared.logs.first(where: {
                $0.title.lowercased().contains(itemName.lowercased())
            }) {
                await MainActor.run {
                    GroupStore.shared.groups[groupIndex].logIDs.removeAll { $0 == log.id }
                }
                return "Removed log from group"
            }
            if let person = ContactsService.shared.people.first(where: {
                $0.name.lowercased().contains(itemName.lowercased())
            }) {
                await MainActor.run {
                    GroupStore.shared.groups[groupIndex].personIDs.removeAll { $0 == person.id }
                }
                return "Removed \(person.name) from group"
            }
            if let event = CalendarService.shared.journaEvents.first(where: {
                $0.title.lowercased().contains(itemName.lowercased())
            }) {
                await MainActor.run {
                    GroupStore.shared.groups[groupIndex].eventIDs.removeAll { $0 == event.id }
                }
                return "Removed event from group"
            }
            return "Could not find item to remove"
        }
    }
}
