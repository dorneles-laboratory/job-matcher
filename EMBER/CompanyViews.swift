import SwiftUI

struct CompanyMainTabView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    
    var body: some View {
        TabView {
            CompanyCandidateSwipeView()
                .tabItem { Label("Candidatos", systemImage: "person.2.fill") }
            
            CompanyJobsManagementView()
                .tabItem { Label("Minhas Vagas", systemImage: "doc.badge.plus") }
            
            AgendaView()
                .tabItem { Label("Agenda", systemImage: "calendar") }
            
            CompanyProfileView()
                .tabItem { Label("Empresa", systemImage: "building.2.fill") }
        }
        .accentColor(.appPurple)
    }
}

enum CandidateViewMode: String, CaseIterable, Identifiable {
    case explore = "Explorar Talentos"
    case swipe = "Triagem (Cards)"
    var id: String { rawValue }
}

enum CandidateFilter: String, CaseIterable, Identifiable {
    case all = "Todos"
    case liked = "💖 Curtiram a Vaga"
    case highCompatibility = "⚡️ Alta Compatibilidade"
    case pcd = "♿️ PCD"
    case mobile = "📱 iOS / Mobile"
    case data = "📊 Dados / Python"
    case web = "🌐 Frontend / Web"
    case sales = "🤝 Vendas / Negócios"
    
    var id: String { rawValue }
}

struct CompanyCandidateSwipeView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    
    @State private var selectedJobId: UUID? = nil
    @State private var viewMode: CandidateViewMode = .explore
    @State private var searchText = ""
    @State private var selectedFilter: CandidateFilter = .all
    @State private var selectedCandidateForDetail: UserProfile? = nil
    @State private var showCreateJobModal = false
    @State private var showChatSheet = false
    
    var companyJobs: [JobPosting] {
        let list = vm.jobs.filter { $0.companyId == vm.currentUser?.id }
        return list.isEmpty ? vm.jobs : list
    }
    
    var activeJob: JobPosting? {
        if let id = selectedJobId, let found = companyJobs.first(where: { $0.id == id }) {
            return found
        }
        return companyJobs.first
    }
    
    // Candidatos filtrados para a busca/exploração
    var filteredCandidates: [UserProfile] {
        guard let job = activeJob else { return vm.candidates }
        
        return vm.candidates.filter { candidate in
            // Filtro por texto de busca
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesQuery: Bool
            if query.isEmpty {
                matchesQuery = true
            } else {
                let nameMatch = candidate.name.lowercased().contains(query)
                let skillMatch = candidate.skills.contains { $0.lowercased().contains(query) }
                let bioMatch = candidate.bio.lowercased().contains(query)
                let locMatch = (candidate.address ?? "").lowercased().contains(query)
                let certMatch = candidate.certificates.contains { $0.lowercased().contains(query) }
                matchesQuery = nameMatch || skillMatch || bioMatch || locMatch || certMatch
            }
            
            guard matchesQuery else { return false }
            
            // Filtro por categoria
            switch selectedFilter {
            case .all:
                return true
            case .liked:
                return vm.candidateLikesByCandidate[candidate.id]?.contains(job.id) ?? false
            case .highCompatibility:
                let score = calculateCompatibility(
                    candidateSkills: candidate.skills,
                    certificates: candidate.certificates,
                    requiredSkills: job.requiredSkills
                )
                return score >= 65
            case .pcd:
                return candidate.disability != nil && candidate.disability != .none
            case .mobile:
                return candidate.skills.contains { s in
                    ["swift", "swiftui", "ios", "xcode", "mobile"].contains(s.lowercased())
                }
            case .data:
                return candidate.skills.contains { s in
                    ["python", "sql", "pandas", "data", "dados", "machine learning"].contains(s.lowercased())
                }
            case .web:
                return candidate.skills.contains { s in
                    ["react", "javascript", "typescript", "html", "css", "next.js", "frontend"].contains(s.lowercased())
                }
            case .sales:
                return candidate.skills.contains { s in
                    ["vendas", "comunicação", "crm", "negociação", "comercial"].contains(s.lowercased())
                }
            }
        }
        .sorted { c1, c2 in
            // Ordena candidatos que já curtiram no topo, e depois por compatibilidade
            let c1Liked = vm.candidateLikesByCandidate[c1.id]?.contains(job.id) ?? false
            let c2Liked = vm.candidateLikesByCandidate[c2.id]?.contains(job.id) ?? false
            if c1Liked != c2Liked { return c1Liked && !c2Liked }
            
            let s1 = calculateCompatibility(candidateSkills: c1.skills, certificates: c1.certificates, requiredSkills: job.requiredSkills)
            let s2 = calculateCompatibility(candidateSkills: c2.skills, certificates: c2.certificates, requiredSkills: job.requiredSkills)
            return s1 > s2
        }
    }
    
    // Candidatos pendentes na fila de swipe
    var pendingSwipeCandidates: [UserProfile] {
        guard let job = activeJob else { return [] }
        let evaluated = vm.companyEvaluatedCandidates[job.id] ?? []
        return vm.candidates.filter { !evaluated.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barra de Seleção da Vaga Alvo
                activeJobHeaderView
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                // Seletor de Modo (Explorar Talentos vs Triagem)
                Picker("Visualização", selection: $viewMode) {
                    ForEach(CandidateViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Conteúdo Principal
                if viewMode == .explore {
                    exploreTalentsView
                } else {
                    swipeTriagemView
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Candidatos & Talentos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: {
                            withAnimation {
                                vm.generateRandomCandidates(count: 6)
                            }
                        }) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.appPurple)
                        }
                        
                        TopBarChatButton {
                            showChatSheet = true
                        }
                    }
                }
            }
            .sheet(item: $selectedCandidateForDetail) { candidate in
                if let job = activeJob {
                    CandidateDetailSheetView(candidate: candidate, targetJob: job)
                }
            }
            .sheet(isPresented: $showCreateJobModal) {
                CreateJobView()
            }
            .sheet(isPresented: $showChatSheet) {
                ChatListView()
            }
        }
    }
    
    // MARK: - Cabeçalho com Menu de Escolha da Vaga
    private var activeJobHeaderView: some View {
        Group {
            if let job = activeJob {
                Menu {
                    Section("Suas Vagas Abertas") {
                        ForEach(companyJobs) { j in
                            Button(action: { selectedJobId = j.id }) {
                                HStack {
                                    Text(j.title)
                                    if j.id == job.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    
                    Section {
                        Button(action: { showCreateJobModal = true }) {
                            Label("Criar Nova Vaga", systemImage: "plus.circle")
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.appPurple.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.appPurple)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("VAGA ATIVA PARA BUSCA:")
                                    .font(.caption2).bold()
                                    .foregroundColor(.secondary)
                                Text("(\(job.modality))")
                                    .font(.caption2)
                                    .foregroundColor(.appPurple)
                            }
                            Text(job.title)
                                .font(.subheadline).bold()
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appPurple.opacity(0.25), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - 1. MODO: EXPLORAR BANCO DE TALENTOS (Busca e Filtros)
    private var exploreTalentsView: some View {
        VStack(spacing: 10) {
            // Barra de Pesquisa
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Buscar por nome, habilidade (ex: Swift, React, Python)...", text: $searchText)
                    .font(.subheadline)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Pílulas de Filtro Rápido
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CandidateFilter.allCases) { filter in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = filter
                            }
                        }) {
                            Text(filter.rawValue)
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedFilter == filter ? Color.appPurple : Color(UIColor.secondarySystemGroupedBackground))
                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                .cornerRadius(16)
                                .overlay(
                                    Capsule()
                                        .stroke(selectedFilter == filter ? Color.clear : Color(UIColor.systemGray4).opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 2)
            }
            
            // Contador de Resultados
            HStack {
                Text("\(filteredCandidates.count) candidato\(filteredCandidates.count == 1 ? "" : "s") encontrado\(filteredCandidates.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Ordenado por relevância")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 2)
            
            // Lista de Candidatos
            if filteredCandidates.isEmpty {
                emptyTalentsSearchView
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredCandidates) { candidate in
                            if let job = activeJob {
                                ExploreCandidateRowCard(
                                    candidate: candidate,
                                    targetJob: job,
                                    onViewDetail: { selectedCandidateForDetail = candidate }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private var emptyTalentsSearchView: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 30)
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 55))
                .foregroundColor(.appSilver)
            
            Text("Nenhum candidato encontrado")
                .font(.headline)
            
            Text("Nenhum talento corresponde ao termo \"\(searchText)\" ou ao filtro selecionado. Tente outros termos como Swift, Python, Dados, ou limpe a busca.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Button("Gerar Mais Candidatos de Teste") {
                withAnimation {
                    vm.generateRandomCandidates(count: 6)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.appPurple)
            .padding(.top, 4)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 2. MODO: TRIAGEM RÁPIDA (SWIPE CARDS)
    private var swipeTriagemView: some View {
        ZStack {
            if pendingSwipeCandidates.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 65))
                        .foregroundColor(.appPurple)
                    
                    Text("Triagem Concluída!")
                        .font(.title3).bold()
                    
                    Text("Você já avaliou todos os candidatos disponíveis para esta vaga.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    HStack(spacing: 12) {
                        if let job = activeJob {
                            Button("Reiniciar Triagem") {
                                withAnimation {
                                    vm.resetEvaluatedCandidates(for: job.id)
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.appPurple)
                        }
                        
                        Button("Buscar Novos Talentos") {
                            withAnimation {
                                vm.generateRandomCandidates(count: 6)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.appPurple)
                    }
                    .padding(.top, 6)
                }
                .padding()
            } else if let job = activeJob {
                ForEach(pendingSwipeCandidates.reversed()) { candidate in
                    CandidateCardView(candidate: candidate, targetJob: job)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Card em Linha para a Busca e Exploração de Candidatos
struct ExploreCandidateRowCard: View {
    @EnvironmentObject var vm: JobTinderViewModel
    let candidate: UserProfile
    let targetJob: JobPosting
    let onViewDetail: () -> Void
    
    var compatibility: Int {
        calculateCompatibility(
            candidateSkills: candidate.skills,
            certificates: candidate.certificates,
            requiredSkills: targetJob.requiredSkills
        )
    }
    
    var isMatched: Bool {
        vm.conversations.contains { $0.jobId == targetJob.id && $0.candidateId == candidate.id }
    }
    
    var candidateAlreadyLiked: Bool {
        vm.candidateLikesByCandidate[candidate.id]?.contains(targetJob.id) ?? false
    }
    
    var companyAlreadyLiked: Bool {
        vm.companyLikes[targetJob.id]?.contains(candidate.id) ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header do Card: Avatar, Nome, Local e Compatibilidade
            HStack(alignment: .top, spacing: 12) {
                // Avatar com Iniciais
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPurple, Color.appPurple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Text(candidateInitials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(candidate.name)
                            .font(.headline)
                            .bold()
                            .foregroundColor(.primary)
                        
                        if candidate.disability != nil && candidate.disability != .none {
                            Text(candidate.disability?.rawValue ?? "PCD")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(candidate.address ?? "Brasil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                CompatibilityBadge(percentage: compatibility)
            }
            
            // Status de Interesse / Match
            if isMatched {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("MATCH MÚTUO CONFIRMADO! 💬")
                        .font(.caption).bold()
                }
                .foregroundColor(.appPurple)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.appPurple.opacity(0.12))
                .cornerRadius(8)
            } else if candidateAlreadyLiked {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Demonstrou interesse na sua vaga! 💖 (Curta para Match imediato)")
                        .font(.caption2).bold()
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.red.opacity(0.12))
                .cornerRadius(8)
            } else if companyAlreadyLiked {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                    Text("Interesse enviado pela empresa • Aguardando o candidato")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(8)
            }
            
            // Resumo da Bio
            if !candidate.bio.isEmpty {
                Text(candidate.bio)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Habilidades em Chips (com destaque para as que dão match com a vaga!)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(candidate.skills, id: \.self) { skill in
                        let matchesJobReq = targetJob.requiredSkills.contains { req in
                            req.caseInsensitiveCompare(skill) == .orderedSame ||
                            skill.lowercased().contains(req.lowercased()) ||
                            req.lowercased().contains(skill.lowercased())
                        }
                        
                        HStack(spacing: 3) {
                            if matchesJobReq {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                            }
                            Text(skill)
                                .font(.caption2)
                                .bold()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(matchesJobReq ? Color.appPurple.opacity(0.18) : Color(UIColor.systemGray5))
                        .foregroundColor(matchesJobReq ? .appPurple : .primary)
                        .cornerRadius(6)
                    }
                }
            }
            
            Divider()
            
            // Barra Inferior de Ação
            HStack {
                Button(action: onViewDetail) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.text.rectangle")
                        Text("Ver Perfil Completo")
                    }
                    .font(.caption).bold()
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                if isMatched {
                    NavigationLink(destination: ChatListView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Abrir Chat")
                        }
                        .font(.caption).bold()
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.appPurple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    Button(action: {
                        withAnimation {
                            vm.swipeCandidate(candidate: candidate, job: targetJob, liked: true)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: candidateAlreadyLiked ? "heart.circle.fill" : "hand.thumbsup.fill")
                            Text(candidateAlreadyLiked ? "Dar Match 💖" : (companyAlreadyLiked ? "Interesse Enviado" : "Curtir Candidato"))
                        }
                        .font(.caption).bold()
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(companyAlreadyLiked ? Color.gray.opacity(0.3) : Color.appPurple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(companyAlreadyLiked)
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private var candidateInitials: String {
        let parts = candidate.name.split(separator: " ")
        if let first = parts.first, let last = parts.last, parts.count > 1 {
            return "\(first.prefix(1))\(last.prefix(1))".uppercased()
        }
        return String(candidate.name.prefix(2)).uppercased()
    }
}

// MARK: - Modal de Detalhes Completos do Candidato (CandidateDetailSheetView)
struct CandidateDetailSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: JobTinderViewModel
    
    let candidate: UserProfile
    let targetJob: JobPosting
    @State private var showScheduleModal = false
    
    var compatibility: Int {
        calculateCompatibility(
            candidateSkills: candidate.skills,
            certificates: candidate.certificates,
            requiredSkills: targetJob.requiredSkills
        )
    }
    
    var isMatched: Bool {
        vm.conversations.contains { $0.jobId == targetJob.id && $0.candidateId == candidate.id }
    }
    
    var candidateAlreadyLiked: Bool {
        vm.candidateLikesByCandidate[candidate.id]?.contains(targetJob.id) ?? false
    }
    
    var companyAlreadyLiked: Bool {
        vm.companyLikes[targetJob.id]?.contains(candidate.id) ?? false
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header com Iniciais e Dados Principais
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.appPurple, Color.appPurple.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 76, height: 76)
                                .shadow(color: Color.appPurple.opacity(0.3), radius: 10, x: 0, y: 4)
                            
                            Text(String(candidate.name.prefix(2)).uppercased())
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(candidate.name)
                                .font(.title3).bold()
                            
                            Text(candidate.address ?? "Localização não informada")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Badge de Compatibilidade com a Vaga
                        HStack(spacing: 8) {
                            CompatibilityBadge(percentage: compatibility)
                            Text("de compatibilidade com a vaga \"\(targetJob.title)\"")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    .padding(.top, 10)
                    
                    // Card de Status do Match
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STATUS DO MATCH")
                            .font(.caption2).bold().foregroundColor(.secondary)
                        
                        if isMatched {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundColor(.appPurple)
                                Text("Match Mútuo Realizado! Vocês já podem conversar.")
                                    .font(.subheadline).bold()
                            }
                        } else if candidateAlreadyLiked {
                            HStack {
                                Image(systemName: "heart.fill").foregroundColor(.red)
                                Text("Este candidato já curtiu esta vaga! Ao curtir de volta, o match será gerado imediatamente.")
                                    .font(.caption).foregroundColor(.red)
                            }
                        } else {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath").foregroundColor(.secondary)
                                Text("O candidato ainda não visualizou esta vaga. Ao demonstrar interesse, seu convite ficará registrado para o candidato.")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Dados Pessoais & Contato
                    VStack(alignment: .leading, spacing: 12) {
                        Text("INFORMAÇÕES DE CONTATO")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        if let phone = candidate.phone, !phone.isEmpty {
                            HStack {
                                Image(systemName: "phone.fill").foregroundColor(.green)
                                Text(phone).font(.subheadline)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "envelope.fill").foregroundColor(.appPurple)
                            Text(candidate.email).font(.subheadline)
                        }
                        
                        if let birth = candidate.birthDate, !birth.isEmpty {
                            HStack {
                                Image(systemName: "calendar").foregroundColor(.orange)
                                Text("Nascimento: \(birth)").font(.subheadline)
                            }
                        }
                        
                        if let dis = candidate.disability, dis != .none {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "accessibility").foregroundColor(.blue)
                                    Text("Condição PCD: \(dis.rawValue)").font(.subheadline).bold()
                                }
                                if let det = candidate.disabilityDetails, !det.isEmpty {
                                    Text("Necessidades: \(det)")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    
                    // Resumo Profissional / Bio
                    VStack(alignment: .leading, spacing: 10) {
                        Text("RESUMO PROFISSIONAL")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        Text(candidate.bio.isEmpty ? "Candidato não preencheu resumo." : candidate.bio)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    
                    // Habilidades
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HABILIDADES (\(candidate.skills.count))")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(candidate.skills, id: \.self) { skill in
                                    Text(skill)
                                        .font(.caption).bold()
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Color.appPurple.opacity(0.15))
                                        .foregroundColor(.appPurple)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    
                    // Certificados
                    if !candidate.certificates.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CERTIFICADOS (\(candidate.certificates.count))")
                                .font(.caption2).bold().foregroundColor(.orange)
                            
                            ForEach(candidate.certificates, id: \.self) { cert in
                                HStack {
                                    Image(systemName: "rosette").foregroundColor(.orange)
                                    Text(cert).font(.subheadline)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    
                    // Links Externos (LinkedIn & PDF)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DOCUMENTOS E LINKS")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        if !candidate.linkedInURL.isEmpty {
                            Link(destination: URL(string: candidate.linkedInURL) ?? URL(string: "https://linkedin.com")!) {
                                HStack {
                                    Image(systemName: "link").foregroundColor(.appPurple)
                                    Text("Ver Perfil no LinkedIn").bold()
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .font(.subheadline)
                                .foregroundColor(.appPurple)
                            }
                        }
                        
                        if let pdf = candidate.pdfResumeName {
                            HStack {
                                Image(systemName: "doc.richtext.fill").foregroundColor(.red)
                                Text("Currículo em PDF: \(pdf)").font(.subheadline)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Detalhes do Talento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Barra de Ação Fixa Inferior
                HStack(spacing: 12) {
                    if isMatched {
                        NavigationLink(destination: ChatListView()) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Abrir Chat")
                            }
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appPurple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            withAnimation {
                                vm.swipeCandidate(candidate: candidate, job: targetJob, liked: true)
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: candidateAlreadyLiked ? "heart.fill" : "hand.thumbsup.fill")
                                Text(candidateAlreadyLiked ? "Confirmar Match Agora! 💖" : "Demonstrar Interesse 👍")
                            }
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appPurple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground).shadow(radius: 4))
            }
        }
    }
}

struct CandidateCardView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    let candidate: UserProfile
    let targetJob: JobPosting
    @State private var offset = CGSize.zero
    
    var compatibility: Int {
        calculateCompatibility(
            candidateSkills: candidate.skills,
            certificates: candidate.certificates,
            requiredSkills: targetJob.requiredSkills
        )
    }
    
    var candidateAlreadyLiked: Bool {
        vm.candidateLikesByCandidate[candidate.id]?.contains(targetJob.id) ?? false
    }
    
    private var likeOpacity: Double {
        let val = Double((offset.width - 20) / 70)
        return min(max(val, 0), 1)
    }
    
    private var passOpacity: Double {
        let val = Double((-offset.width - 20) / 70)
        return min(max(val, 0), 1)
    }
    
    private var borderStrokeColor: Color {
        if offset.width > 20 {
            let op = min(Double(abs(offset.width) / 100), 0.85)
            return Color.green.opacity(op)
        } else if offset.width < -20 {
            let op = min(Double(abs(offset.width) / 100), 0.85)
            return Color.red.opacity(op)
        } else {
            return Color.clear
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 8)
            
            VStack(alignment: .leading, spacing: 12) {
                // Header com Nome e Badges
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.name).font(.title2).bold()
                        Text("CPF: \(candidate.cpf ?? "Não informado")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    CompatibilityBadge(percentage: compatibility)
                }
                
                // Badge se o candidato já curtiu esta vaga
                if candidateAlreadyLiked {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("Demonstrou interesse nesta vaga! (Match garantido ao curtir)")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(8)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("O Match só será concluído se o candidato também curtir")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                }
                
                HStack(spacing: 12) {
                    if let gender = candidate.gender {
                        Label(gender.rawValue, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let dis = candidate.disability, dis != .none {
                        Text(dis.rawValue)
                            .font(.caption2).bold()
                            .padding(4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
                
                Text(candidate.bio).font(.body).foregroundColor(.secondary)
                
                Divider()
                
                Text("Skills:").font(.subheadline).bold()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(candidate.skills, id: \.self) { skill in
                            Text(skill)
                                .font(.caption)
                                .padding(8)
                                .background(Color.appPurple.opacity(0.15))
                                .foregroundColor(.appPurple)
                                .cornerRadius(8)
                        }
                    }
                }
                
                if !candidate.certificates.isEmpty {
                    Text("Certificados:").font(.subheadline).bold()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(candidate.certificates, id: \.self) { cert in
                                Label(cert, systemImage: "rosette")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    if !candidate.linkedInURL.isEmpty {
                        Link(destination: URL(string: candidate.linkedInURL) ?? URL(string: "https://linkedin.com")!) {
                            Label("Ver LinkedIn", systemImage: "link")
                                .font(.subheadline)
                                .foregroundColor(.appPurple)
                        }
                    }
                    
                    if let pdf = candidate.pdfResumeName {
                        Label("PDF: \(pdf)", systemImage: "doc.fill")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 40) {
                    Button(action: { swipe(liked: false) }) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .resizable().frame(width: 50, height: 50).foregroundColor(.red)
                    }
                    Button(action: { swipe(liked: true) }) {
                        Image(systemName: "hand.thumbsup.fill")
                            .resizable().frame(width: 50, height: 50).foregroundColor(.appPurple)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            
            // MARK: - RETORNO VISUAL AO ARRASTAR CANDIDATO
            if offset.width > 20 {
                VStack {
                    HStack {
                        Text(candidateAlreadyLiked ? "MATCH! ✨" : "CURTIR 👍")
                            .font(.title2).bold()
                            .foregroundColor(.green)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 3)
                            )
                            .rotationEffect(.degrees(-15))
                            .opacity(likeOpacity)
                            .scaleEffect(0.9 + CGFloat(likeOpacity) * 0.2)
                            .padding(24)
                        Spacer()
                    }
                    Spacer()
                }
            }
            
            if offset.width < -20 {
                VStack {
                    HStack {
                        Spacer()
                        Text("DESCARTAR ✕")
                            .font(.title2).bold()
                            .foregroundColor(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 3)
                            )
                            .rotationEffect(.degrees(15))
                            .opacity(passOpacity)
                            .scaleEffect(0.9 + CGFloat(passOpacity) * 0.2)
                            .padding(24)
                    }
                    Spacer()
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderStrokeColor, lineWidth: 3)
        )
        .padding()
        .offset(x: offset.width, y: offset.height * 0.3)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .gesture(
            DragGesture()
                .onChanged { g in offset = g.translation }
                .onEnded { _ in
                    if offset.width > 120 { swipe(liked: true) }
                    else if offset.width < -120 { swipe(liked: false) }
                    else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            offset = .zero
                        }
                    }
                }
        )
    }
    
    private func swipe(liked: Bool) {
        withAnimation {
            vm.swipeCandidate(candidate: candidate, job: targetJob, liked: liked)
        }
    }
}

struct CompanyJobsManagementView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @State private var showCreateJobModal = false
    @State private var showChatSheet = false
    
    var body: some View {
        NavigationView {
            List(vm.jobs) { job in
                VStack(alignment: .leading) {
                    Text(job.title).font(.headline)
                    Text(job.location).font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Vagas Publicadas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: { showCreateJobModal = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.appPurple)
                        }
                        
                        TopBarChatButton {
                            showChatSheet = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateJobModal) {
                CreateJobView()
            }
            .sheet(isPresented: $showChatSheet) {
                ChatListView()
            }
        }
    }
}

struct CreateJobView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var vm: JobTinderViewModel
    
    @State private var title = ""
    @State private var location = ""
    @State private var modality = "Remoto"
    @State private var description = ""
    @State private var requiredSkillTags: [String] = []
    @State private var salary = ""
    
    let modalityOptions = ["Remoto", "Híbrido", "Presencial"]
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Informações Básicas
                    VStack(alignment: .leading, spacing: 14) {
                        Text("INFORMAÇÕES DA VAGA")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        EmberTextField(
                            title: "TÍTULO DA VAGA",
                            placeholder: "ex: Desenvolvedor iOS Pleno",
                            text: $title,
                            icon: "briefcase.fill",
                            isRequired: true,
                            autocapitalization: .words
                        )
                        
                        EmberTextField(
                            title: "LOCALIZAÇÃO",
                            placeholder: "ex: São Paulo - SP ou Brasil (Remoto)",
                            text: $location,
                            icon: "mappin.and.ellipse",
                            isRequired: true,
                            autocapitalization: .words
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MODALIDADE DE TRABALHO")
                                .font(.caption).bold().foregroundColor(.secondary)
                            
                            Picker("Modalidade", selection: $modality) {
                                ForEach(modalityOptions, id: \.self) { mod in
                                    Text(mod).tag(mod)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        EmberTextField(
                            title: "FAIXA SALARIAL",
                            placeholder: "ex: R$ 6.500 - R$ 9.000 (CLT)",
                            text: $salary,
                            icon: "banknote.fill"
                        )
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    
                    // Requisitos & Habilidades
                    VStack(alignment: .leading, spacing: 14) {
                        Text("REQUISITOS & COMPETÊNCIAS EXIGIDAS")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        SkillTagInputView(
                            title: "HABILIDADES NECESSÁRIAS",
                            placeholder: "Digite o requisito (ex: SwiftUI, Git)",
                            tags: $requiredSkillTags,
                            suggestions: ["Swift", "SwiftUI", "iOS", "Git", "Clean Architecture", "Python", "SQL", "React", "Comunicação", "Figma"],
                            isRequired: true
                        )
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    
                    // Descrição Completa
                    VStack(alignment: .leading, spacing: 14) {
                        Text("DETALHES DA OPORTUNIDADE")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        EmberTextEditor(
                            title: "DESCRIÇÃO DA VAGA",
                            placeholder: "Descreva as principais responsabilidades, benefícios, desafios e diferenciais da oportunidade...",
                            text: $description,
                            icon: "text.alignleft",
                            isRequired: true,
                            minHeight: 120
                        )
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Criar Nova Vaga")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    let canPublish = !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                                     !location.trimmingCharacters(in: .whitespaces).isEmpty &&
                                     !requiredSkillTags.isEmpty
                    
                    Button("Publicar") {
                        let requirementsString = requiredSkillTags.joined(separator: ", ")
                        vm.addJob(
                            title: title,
                            location: location,
                            modality: modality,
                            description: description,
                            requirements: requirementsString,
                            salary: salary
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                    .bold()
                    .foregroundColor(canPublish ? .appPurple : .gray)
                    .disabled(!canPublish)
                }
            }
        }
    }
}

struct CompanyProfileView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @State private var autoMessage: String = ""
    @State private var showSaveAlert = false
    @State private var showEditCompanySheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button(action: { showEditCompanySheet = true }) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.appPurple.opacity(0.15))
                                    .frame(width: 42, height: 42)
                                Image(systemName: "pencil")
                                    .font(.headline)
                                    .foregroundColor(.appPurple)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Editar Informações da Empresa")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Alterar razão social, nome fantasia, telefone, sede e bio")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Dados da Empresa")) {
                    Text(vm.currentUser?.tradeName ?? vm.currentUser?.companyName ?? vm.currentUser?.name ?? "Empresa").font(.title2).bold()
                    
                    if let legal = vm.currentUser?.companyName, legal != vm.currentUser?.tradeName {
                        Text("Razão Social: \(legal)").font(.caption).foregroundColor(.secondary)
                    }
                    
                    Text("CNPJ: \(vm.currentUser?.cnpj ?? "Não informado")").foregroundColor(.secondary)
                    
                    if let phone = vm.currentUser?.phone, !phone.isEmpty {
                        HStack {
                            Text("Telefone:").bold()
                            Text(phone)
                        }
                    }
                    
                    if let addr = vm.currentUser?.address, !addr.isEmpty {
                        HStack {
                            Text("Sede:").bold()
                            Text(addr)
                        }
                    }
                    
                    if let ind = vm.currentUser?.industry, !ind.isEmpty {
                        Text("Setor: \(ind)").font(.subheadline)
                    }
                    if let size = vm.currentUser?.companySize {
                        Text("Porte: \(size.rawValue)").font(.subheadline)
                    }
                    
                    Text(vm.currentUser?.email ?? "").foregroundColor(.secondary)
                    
                    if let bio = vm.currentUser?.bio, !bio.isEmpty {
                        Text(bio).font(.subheadline)
                    }
                }
                
                Section(
                    header: Text("Mensagem Automática de Match"),
                    footer: Text("Esta mensagem é enviada automaticamente ao candidato assim que um Match for realizado.")
                ) {
                    TextEditor(text: $autoMessage)
                        .frame(height: 100)
                    
                    Button(action: {
                        vm.updateAutoWelcomeMessage(autoMessage)
                        showSaveAlert = true
                    }) {
                        Label("Salvar Mensagem Automática", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.appPurple)
                            .bold()
                    }
                }
                
                Section {
                    Button("Sair da Conta", role: .destructive) {
                        vm.isAuthenticated = false
                    }
                }
            }
            .navigationTitle("Aba Empresa")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditCompanySheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Editar")
                        }
                        .font(.subheadline).bold()
                        .foregroundColor(.appPurple)
                    }
                }
            }
            .sheet(isPresented: $showEditCompanySheet) {
                EditCompanyProfileView()
            }
            .onAppear {
                autoMessage = vm.currentUser?.autoWelcomeMessage ?? "Olá! Vimos seu interesse na vaga e adoramos seu perfil. Como podemos avançar com seu processo seletivo?"
            }
            .alert("Mensagem Salva!", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A nova mensagem automática será enviada em todos os próximos Matches.")
            }
        }
    }
}

// MARK: - Tela de Edição de Perfil da Empresa
struct EditCompanyProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: JobTinderViewModel
    
    @State private var companyName: String = ""
    @State private var tradeName: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var industry: String = ""
    @State private var companySize: CompanySize = .small
    @State private var bio: String = ""
    @State private var website: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Identificação da Empresa
                    VStack(alignment: .leading, spacing: 14) {
                        Text("IDENTIFICAÇÃO DA EMPRESA")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        EmberTextField(
                            title: "RAZÃO SOCIAL",
                            placeholder: "Razão social cadastrada",
                            text: $companyName,
                            icon: "building.2.fill",
                            isRequired: true,
                            autocapitalization: .words
                        )
                        
                        EmberTextField(
                            title: "NOME FANTASIA (PÚBLICO)",
                            placeholder: "Nome exibido nas vagas",
                            text: $tradeName,
                            icon: "tag.fill",
                            autocapitalization: .words
                        )
                        
                        HStack(spacing: 12) {
                            EmberTextField(
                                title: "TELEFONE CORPORATIVO",
                                placeholder: "(00) 0000-0000",
                                text: $phone,
                                icon: "phone.fill",
                                keyboardType: .phonePad,
                                mask: InputMask.phone
                            )
                            
                            EmberTextField(
                                title: "SEDE (CIDADE - UF)",
                                placeholder: "ex: São Paulo - SP",
                                text: $address,
                                icon: "mappin.and.ellipse",
                                autocapitalization: .words
                            )
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    
                    // Segmento e Porte
                    VStack(alignment: .leading, spacing: 14) {
                        Text("SEGMENTO & PORTE")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        EmberTextField(
                            title: "RAMO / SETOR DE ATUAÇÃO",
                            placeholder: "ex: Tecnologia, Serviços Financeiros...",
                            text: $industry,
                            icon: "briefcase.fill",
                            autocapitalization: .words
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PORTE DA EMPRESA")
                                .font(.caption).bold().foregroundColor(.secondary)
                            
                            Picker("Porte da Empresa", selection: $companySize) {
                                ForEach(CompanySize.allCases) { size in
                                    Text(size.rawValue).tag(size)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    
                    // Descrição Institucional
                    VStack(alignment: .leading, spacing: 14) {
                        Text("SOBRE A ORGANIZAÇÃO")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        EmberTextEditor(
                            title: "DESCRIÇÃO INSTITUCIONAL (BIO)",
                            placeholder: "Conte sobre a história, valores, projetos e ambiente de trabalho da empresa...",
                            text: $bio,
                            icon: "text.quote",
                            minHeight: 110
                        )
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    
                    // Links
                    VStack(alignment: .leading, spacing: 14) {
                        Text("PÁGINA OU WEBSITE")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        EmberTextField(
                            title: "URL DO WEBSITE OU LINKEDIN",
                            placeholder: "https://suaempresa.com.br",
                            text: $website,
                            icon: "globe",
                            keyboardType: .URL,
                            autocapitalization: .never
                        )
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Editar Empresa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        vm.updateCompanyProfile(
                            companyName: companyName,
                            tradeName: tradeName,
                            phone: phone,
                            address: address,
                            industry: industry,
                            companySize: companySize,
                            bio: bio,
                            website: website
                        )
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(.appPurple)
                    .disabled(companyName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let user = vm.currentUser {
                    companyName = user.companyName ?? user.name
                    tradeName = user.tradeName ?? ""
                    phone = user.phone ?? ""
                    address = user.address ?? ""
                    industry = user.industry ?? ""
                    companySize = user.companySize ?? .small
                    bio = user.bio
                    website = user.linkedInURL
                }
            }
        }
    }
}
