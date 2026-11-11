import SwiftUI

// MARK: - Botão de Chat no Canto Superior Direito do App
struct TopBarChatButton: View {
    @EnvironmentObject var vm: JobTinderViewModel
    var action: () -> Void
    
    var conversationCount: Int {
        guard let user = vm.currentUser else { return 0 }
        if user.role == .candidate {
            return vm.conversations.filter { $0.candidateId == user.id }.count
        } else {
            return vm.conversations.count
        }
    }
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.appPurple)
                    .padding(8)
                    .background(Color.appPurple.opacity(0.12))
                    .clipShape(Circle())
                
                if conversationCount > 0 {
                    Text("\(conversationCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 6, y: -4)
                }
            }
        }
        .accessibilityLabel("Abrir Mensagens e Chat")
    }
}

// MARK: - Lista de Chats (Usada tanto pelo Candidato quanto pela Empresa)
struct ChatListView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: JobTinderViewModel
    
    var filteredConversations: [MatchConversation] {
        guard let user = vm.currentUser else { return [] }
        if user.role == .candidate {
            return vm.conversations.filter { $0.candidateId == user.id }
        } else {
            return vm.conversations
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if filteredConversations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.appSilver)
                        Text("Nenhuma conversa ainda")
                            .font(.headline)
                        Text("Quando você der Match com uma vaga ou candidato, o chat aparecerá aqui!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                } else {
                    List(filteredConversations) { conv in
                        NavigationLink(destination: ChatDetailView(conversation: conv)) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.appPurple.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: vm.currentUser?.role == .candidate ? "building.2.fill" : "person.fill")
                                        .foregroundColor(.appPurple)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vm.currentUser?.role == .candidate ? conv.companyName : conv.candidateName)
                                        .font(.headline)
                                    
                                    Text(conv.jobTitle)
                                        .font(.caption)
                                        .foregroundColor(.appPurple)
                                        .bold()
                                    
                                    Text(conv.lastMessageText)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Mensagens & Matches")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Janela Principal de Mensagens
struct ChatDetailView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    let conversation: MatchConversation
    @State private var messageText = ""
    @State private var showCompanyInfo = false
    @State private var showScheduleSheet = false
    
    var currentMessages: [ChatMessage] {
        vm.conversations.first(where: { $0.id == conversation.id })?.messages ?? conversation.messages
    }
    
    var matchedCompany: UserProfile? {
        vm.getCompany(by: conversation.companyId) ?? vm.getCompany(byName: conversation.companyName)
    }
    
    var activeAppointment: InterviewAppointment? {
        vm.appointments.first { appt in
            (appt.conversationId == conversation.id || (appt.jobId == conversation.jobId && appt.candidateId == conversation.candidateId)) &&
            (appt.effectiveStatus == .pending || appt.effectiveStatus == .confirmed)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header estilo Telegram / WhatsApp com toque para ver perfil do contato
            Button(action: {
                if vm.currentUser?.role == .candidate {
                    showCompanyInfo = true
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.appPurple.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: vm.currentUser?.role == .candidate ? "building.2.fill" : "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.appPurple)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(vm.currentUser?.role == .candidate ? conversation.companyName : conversation.candidateName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if vm.currentUser?.role == .candidate {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Text("Vaga: \(conversation.jobTitle)")
                                .font(.caption)
                                .foregroundColor(.appPurple)
                                .bold()
                            
                            if vm.currentUser?.role == .candidate {
                                Text("• Ver informações")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if vm.currentUser?.role == .candidate {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Banner de Entrevista Ativa ou Proposta na conversa
            if let appt = activeAppointment {
                ActiveAppointmentBannerView(appointment: appt)
                Divider()
            }
            
            // Mensagens
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(currentMessages) { msg in
                            let isMe = msg.senderId == vm.currentUser?.id
                            HStack {
                                if isMe { Spacer() }
                                
                                Text(msg.text)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(isMe ? Color.appPurple : Color(UIColor.systemGray5))
                                    .foregroundColor(isMe ? .white : .primary)
                                    .cornerRadius(16)
                                    .frame(maxWidth: 280, alignment: isMe ? .trailing : .leading)
                                
                                if !isMe { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: currentMessages.count) { _ in
                    if let last = currentMessages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            
            // Input de Mensagem
            HStack(spacing: 10) {
                TextField("Digite uma mensagem...", text: $messageText)
                    .submitLabel(.send)
                    .onSubmit {
                        sendCurrentMessage()
                    }
                    .padding(10)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(20)
                
                Button(action: sendCurrentMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : Color.appPurple)
                        .clipShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showScheduleSheet = true
                } label: {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.appPurple)
                }
            }
        }
        .sheet(isPresented: $showCompanyInfo) {
            CompanyContactInfoSheet(
                company: matchedCompany,
                fallbackName: conversation.companyName,
                jobTitle: conversation.jobTitle
            )
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleInterviewSheet(
                preselectedCandidate: vm.getCandidate(by: conversation.candidateId),
                preselectedJobId: conversation.jobId,
                preselectedJobTitle: conversation.jobTitle,
                conversationId: conversation.id
            )
        }
    }
    
    private func sendCurrentMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        vm.sendMessage(conversationId: conversation.id, text: trimmed)
        messageText = ""
    }
}

// MARK: - Modal de Informações da Empresa (Estilo Telegram Contact Profile)
struct CompanyContactInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    let company: UserProfile?
    let fallbackName: String
    let jobTitle: String
    
    @State private var copiedAlert = false
    
    var displayName: String {
        company?.tradeName ?? company?.companyName ?? fallbackName
    }
    
    var phone: String {
        company?.phone ?? "+55 (11) 4004-0101"
    }
    
    var creationDate: String {
        company?.creationDate ?? "12/08/2017"
    }
    
    var description: String {
        if let bio = company?.bio, !bio.isEmpty {
            return bio
        }
        return "Empresa atuante no setor de tecnologia e inovação, comprometida com a atração e desenvolvimento de grandes talentos em parceria com a plataforma EMBER."
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar e Cabeçalho do Contato estilo Telegram
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appPurple.opacity(0.8), Color.appPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 95, height: 95)
                                .shadow(color: Color.appPurple.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 42))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)
                        
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Text(displayName)
                                    .font(.title2)
                                    .bold()
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                            }
                            
                            if let legalName = company?.companyName, legalName != displayName {
                                Text(legalName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let ind = company?.industry {
                                Text(ind)
                                    .font(.caption)
                                    .bold()
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.appPurple.opacity(0.12))
                                    .foregroundColor(.appPurple)
                                    .cornerRadius(12)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 6)
                    
                    // Card com Número de Telefone e Ação Rápida
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CONTATO")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(phone)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Telefone Corporativo / WhatsApp")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = phone
                                copiedAlert = true
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.subheadline)
                                    .foregroundColor(.appPurple)
                                    .padding(8)
                                    .background(Color.appPurple.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    
                    // Card com Descrição da Empresa
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DESCRIÇÃO / SOBRE A EMPRESA")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if let website = company?.linkedInURL, !website.isEmpty {
                                    Link(destination: URL(string: website) ?? URL(string: "https://ember.app")!) {
                                        Label("Visitar Website / LinkedIn", systemImage: "link")
                                            .font(.caption).bold()
                                            .foregroundColor(.appPurple)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    
                    // Card com Data de Criação / Fundação
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DATA DE CRIAÇÃO & INFORMAÇÕES CORPORATIVAS")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.orange)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(creationDate)
                                        .font(.headline)
                                    Text("Data de Fundação / Cadastro no Sistema")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            
                            if let cnpj = company?.cnpj {
                                Divider()
                                HStack(spacing: 14) {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 44)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cnpj)
                                            .font(.subheadline).bold()
                                        Text("CNPJ Cadastrado")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            
                            if let address = company?.address {
                                Divider()
                                HStack(spacing: 14) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.red)
                                        .frame(width: 44)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(address)
                                            .font(.subheadline)
                                        Text("Sede Corporativa")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    
                    // Card da Vaga Relacionada
                    VStack(alignment: .leading, spacing: 12) {
                        Text("VAGA DO PROCESSO SELETIVO")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.appPurple.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "briefcase.fill")
                                    .foregroundColor(.appPurple)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(jobTitle)
                                    .font(.headline)
                                Text("Match confirmado no chat")
                                    .font(.caption2)
                                    .foregroundColor(.appPurple)
                                    .bold()
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Perfil do Contato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.appPurple)
                        .bold()
                }
            }
            .alert("Número Copiado!", isPresented: $copiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("O telefone \(phone) foi copiado para a área de transferência.")
            }
        }
    }
}
