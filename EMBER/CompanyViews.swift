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
            
            ChatListView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
            
            CompanyProfileView()
                .tabItem { Label("Empresa", systemImage: "building.2.fill") }
        }
        .accentColor(.appPurple)
    }
}

struct CompanyCandidateSwipeView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @State private var selectedJobId: UUID? = nil
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                // Seletor da Vaga da Empresa em Avaliação
                if let job = activeJob {
                    Menu {
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
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "briefcase.fill")
                                .foregroundColor(.appPurple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AVALIANDO PARA A VAGA:")
                                    .font(.caption2).bold().foregroundColor(.secondary)
                                Text(job.title)
                                    .font(.subheadline).bold().foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appPurple.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
                
                ZStack {
                    if vm.candidates.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundColor(.appPurple)
                            Text("Nenhum currículo pendente para análise.")
                                .font(.headline)
                            Text("Todos os candidatos para esta vaga já foram avaliados.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if let job = activeJob {
                        ForEach(vm.candidates.reversed()) { candidate in
                            CandidateCardView(candidate: candidate, targetJob: job)
                        }
                    }
                }
            }
            .navigationTitle("Análise de Currículos")
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
        }
        .padding()
        .offset(x: offset.width)
        .gesture(
            DragGesture()
                .onChanged { g in offset = g.translation }
                .onEnded { _ in
                    if offset.width > 120 { swipe(liked: true) }
                    else if offset.width < -120 { swipe(liked: false) }
                    else { offset = .zero }
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
                Button(action: { showCreateJobModal = true }) {
                    Image(systemName: "plus").foregroundColor(.appPurple)
                }
            }
            .sheet(isPresented: $showCreateJobModal) {
                CreateJobView()
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
