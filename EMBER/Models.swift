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
