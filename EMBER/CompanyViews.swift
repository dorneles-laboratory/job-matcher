import SwiftUI

struct CompanyMainTabView: View {
    var body: some View {
        TabView {
            CompanyCandidateSwipeView()
                .tabItem { Label("Candidatos", systemImage: "person.2.fill") }
            
            CompanyJobsManagementView()
                .tabItem { Label("Minhas Vagas", systemImage: "doc.badge.plus") }
            
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
    
    var body: some View {
        NavigationView {
            ZStack {
                if vm.candidates.isEmpty {
                    VStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundColor(.appPurple)
                        Text("Nenhum currículo pendente para análise.")
                            .font(.headline)
                            .padding(.top, 10)
                    }
                } else {
                    ForEach(vm.candidates.reversed()) { candidate in
                        CandidateCardView(candidate: candidate)
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
    @State private var offset = CGSize.zero
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 8)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.name).font(.title2).bold()
                        Text("CPF: \(candidate.cpf ?? "Não informado")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    if let dis = candidate.disability, dis != .none {
                        Text(dis.rawValue)
                            .font(.caption2).bold()
                            .padding(6)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                
                if let gender = candidate.gender {
                    HStack {
                        Label(gender.rawValue, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
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
        if let currentJob = vm.jobs.first {
            withAnimation {
                vm.swipeCandidate(candidate: candidate, job: currentJob, liked: liked)
            }
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
    @State private var requirements = ""
    @State private var salary = ""
    
    let modalityOptions = ["Remoto", "Híbrido", "Presencial"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informações Básicas")) {
                    TextField("Título da Vaga (ex: Desenvolvedor iOS)", text: $title)
                    TextField("Localização (ex: São Paulo - SP)", text: $location)
                    
                    Picker("Modalidade", selection: $modality) {
                        ForEach(modalityOptions, id: \.self) { mod in
                            Text(mod).tag(mod)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("Faixa Salarial (ex: R$ 6.000 - R$ 8.000)", text: $salary)
                }
                
                Section(header: Text("Requisitos"), footer: Text("Separe múltiplos requisitos por vírgula.")) {
                    TextField("Ex: Swift, SwiftUI, MVVM, Git", text: $requirements)
                }
                
                Section(header: Text("Descrição da Vaga")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Criar Nova Vaga")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Publicar") {
                        vm.addJob(
                            title: title,
                            location: location,
                            modality: modality,
                            description: description,
                            requirements: requirements,
                            salary: salary
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                    .bold()
                    .foregroundColor(.appPurple)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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
            Form {
                Section(header: Text("Identificação da Empresa")) {
                    TextField("Razão Social", text: $companyName)
                    TextField("Nome Fantasia", text: $tradeName)
                    TextField("Telefone Corporativo / WhatsApp", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Endereço / Sede (Cidade - UF)", text: $address)
                }
                
                Section(header: Text("Segmento & Porte")) {
                    TextField("Ramo / Setor de Atuação", text: $industry)
                    
                    Picker("Porte da Empresa", selection: $companySize) {
                        ForEach(CompanySize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                }
                
                Section(header: Text("Descrição Institucional (Bio)")) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 110)
                }
                
                Section(header: Text("Website ou Página")) {
                    TextField("URL do Website / LinkedIn", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
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
