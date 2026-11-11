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
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    CompatibilityBadge(percentage: compatibility)
                    Spacer()
                    Text(job.salaryRange)
                        .font(.caption).bold()
                        .padding(6)
                        .background(Color.appPurple.opacity(0.15))
                        .foregroundColor(.appPurple)
                        .cornerRadius(6)
                }
                .padding(.top, 8)
                
                Text(job.title).font(.title2).bold()
                Text(job.companyName).font(.headline).foregroundColor(.secondary)
                
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
                    .font(.caption).bold()
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
                .font(.subheadline).foregroundColor(.gray)
                
                Divider()
                
                Text("Requisitos:").font(.subheadline).bold()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(job.requiredSkills, id: \.self) { skill in
                            Text(skill)
                                .font(.caption)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.appPurple.opacity(0.1))
                                .foregroundColor(.appPurple)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Text(job.description)
                    .font(.body).foregroundColor(.secondary).lineLimit(4)
                
                Spacer()
                
                HStack(spacing: 40) {
                    Button(action: { swipe(liked: false) }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable().frame(width: 60, height: 60).foregroundColor(.red)
                    }
                    
                    Button(action: { swipe(liked: true) }) {
                        Image(systemName: "heart.circle.fill")
                            .resizable().frame(width: 60, height: 60).foregroundColor(.appPurple)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
            }
            .padding(20)
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

struct ExploreJobsView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @State private var searchText = ""
    
    var filteredJobs: [JobPosting] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return vm.jobs
        } else {
            return vm.jobs.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.companyName.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if filteredJobs.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 55))
                            .foregroundColor(.appSilver)
                        Text("Nenhuma vaga encontrada")
                            .font(.headline)
                        Text("Não encontramos vagas com o termo \"\(searchText)\". Tente outros termos como iOS, Frontend, Python, Dados ou Design.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding()
                } else {
                    List(filteredJobs) { job in
                        let compat = calculateCompatibility(
                            candidateSkills: vm.currentUser?.skills ?? [],
                            certificates: vm.currentUser?.certificates ?? [],
                            requiredSkills: job.requiredSkills
                        )
                        let isLiked = vm.candidateLikes.contains(job.id)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                CompatibilityBadge(percentage: compat)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: modalityIcon(job.modality))
                                    Text(job.modality)
                                }
                                .font(.caption2).bold()
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.appPurple.opacity(0.12))
                                .foregroundColor(.appPurple)
                                .cornerRadius(6)
                                
                                Spacer()
                                
                                if isLiked {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(job.title)
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 4) {
                                    Text(job.companyName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(job.location)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Text(job.salaryRange)
                                    .font(.caption).bold()
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(6)
                            }
                            
                            Text(job.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Explorar Vagas")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Pesquisar por nome da vaga (ex: iOS, Frontend...)"
            )
        }
    }
    
    private func modalityIcon(_ modality: String) -> String {
        switch modality.lowercased() {
        case "remoto": return "laptopcomputer"
        case "presencial": return "building.2"
        default: return "arrow.triangle.swap"
        }
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
            Form {
                Section(header: Text("Dados Pessoais & Contato")) {
                    TextField("Nome Completo", text: $name)
                    TextField("Telefone / WhatsApp", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Residência (Cidade / Estado)", text: $address)
                    TextField("Data de Nascimento (DD/MM/AAAA)", text: $birthDate)
                    
                    Picker("Gênero", selection: $gender) {
                        ForEach(Gender.allCases) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                }
                
                Section(header: Text("Acessibilidade / PCD")) {
                    Picker("Condição PCD", selection: $disability) {
                        ForEach(DisabilityType.allCases) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    
                    if disability != .none {
                        TextField("Detalhes ou necessidades de acessibilidade", text: $disabilityDetails)
                    }
                }
                
                Section(header: Text("Biografia / Sobre Você")) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 110)
                }
                
                Section(header: Text("Links Profissionais")) {
                    TextField("URL do LinkedIn", text: $linkedInURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
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
