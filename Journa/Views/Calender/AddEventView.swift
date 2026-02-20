import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) var dismiss
    var selectedDate: Date
    
    @State private var title: String = ""
    @State private var date: Date
    @State private var selectedType: EventType = .date
    @State private var recurrence: RecurrenceType = .none
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        _date = State(initialValue: selectedDate)
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E").ignoresSafeArea()
            
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 16)
                
                HStack {
                    Text("Add Event")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TITLE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            TextField("Event title", text: $title)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(10)
                        }
                        
                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DATE & TIME")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            DatePicker("", selection: $date)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .tint(Color(hex: "8FA8A8"))
                        }
                        
                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TYPE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            HStack(spacing: 10) {
                                TypeButton(label: "Event", color: Color(hex: "E05555"), selected: selectedType == .date) {
                                    selectedType = .date
                                }
                                TypeButton(label: "Log", color: Color(hex: "4CAF50"), selected: selectedType == .log) {
                                    selectedType = .log
                                }
                            }
                        }
                        
                        // Recurrence
                        VStack(alignment: .leading, spacing: 8) {
                            Text("REPEATS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(RecurrenceType.allCases, id: \.self) { type in
                                        Button(action: { recurrence = type }) {
                                            Text(type.rawValue)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(recurrence == type ? Color(hex: "8FA8A8") : .white.opacity(0.4))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(recurrence == type ?
                                                    Color(hex: "8FA8A8").opacity(0.15) :
                                                    Color.white.opacity(0.06))
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(recurrence == type ?
                                                            Color(hex: "8FA8A8").opacity(0.4) :
                                                            Color.clear, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Save button
                        Button(action: {
                            Task {
                                await CalendarService.shared.saveEvent(
                                    title: title,
                                    date: date,
                                    type: selectedType,
                                    recurrence: recurrence
                                )
                                dismiss()
                            }
                        }) {
                            Text("Add Event")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(title.isEmpty ? Color.white.opacity(0.1) : Color(hex: "8FA8A8"))
                                .cornerRadius(14)
                        }
                        .disabled(title.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}
