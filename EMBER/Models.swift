import SwiftUI
import UniformTypeIdentifiers

enum UserRole: String, CaseIterable, Identifiable, Codable {
    case candidate = "Candidato (Pessoa Física)"
    case company = "Empresa (Pessoa Jurídica)"
    var id: String { rawValue }
}

enum Gender: String, CaseIterable, Identifiable, Codable {
    case male = "Masculino"
    case female = "Feminino"
    case nonBinary = "Não-Binário"
    case other = "Outro"
    case preferNotToSay = "Prefiro não informar"
    var id: String { rawValue }
}

enum DisabilityType: String, CaseIterable, Identifiable, Codable {
    case none = "Não PCD"
    case physical = "PCD Físico"
    case mental = "PCD Mental / Intelectual"
    case visual = "PCD Visual"
    case hearing = "PCD Auditivo"
    case multiple = "PCD Múltiplo"
    var id: String { rawValue }
}

enum CompanySize: String, CaseIterable, Identifiable, Codable {
    case startup = "1 - 10 funcionários (Startup)"
    case small = "11 - 50 funcionários (Pequena)"
    case medium = "51 - 200 funcionários (Média)"
    case large = "201 - 1000 funcionários (Grande)"
    case enterprise = "+1000 funcionários (Corporativo)"
    var id: String { rawValue }
}

enum WorkShift: String, CaseIterable, Identifiable, Codable {
    case morning = "Manhã (08h às 12h)"
    case afternoon = "Tarde (13h às 18h)"
    case night = "Noite (18h às 22h)"
    case fullTime = "Comercial Integral (09h às 18h)"
    case flexible = "Horário Flexível"
    
    var id: String { rawValue }
    
    var shortName: String {
        switch self {
        case .morning: return "Manhã"
        case .afternoon: return "Tarde"
        case .night: return "Noite"
        case .fullTime: return "Comercial"
        case .flexible: return "Flexível"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .night: return "moon.stars.fill"
        case .fullTime: return "briefcase.fill"
        case .flexible: return "arrow.triangle.2.circlepath"
        }
    }
}

enum InterviewStatus: String, CaseIterable, Identifiable, Codable {
    case pending = "Aguardando Resposta"
    case confirmed = "Confirmada"
    case declined = "Recusada"
    case expired = "Expirada por Prazo"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .green
        case .declined: return .red
        case .expired: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.badge.exclamationmark.fill"
        case .confirmed: return "checkmark.seal.fill"
        case .declined: return "xmark.circle.fill"
        case .expired: return "timer"
        }
    }
}

struct InterviewAppointment: Identifiable, Codable, Equatable {
    let id: UUID
    var conversationId: UUID? = nil
    let jobId: UUID
    let jobTitle: String
    let companyId: UUID
    let companyName: String
    let candidateId: UUID
    let candidateName: String
    var scheduledDate: Date
    var durationMinutes: Int
    var meetingLink: String
    var locationOrPlatform: String // Ex: "Google Meet", "Presencial", "Microsoft Teams"
    var notes: String
    var status: InterviewStatus
    var deadlineDate: Date // Prazo para resposta do candidato (ex: 24h)
    var createdAt: Date
    
    // Verifica se expirou automaticamente
    var isExpired: Bool {
        if status == .pending && Date() > deadlineDate {
            return true
        }
        return status == .expired
    }
    
    var effectiveStatus: InterviewStatus {
        if status == .pending && Date() > deadlineDate {
            return .expired
        }
        return status
    }
    
    var remainingTimeText: String {
        if effectiveStatus != .pending { return "" }
        let interval = deadlineDate.timeIntervalSince(Date())
        if interval <= 0 { return "Prazo de resposta expirado" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "Responda em até \(hours)h \(minutes)min"
        } else {
            return "Responda em até \(max(1, minutes)) min"
        }
    }
    
    static func == (lhs: InterviewAppointment, rhs: InterviewAppointment) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.scheduledDate == rhs.scheduledDate
    }
}

struct GoogleCalendarHelper {
    static func generateGoogleCalendarURL(appointment: InterviewAppointment) -> URL? {
        let title = "Entrevista EMBER: \(appointment.jobTitle) (\(appointment.companyName))"
        let details = """
        Entrevista de Emprego pelo App EMBER.
        Vaga: \(appointment.jobTitle)
        Empresa: \(appointment.companyName)
        Candidato: \(appointment.candidateName)
        Plataforma/Local: \(appointment.locationOrPlatform)
        Link: \(appointment.meetingLink)
        Observações: \(appointment.notes)
        """
        let location = appointment.meetingLink.isEmpty ? appointment.locationOrPlatform : appointment.meetingLink
        
        return createCalendarURL(
            title: title,
            details: details,
            location: location,
            startDate: appointment.scheduledDate,
            durationMinutes: appointment.durationMinutes
        )
    }
    
    static func createCalendarURL(
        title: String,
        details: String,
        location: String,
        startDate: Date,
        durationMinutes: Int = 45
    ) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let datesParam = "\(formatter.string(from: startDate))/\(formatter.string(from: endDate))"
        
        var components = URLComponents(string: "https://calendar.google.com/calendar/render")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "TEMPLATE"),
            URLQueryItem(name: "text", value: title),
            URLQueryItem(name: "details", value: details),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "dates", value: datesParam)
        ]
        return components?.url
    }
}

struct UserProfile: Identifiable, Equatable {
    let id: UUID
    var email: String
    var password: String
    var role: UserRole
    
    // Dados de Candidato (CPF)
    var name: String
    var cpf: String?
    var phone: String?         // NOVO: Telefone
    var address: String?       // NOVO: Residência
    var birthDate: String?
    var gender: Gender?
    var disability: DisabilityType?
    var disabilityDetails: String?
    var bio: String
    var skills: [String]
    var certificates: [String]
    var linkedInURL: String
    var pdfResumeName: String?
    
    // Disponibilidade de Agenda do Candidato (Turnos e Dias)
    var availableShifts: [WorkShift] = [.morning, .afternoon, .flexible]
    var availableDays: [String] = ["Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira"]
    
    // Dados de Empresa (CNPJ)
    var companyName: String?
    var tradeName: String?
    var cnpj: String?
    var industry: String?
    var companySize: CompanySize?
    var autoWelcomeMessage: String?
    var creationDate: String? // Data de criação/fundação ou cadastro
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
}

struct JobPosting: Identifiable, Equatable {
    let id: UUID
    let companyId: UUID
    let companyName: String
    let title: String
    let location: String
    var modality: String = "Remoto" // Remoto, Híbrido, Presencial
    var shift: WorkShift = .fullTime
    let description: String
    let requiredSkills: [String]
    var requirements: [String] = [] // Requisitos da vaga
    let salaryRange: String
    
    init(
        id: UUID = UUID(),
        companyId: UUID,
        companyName: String,
        title: String,
        location: String,
        modality: String = "Remoto",
        shift: WorkShift = .fullTime,
        description: String,
        requiredSkills: [String],
        requirements: [String] = [],
        salaryRange: String
    ) {
        self.id = id
        self.companyId = companyId
        self.companyName = companyName
        self.title = title
        self.location = location
        self.modality = modality
        self.shift = shift
        self.description = description
        self.requiredSkills = requiredSkills
        self.requirements = requirements
        self.salaryRange = salaryRange
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let senderId: UUID
    let text: String
    let timestamp: Date
}

struct MatchConversation: Identifiable, Equatable {
    let id: UUID
    let jobId: UUID
    let jobTitle: String
    let candidateId: UUID
    let candidateName: String
    let companyName: String
    var companyId: UUID? = nil
    var messages: [ChatMessage]
    
    var lastMessageText: String {
        messages.last?.text ?? "Match realizado! Inicie a conversa."
    }
}

func calculateCompatibility(candidateSkills: [String], certificates: [String], requiredSkills: [String]) -> Int {
    guard !requiredSkills.isEmpty else { return 100 }
    
    let candidatePool = Set(
        (candidateSkills + certificates)
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
    )
    
    let relatedSkillsMap: [String: Set<String>] = [
        "swift": ["ios", "swiftui", "uikit", "xcode", "mobile", "apple"],
        "swiftui": ["swift", "ios", "uikit", "mobile", "frontend"],
        "ios": ["swift", "swiftui", "xcode", "mobile", "apple"],
        "javascript": ["typescript", "react", "node", "frontend", "web", "html/css"],
        "react": ["javascript", "typescript", "frontend", "web"],
        "python": ["data science", "backend", "machine learning", "ia", "django"],
        "git": ["github", "gitlab", "ci/cd", "devops"],
        "sql": ["database", "mysql", "postgresql", "backend"],
        "lavar louca": ["limpeza", "serviços gerais", "cozinha", "higienização"],
        "passar pano": ["limpeza", "serviços gerais", "organização", "faxina"],
        "lava jato": ["lavagem", "detalhamento", "estética automotiva", "automotivo"]
    ]
    
    var matchedCount: Double = 0.0
    
    for req in requiredSkills {
        let reqClean = req.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if candidatePool.contains(reqClean) {
            matchedCount += 1.0
        } else {
            var foundRelated = false
            for item in candidatePool {
                if let relatedSet = relatedSkillsMap[item], relatedSet.contains(reqClean) {
                    matchedCount += 0.75
                    foundRelated = true
                    break
                }
            }
            if !foundRelated, let reqRelated = relatedSkillsMap[reqClean] {
                for item in candidatePool {
                    if reqRelated.contains(item) {
                        matchedCount += 0.75
                        break
                    }
                }
            }
        }
    }
    
    let percentage = Int((matchedCount / Double(requiredSkills.count)) * 100)
    return max(min(percentage, 100), 15)
}
