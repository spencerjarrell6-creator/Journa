import Foundation
import Contacts

class AIService {
    static let shared = AIService()
    
    private let apiURL = "https://api.anthropic.com/v1/messages"
    
    // Only active (non-disabled) contacts
    private func activeContactList() async -> String {
        let contacts = await ContactsService.shared.fetchContacts()
        let activePeople = ContactsService.shared.people.filter { $0.isActive }
        let activeNames = Set(activePeople.map { $0.name.lowercased() })
        
        return contacts.map {
            $0.givenName.trimmingCharacters(in: .whitespaces)
        }
        .filter { name in
            !name.isEmpty && activeNames.contains(name.lowercased())
        }
        .joined(separator: ", ")
    }
    
    func summarizeJournal(text: String) async throws -> [TaggedSegment] {
        let contactList = await activeContactList()
        
        var allSegments: [TaggedSegment] = []
        
        if Secrets.categorizePeople {
            let people = try await scanForPeople(text: text, contactList: contactList)
            allSegments += people
        }
        if Secrets.categorizeCalendar {
            let dates = try await scanForDates(text: text)
            allSegments += dates
        }
        if Secrets.categorizeLogs {
            let logs = try await scanForLogs(text: text)
            allSegments += logs
        }
        
        return allSegments
    }
    
    func summarizeImport(text: String, source: String?, fromContact: String?, povIsMe: Bool) async throws -> [TaggedSegment] {
        let contactList = await activeContactList()
        let sourceLabel = source ?? "a messaging platform"
        let contactLabel = fromContact ?? "the other person"
        
        let povDescription: String
        if povIsMe {
            povDescription = """
            This is a conversation from \(sourceLabel). The POV is MINE (the journal author).
            - Messages I sent are MY words
            - Messages from \(contactLabel) are their words
            
            Extract:
            - Key things \(contactLabel) said, expressed, or shared — these are notes about \(contactLabel)
            - Any dates or plans mentioned by either side
            - A summary of the overall conversation
            
            Focus on what you can learn about \(contactLabel) from this conversation.
            """
        } else {
            povDescription = """
            This is a conversation from \(sourceLabel) from \(contactLabel)'s point of view.
            - All messages or content here are from \(contactLabel)'s perspective
            - Extract what \(contactLabel) said, felt, expressed, or shared
            - Treat everything as coming from \(contactLabel) unless clearly attributed to someone else
            
            Focus entirely on \(contactLabel) — their thoughts, feelings, plans, and statements.
            """
        }
        
        let prompt = """
        \(povDescription)
        
        Format your response using these tags:
        - <person name="\(contactLabel)">one distinct thought or thing \(contactLabel) expressed</person>
        - <date>specific date or time reference</date>
        - <log>one sentence summary of the conversation</log>
        
        Rules:
        - One <person> tag per distinct thought — if \(contactLabel) expressed 4 different things, make 4 tags
        - Only include dates that are specific and actionable (not vague like "someday")
        - Only tag other people if they're in this contact list: [\(contactList)]
        - Return only tagged content, no explanation
        
        Conversation:
        \(text)
        """
        
        let response = try await callAPI(prompt: prompt, maxTokens: 1500)
        
        var segments: [TaggedSegment] = []
        segments += parsePersonTags(response)
        segments += parseTag(response, type: .date)
        segments += parseTag(response, type: .log)
        return segments
    }
    
    private func scanForPeople(text: String, contactList: String) async throws -> [TaggedSegment] {
        let prompt = """
        Contact list: [\(contactList)]
        
        Read this journal entry. For each distinct thought or trait about someone from the contact list, create a separate <person> tag.
        
        Format each one exactly like this:
        <person name="FIRSTNAME">the thought about this person, using their name instead of pronouns</person>
        
        Rules:
        - One tag per distinct thought or trait — a thought may span multiple sentences if they're connected
        - If John has 3 separate thoughts written about him, create 3 separate John tags
        - Resolve pronouns — "he seemed tired" referring to John becomes "John seemed tired"
        - If a thought mentions multiple contacts, create a separate tag for each contact
        - Only tag people from the contact list
        - Do not tag thoughts only about the journal author
        - Return only tagged content, no explanation
        
        Example:
        Input: "Hung out with John today. He seemed tired but was in good spirits. He also mentioned he wants to move to Austin."
        Output:
        <person name="John">John seemed tired but was in good spirits.</person>
        <person name="John">John mentioned he wants to move to Austin.</person>
        
        Journal entry:
        \(text)
        """
        
        let response = try await callAPI(prompt: prompt, maxTokens: 1024)
        return parsePersonTags(response)
    }

    private func parsePersonTags(_ response: String) -> [TaggedSegment] {
        let pattern = #"<person name="([^"]+)">(.*?)</person>"#
        
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: .dotMatchesLineSeparators
        ) else { return [] }
        
        let matches = regex.matches(
            in: response,
            range: NSRange(response.startIndex..., in: response)
        )
        
        return matches.compactMap { match in
            guard
                let nameRange = Range(match.range(at: 1), in: response),
                let textRange = Range(match.range(at: 2), in: response)
            else { return nil }
            
            let name = String(response[nameRange])
            let text = String(response[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            
            return TaggedSegment(text: text, types: [.person], contactName: name)
        }
    }
    
    private func scanForDates(text: String) async throws -> [TaggedSegment] {
        let prompt = """
        Read this journal entry and find sentences that mention a SPECIFIC actionable date or time.
        Wrap each one in <date>...</date> tags.
        
        INCLUDE:
        - Specific dates: "March 5th", "February 29th", "the 22nd"
        - Relative future references: "tomorrow", "today", "this Friday", "next Tuesday", "next week"
        - Specific times with context: "at 3pm", "at noon on Thursday"
        
        DO NOT INCLUDE:
        - Vague future plans with no specific time: "next month", "someday", "soon", "eventually"
        - Past references: "last week", "yesterday", "the other day", "a few days ago"
        - General intentions with no time: "thinking about moving", "planning to call"
        
        If no qualifying dates exist, return nothing.
        Return only tagged content, no explanation.
        
        Journal entry:
        \(text)
        """
        
        let response = try await callAPI(prompt: prompt, maxTokens: 1024)
        return parseTag(response, type: .date)
    }
    
    private func scanForLogs(text: String) async throws -> [TaggedSegment] {
        let prompt = """
        Read this journal entry and write ONE single sentence that summarizes the overall gist of what happened or was discussed. Keep it short and punchy — no more than 20 words.
        Wrap it in a single <log>...</log> tag.
        Return only the tagged summary, no explanation.
        
        Journal entry:
        \(text)
        """
        
        let response = try await callAPI(prompt: prompt, maxTokens: 256)
        return parseTag(response, type: .log)
    }
    
    private func callAPI(prompt: String, maxTokens: Int) async throws -> String {
        let body: [String: Any] = [
            "model": "claude-opus-4-6",
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return response.content.first?.text ?? ""
    }
    
    private func parseTag(_ response: String, type: SegmentType) -> [TaggedSegment] {
        let tagName = type == .date ? "date" : type == .person ? "person" : "log"
        let pattern = "<\(tagName)>(.*?)</\(tagName)>"
        
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: .dotMatchesLineSeparators
        ) else { return [] }
        
        let matches = regex.matches(
            in: response,
            range: NSRange(response.startIndex..., in: response)
        )
        
        return matches.compactMap { match in
            guard let textRange = Range(match.range(at: 1), in: response) else { return nil }
            let text = String(response[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return TaggedSegment(text: text, types: [type])
        }
    }
}

// MARK: - Response Models
struct AnthropicResponse: Codable {
    let content: [ContentBlock]
}

struct ContentBlock: Codable {
    let text: String
}
