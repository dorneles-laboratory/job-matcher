import SwiftUI
import UniformTypeIdentifiers

struct CandidateMainTabView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    
    var pendingAppointmentsCount: Int {
        guard let user = vm.currentUser else { return 0 }
        return vm.appointments.filter { $0.candidateId == user.id && $0.effectiveStatus == .pending }.count
    }
    
    var body: some View {
        TabView {
            CandidateSwipeView()
                .tabItem { Label("Vagas", systemImage: "flame.fill") }
            
            ExploreJobsView()
                .tabItem { Label("Explorar", systemImage: "magnifyingglass") }
            
            LikedJobsView()
                .tabItem { Label("Curtidas", systemImage: "heart.fill") }
            
            AgendaView()
                .tabItem {
                    Label(
                        "Agenda",
                        systemImage: pendingAppointmentsCount > 0 ? "calendar.badge.exclamationmark" : "calendar"
                    )
                }
                .badge(pendingAppointmentsCount)
            
            ChatListView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
            
            CandidateProfileView()
                .tabItem { Label("Pessoal", systemImage: "person.fill") }
        }
        .accentColor(.appPurple)
    }
}

struct LikedJobsView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if vm.likedJobsList.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.appSilver)
                        Text("Nenhuma vaga curtida ainda")
                            .font(.headline)
                        Text("Explore as vagas disponíveis e dê match nas suas favoritas!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(vm.likedJobsList) { job in
                                LikedJobCardView(job: job)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Vagas Curtidas")
        }
    }
}

// MARK: - Card Detalhado da Vaga Curtida
struct LikedJobCardView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    let job: JobPosting
    
    var compatibility: Int {
        calculateCompatibility(
            candidateSkills: vm.currentUser?.skills ?? [],
            certificates: vm.currentUser?.certificates ?? [],
            requiredSkills: job.requiredSkills
        )
    }
    
    var isMatched: Bool {
        vm.conversations.contains { $0.jobId == job.id && $0.candidateId == vm.currentUser?.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Cabeçalho com Badges (Compatibilidade + Modalidade + Status Match)
            HStack(alignment: .center, spacing: 8) {
                CompatibilityBadge(percentage: compatibility)
                
                // Badge de Modalidade
                HStack(spacing: 4) {
                    Image(systemName: modalityIcon(job.modality))
                    Text(job.modality)
                }
                .font(.caption).bold()
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(modalityColor(job.modality).opacity(0.15))
                .foregroundColor(modalityColor(job.modality))
                .cornerRadius(8)
                
                // Badge de Turno
                HStack(spacing: 4) {
                    Image(systemName: job.shift.icon)
                    Text(job.shift.shortName)
                }
                .font(.caption).bold()
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(Color.blue.opacity(0.12))
                .foregroundColor(.blue)
                .cornerRadius(8)
                
                Spacer()
                
                if let appt = vm.appointments.first(where: { $0.jobId == job.id && $0.candidateId == vm.currentUser?.id }) {
                    HStack(spacing: 4) {
                        Image(systemName: appt.effectiveStatus.icon)
                        Text(appt.effectiveStatus == .confirmed ? "Entrevista" : "Resposta Pendente")
                    }
                    .font(.caption2).bold()
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(appt.effectiveStatus.color.opacity(0.15))
                    .foregroundColor(appt.effectiveStatus.color)
                    .cornerRadius(8)
                } else if isMatched {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("MATCH! 💬")
                    }
                    .font(.caption).bold()
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.appPurple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            // Informações Principais da Vaga
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.appPurple)
                    Text(job.companyName)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                    Text(job.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Faixa Salarial
            HStack(spacing: 6) {
                Image(systemName: "banknote.fill")
                    .foregroundColor(.green)
                Text("Salário:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(job.salaryRange)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            
            Divider()
            
            // Seção de Habilidades Necessárias
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.appPurple)
                    Text("Habilidades Necessárias:")
                        .font(.caption).bold()
                        .foregroundColor(.secondary)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(job.requiredSkills, id: \.self) { skill in
                            let userHasSkill = (vm.currentUser?.skills ?? []).contains {
                                $0.caseInsensitiveCompare(skill) == .orderedSame
                            }
                            HStack(spacing: 4) {
                                if userHasSkill {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                }
                                Text(skill)
                                    .font(.caption)
                                    .bold()
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(userHasSkill ? Color.appPurple.opacity(0.18) : Color(UIColor.systemGray5))
                            .foregroundColor(userHasSkill ? .appPurple : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Seção de Requisitos Detalhados
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .foregroundColor(.appPurple)
                    Text("Requisitos:")
                        .font(.caption).bold()
                        .foregroundColor(.secondary)
                }
                
                let reqList = job.requirements.isEmpty ? [job.description] : job.requirements
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(reqList, id: \.self) { req in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption)
                                .foregroundColor(.appPurple)
                                .padding(.top, 2)
                            Text(req)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            
            Divider()
            
            // Ações do Card
            HStack {
                Button(role: .destructive, action: {
                    withAnimation {
                        vm.removeLikedJob(id: job.id)
                    }
                }) {
                    Label("Descurtir", systemImage: "heart.slash")
                        .font(.caption).bold()
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                if isMatched {
                    NavigationLink(destination: ChatListView()) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Abrir Chat")
                                .bold()
                        }
                        .font(.caption)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.appPurple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                } else {
                    Text("Aguardando retorno da empresa")
                        .font(.caption2)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    private func modalityIcon(_ modality: String) -> String {
        switch modality.lowercased() {
        case "remoto": return "laptopcomputer"
        case "presencial": return "building.2"
        default: return "arrow.triangle.swap"
        }
    }
    
    private func modalityColor(_ modality: String) -> Color {
        switch modality.lowercased() {
        case "remoto": return .blue
        case "presencial": return .orange
        default: return .appPurple
        }
    }
}

struct CandidateSwipeView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                if vm.jobs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.appPurple)
                        Text("Você visualizou todas as vagas!")
                            .font(.headline)
                        Button("Carregar Mais Vagas") {
                            vm.generateRandomJobs(count: 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.appPurple)
                    }
                } else {
                    ForEach(vm.jobs.reversed()) { job in
                        JobCardView(job: job)
                    }
                }
            }
            .navigationTitle("Match de Vagas")
        }
    }
}

struct JobCardView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    let job: JobPosting
    @State private var offset = CGSize.zero
    
    var compatibility: Int {
        let candidateSkills = vm.currentUser?.skills ?? []
        let certificates = vm.currentUser?.certificates ?? []
        return calculateCompatibility(candidateSkills: candidateSkills, certificates: certificates, requiredSkills: job.requiredSkills)
    }
    
    var coverURL: String {
        job.coverImageURL ?? GeminiJobService.getCoverImage(for: job.companyName)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 0) {
                // Capa da Empresa da Internet (Unsplash CDN)
                ZStack(alignment: .topTrailing) {
                    if let url = URL(string: coverURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 145)
                                    .clipped()
                            case .empty:
                                Rectangle()
                                    .fill(Color.appPurple.opacity(0.15))
                                    .frame(height: 145)
                                    .overlay(ProgressView())
                            case .failure:
                                LinearGradient(
                                    colors: [Color.appPurple, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(height: 145)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 145)
                    }
                    
                    // Gradiente de transição para o corpo do card
                    LinearGradient(
                        colors: [Color.black.opacity(0.35), Color.clear, Color(UIColor.systemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 145)
                    
                    // Badges flutuantes sobre a capa
                    HStack {
                        CompatibilityBadge(percentage: compatibility)
                        Spacer()
                        Text(job.salaryRange)
                            .font(.caption).bold()
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                // Informações da Vaga
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(job.title)
                            .font(.title3).bold()
                            .lineLimit(2)
                        
                        Text(job.companyName)
                            .font(.subheadline)
                            .foregroundColor(.appPurple)
                            .bold()
                    }
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(job.location)
                        }
                        
                        Text("•")
                        
                        HStack(spacing: 4) {
                            Image(systemName: job.shift.icon)
                            Text(job.shift.shortName)
                        }
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                        
                        if let user = vm.currentUser, vm.hasShiftConflict(candidate: user, job: job) {
                            HStack(spacing: 3) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Turno Divergente")
                            }
                            .font(.caption2).bold()
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                        }
                    }
                    .font(.caption).foregroundColor(.gray)
                    
                    Divider()
                    
                    Text("Requisitos:").font(.caption).bold().foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(job.requiredSkills, id: \.self) { skill in
                                Text(skill)
                                    .font(.caption2).bold()
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.appPurple.opacity(0.1))
                                    .foregroundColor(.appPurple)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    Text(job.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    Spacer()
                    
                    HStack(spacing: 40) {
                        Button(action: { swipe(liked: false) }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable().frame(width: 58, height: 58).foregroundColor(.red)
                        }
                        
                        Button(action: { swipe(liked: true) }) {
                            Image(systemName: "heart.circle.fill")
                                .resizable().frame(width: 58, height: 58).foregroundColor(.appPurple)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .padding()
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .gesture(
            DragGesture()
                .onChanged { gesture in offset = gesture.translation }
                .onEnded { _ in
                    if offset.width > 120 { swipe(liked: true) }
                    else if offset.width < -120 { swipe(liked: false) }
                    else { offset = .zero }
                }
        )
    }
    
    private func swipe(liked: Bool) {
        withAnimation(.spring()) {
            vm.swipeJob(job: job, liked: liked)
        }
    }
}

// MARK: - Aba Explorar com Filtros de Interesses e IA Gemini
struct ExploreJobsView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @State private var searchText = ""
    @State private var selectedCategory: String = "Todas"
    @State private var selectedModality: String = "Todas"
    @State private var selectedShift: String = "Todos"
    @State private var showAIGeneratorSuccessAlert: Bool = false
    
    let categories = [
        "Todas", "iOS / Mobile", "Web / Frontend", "Dados & IA",
        "Design UI/UX", "Cloud & DevOps", "Vendas / Negócios"
    ]
    
    let modalities = ["Todas", "Remoto", "Híbrido", "Presencial"]
    
    var filteredJobs: [JobPosting] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return vm.jobs.filter { job in
            // Filtro por termo de busca
            let matchesQuery: Bool
            if query.isEmpty {
                matchesQuery = true
            } else {
                matchesQuery = job.title.localizedCaseInsensitiveContains(query) ||
                               job.companyName.localizedCaseInsensitiveContains(query) ||
                               job.requiredSkills.contains { $0.localizedCaseInsensitiveContains(query) }
            }
            
            // Filtro por Categoria / Área
            let matchesCategory: Bool
            switch selectedCategory {
            case "iOS / Mobile":
                matchesCategory = job.title.localizedCaseInsensitiveContains("iOS") ||
                                  job.title.localizedCaseInsensitiveContains("Mobile") ||
                                  job.requiredSkills.contains { $0.caseInsensitiveCompare("Swift") == .orderedSame }
            case "Web / Frontend":
                matchesCategory = job.title.localizedCaseInsensitiveContains("Frontend") ||
                                  job.title.localizedCaseInsensitiveContains("React")
            case "Dados & IA":
                matchesCategory = job.title.localizedCaseInsensitiveContains("Dados") ||
                                  job.title.localizedCaseInsensitiveContains("Machine Learning") ||
                                  job.title.localizedCaseInsensitiveContains("IA")
            case "Design UI/UX":
                matchesCategory = job.title.localizedCaseInsensitiveContains("Design") ||
                                  job.requiredSkills.contains { $0.caseInsensitiveCompare("Figma") == .orderedSame }
            case "Cloud & DevOps":
                matchesCategory = job.title.localizedCaseInsensitiveContains("Cloud") ||
                                  job.title.localizedCaseInsensitiveContains("DevOps")
            case "Vendas / Negócios":
                matchesCategory = job.title.localizedCaseInsensitiveContains("Vendas") ||
                                  job.title.localizedCaseInsensitiveContains("SDR") ||
                                  job.title.localizedCaseInsensitiveContains("Comercial")
            default:
                matchesCategory = true
            }
            
            // Filtro por Modalidade
            let matchesModality = (selectedModality == "Todas") || (job.modality.caseInsensitiveCompare(selectedModality) == .orderedSame)
            
            // Filtro por Turno
            let matchesShift = (selectedShift == "Todos") || (job.shift.shortName.caseInsensitiveCompare(selectedShift) == .orderedSame)
            
            return matchesQuery && matchesCategory && matchesModality && matchesShift
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barra de Filtros de Interesses (Pills Horizontais)
                VStack(spacing: 8) {
                    // Chips de Categorias
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedCategory = cat
                                    }
                                } label: {
                                    Text(cat)
                                        .font(.caption).bold()
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(selectedCategory == cat ? Color.appPurple : Color(UIColor.systemGray5))
                                        .foregroundColor(selectedCategory == cat ? .white : .primary)
                                        .cornerRadius(14)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Filtro rápido de Modalidade
                    HStack(spacing: 8) {
                        ForEach(modalities, id: \.self) { mod in
                            Button {
                                withAnimation { selectedModality = mod }
                            } label: {
                                Text(mod)
                                    .font(.caption2).bold()
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(selectedModality == mod ? Color.blue : Color(UIColor.secondarySystemBackground))
                                    .foregroundColor(selectedModality == mod ? .white : .secondary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        // Botão Gemini IA
                        Button {
                            Task {
                                await vm.fetchMarketJobsWithGemini(category: selectedCategory, query: searchText)
                                showAIGeneratorSuccessAlert = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if vm.isGeneratingAIJobs {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text("Vagas IA (Gemini)")
                                    .font(.caption2).bold()
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.appPurple.opacity(0.18))
                            .foregroundColor(.appPurple)
                            .cornerRadius(8)
                        }
                        .disabled(vm.isGeneratingAIJobs)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
                .padding(.top, 6)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                Divider()
                
                // Lista de Vagas Filtradas com Capas Corporativas
                if filteredJobs.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.appSilver)
                        
                        Text("Nenhuma vaga nesta categoria")
                            .font(.headline)
                        
                        Text("Não encontramos vagas para o filtro selecionado. Use o botão 'Vagas IA (Gemini)' acima para buscar novas vagas de mercado em tempo real!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        Button {
                            Task {
                                await vm.fetchMarketJobsWithGemini(category: selectedCategory, query: searchText)
                                showAIGeneratorSuccessAlert = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                Text("Buscar Vagas com Gemini AI")
                            }
                            .font(.subheadline).bold()
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Color.appPurple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding()
                } else {
                    List(filteredJobs) { job in
                        ExploreJobCardRow(job: job)
                            .listRowInsets(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Explorar Vagas")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar por cargo, habilidade ou empresa..."
            )
            .alert("Vagas de Mercado Atualizadas!", isPresented: $showAIGeneratorSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A inteligência artificial do Gemini atualizou o catálogo com vagas reais e recentes do mercado brasileiro.")
            }
        }
    }
}

// MARK: - Linha do Card de Vaga com Capa da Empresa na Aba Explorar
struct ExploreJobCardRow: View {
    @EnvironmentObject var vm: JobTinderViewModel
    let job: JobPosting
    
    var compatibility: Int {
        let candidateSkills = vm.currentUser?.skills ?? []
        let certificates = vm.currentUser?.certificates ?? []
        return calculateCompatibility(candidateSkills: candidateSkills, certificates: certificates, requiredSkills: job.requiredSkills)
    }
    
    var isLiked: Bool {
        vm.candidateLikes.contains(job.id)
    }
    
    var coverURL: String {
        job.coverImageURL ?? GeminiJobService.getCoverImage(for: job.companyName)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imagem de Capa Corporativa da Empresa
            ZStack(alignment: .topTrailing) {
                if let url = URL(string: coverURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 90)
                                .clipped()
                        case .empty:
                            Rectangle()
                                .fill(Color.appPurple.opacity(0.12))
                                .frame(height: 90)
                        case .failure:
                            LinearGradient(
                                colors: [Color.appPurple.opacity(0.7), Color.blue.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 90)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 90)
                }
                
                // Badges sobre a capa
                HStack {
                    CompatibilityBadge(percentage: compatibility)
                    Spacer()
                    Button {
                        withAnimation {
                            if isLiked {
                                vm.removeLikedJob(id: job.id)
                            } else {
                                vm.swipeJob(job: job, liked: true)
                            }
                        }
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(isLiked ? .red : .white)
                            .padding(6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            // Corpo da Vaga
            VStack(alignment: .leading, spacing: 6) {
                Text(job.title)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(job.companyName)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.appPurple)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(job.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 6) {
                    Text(job.salaryRange)
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(6)
                    
                    HStack(spacing: 3) {
                        Image(systemName: job.shift.icon)
                        Text(job.shift.shortName)
                    }
                    .font(.caption2).bold()
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                    
                    Text(job.modality)
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
                
                Text(job.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            .padding(12)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct CandidateProfileView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @State private var showFileImporter = false
    @State private var importedPDFName: String?
    
    // Edição de Perfil
    @State private var showEditProfileSheet = false
    
    // Adição de Habilidades (Skills)
    @State private var showAddSkillAlert = false
    @State private var newSkillName = ""
    @State private var skillNotification: String? = nil
    
    // Upload de Certificados
    @State private var showCertFileImporter = false
    @State private var showAddCertAlert = false
    @State private var manualCertName = ""
    @State private var uploadedCertNotification: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Atalho Rápido para Edição de Perfil
                Section {
                    Button(action: { showEditProfileSheet = true }) {
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
                                Text("Editar Informações do Perfil")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Alterar nome, contato, endereço, bio, PCD e links")
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
                
                Section(header: Text("Informações Pessoais")) {
                    Text(vm.currentUser?.name ?? "").font(.title3).bold()
                    Text(vm.currentUser?.email ?? "").foregroundColor(.secondary)
                    
                    HStack {
                        Text("CPF:")
                            .bold()
                        Text(vm.currentUser?.cpf ?? "Não informado")
                    }
                    
                    if let phone = vm.currentUser?.phone, !phone.isEmpty {
                        HStack {
                            Text("Telefone:").bold()
                            Text(phone)
                        }
                    }
                    
                    if let address = vm.currentUser?.address, !address.isEmpty {
                        HStack {
                            Text("Residência:").bold()
                            Text(address)
                        }
                    }
                    
                    if let birth = vm.currentUser?.birthDate, !birth.isEmpty {
                        HStack {
                            Text("Data de Nascimento:").bold()
                            Text(birth)
                        }
                    }
                    
                    HStack {
                        Text("Gênero:")
                            .bold()
                        Text(vm.currentUser?.gender?.rawValue ?? "Não informado")
                    }
                    
                    HStack {
                        Text("Condição PCD:")
                            .bold()
                        Text(vm.currentUser?.disability?.rawValue ?? "Não PCD")
                            .foregroundColor(vm.currentUser?.disability != .none ? .appPurple : .primary)
                    }
                    
                    if let details = vm.currentUser?.disabilityDetails, !details.isEmpty {
                        Text("Detalhes PCD: \(details)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let bio = vm.currentUser?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                // MARK: - Seção Interativa de Habilidades (Skills)
                Section(header: HStack {
                    Text("Habilidades (\(vm.currentUser?.skills.count ?? 0))")
                    Spacer()
                    Button(action: { showAddSkillAlert = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Adicionar")
                        }
                        .font(.caption).bold()
                        .foregroundColor(.appPurple)
                    }
                }) {
                    if let note = skillNotification {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if let skills = vm.currentUser?.skills, !skills.isEmpty {
                        ForEach(skills, id: \.self) { skill in
                            HStack {
                                Label(skill, systemImage: "checkmark.seal.fill")
                                    .foregroundColor(.appPurple)
                                Spacer()
                                Button(role: .destructive, action: {
                                    if let index = vm.currentUser?.skills.firstIndex(of: skill) {
                                        vm.removeSkill(at: IndexSet(integer: index))
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .onDelete(perform: vm.removeSkill)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nenhuma habilidade cadastrada")
                                .foregroundColor(.secondary)
                            Button(action: { showAddSkillAlert = true }) {
                                Label("Adicionar sua primeira habilidade", systemImage: "plus")
                                    .font(.caption).bold()
                                    .foregroundColor(.appPurple)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: - Seção Interativa de Upload de Certificados
                Section(header: HStack {
                    Text("Certificados (\(vm.currentUser?.certificates.count ?? 0))")
                    Spacer()
                    Menu {
                        Button(action: { showCertFileImporter = true }) {
                            Label("Upload de Arquivo (PDF / Imagem)", systemImage: "doc.badge.plus")
                        }
                        Button(action: { showAddCertAlert = true }) {
                            Label("Digitar Nome do Certificado", systemImage: "keyboard")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Adicionar")
                        }
                        .font(.caption).bold()
                        .foregroundColor(.appPurple)
                    }
                }) {
                    if let note = uploadedCertNotification {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if let certs = vm.currentUser?.certificates, !certs.isEmpty {
                        ForEach(certs, id: \.self) { cert in
                            HStack {
                                Label(cert, systemImage: "rosette")
                                    .foregroundColor(.orange)
                                    .font(.subheadline)
                                Spacer()
                                Button(role: .destructive, action: {
                                    if let index = vm.currentUser?.certificates.firstIndex(of: cert) {
                                        vm.removeCertificate(at: IndexSet(integer: index))
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .onDelete(perform: vm.removeCertificate)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nenhum certificado cadastrado")
                                .foregroundColor(.secondary)
                            Button(action: { showCertFileImporter = true }) {
                                Label("Fazer upload do seu primeiro certificado", systemImage: "arrow.up.doc")
                                    .font(.caption).bold()
                                    .foregroundColor(.appPurple)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Currículo & Links")) {
                    if let linkedin = vm.currentUser?.linkedInURL, !linkedin.isEmpty {
                        Link(destination: URL(string: linkedin) ?? URL(string: "https://linkedin.com")!) {
                            Label("Ver Perfil do LinkedIn", systemImage: "link")
                                .foregroundColor(.appPurple)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "doc.richtext.fill").foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Arquivo PDF:").font(.caption).foregroundColor(.secondary)
                            Text(importedPDFName ?? vm.currentUser?.pdfResumeName ?? "Nenhum PDF selecionado")
                                .font(.subheadline).bold()
                        }
                        Spacer()
                        Button("Enviar PDF") { showFileImporter = true }
                            .buttonStyle(.bordered).tint(.appPurple)
                    }
                }
                
                Section {
                    Button("Sair da Conta", role: .destructive) {
                        vm.isAuthenticated = false
                        vm.currentUser = nil
                    }
                }
            }
            .navigationTitle("Aba Pessoal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditProfileSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Editar")
                        }
                        .font(.subheadline).bold()
                        .foregroundColor(.appPurple)
                    }
                }
            }
            .sheet(isPresented: $showEditProfileSheet) {
                EditCandidateProfileView()
            }
            .alert("Adicionar Habilidade", isPresented: $showAddSkillAlert) {
                TextField("Ex: Swift, SwiftUI, Python, SQL, Git...", text: $newSkillName)
                Button("Cancelar", role: .cancel) { newSkillName = "" }
                Button("Adicionar") {
                    let trimmed = newSkillName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        vm.addSkill(trimmed)
                        skillNotification = "Habilidade \"\(trimmed)\" adicionada!"
                        newSkillName = ""
                    }
                }
            } message: {
                Text("Adicione uma habilidade técnica ou competência para aumentar sua compatibilidade com as vagas disponíveis.")
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let firstUrl = urls.first {
                        importedPDFName = firstUrl.lastPathComponent
                        vm.currentUser?.pdfResumeName = firstUrl.lastPathComponent
                    }
                case .failure(let error):
                    print("Erro no upload do PDF: \(error.localizedDescription)")
                }
            }
            .fileImporter(
                isPresented: $showCertFileImporter,
                allowedContentTypes: [.pdf, .png, .jpeg, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let firstUrl = urls.first {
                        let rawName = firstUrl.deletingPathExtension().lastPathComponent
                        let displayName = rawName
                            .replacingOccurrences(of: "_", with: " ")
                            .replacingOccurrences(of: "-", with: " ")
                        let finalName = displayName.isEmpty ? firstUrl.lastPathComponent : displayName
                        vm.addCertificate(finalName)
                        uploadedCertNotification = "Certificado \"\(finalName)\" adicionado com sucesso!"
                    }
                case .failure(let error):
                    print("Erro no upload do certificado: \(error.localizedDescription)")
                }
            }
            .alert("Novo Certificado", isPresented: $showAddCertAlert) {
                TextField("Ex: Certificação Swift Specialist", text: $manualCertName)
                Button("Cancelar", role: .cancel) { manualCertName = "" }
                Button("Adicionar") {
                    let trimmed = manualCertName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        vm.addCertificate(trimmed)
                        uploadedCertNotification = "Certificado \"\(trimmed)\" cadastrado!"
                        manualCertName = ""
                    }
                }
            } message: {
                Text("Informe o nome do certificado ou curso para aumentar sua pontuação de compatibilidade com as vagas.")
            }
        }
    }
}

// MARK: - Tela de Edição de Perfil do Candidato
struct EditCandidateProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: JobTinderViewModel
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var birthDate: String = ""
    @State private var gender: Gender = .male
    @State private var disability: DisabilityType = .none
    @State private var disabilityDetails: String = ""
    @State private var bio: String = ""
    @State private var linkedInURL: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Seção: Dados Pessoais & Contato
                    VStack(alignment: .leading, spacing: 14) {
                        Text("DADOS PESSOAIS & CONTATO")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        EmberTextField(
                            title: "NOME COMPLETO",
                            placeholder: "Seu nome",
                            text: $name,
                            icon: "person.fill",
                            isRequired: true,
                            autocapitalization: .words
                        )
                        
                        HStack(spacing: 12) {
                            EmberTextField(
                                title: "CELULAR / WHATSAPP",
                                placeholder: "(00) 00000-0000",
                                text: $phone,
                                icon: "phone.fill",
                                keyboardType: .phonePad,
                                mask: InputMask.phone
                            )
                            
                            EmberTextField(
                                title: "DATA DE NASCIMENTO",
                                placeholder: "DD/MM/AAAA",
                                text: $birthDate,
                                icon: "calendar",
                                keyboardType: .numberPad,
                                mask: InputMask.date
                            )
                        }
                        
                        EmberTextField(
                            title: "RESIDÊNCIA (CIDADE / ESTADO)",
                            placeholder: "ex: Santa Maria - RS",
                            text: $address,
                            icon: "mappin.and.ellipse",
                            autocapitalization: .words
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("GÊNERO")
                                .font(.caption).bold().foregroundColor(.secondary)
                            
                            Picker("Gênero", selection: $gender) {
                                ForEach(Gender.allCases) { g in
                                    Text(g.rawValue).tag(g)
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
                    
                    // Seção: Acessibilidade & PCD
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ACESSIBILIDADE / PCD")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CONDIÇÃO PCD")
                                .font(.caption).bold().foregroundColor(.secondary)
                            
                            Picker("Condição PCD", selection: $disability) {
                                ForEach(DisabilityType.allCases) { d in
                                    Text(d.rawValue).tag(d)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        if disability != .none {
                            EmberTextField(
                                title: "DETALHES OU NECESSIDADES ESPECÍFICAS",
                                placeholder: "ex: Leitor de tela, recursos ergonômicos...",
                                text: $disabilityDetails,
                                icon: "accessibility"
                            )
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    
                    // Seção: Biografia & Resumo
                    VStack(alignment: .leading, spacing: 14) {
                        Text("RESUMO PROFISSIONAL")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        EmberTextEditor(
                            title: "BIOGRAFIA / SOBRE VOCÊ",
                            placeholder: "Compartilhe sua trajetória, objetivos e especialidades...",
                            text: $bio,
                            icon: "text.quote",
                            minHeight: 100
                        )
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    
                    // Seção: Links
                    VStack(alignment: .leading, spacing: 14) {
                        Text("LINKS E REDES")
                            .font(.caption2).bold().foregroundColor(.appPurple)
                        
                        EmberTextField(
                            title: "LINKEDIN OU PORTFÓLIO",
                            placeholder: "https://linkedin.com/in/...",
                            text: $linkedInURL,
                            icon: "link",
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
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        vm.updateCandidateProfile(
                            name: name,
                            phone: phone,
                            address: address,
                            birthDate: birthDate,
                            gender: gender,
                            disability: disability,
                            disabilityDetails: disabilityDetails,
                            bio: bio,
                            linkedin: linkedInURL
                        )
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(.appPurple)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let user = vm.currentUser {
                    name = user.name
                    phone = user.phone ?? ""
                    address = user.address ?? ""
                    birthDate = user.birthDate ?? ""
                    gender = user.gender ?? .male
                    disability = user.disability ?? .none
                    disabilityDetails = user.disabilityDetails ?? ""
                    bio = user.bio
                    linkedInURL = user.linkedInURL
                }
            }
        }
    }
}
