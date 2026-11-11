import SwiftUI
import Combine

private enum JobDomain: CaseIterable {
    case operational, bad, medium, good
}

@MainActor
class JobTinderViewModel: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false
    
    @Published var jobs: [JobPosting] = []
    @Published var candidates: [UserProfile] = []
    @Published var companies: [UserProfile] = []
    
    @Published var likedJobsList: [JobPosting] = []
    @Published var candidateLikes: Set<UUID> = []
    @Published var companyLikes: [UUID: Set<UUID>] = [:]
    
    @Published var conversations: [MatchConversation] = []
    @Published var activeMatchNotification: (candidateName: String, jobTitle: String)? = nil
    @Published var appointments: [InterviewAppointment] = []
    
    init() {
        loadMockData()
    }
    
    func login(email: String, password: String, role: UserRole) -> Bool {
        if role == .candidate {
            if let candidate = candidates.first(where: { $0.email.lowercased() == email.lowercased() && $0.password == password }) {
                self.currentUser = candidate
                self.isAuthenticated = true
                sortJobsByRelevance()
                return true
            }
        } else {
            if let company = companies.first(where: { $0.email.lowercased() == email.lowercased() && $0.password == password }) {
                self.currentUser = company
                self.isAuthenticated = true
                return true
            }
        }
        return false
    }
    
    func registerCandidate(
        name: String, email: String, password: String, cpf: String, phone: String, address: String,
        birthDate: String, gender: Gender, disability: DisabilityType,
        disabilityDetails: String, bio: String, skills: String,
        certificates: String, linkedin: String
    ) {
        let skillsArray = skills.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let certsArray = certificates.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let newCandidate = UserProfile(
            id: UUID(), email: email, password: password, role: .candidate, name: name,
            cpf: cpf, phone: phone, address: address, birthDate: birthDate, gender: gender,
            disability: disability, disabilityDetails: disabilityDetails.isEmpty ? nil : disabilityDetails,
            bio: bio, skills: skillsArray, certificates: certsArray, linkedInURL: linkedin
        )
        candidates.append(newCandidate)
        self.currentUser = newCandidate
        self.isAuthenticated = true
        
        generateRandomJobs(count: 8)
        sortJobsByRelevance()
    }
    
    func registerCompany(
        companyName: String, tradeName: String, email: String, password: String,
        cnpj: String, phone: String, address: String, industry: String, companySize: CompanySize,
        bio: String, website: String, welcomeMessage: String
    ) {
        let newCompany = UserProfile(
            id: UUID(), email: email, password: password, role: .company,
            name: tradeName.isEmpty ? companyName : tradeName,
            phone: phone, address: address,
            bio: bio, skills: [], certificates: [], linkedInURL: website,
            companyName: companyName, tradeName: tradeName, cnpj: cnpj,
            industry: industry, companySize: companySize, autoWelcomeMessage: welcomeMessage
        )
        companies.append(newCompany)
        self.currentUser = newCompany
        self.isAuthenticated = true
    }
    
    func updateAutoWelcomeMessage(_ message: String) {
        currentUser?.autoWelcomeMessage = message
    }
    
    func sortJobsByRelevance() {
        guard let user = currentUser, user.role == .candidate else { return }
        jobs.sort { j1, j2 in
            let score1 = calculateCompatibility(candidateSkills: user.skills, certificates: user.certificates, requiredSkills: j1.requiredSkills)
            let score2 = calculateCompatibility(candidateSkills: user.skills, certificates: user.certificates, requiredSkills: j2.requiredSkills)
            return score1 > score2
        }
    }
    
    func swipeJob(job: JobPosting, liked: Bool) {
        guard let candidate = currentUser, candidate.role == .candidate else { return }
        
        if liked {
            candidateLikes.insert(job.id)
            if !likedJobsList.contains(where: { $0.id == job.id }) { likedJobsList.append(job) }
            
            let companyAlreadyLiked = companyLikes[job.id]?.contains(candidate.id) ?? false
            let compatibility = calculateCompatibility(
                candidateSkills: candidate.skills, certificates: candidate.certificates, requiredSkills: job.requiredSkills
            )
            
            let isRandomMatch = compatibility >= 30 && Int.random(in: 1...100) <= 35
            let isHighCompatibilityMatch = compatibility >= 65
            
            if companyAlreadyLiked || isRandomMatch || isHighCompatibilityMatch {
                companyLikes[job.id, default: []].insert(candidate.id)
                createConversationIfNeeded(candidate: candidate, job: job)
                triggerMatch(candidateName: candidate.name, jobTitle: job.title)
            }
        }
        
        jobs.removeAll { $0.id == job.id }
        if jobs.count < 3 { generateRandomJobs(count: 6) }
    }
    
    func swipeCandidate(candidate: UserProfile, job: JobPosting, liked: Bool) {
        if liked {
            companyLikes[job.id, default: []].insert(candidate.id)
            if candidateLikes.contains(job.id) {
                createConversationIfNeeded(candidate: candidate, job: job)
                triggerMatch(candidateName: candidate.name, jobTitle: job.title)
            }
        }
        candidates.removeAll { $0.id == candidate.id }
    }
    
    func sendMessage(conversationId: UUID, text: String) {
        guard let currentUser = currentUser, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            let newMessage = ChatMessage(id: UUID(), senderId: currentUser.id, text: text, timestamp: Date())
            conversations[index].messages.append(newMessage)
        }
    }
    
    private func createConversationIfNeeded(candidate: UserProfile, job: JobPosting) {
        let exists = conversations.contains { $0.jobId == job.id && $0.candidateId == candidate.id }
        if !exists {
            let companyWelcomeText = currentUser?.autoWelcomeMessage ?? "Olá \(candidate.name)! Vimos seu perfil e adoramos suas competências para a vaga de \(job.title)."
            let newConv = MatchConversation(
                id: UUID(), jobId: job.id, jobTitle: job.title, candidateId: candidate.id,
                candidateName: candidate.name, companyName: job.companyName, companyId: job.companyId,
                messages: [ChatMessage(id: UUID(), senderId: job.companyId, text: companyWelcomeText, timestamp: Date())]
            )
            conversations.append(newConv)
        }
    }
    
    // MARK: - Gerenciamento de Habilidades (Skills)
    func addSkill(_ skill: String) {
        let clean = skill.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        if currentUser?.skills.contains(where: { $0.caseInsensitiveCompare(clean) == .orderedSame }) == false {
            currentUser?.skills.append(clean)
            if let idx = candidates.firstIndex(where: { $0.id == currentUser?.id }) {
                candidates[idx].skills = currentUser?.skills ?? []
            }
            sortJobsByRelevance()
        }
    }
    
    func removeSkill(at offsets: IndexSet) {
        currentUser?.skills.remove(atOffsets: offsets)
        if let idx = candidates.firstIndex(where: { $0.id == currentUser?.id }) {
            candidates[idx].skills = currentUser?.skills ?? []
        }
        sortJobsByRelevance()
    }
    
    // MARK: - Edição de Perfil de Candidato
    func updateCandidateProfile(
        name: String,
        phone: String,
        address: String,
        birthDate: String,
        gender: Gender,
        disability: DisabilityType,
        disabilityDetails: String,
        bio: String,
        linkedin: String
    ) {
        guard var user = currentUser else { return }
        user.name = name
        user.phone = phone
        user.address = address
        user.birthDate = birthDate
        user.gender = gender
        user.disability = disability
        user.disabilityDetails = disabilityDetails.isEmpty ? nil : disabilityDetails
        user.bio = bio
        user.linkedInURL = linkedin
        
        self.currentUser = user
        if let idx = candidates.firstIndex(where: { $0.id == user.id }) {
            candidates[idx] = user
        }
        sortJobsByRelevance()
    }
    
    // MARK: - Edição de Perfil de Empresa
    func updateCompanyProfile(
        companyName: String,
        tradeName: String,
        phone: String,
        address: String,
        industry: String,
        companySize: CompanySize,
        bio: String,
        website: String
    ) {
        guard var user = currentUser else { return }
        user.companyName = companyName
        user.tradeName = tradeName
        user.name = tradeName.isEmpty ? companyName : tradeName
        user.phone = phone
        user.address = address
        user.industry = industry
        user.companySize = companySize
        user.bio = bio
        user.linkedInURL = website
        
        self.currentUser = user
        if let idx = companies.firstIndex(where: { $0.id == user.id }) {
            companies[idx] = user
        }
    }
    
    // MARK: - Gerenciamento de Certificados (Upload e Exclusão)
    func addCertificate(_ cert: String) {
        let clean = cert.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        if currentUser?.certificates.contains(where: { $0.caseInsensitiveCompare(clean) == .orderedSame }) == false {
            currentUser?.certificates.append(clean)
            sortJobsByRelevance()
        }
    }
    
    func removeCertificate(at offsets: IndexSet) {
        currentUser?.certificates.remove(atOffsets: offsets)
        sortJobsByRelevance()
    }
    
    func removeLikedJob(id: UUID) {
        likedJobsList.removeAll { $0.id == id }
        candidateLikes.remove(id)
    }
    
    func getCompany(by id: UUID?) -> UserProfile? {
        guard let id = id else { return nil }
        return companies.first { $0.id == id }
    }
    
    func getCompany(byName name: String) -> UserProfile? {
        return companies.first { 
            ($0.tradeName?.caseInsensitiveCompare(name) == .orderedSame) ||
            ($0.companyName?.caseInsensitiveCompare(name) == .orderedSame) ||
            ($0.name.caseInsensitiveCompare(name) == .orderedSame)
        }
    }
    
    func getCandidate(by id: UUID?) -> UserProfile? {
        guard let id = id else { return nil }
        return candidates.first { $0.id == id }
    }
    
    // MARK: - Gestão de Agenda & Entrevistas
    
    /// Verifica se há sobreposição de horário na agenda do candidato
    func hasScheduleConflict(candidateId: UUID, targetDate: Date, durationMinutes: Int = 45) -> (hasConflict: Bool, conflictingTitle: String?) {
        let newStart = targetDate
        let newEnd = targetDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        
        for appt in appointments where appt.candidateId == candidateId && (appt.status == .confirmed || appt.status == .pending) {
            let apptStart = appt.scheduledDate
            let apptEnd = appt.scheduledDate.addingTimeInterval(TimeInterval(appt.durationMinutes * 60))
            
            // Sobreposição de intervalos
            if max(newStart, apptStart) < min(newEnd, apptEnd) {
                return (true, appt.jobTitle)
            }
        }
        return (false, nil)
    }
    
    /// Verifica se o turno da vaga conflita com a disponibilidade do candidato
    func hasShiftConflict(candidate: UserProfile, job: JobPosting) -> Bool {
        if candidate.availableShifts.contains(.flexible) { return false }
        return !candidate.availableShifts.contains(job.shift)
    }
    
    /// Agendar nova entrevista com prazo de resposta para evitar empresas esperando no vácuo
    func scheduleInterview(
        conversationId: UUID?,
        jobId: UUID,
        jobTitle: String,
        companyId: UUID,
        companyName: String,
        candidateId: UUID,
        candidateName: String,
        date: Date,
        durationMinutes: Int = 45,
        locationOrPlatform: String = "Google Meet",
        meetingLink: String = "https://meet.google.com/ember-interview",
        notes: String = "",
        deadlineHours: Int = 24
    ) -> (success: Bool, message: String) {
        let conflict = hasScheduleConflict(candidateId: candidateId, targetDate: date, durationMinutes: durationMinutes)
        if conflict.hasConflict {
            return (false, "Conflito de agenda! O candidato já possui outro compromisso (\(conflict.conflictingTitle ?? "")) nesse horário.")
        }
        
        let deadline = Date().addingTimeInterval(TimeInterval(deadlineHours * 3600))
        let newAppointment = InterviewAppointment(
            id: UUID(),
            conversationId: conversationId,
            jobId: jobId,
            jobTitle: jobTitle,
            companyId: companyId,
            companyName: companyName,
            candidateId: candidateId,
            candidateName: candidateName,
            scheduledDate: date,
            durationMinutes: durationMinutes,
            meetingLink: meetingLink,
            locationOrPlatform: locationOrPlatform,
            notes: notes,
            status: .pending,
            deadlineDate: deadline,
            createdAt: Date()
        )
        
        appointments.append(newAppointment)
        
        // Mensagem automática no chat vinculado
        let targetConvId = conversationId ?? conversations.first(where: { $0.jobId == jobId && $0.candidateId == candidateId })?.id
        if let convId = targetConvId {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "pt_BR")
            let dateStr = formatter.string(from: date)
            
            let inviteText = "📅 Convite para Entrevista: \(dateStr) (\(durationMinutes) min) via \(locationOrPlatform). Por favor, confirme na aba Agenda em até \(deadlineHours) horas para garantir sua vaga!"
            sendMessage(conversationId: convId, text: inviteText)
        }
        
        return (true, "Convite enviado com sucesso! Prazo de resposta: \(deadlineHours)h.")
    }
    
    /// Candidato confirma o horário da entrevista
    func acceptInterview(appointmentId: UUID) {
        guard let index = appointments.firstIndex(where: { $0.id == appointmentId }) else { return }
        appointments[index].status = .confirmed
        
        let appt = appointments[index]
        let targetConvId = appt.conversationId ?? conversations.first(where: { $0.jobId == appt.jobId && $0.candidateId == appt.candidateId })?.id
        if let convId = targetConvId {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "pt_BR")
            sendMessage(conversationId: convId, text: "✅ Entrevista confirmada para \(formatter.string(from: appt.scheduledDate))! Compromisso salvo na agenda.")
        }
    }
    
    /// Recusa de entrevista (Candidato ou Empresa)
    func declineInterview(appointmentId: UUID, reason: String? = nil) {
        guard let index = appointments.firstIndex(where: { $0.id == appointmentId }) else { return }
        appointments[index].status = .declined
        
        let appt = appointments[index]
        let targetConvId = appt.conversationId ?? conversations.first(where: { $0.jobId == appt.jobId && $0.candidateId == appt.candidateId })?.id
        if let convId = targetConvId {
            let reasonText = (reason != nil && !reason!.isEmpty) ? " Motivo: \(reason!)" : ""
            sendMessage(conversationId: convId, text: "❌ O convite de entrevista para \(appt.jobTitle) foi recusado.\(reasonText) O horário foi liberado na agenda da empresa.")
        }
    }
    
    /// Atualiza os turnos e dias de disponibilidade do candidato
    func updateCandidateAvailability(shifts: [WorkShift], days: [String]) {
        guard var user = currentUser else { return }
        user.availableShifts = shifts
        user.availableDays = days
        self.currentUser = user
        if let idx = candidates.firstIndex(where: { $0.id == user.id }) {
            candidates[idx] = user
        }
    }
    
    /// Verifica e expira automaticamente entrevistas cujo prazo passou
    func checkAndExpireAppointments() {
        let now = Date()
        for i in appointments.indices {
            if appointments[i].status == .pending && now > appointments[i].deadlineDate {
                appointments[i].status = .expired
                
                let appt = appointments[i]
                let targetConvId = appt.conversationId ?? conversations.first(where: { $0.jobId == appt.jobId && $0.candidateId == appt.candidateId })?.id
                if let convId = targetConvId {
                    sendMessage(conversationId: convId, text: "⚠️ O prazo de resposta para a entrevista de \(appt.jobTitle) expirou. O horário foi liberado para outros candidatos.")
                }
            }
        }
    }
    
    func addJob(
        title: String,
        location: String,
        modality: String = "Remoto",
        description: String,
        requirements: String,
        salary: String
    ) {
        guard let company = currentUser, company.role == .company else { return }
        let reqArray = requirements.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let newJob = JobPosting(
            id: UUID(),
            companyId: company.id,
            companyName: company.tradeName ?? company.companyName ?? company.name,
            title: title,
            location: location,
            modality: modality,
            description: description,
            requiredSkills: reqArray,
            requirements: reqArray,
            salaryRange: salary
        )
        jobs.append(newJob)
        sortJobsByRelevance()
    }
    
    func generateRandomJobs(count: Int = 10) {
        var newJobs: [JobPosting] = []
        let mockCompanyId = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        
        let skillJobTemplates: [(keywords: [String], title: String, company: String, desc: String, reqs: [String], salary: String)] = [
            (["swift", "ios", "xcode", "apple", "swiftui"], "Desenvolvedor iOS Pleno", "Tech Solutions S.A.", "Buscamos desenvolvedor focado em ecossistema Apple.", ["Swift", "SwiftUI", "Git"], "R$ 6.500 - R$ 9.000"),
            (["python", "dados", "machine learning", "ia", "sql"], "Engenheiro de Dados", "DataCorp Analytics", "Construção de pipelines de dados avançados.", ["Python", "SQL", "Pandas"], "R$ 7.000 - R$ 11.000"),
            (["react", "javascript", "html", "css", "frontend", "web"], "Desenvolvedor Frontend", "Agência Digital Web", "Desenvolvimento de interfaces responsivas.", ["JavaScript", "React", "CSS3"], "R$ 4.500 - R$ 7.000"),
            (["design", "figma", "ui", "ux", "photoshop"], "Product Designer (UI/UX)", "Creative Studio", "Prototipação e pesquisa de usabilidade.", ["Figma", "UI/UX"], "R$ 5.000 - R$ 8.000"),
            (["vendas", "comercial", "negociação", "atendimento"], "Executivo de Vendas (SDR)", "SalesTech B2B", "Prospecção de clientes e gestão de funil.", ["Comunicação", "Negociação"], "R$ 3.000 + Comissão"),
            (["limpeza", "passar pano", "serviços gerais", "organização", "faxina"], "Auxiliar de Limpeza", "Grupo LimpMais", "Conservação e higienização diária.", ["Organização", "Proatividade"], "R$ 1.800 - R$ 2.200 + VA"),
            (["cozinha", "lavar louca", "louça", "comida", "culinária"], "Auxiliar de Cozinha", "Restaurante Central Grill", "Apoio no preparo e higienização de utensílios.", ["Higiene", "Agilidade"], "R$ 1.900 - R$ 2.400"),
            (["carro", "lava jato", "mecânica", "veículo", "automotiva"], "Estética Automotiva", "Auto Premium Center", "Lavagem detalhada e polimento técnico.", ["Cuidado", "Pontualidade"], "R$ 2.000 - R$ 3.000")
        ]
        
        var generatedDynamicTitles = Set<String>()
        var dynamicJobsCount = 0
        
        if let candidateSkills = currentUser?.skills, !candidateSkills.isEmpty {
            for skill in candidateSkills {
                let cleanSkill = skill.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if let match = skillJobTemplates.first(where: { template in template.keywords.contains { cleanSkill.contains($0) } }) {
                    if !generatedDynamicTitles.contains(match.title) {
                        let dynamicJob = JobPosting(id: UUID(), companyId: mockCompanyId, companyName: match.company, title: match.title, location: "Presencial / Híbrido", description: match.desc, requiredSkills: match.reqs, salaryRange: match.salary)
                        newJobs.append(dynamicJob)
                        generatedDynamicTitles.insert(match.title)
                        dynamicJobsCount += 1
                    }
                }
            }
        }
        
        let remainingCount = count - dynamicJobsCount
        
        if remainingCount > 0 {
            let opTitles = ["Auxiliar de Serviços Gerais", "Operador de Atendimento", "Auxiliar Administrativo"]
            let opCompanies = ["Prestadora Integrada", "CallCenter Brasil", "Escritórios Associados"]
            let opLocations = ["Presencial - Centro", "Escala 5x2 - Comercial"]
            let opDescriptions = ["Rotinas administrativas.", "Suporte direto ao cliente, atendimento."]
            let opSkills = [["Organização", "Pacote Office"], ["Atendimento", "Comunicação"]]
            let opSalaries = ["R$ 1.800 - R$ 2.400 + VT", "R$ 2.100 (CLT)"]
            
            let badTitles = ["Digitador de Dados", "Estagiário Administrativo"]
            let badCompanies = ["Consultoria Alpha", "Startup Beta"]
            let badLocations = ["Presencial 6x1", "Presencial"]
            let badDescriptions = ["Inserção contínua de dados em sistema.", "Primeiro contato para suporte."]
            let badSkills = [["Excel", "Digitação"], ["Windows"]]
            let badSalaries = ["R$ 1.412 (CLT)", "R$ 1.000 (Bolsa)"]

            let mediumTitles = ["Analista de TI Junior", "Dev Web Frontend"]
            let mediumCompanies = ["Inovação Digital", "Soft House Regional"]
            let mediumLocations = ["Híbrido - Santa Maria", "Híbrido - Porto Alegre"]
            let mediumDescriptions = ["Projetos de integração de APIs.", "Testes manuais e web."]
            let mediumSkills = [["JavaScript", "HTML/CSS"], ["QA", "Lógica"]]
            let mediumSalaries = ["R$ 3.000 - R$ 4.500", "R$ 3.500 (CLT)"]

            for _ in 0..<remainingCount {
                let domain = JobDomain.allCases.randomElement()!
                let newJob: JobPosting
                
                switch domain {
                case .operational:
                    newJob = JobPosting(
                        id: UUID(), companyId: mockCompanyId, companyName: opCompanies.randomElement()!,
                        title: opTitles.randomElement()!, location: opLocations.randomElement()!,
                        description: opDescriptions.randomElement()!, requiredSkills: opSkills.randomElement()!,
                        salaryRange: opSalaries.randomElement()!
                    )
                case .bad:
                    newJob = JobPosting(
                        id: UUID(), companyId: mockCompanyId, companyName: badCompanies.randomElement()!,
                        title: badTitles.randomElement()!, location: badLocations.randomElement()!,
                        description: badDescriptions.randomElement()!, requiredSkills: badSkills.randomElement()!,
                        salaryRange: badSalaries.randomElement()!
                    )
                case .medium:
                    newJob = JobPosting(
                        id: UUID(), companyId: mockCompanyId, companyName: mediumCompanies.randomElement()!,
                        title: mediumTitles.randomElement()!, location: mediumLocations.randomElement()!,
                        description: mediumDescriptions.randomElement()!, requiredSkills: mediumSkills.randomElement()!,
                        salaryRange: mediumSalaries.randomElement()!
                    )
                case .good:
                    newJob = JobPosting(
                        id: UUID(), companyId: mockCompanyId, companyName: "Global Tech",
                        title: "Tech Lead", location: "Remoto",
                        description: "Vaga Senior de liderança.", requiredSkills: ["Gestão", "Cloud"],
                        salaryRange: "R$ 15.000"
                    )
                }
                newJobs.append(newJob)
            }
        }
        self.jobs.append(contentsOf: newJobs)
        sortJobsByRelevance()
    }
    
    private func triggerMatch(candidateName: String, jobTitle: String) {
        activeMatchNotification = (candidateName: candidateName, jobTitle: jobTitle)
    }
    
    private func loadMockData() {
        // MARK: - 1. Empresas Simuladas com Dados Detalhados
        let companyIdNuTech = UUID(uuidString: "11111111-2222-3333-4444-555555555551")!
        let companyIdCocoa = UUID(uuidString: "11111111-2222-3333-4444-555555555552")!
        let companyIdCloud = UUID(uuidString: "11111111-2222-3333-4444-555555555553")!
        let companyIdMercado = UUID(uuidString: "11111111-2222-3333-4444-555555555554")!
        let companyIdInova = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let companyIdPixel = UUID(uuidString: "11111111-2222-3333-4444-555555555556")!
        
        let mockCompanies: [UserProfile] = [
            UserProfile(
                id: companyIdCocoa,
                email: "jobs@cocoaapps.io",
                password: "123",
                role: .company,
                name: "Cocoa Apps Studio",
                phone: "+55 (11) 99871-2233",
                address: "Alameda Santos, 1800 - Cerqueira César, São Paulo - SP",
                bio: "Estúdio de excelência técnica e visual especializado no ecossistema Apple (iOS, iPadOS, macOS, visionOS). Vencedores de prêmios Apple Design Award com foco em SwiftUI, fluidez e arquitetura limpa.",
                skills: [],
                certificates: [],
                linkedInURL: "https://cocoaapps.io",
                companyName: "Cocoa Apps Desenvolvimento de Software Ltda.",
                tradeName: "Cocoa Apps Studio",
                cnpj: "25.109.840/0001-32",
                industry: "Mobile Development & Design",
                companySize: .medium,
                autoWelcomeMessage: "Olá! Vimos seu perfil e adoramos seu interesse em fazer parte do nosso time de desenvolvedores iOS!",
                creationDate: "12/08/2017"
            ),
            UserProfile(
                id: companyIdNuTech,
                email: "carreiras@nutech.com.br",
                password: "123",
                role: .company,
                name: "NuTech Solutions",
                phone: "+55 (11) 4004-0101",
                address: "Av. Brigadeiro Faria Lima, 3477 - Itaim Bibi, São Paulo - SP",
                bio: "Pioneira em tecnologia financeira com mais de 80 milhões de usuários diários. Nossa cultura preza por simplicidade, segurança rigorosa e engenharia de software de altíssima escala.",
                skills: [],
                certificates: [],
                linkedInURL: "https://nutech.com.br",
                companyName: "Nu Pagamentos e Tecnologia S.A.",
                tradeName: "NuTech Solutions",
                cnpj: "18.236.120/0001-58",
                industry: "Fintech & Serviços Financeiros",
                companySize: .enterprise,
                autoWelcomeMessage: "Parabéns pelo Match! Adoramos suas competências técnicas e gostaríamos de te convidar para o processo.",
                creationDate: "06/05/2013"
            ),
            UserProfile(
                id: companyIdCloud,
                email: "vagas@cloudscale.net",
                password: "123",
                role: .company,
                name: "CloudScale",
                phone: "+55 (21) 3254-8899",
                address: "Praia de Botafogo, 300 - Botafogo, Rio de Janeiro - RJ",
                bio: "Consultoria e engenharia de infraestrutura em nuvem, microsserviços, Kubernetes, segurança distribuída e automação multicloud (AWS, Azure e GCP).",
                skills: [],
                certificates: [],
                linkedInURL: "https://cloudscale.net",
                companyName: "CloudScale Infraestrutura em Nuvem Ltda.",
                tradeName: "CloudScale",
                cnpj: "33.445.556/0001-77",
                industry: "Computação em Nuvem e DevOps",
                companySize: .small,
                autoWelcomeMessage: "Match confirmado! Sua experiência com infraestrutura e tecnologia chamou nossa atenção.",
                creationDate: "22/11/2019"
            ),
            UserProfile(
                id: companyIdMercado,
                email: "talentos@mercadoglobal.com",
                password: "123",
                role: .company,
                name: "Mercado Global",
                phone: "+55 (11) 3003-9090",
                address: "Av. das Nações Unidas, 12901 - Brooklin, São Paulo - SP",
                bio: "O ecossistema líder de compras online, logística inteligente e soluções de checkout na América Latina. Conectamos milhões de pessoas e empreendedores todos os dias.",
                skills: [],
                certificates: [],
                linkedInURL: "https://mercadoglobal.com",
                companyName: "Mercado Global Varejo Digital S.A.",
                tradeName: "Mercado Global",
                cnpj: "03.007.331/0001-41",
                industry: "E-Commerce & Logística",
                companySize: .enterprise,
                autoWelcomeMessage: "Olá! Recebemos seu match com muito entusiasmo. Quando podemos conversar sobre nossa vaga?",
                creationDate: "14/02/2010"
            ),
            UserProfile(
                id: companyIdInova,
                email: "contato@inovadata.ai",
                password: "123",
                role: .company,
                name: "InovaData AI",
                phone: "+55 (31) 98452-1100",
                address: "R. Paraíba, 550 - Savassi, Belo Horizonte - MG",
                bio: "Laboratório de pesquisa e aplicação prática de Inteligência Artificial Generativa, modelos preditivos em larga escala e ciência de dados moderna.",
                skills: [],
                certificates: [],
                linkedInURL: "https://inovadata.ai",
                companyName: "InovaData Ciência de Dados Ltda.",
                tradeName: "InovaData AI",
                cnpj: "45.890.123/0001-05",
                industry: "Inteligência Artificial & Big Data",
                companySize: .startup,
                autoWelcomeMessage: "Olá! Vimos seu interesse e achamos seu perfil alinhado com nossos desafios de IA e dados.",
                creationDate: "01/04/2022"
            ),
            UserProfile(
                id: companyIdPixel,
                email: "hello@studiopixel.design",
                password: "123",
                role: .company,
                name: "Studio Pixel",
                phone: "+55 (41) 99123-4567",
                address: "Av. Sete de Setembro, 4200 - Batel, Curitiba - PR",
                bio: "Estúdio premiado de design digital e estratégia de produto. Projetamos experiências humanas, acessíveis e memoráveis em mobile e web.",
                skills: [],
                certificates: [],
                linkedInURL: "https://studiopixel.design",
                companyName: "Pixel Design & Consultoria Ltda.",
                tradeName: "Studio Pixel",
                cnpj: "38.990.111/0001-90",
                industry: "Design de Produto & UI/UX",
                companySize: .startup,
                autoWelcomeMessage: "Seja bem-vindo ao Studio Pixel! Amamos seu perfil e gostaríamos de ver mais do seu trabalho.",
                creationDate: "10/10/2020"
            )
        ]
        
        self.companies = mockCompanies
        
        // MARK: - 2. Candidato Mock Inicial (Thiago Mikael)
        let mockCandidateId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let mockCandidate = UserProfile(
            id: mockCandidateId,
            email: "thiago@example.com",
            password: "123",
            role: .candidate,
            name: "Thiago Mikael",
            cpf: "012.345.678-90",
            phone: "+55 (55) 99712-3456",
            address: "Santa Maria - RS",
            birthDate: "15/05/2005",
            gender: .male,
            disability: .none,
            bio: "Estudante e Desenvolvedor focado no ecossistema Apple (Swift & SwiftUI). Apaixonado por criar interfaces fluidas, arquitetura limpa e soluções elegantes.",
            skills: ["Swift", "SwiftUI", "Git", "iOS", "Xcode"],
            certificates: ["Apple Developer Academy", "Certificação de Especialista SwiftUI"],
            linkedInURL: "https://www.linkedin.com/in/thiago-mikael-copetti-dos-santos",
            pdfResumeName: "Curriculo_Thiago_Mikael.pdf"
        )
        self.candidates = [mockCandidate]
        
        // MARK: - 3. Vagas Simuladas Detalhadas
        let job1 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0001-0001-0001-000000000001")!,
            companyId: companyIdCocoa,
            companyName: "Cocoa Apps Studio",
            title: "Desenvolvedor iOS SwiftUI Júnior / Pleno",
            location: "Remoto (Brasil)",
            modality: "Remoto",
            description: "Buscamos um desenvolvedor apaixonado pelo ecossistema Apple para criar interfaces fluidas, responsivas e modernas com SwiftUI e Swift Concurrency.",
            requiredSkills: ["Swift", "SwiftUI", "Git", "iOS", "Xcode"],
            requirements: [
                "Experiência prática com Swift e SwiftUI moderno",
                "Domínio do padrão arquitetural MVVM e injeção de dependências",
                "Consumo e serialização de APIs REST com URLSession / Codable",
                "Versionamento de código utilizando Git e GitHub",
                "Certificados na área ou apps publicados na App Store são diferenciais"
            ],
            salaryRange: "R$ 6.500 - R$ 9.000 (CLT)"
        )
        
        let job2 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0002-0002-0002-000000000002")!,
            companyId: companyIdNuTech,
            companyName: "NuTech Solutions",
            title: "Engenheiro de Software iOS Senior",
            location: "São Paulo - SP (Faria Lima)",
            modality: "Híbrido",
            description: "Lidere a concepção técnica de novas funcionalidades de pagamentos globais, garantindo alta performance, segurança bancária e cobertura completa de testes unitários.",
            requiredSkills: ["Swift", "iOS", "CI/CD", "Clean Architecture", "Unit Tests"],
            requirements: [
                "Sólida experiência com desenvolvimento iOS nativo em larga escala",
                "Domínio de testes unitários (XCTest) e testes de interface",
                "Experiência com pipelines de CI/CD (Fastlane / GitHub Actions)",
                "Atenção rigorosa a acessibilidade (VoiceOver, Dynamic Type)",
                "Graduação em Ciência da Computação ou experiência equivalente"
            ],
            salaryRange: "R$ 13.000 - R$ 17.500 (CLT)"
        )
        
        let job3 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0003-0003-0003-000000000003")!,
            companyId: companyIdMercado,
            companyName: "Mercado Global",
            title: "Desenvolvedor Frontend React & TypeScript",
            location: "São Paulo - SP (Brooklin)",
            modality: "Híbrido",
            description: "Construção de aplicações web de altíssimo tráfego com foco em otimização de tempo de carregamento, SEO e componentização escalável.",
            requiredSkills: ["React", "TypeScript", "JavaScript", "HTML/CSS", "Next.js"],
            requirements: [
                "Experiência com React moderno (Hooks, Context, SSR com Next.js)",
                "Domínio de TypeScript e integração com APIs REST e GraphQL",
                "Foco em performance web (Core Web Vitals) e responsividade",
                "Vivência em times ágeis usando Scrum ou Kanban"
            ],
            salaryRange: "R$ 6.000 - R$ 8.500 (CLT)"
        )
        
        let job4 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0004-0004-0004-000000000004")!,
            companyId: companyIdInova,
            companyName: "InovaData AI",
            title: "Engenheiro de Dados & Machine Learning",
            location: "Belo Horizonte - MG",
            modality: "Remoto",
            description: "Desenvolvimento de pipelines de dados em tempo real e implantação de modelos de aprendizado de máquina em ambientes de produção de alta confiabilidade.",
            requiredSkills: ["Python", "SQL", "Machine Learning", "Data Science", "Pandas"],
            requirements: [
                "Proficiência sólida em Python e modelagem de dados SQL",
                "Vivência com frameworks de ML/Data (Pandas, Scikit-Learn, PyTorch)",
                "Conhecimento de arquiteturas de dados distribuídos (Spark ou Kafka)",
                "Certificações em Cloud ou Data Science valorizadas"
            ],
            salaryRange: "R$ 8.500 - R$ 12.000 (PJ)"
        )
        
        let job5 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0005-0005-0005-000000000005")!,
            companyId: companyIdCloud,
            companyName: "CloudScale",
            title: "DevOps & Cloud Engineer",
            location: "Rio de Janeiro - RJ",
            modality: "Remoto",
            description: "Projetar, orquestrar e monitorar infraestruturas multicloud escaláveis e resilientes para clientes corporativos de grande porte.",
            requiredSkills: ["AWS", "Docker", "Kubernetes", "Git", "CI/CD"],
            requirements: [
                "Experiência comprovada em serviços AWS (EKS, EC2, VPC, IAM)",
                "Automação e infraestrutura como código com Terraform",
                "Gerenciamento de containers e esteiras de entrega contínua",
                "Conhecimento em monitoramento com Prometheus e Grafana"
            ],
            salaryRange: "R$ 9.000 - R$ 13.500 (CLT)"
        )
        
        let job6 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0006-0006-0006-000000000006")!,
            companyId: companyIdPixel,
            companyName: "Studio Pixel",
            title: "Product Designer (UI/UX Pleno)",
            location: "Curitiba - PR",
            modality: "Remoto",
            description: "Conduzir pesquisas de discovery, criar protótipos de alta fidelidade e manter a consistência estética do Design System para aplicativos mobile e web.",
            requiredSkills: ["Figma", "UI/UX", "Design System", "Prototipagem"],
            requirements: [
                "Portfólio consistente com projetos mobile (iOS/Android) e web",
                "Domínio avançado de Figma (Auto Layout, Design Tokens e Variáveis)",
                "Experiência na realização de testes de usabilidade e entrevistas",
                "Capacidade de colaborar ativamente com desenvolvedores frontend e mobile"
            ],
            salaryRange: "R$ 6.000 - R$ 8.500 (CLT)"
        )
        
        let job7 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0007-0007-0007-000000000007")!,
            companyId: companyIdCocoa,
            companyName: "Cocoa Apps Studio",
            title: "Analista de Qualidade e QA Mobile",
            location: "São Paulo - SP",
            modality: "Híbrido",
            description: "Garantir a estabilidade e usabilidade impecável de nossos apps através de testes automatizados e manuais, homologando builds antes do envio à App Store.",
            requiredSkills: ["QA", "Testes Automatizados", "Git", "XCTest", "Postman"],
            requirements: [
                "Experiência na elaboração de planos de teste e casos de teste regressivos",
                "Conhecimento em ferramentas de automação para testes mobile",
                "Familiaridade com o ciclo de validação do TestFlight e App Store Connect",
                "Boa escrita técnica para reporte de bugs e evidências"
            ],
            salaryRange: "R$ 5.000 - R$ 7.200 (CLT)"
        )
        
        let job8 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0008-0008-0008-000000000008")!,
            companyId: companyIdMercado,
            companyName: "Mercado Global",
            title: "Executivo de Vendas & Contas (SDR B2B)",
            location: "São Paulo - SP (Centro)",
            modality: "Presencial",
            description: "Prospectar e qualificar novos parceiros comerciais estratégicos, conduzindo apresentações de soluções e negociando termos de adesão.",
            requiredSkills: ["Comunicação", "Vendas", "Negociação", "CRM"],
            requirements: [
                "Vivência em vendas consultivas B2B ou prospecção ativa de clientes",
                "Excelente comunicação interpessoal e oratória clara",
                "Familiaridade com ferramentas de CRM (HubSpot, Salesforce)",
                "Resiliência, proatividade e foco no atingimento de metas"
            ],
            salaryRange: "R$ 3.500 + Comissão (Média R$ 7.000)"
        )
        
        let job9 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0009-0009-0009-000000000009")!,
            companyId: companyIdNuTech,
            companyName: "NuTech Solutions",
            title: "Estágio em Desenvolvimento Mobile / iOS",
            location: "São Paulo - SP",
            modality: "Híbrido",
            description: "Programa de desenvolvimento acelerado para estudantes que querem ingressar no desenvolvimento de software de alta performance com mentoria dedicada.",
            requiredSkills: ["Lógica de Programação", "Swift", "Git"],
            requirements: [
                "Matriculado em curso superior de TI, Engenharia ou cursos correlatos",
                "Conhecimento teórico em lógica de programação e orientação a objetos",
                "Interesse genuíno em Swift e ecossistema Apple",
                "Disponibilidade para estagiar 30h semanais"
            ],
            salaryRange: "R$ 2.400 (Bolsa) + VR + VT + Seguro"
        )
        
        let job10 = JobPosting(
            id: UUID(uuidString: "aaaaaaaa-0010-0010-0010-000000000010")!,
            companyId: companyIdCloud,
            companyName: "CloudScale",
            title: "Auxiliar Administrativo e Operações",
            location: "Rio de Janeiro - RJ (Botafogo)",
            modality: "Presencial",
            description: "Suporte administrativo à equipe executiva, controle de documentações contratuais, emissão de notas fiscais e organização de suprimentos.",
            requiredSkills: ["Pacote Office", "Excel", "Organização", "Comunicação"],
            requirements: [
                "Ensino Médio completo ou Superior em andamento",
                "Bons conhecimentos em planilhas eletrônicas (Excel / Google Sheets)",
                "Capacidade de organização e pontualidade",
                "Facilidade para lidar com prazos e rotinas administrativas"
            ],
            salaryRange: "R$ 2.200 - R$ 2.800 (CLT) + Benefícios"
        )
        
        self.jobs = [job1, job2, job3, job4, job5, job6, job7, job8, job9, job10]
        
        // MARK: - 4. Mock Inicial de Curtidas e Conversa no Chat para Demonstração Imediata
        self.candidateLikes.insert(job1.id)
        self.candidateLikes.insert(job2.id)
        self.likedJobsList = [job1, job2]
        
        self.companyLikes[job1.id] = [mockCandidateId]
        
        let initialChat = MatchConversation(
            id: UUID(uuidString: "cccccccc-1111-2222-3333-444444444444")!,
            jobId: job1.id,
            jobTitle: job1.title,
            candidateId: mockCandidateId,
            candidateName: mockCandidate.name,
            companyName: job1.companyName,
            companyId: job1.companyId,
            messages: [
                ChatMessage(
                    id: UUID(),
                    senderId: job1.companyId,
                    text: "Olá Thiago! Vimos que você curtiu a vaga de \(job1.title). Seu perfil com Swift e SwiftUI deu match perfeito conosco! Quando você teria disponibilidade para bater um papo?",
                    timestamp: Date().addingTimeInterval(-3600)
                ),
                ChatMessage(
                    id: UUID(),
                    senderId: mockCandidateId,
                    text: "Olá! Fico muito feliz com a oportunidade. Tenho total disponibilidade nesta quinta ou sexta no período da tarde!",
                    timestamp: Date().addingTimeInterval(-1800)
                )
            ]
        )
        self.conversations = [initialChat]
        
        // MARK: - 5. Mock Inicial de Entrevistas na Agenda (com Google Agenda e SLA de Resposta)
        let calendar = Calendar.current
        let tomorrow14h30 = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date().addingTimeInterval(86400)) ?? Date().addingTimeInterval(86400)
        let in3Days10h = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date().addingTimeInterval(86400 * 3)) ?? Date().addingTimeInterval(86400 * 3)
        
        let initialAppt1 = InterviewAppointment(
            id: UUID(uuidString: "dddddddd-1111-2222-3333-444444444441")!,
            conversationId: initialChat.id,
            jobId: job1.id,
            jobTitle: job1.title,
            companyId: companyIdCocoa,
            companyName: "Cocoa Apps Studio",
            candidateId: mockCandidateId,
            candidateName: mockCandidate.name,
            scheduledDate: tomorrow14h30,
            durationMinutes: 45,
            meetingLink: "https://meet.google.com/ember-cocoa-swiftui",
            locationOrPlatform: "Google Meet",
            notes: "Alinhamento técnico e apresentação do time de iOS.",
            status: .pending,
            deadlineDate: Date().addingTimeInterval(3600 * 20), // 20 horas restantes
            createdAt: Date().addingTimeInterval(-3600 * 4)
        )
        
        let initialAppt2 = InterviewAppointment(
            id: UUID(uuidString: "dddddddd-1111-2222-3333-444444444442")!,
            conversationId: nil,
            jobId: job2.id,
            jobTitle: job2.title,
            companyId: companyIdNuTech,
            companyName: "NuTech Solutions",
            candidateId: mockCandidateId,
            candidateName: mockCandidate.name,
            scheduledDate: in3Days10h,
            durationMinutes: 60,
            meetingLink: "https://meet.google.com/nutech-swift-tech",
            locationOrPlatform: "Google Meet",
            notes: "Entrevista com Tech Lead e Gestor de Engenharia.",
            status: .confirmed,
            deadlineDate: Date().addingTimeInterval(-3600),
            createdAt: Date().addingTimeInterval(-86400)
        )
        
        self.appointments = [initialAppt1, initialAppt2]
        
        sortJobsByRelevance()
    }
}
