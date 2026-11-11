import SwiftUI

enum AuthScreenMode {
    case welcome
    case login
    case register
}

struct AuthView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    
    @State private var screenMode: AuthScreenMode = .welcome
    @State private var selectedRole: UserRole = .candidate
    
    // Alerta de Erro de Login
    @State private var showAuthError = false
    @State private var authErrorMessage = ""
    
    // Credenciais comuns de Login
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    
    // Wizard de Cadastro (Passo 1 a 3)
    @State private var currentStep: Int = 1
    
    // Passo 1: Credenciais
    @State private var regEmail = ""
    @State private var regPassword = ""
    @State private var regConfirmPassword = ""
    
    // Passo 2: Dados Pessoais / Corporativos
    // Candidato:
    @State private var candidateName = ""
    @State private var cpf = ""
    @State private var birthDate = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var gender: Gender = .male
    @State private var disability: DisabilityType = .none
    @State private var disabilityDetails = ""
    
    // Empresa:
    @State private var companyName = ""
    @State private var tradeName = ""
    @State private var cnpj = ""
    @State private var industry = ""
    @State private var companySize: CompanySize = .small
    
    // Passo 3: Perfil Profissional / Institucional
    // Candidato:
    @State private var candidateSkills: [String] = []
    @State private var candidateCertificates: [String] = []
    @State private var candidateBio = ""
    @State private var linkedinURL = ""
    
    // Empresa:
    @State private var companyBio = ""
    @State private var companyWebsite = ""
    @State private var autoWelcomeMessage = "Olá! Ficamos muito felizes com o Match. Quando podemos agendar uma primeira conversa?"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                switch screenMode {
                case .welcome:
                    welcomeView
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .leading)), removal: .opacity.combined(with: .move(edge: .leading))))
                case .login:
                    loginView
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                case .register:
                    registerWizardView
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                }
            }
            .navigationBarHidden(true)
            .alert("Erro de Autenticação", isPresented: $showAuthError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authErrorMessage)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - 1. TELA DE BOAS-VINDAS (WelcomeView)
    private var welcomeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header Hero
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appPurple, Color.appPurple.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.appPurple.opacity(0.35), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 24)
                    
                    VStack(spacing: 4) {
                        Text("Job Matcher")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Conectando Talentos e Oportunidades com Inteligência")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                
                // Destaques / Benefícios Rápidos
                HStack(spacing: 12) {
                    featurePill(icon: "sparkles", text: "Match Preciso")
                    featurePill(icon: "bubble.left.and.bubble.right.fill", text: "Chat Direto")
                    featurePill(icon: "shield.checkerboard", text: "Perfis Verificados")
                }
                .padding(.horizontal)
                
                // Seletor de Perfil Visual
                VStack(alignment: .leading, spacing: 12) {
                    Text("COMO DESEJA COMEÇAR?")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 10) {
                        RoleSelectionCard(
                            role: .candidate,
                            isSelected: selectedRole == .candidate
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRole = .candidate
                            }
                        }
                        
                        RoleSelectionCard(
                            role: .company,
                            isSelected: selectedRole == .company
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRole = .company
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Botões de Ação
                VStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentStep = 1
                            screenMode = .register
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Criar Nova Conta")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPurple)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.appPurple.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            screenMode = .login
                        }
                    }) {
                        HStack {
                            Text("Já tenho uma conta • Entrar")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(UIColor.systemGray4).opacity(0.6), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                
                // Seção de Demonstração Rápida (Demo)
                VStack(spacing: 10) {
                    HStack {
                        Rectangle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(height: 1)
                        Text("TESTAR SEM DIGITAR (DEMO)")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.secondary)
                        Rectangle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                    
                    VStack(spacing: 8) {
                        Button(action: { quickLoginCandidate() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill.viewfinder")
                                    .foregroundColor(.appPurple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Entrar como Candidato Demo")
                                        .font(.subheadline).bold()
                                        .foregroundColor(.primary)
                                    Text("Thiago Mikael • Dev iOS Pleno (Swift / SwiftUI)")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.appPurple)
                            }
                            .padding(12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appPurple.opacity(0.3), lineWidth: 1))
                        }
                        
                        Button(action: { quickLoginCompany() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Entrar como Empresa Demo")
                                        .font(.subheadline).bold()
                                        .foregroundColor(.primary)
                                    Text("Cocoa Apps Studio • Estúdio Apple & SwiftUI")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .padding(12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.appPurple)
            Text(text)
                .font(.caption2)
                .bold()
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .overlay(
            Capsule()
                .stroke(Color.appPurple.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 2. TELA DE LOGIN (LoginFormView)
    private var loginView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                // Barra de Topo com Voltar
                HStack {
                    Button(action: {
                        withAnimation(.spring()) { screenMode = .welcome }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Início")
                        }
                        .font(.subheadline).bold()
                        .foregroundColor(.appPurple)
                    }
                    
                    Spacer()
                    
                    Text("Acessar Conta")
                        .font(.headline)
                        .bold()
                    
                    Spacer()
                    
                    // Spacer compensatório
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Início")
                    }
                    .font(.subheadline)
                    .opacity(0)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Seletor de Tipo de Perfil
                VStack(alignment: .leading, spacing: 8) {
                    Text("ENTRANDO COMO:")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.secondary)
                    
                    Picker("Tipo de Perfil", selection: $selectedRole) {
                        ForEach(UserRole.allCases) { role in
                            Text(role == .candidate ? "Candidato (CPF)" : "Empresa (CNPJ)").tag(role)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Campos de Entrada
                VStack(spacing: 16) {
                    EmberTextField(
                        title: "E-MAIL CADASTRADO",
                        placeholder: "exemplo@email.com",
                        text: $loginEmail,
                        icon: "envelope.fill",
                        isRequired: true,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )
                    
                    EmberSecureField(
                        title: "SUA SENHA",
                        placeholder: "Digite sua senha",
                        text: $loginPassword,
                        isRequired: true
                    )
                }
                .padding(.horizontal)
                
                // Botão de Login
                let canLogin = !loginEmail.trimmingCharacters(in: .whitespaces).isEmpty &&
                               !loginPassword.trimmingCharacters(in: .whitespaces).isEmpty
                
                Button(action: handleLogin) {
                    HStack(spacing: 6) {
                        Text("Entrar")
                            .bold()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canLogin ? Color.appPurple : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: canLogin ? Color.appPurple.opacity(0.25) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .disabled(!canLogin)
                .padding(.horizontal)
                .padding(.top, 6)
                
                // Atalho de Preenchimento Rápido
                Button(action: fillDemoCredentials) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Preencher dados demo para teste")
                            .font(.caption)
                            .bold()
                    }
                    .foregroundColor(.appPurple)
                }
                .padding(.top, 4)
                
                Spacer().frame(height: 20)
                
                // Rodapé com link para cadastro
                HStack(spacing: 4) {
                    Text("Ainda não possui conta?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Cadastre-se") {
                        withAnimation(.spring()) {
                            currentStep = 1
                            screenMode = .register
                        }
                    }
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.appPurple)
                }
            }
        }
    }
    
    // MARK: - 3. CADASTRO EM ETAPAS (RegistrationWizardView)
    private var registerWizardView: some View {
        VStack(spacing: 0) {
            // Top Bar com Navegação e Indicador de Progresso
            VStack(spacing: 12) {
                HStack {
                    Button(action: handleWizardBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(currentStep == 1 ? "Início" : "Voltar")
                        }
                        .font(.subheadline).bold()
                        .foregroundColor(.appPurple)
                    }
                    
                    Spacer()
                    
                    Text("Cadastro • \(selectedRole == .candidate ? "Candidato" : "Empresa")")
                        .font(.headline)
                        .bold()
                    
                    Spacer()
                    
                    Text("Passo \(currentStep) de 3")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Barra de Progresso
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.appPurple)
                            .frame(width: geo.size.width * (CGFloat(currentStep) / 3.0), height: 6)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal)
                
                // Nomes das Etapas
                HStack {
                    stepLabel(step: 1, title: "1. Conta")
                    Spacer()
                    stepLabel(step: 2, title: selectedRole == .candidate ? "2. Pessoal" : "2. Empresa")
                    Spacer()
                    stepLabel(step: 3, title: selectedRole == .candidate ? "3. Perfil" : "3. Sobre")
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
            
            // Conteúdo Rolável da Etapa Atual
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if currentStep == 1 {
                        step1AccountView
                            .transition(.opacity)
                    } else if currentStep == 2 {
                        if selectedRole == .candidate {
                            step2CandidatePersonalView
                                .transition(.opacity)
                        } else {
                            step2CompanyCorporateView
                                .transition(.opacity)
                        }
                    } else {
                        if selectedRole == .candidate {
                            step3CandidateProfessionalView
                                .transition(.opacity)
                        } else {
                            step3CompanyProfileView
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            
            // Rodapé Fixo de Ação
            VStack(spacing: 8) {
                Divider()
                
                HStack(spacing: 12) {
                    if currentStep > 1 {
                        Button(action: {
                            withAnimation(.spring()) { currentStep -= 1 }
                        }) {
                            Text("Voltar")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(UIColor.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                        .frame(width: 100)
                    }
                    
                    let valid = isCurrentStepValid
                    
                    Button(action: handleWizardNext) {
                        HStack(spacing: 6) {
                            Text(currentStep == 3 ? "Concluir Cadastro" : "Avançar")
                                .bold()
                            Image(systemName: currentStep == 3 ? "checkmark" : "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(valid ? Color.appPurple : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: valid ? Color.appPurple.opacity(0.25) : Color.clear, radius: 6, x: 0, y: 3)
                    }
                    .disabled(!valid)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private func stepLabel(step: Int, title: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(currentStep >= step ? Color.appPurple : Color.gray.opacity(0.4))
                .frame(width: 16, height: 16)
                .overlay(
                    Text("\(step)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(title)
                .font(.caption2)
                .bold()
                .foregroundColor(currentStep >= step ? .primary : .secondary)
        }
    }
    
    // MARK: - Passos do Wizard
    // PASSO 1: Conta & Credenciais
    private var step1AccountView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tipo de Conta")
                    .font(.caption).bold().foregroundColor(.secondary)
                
                Picker("Tipo", selection: $selectedRole) {
                    ForEach(UserRole.allCases) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            EmberTextField(
                title: "E-MAIL DE ACESSO",
                placeholder: "seu.email@exemplo.com",
                text: $regEmail,
                icon: "envelope.fill",
                isRequired: true,
                keyboardType: .emailAddress,
                autocapitalization: .never,
                helperText: "Será utilizado para acessar a sua conta."
            )
            
            EmberSecureField(
                title: "SENHA",
                placeholder: "Crie uma senha segura",
                text: $regPassword,
                isRequired: true,
                helperText: "Mínimo de 3 caracteres para o ambiente de testes."
            )
            
            EmberSecureField(
                title: "CONFIRMAR SENHA",
                placeholder: "Digite a mesma senha novamente",
                text: $regConfirmPassword,
                isRequired: true
            )
            
            if !regPassword.isEmpty && !regConfirmPassword.isEmpty && regPassword != regConfirmPassword {
                Text("As senhas digitadas não coincidem.")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
    
    // PASSO 2 (CANDIDATO): Dados Pessoais
    private var step2CandidatePersonalView: some View {
        VStack(alignment: .leading, spacing: 16) {
            EmberTextField(
                title: "NOME COMPLETO",
                placeholder: "ex: Maria da Silva",
                text: $candidateName,
                icon: "person.fill",
                isRequired: true,
                autocapitalization: .words
            )
            
            HStack(spacing: 12) {
                EmberTextField(
                    title: "CPF",
                    placeholder: "000.000.000-00",
                    text: $cpf,
                    icon: "number",
                    isRequired: true,
                    keyboardType: .numberPad,
                    mask: InputMask.cpf
                )
                
                EmberTextField(
                    title: "NASCIMENTO",
                    placeholder: "DD/MM/AAAA",
                    text: $birthDate,
                    icon: "calendar",
                    keyboardType: .numberPad,
                    mask: InputMask.date
                )
            }
            
            HStack(spacing: 12) {
                EmberTextField(
                    title: "CELULAR / WHATSAPP",
                    placeholder: "(00) 00000-0000",
                    text: $phone,
                    icon: "phone.fill",
                    isRequired: true,
                    keyboardType: .phonePad,
                    mask: InputMask.phone
                )
                
                EmberTextField(
                    title: "CIDADE / BAIRRO",
                    placeholder: "São Paulo - SP",
                    text: $address,
                    icon: "mappin.and.ellipse",
                    isRequired: true,
                    autocapitalization: .words
                )
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GÊNERO")
                        .font(.caption).bold().foregroundColor(.secondary)
                    
                    Picker("Gênero", selection: $gender) {
                        ForEach(Gender.allCases) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("CONDIÇÃO PCD")
                        .font(.caption).bold().foregroundColor(.secondary)
                    
                    Picker("PCD", selection: $disability) {
                        ForEach(DisabilityType.allCases) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
            
            if disability != .none {
                EmberTextField(
                    title: "DETALHES OU ADAPTAÇÕES PCD",
                    placeholder: "ex: Leitor de tela, rampa de acesso, etc.",
                    text: $disabilityDetails,
                    icon: "accessibility"
                )
            }
        }
    }
    
    // PASSO 2 (EMPRESA): Dados Corporativos
    private var step2CompanyCorporateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            EmberTextField(
                title: "RAZÃO SOCIAL",
                placeholder: "ex: Tech Solutions Desenvolvimento Ltda.",
                text: $companyName,
                icon: "building.2.fill",
                isRequired: true,
                autocapitalization: .words
            )
            
            EmberTextField(
                title: "NOME FANTASIA (EXIBIÇÃO)",
                placeholder: "ex: Tech Solutions",
                text: $tradeName,
                icon: "tag.fill",
                autocapitalization: .words
            )
            
            HStack(spacing: 12) {
                EmberTextField(
                    title: "CNPJ",
                    placeholder: "00.000.000/0000-00",
                    text: $cnpj,
                    icon: "number",
                    isRequired: true,
                    keyboardType: .numberPad,
                    mask: InputMask.cnpj
                )
                
                EmberTextField(
                    title: "SETOR DE ATUAÇÃO",
                    placeholder: "ex: Tecnologia, Fintech...",
                    text: $industry,
                    icon: "briefcase.fill",
                    autocapitalization: .words
                )
            }
            
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
                    placeholder: "ex: Curitiba - PR",
                    text: $address,
                    icon: "mappin.and.ellipse",
                    autocapitalization: .words
                )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("PORTE DA ORGANIZAÇÃO")
                    .font(.caption).bold().foregroundColor(.secondary)
                
                Picker("Porte", selection: $companySize) {
                    ForEach(CompanySize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // PASSO 3 (CANDIDATO): Perfil Profissional
    private var step3CandidateProfessionalView: some View {
        VStack(alignment: .leading, spacing: 18) {
            SkillTagInputView(
                title: "HABILIDADES E COMPETÊNCIAS",
                placeholder: "Digite uma habilidade (ex: Swift)",
                tags: $candidateSkills,
                suggestions: ["Swift", "SwiftUI", "iOS", "Git", "Python", "SQL", "React", "Figma", "Comunicação", "Organização"],
                isRequired: true
            )
            
            SkillTagInputView(
                title: "CERTIFICADOS E FORMAÇÕES",
                placeholder: "Digite um certificado (ex: Apple Developer)",
                tags: $candidateCertificates,
                suggestions: ["Apple Developer Academy", "Scrum Master", "AWS Cloud", "Inglês Avançado", "Graduação em TI"],
                isRequired: false,
                accentColor: .orange
            )
            
            EmberTextEditor(
                title: "RESUMO PROFISSIONAL (BIO)",
                placeholder: "Conte brevemente sobre seus objetivos de carreira, experiência e pontos fortes...",
                text: $candidateBio,
                icon: "text.quote",
                minHeight: 90
            )
            
            EmberTextField(
                title: "LINKEDIN / PORTFÓLIO",
                placeholder: "https://linkedin.com/in/seuperfil",
                text: $linkedinURL,
                icon: "link",
                keyboardType: .URL,
                autocapitalization: .never
            )
        }
    }
    
    // PASSO 3 (EMPRESA): Perfil Institucional
    private var step3CompanyProfileView: some View {
        VStack(alignment: .leading, spacing: 18) {
            EmberTextEditor(
                title: "SOBRE A EMPRESA (DESCRIÇÃO)",
                placeholder: "Conte sobre a cultura da empresa, seus produtos e missão...",
                text: $companyBio,
                icon: "text.quote",
                minHeight: 90
            )
            
            EmberTextField(
                title: "WEBSITE OU LINKEDIN",
                placeholder: "https://suaempresa.com.br",
                text: $companyWebsite,
                icon: "globe",
                keyboardType: .URL,
                autocapitalization: .never
            )
            
            EmberTextEditor(
                title: "MENSAGEM AUTOMÁTICA DE MATCH",
                placeholder: "Mensagem que será enviada aos candidatos no momento em que um Match acontecer...",
                text: $autoWelcomeMessage,
                icon: "bubble.left.and.bubble.right.fill",
                minHeight: 80,
                helperText: "Enviada automaticamente ao candidato no chat quando houver Match."
            )
        }
    }
    
    // MARK: - Validação de Etapas do Wizard
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 1:
            return !regEmail.trimmingCharacters(in: .whitespaces).isEmpty &&
                   regEmail.contains("@") &&
                   !regPassword.trimmingCharacters(in: .whitespaces).isEmpty &&
                   regPassword == regConfirmPassword
        case 2:
            if selectedRole == .candidate {
                return !candidateName.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !cpf.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !address.trimmingCharacters(in: .whitespaces).isEmpty
            } else {
                return !companyName.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !cnpj.trimmingCharacters(in: .whitespaces).isEmpty
            }
        case 3:
            if selectedRole == .candidate {
                return !candidateSkills.isEmpty
            } else {
                return true
            }
        default:
            return false
        }
    }
    
    // MARK: - Ações e Lógica de Navegação
    private func handleWizardBack() {
        if currentStep > 1 {
            withAnimation(.spring()) { currentStep -= 1 }
        } else {
            withAnimation(.spring()) { screenMode = .welcome }
        }
    }
    
    private func handleWizardNext() {
        if currentStep < 3 {
            withAnimation(.spring()) { currentStep += 1 }
        } else {
            handleRegister()
        }
    }
    
    private func handleLogin() {
        let success = vm.login(email: loginEmail, password: loginPassword, role: selectedRole)
        if !success {
            authErrorMessage = "E-mail ou senha incorretos, ou o perfil selecionado (\(selectedRole == .candidate ? "Candidato" : "Empresa")) não corresponde a esta conta."
            showAuthError = true
        }
    }
    
    private func handleRegister() {
        if selectedRole == .candidate {
            let skillsString = candidateSkills.joined(separator: ", ")
            let certsString = candidateCertificates.joined(separator: ", ")
            
            vm.registerCandidate(
                name: candidateName,
                email: regEmail,
                password: regPassword,
                cpf: cpf,
                phone: phone,
                address: address,
                birthDate: birthDate,
                gender: gender,
                disability: disability,
                disabilityDetails: disabilityDetails,
                bio: candidateBio,
                skills: skillsString,
                certificates: certsString,
                linkedin: linkedinURL
            )
        } else {
            vm.registerCompany(
                companyName: companyName,
                tradeName: tradeName,
                email: regEmail,
                password: regPassword,
                cnpj: cnpj,
                phone: phone,
                address: address,
                industry: industry,
                companySize: companySize,
                bio: companyBio,
                website: companyWebsite,
                welcomeMessage: autoWelcomeMessage
            )
        }
    }
    
    private func quickLoginCandidate() {
        _ = vm.login(email: "thiago@example.com", password: "123", role: .candidate)
    }
    
    private func quickLoginCompany() {
        _ = vm.login(email: "jobs@cocoaapps.io", password: "123", role: .company)
    }
    
    private func fillDemoCredentials() {
        if selectedRole == .candidate {
            loginEmail = "thiago@example.com"
            loginPassword = "123"
        } else {
            loginEmail = "jobs@cocoaapps.io"
            loginPassword = "123"
        }
    }
}
