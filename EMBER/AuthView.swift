import SwiftUI

struct AuthView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    
    @State private var isRegistering = true
    @State private var showAuthError = false
    
    // Credenciais comuns
    @State private var email = ""
    @State private var password = ""
    @State private var role: UserRole = .candidate
    
    // Campos específicos de CANDIDATO (CPF)
    @State private var candidateName = ""
    @State private var cpf = ""
    @State private var phone = ""             // NOVO
    @State private var address = ""           // NOVO
    @State private var birthDate = ""
    @State private var gender: Gender = .male
    @State private var disability: DisabilityType = .none
    @State private var disabilityDetails = ""
    @State private var candidateBio = ""
    @State private var skills = ""
    @State private var certificates = ""
    @State private var linkedinURL = ""
    
    // Campos específicos de EMPRESA (CNPJ)
    @State private var companyName = ""
    @State private var tradeName = ""
    @State private var cnpj = ""
    @State private var industry = ""
    @State private var companySize: CompanySize = .small
    @State private var companyBio = ""
    @State private var companyWebsite = ""
    @State private var autoWelcomeMessage = "Olá! Ficamos muito felizes com o Match. Quando podemos agendar uma primeira conversa?"
    
    // MARK: - Validação de Formulário Obrigatório
    var isFormValid: Bool {
        if !isRegistering {
            // No modo Login, apenas email e senha são exigidos
            return !email.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !password.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            // No Cadastro, os campos essenciais não podem estar em branco
            if role == .candidate {
                return !email.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !password.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !candidateName.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !cpf.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !address.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !skills.trimmingCharacters(in: .whitespaces).isEmpty
            } else {
                return !email.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !password.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !companyName.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !cnpj.trimmingCharacters(in: .whitespaces).isEmpty
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Top Header
                VStack(spacing: 6) {
                    Image(systemName: "briefcase.fill")
                        .resizable().scaledToFit().frame(width: 50, height: 50).foregroundColor(.appPurple)
                    Text("Job Matcher").font(.title).bold()
                    Text("Conectando Talentos e Oportunidades").font(.caption).foregroundColor(.secondary)
                }
                .padding(.top, 10)
                
                Picker("Modo", selection: $isRegistering) {
                    Text("Entrar").tag(false)
                    Text("Cadastrar-se").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if isRegistering {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("TIPO DE PERFIL").font(.caption2).bold().foregroundColor(.secondary)
                                Picker("Perfil", selection: $role) {
                                    ForEach(UserRole.allCases) { r in Text(r.rawValue).tag(r) }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                        
                        Group {
                            TextField("E-mail *", text: $email)
                                .keyboardType(.emailAddress).autocapitalization(.none).textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            SecureField("Senha de acesso *", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        if isRegistering {
                            Divider().padding(.vertical, 4)
                            
                            if role == .candidate {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("DADOS PESSOAIS E CONTATO").font(.caption2).bold().foregroundColor(.appPurple)
                                    
                                    TextField("Nome Completo *", text: $candidateName).textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    HStack(spacing: 10) {
                                        TextField("CPF *", text: $cpf).keyboardType(.numberPad).textFieldStyle(RoundedBorderTextFieldStyle())
                                        TextField("Nascimento", text: $birthDate).keyboardType(.numbersAndPunctuation).textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    
                                    HStack(spacing: 10) {
                                        TextField("Celular (WhatsApp) *", text: $phone).keyboardType(.phonePad).textFieldStyle(RoundedBorderTextFieldStyle())
                                        TextField("Cidade / Bairro (Residência) *", text: $address).textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Gênero:").font(.caption).foregroundColor(.secondary)
                                            Picker("Gênero", selection: $gender) { ForEach(Gender.allCases) { g in Text(g.rawValue).tag(g) } }
                                                .pickerStyle(MenuPickerStyle()).padding(6).background(Color(UIColor.systemGray6)).cornerRadius(8)
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("PCD:").font(.caption).foregroundColor(.secondary)
                                            Picker("PCD", selection: $disability) { ForEach(DisabilityType.allCases) { d in Text(d.rawValue).tag(d) } }
                                                .pickerStyle(MenuPickerStyle()).padding(6).background(Color(UIColor.systemGray6)).cornerRadius(8)
                                        }
                                    }
                                    
                                    if disability != .none {
                                        TextField("Detalhes ou adaptações", text: $disabilityDetails).textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    
                                    Text("PERFIL PROFISSIONAL").font(.caption2).bold().foregroundColor(.appPurple).padding(.top, 6)
                                    
                                    TextField("Habilidades (ex: Swift, Vendas) *", text: $skills).textFieldStyle(RoundedBorderTextFieldStyle())
                                    TextField("Resumo profissional (Bio)", text: $candidateBio).textFieldStyle(RoundedBorderTextFieldStyle())
                                    TextField("Certificados", text: $certificates).textFieldStyle(RoundedBorderTextFieldStyle())
                                    TextField("LinkedIn (URL)", text: $linkedinURL).keyboardType(.URL).autocapitalization(.none).textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("DADOS CORPORATIVOS").font(.caption2).bold().foregroundColor(.appPurple)
                                    
                                    TextField("Razão Social *", text: $companyName).textFieldStyle(RoundedBorderTextFieldStyle())
                                    TextField("Nome Fantasia", text: $tradeName).textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    HStack {
                                        TextField("CNPJ *", text: $cnpj).keyboardType(.numberPad).textFieldStyle(RoundedBorderTextFieldStyle())
                                        TextField("Setor", text: $industry).textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    
                                    HStack {
                                        TextField("Telefone de Contato", text: $phone).keyboardType(.phonePad).textFieldStyle(RoundedBorderTextFieldStyle())
                                        TextField("Sede / Endereço", text: $address).textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Porte da Empresa:").font(.caption).foregroundColor(.secondary)
                                        Picker("Porte", selection: $companySize) { ForEach(CompanySize.allCases) { s in Text(s.rawValue).tag(s) } }
                                            .pickerStyle(MenuPickerStyle()).padding(6).frame(maxWidth: .infinity, alignment: .leading).background(Color(UIColor.systemGray6)).cornerRadius(8)
                                    }
                                    
                                    Text("SOBRE A ORGANIZAÇÃO").font(.caption2).bold().foregroundColor(.appPurple).padding(.top, 6)
                                    TextField("Descrição da Empresa", text: $companyBio).textFieldStyle(RoundedBorderTextFieldStyle())
                                    TextField("Website", text: $companyWebsite).keyboardType(.URL).autocapitalization(.none).textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Mensagem Automática de Match:").font(.caption).foregroundColor(.secondary)
                                        TextEditor(text: $autoWelcomeMessage).frame(height: 70).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(UIColor.systemGray4), lineWidth: 1))
                                    }
                                }
                            }
                        }
                        
                        // Aviso de campos obrigatórios se o formulário não for válido
                        if isRegistering && !isFormValid {
                            Text("Preencha todos os campos obrigatórios marcados com (*)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                        
                        Button(action: handleAuth) {
                            Text(isRegistering ? "Concluir Cadastro" : "Acessar Conta")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                // Botão fica Cinza se o formulário estiver incompleto
                                .background(isFormValid ? Color.appPurple : Color.gray.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top, 5)
                        .disabled(!isFormValid) // Bloqueia o clique fisicamente
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .alert("Erro de Login", isPresented: $showAuthError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("E-mail ou senha incorretos, ou o tipo de perfil (Candidato/Empresa) selecionado está errado.")
            }
        }
    }
    
    private func handleAuth() {
        if isRegistering {
            if role == .candidate {
                vm.registerCandidate(
                    name: candidateName, email: email, password: password, cpf: cpf, phone: phone, address: address,
                    birthDate: birthDate, gender: gender, disability: disability,
                    disabilityDetails: disabilityDetails, bio: candidateBio, skills: skills,
                    certificates: certificates, linkedin: linkedinURL
                )
            } else {
                vm.registerCompany(
                    companyName: companyName, tradeName: tradeName, email: email, password: password,
                    cnpj: cnpj, phone: phone, address: address, industry: industry, companySize: companySize, bio: companyBio,
                    website: companyWebsite, welcomeMessage: autoWelcomeMessage
                )
            }
        } else {
            let success = vm.login(email: email, password: password, role: role)
            if !success { showAuthError = true }
        }
    }
}
