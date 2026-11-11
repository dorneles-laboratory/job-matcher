import SwiftUI

// MARK: - Tela Principal da Agenda
struct AgendaView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @State private var selectedTab: Int = 0 // 0: Entrevistas, 1: Disponibilidade / Nova
    @State private var statusFilter: String = "Todas"
    @State private var showScheduleSheet: Bool = false
    @State private var showGoogleSyncNotice: Bool = false
    
    var userAppointments: [InterviewAppointment] {
        guard let user = vm.currentUser else { return [] }
        if user.role == .candidate {
            return vm.appointments.filter { $0.candidateId == user.id }
        } else {
            return vm.appointments.filter { $0.companyId == user.id }
        }
    }
    
    var filteredAppointments: [InterviewAppointment] {
        let list = userAppointments.sorted { $0.scheduledDate < $1.scheduledDate }
        switch statusFilter {
        case "Aguardando":
            return list.filter { $0.effectiveStatus == .pending }
        case "Confirmadas":
            return list.filter { $0.effectiveStatus == .confirmed }
        case "Histórico":
            return list.filter { $0.effectiveStatus == .declined || $0.effectiveStatus == .expired }
        default:
            return list
        }
    }
    
    var pendingCount: Int {
        userAppointments.filter { $0.effectiveStatus == .pending }.count
    }
    
    var confirmedCount: Int {
        userAppointments.filter { $0.effectiveStatus == .confirmed }.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Seletor de Modo (Entrevistas vs Configurar Disponibilidade)
                Picker("Modo da Agenda", selection: $selectedTab) {
                    Text("Compromissos").tag(0)
                    if vm.currentUser?.role == .candidate {
                        Text("Minha Disponibilidade").tag(1)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                if selectedTab == 0 {
                    appointmentsContent
                } else {
                    CandidateAvailabilityView()
                }
            }
            .navigationTitle("Agenda & Entrevistas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vm.currentUser?.role == .company {
                        Button {
                            showScheduleSheet = true
                        } label: {
                            Label("Agendar", systemImage: "plus.circle.fill")
                                .foregroundColor(.appPurple)
                        }
                    }
                }
            }
            .sheet(isPresented: $showScheduleSheet) {
                ScheduleInterviewSheet()
            }
            .alert("Sincronização Google Agenda", isPresented: $showGoogleSyncNotice) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Ao tocar em 'Adicionar ao Google Agenda', o evento será aberto diretamente no seu Google Calendar com data, horário e link preenchidos.")
            }
            .onAppear {
                vm.checkAndExpireAppointments()
            }
        }
    }
    
    // Conteúdo da Lista de Entrevistas
    private var appointmentsContent: some View {
        VStack(spacing: 0) {
            // Cartões de Resumo e Integração Google
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Card Pendentes
                    StatPillCard(
                        title: "Aguardando",
                        count: pendingCount,
                        icon: "clock.badge.exclamationmark.fill",
                        color: .orange
                    )
                    
                    // Card Confirmadas
                    StatPillCard(
                        title: "Confirmadas",
                        count: confirmedCount,
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                }
                
                // Banner Informativo de Integração Google Agenda
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Integração Google Agenda Ativa")
                            .font(.caption).bold()
                        Text("Sincronize entrevistas e evite conflitos de horário em tempo real.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button {
                        showGoogleSyncNotice = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding(10)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Filtros de Status (Pills)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Todas", "Aguardando", "Confirmadas", "Histórico"], id: \.self) { filter in
                        FilterChip(title: filter, isSelected: statusFilter == filter) {
                            statusFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            
            Divider()
            
            // Lista de Compromissos
            if filteredAppointments.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60))
                        .foregroundColor(.appSilver)
                    
                    Text(statusFilter == "Todas" ? "Nenhuma entrevista agendada" : "Nenhum compromisso nesta categoria")
                        .font(.headline)
                    
                    Text(vm.currentUser?.role == .candidate
                         ? "Quando uma empresa propor um horário para entrevista, você verá aqui com o prazo para aceitar ou recusar."
                         : "Abra uma conversa de Match ou toque no botão '+' acima para propor uma entrevista a um candidato.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredAppointments) { appt in
                            AppointmentCardView(appointment: appt)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Card de Resumo Numérico
struct StatPillCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.title3).bold()
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Chip de Filtro
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption).bold()
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.appPurple : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card Detalhado do Agendamento / Entrevista
struct AppointmentCardView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @Environment(\.openURL) var openURL
    let appointment: InterviewAppointment
    
    @State private var showDeclineAlert: Bool = false
    @State private var declineReason: String = ""
    @State private var copiedLinkToast: Bool = false
    
    var isCandidate: Bool {
        vm.currentUser?.role == .candidate
    }
    
    var otherPartyName: String {
        isCandidate ? appointment.companyName : appointment.candidateName
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, dd 'de' MMMM"
        return formatter.string(from: appointment.scheduledDate).capitalized
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: appointment.scheduledDate)
        let end = formatter.string(from: appointment.scheduledDate.addingTimeInterval(TimeInterval(appointment.durationMinutes * 60)))
        return "\(start) às \(end) (\(appointment.durationMinutes) min)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cabeçalho: Status + Badge de Prazo
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    Image(systemName: appointment.effectiveStatus.icon)
                        .foregroundColor(appointment.effectiveStatus.color)
                    Text(appointment.effectiveStatus.title)
                        .font(.caption).bold()
                        .foregroundColor(appointment.effectiveStatus.color)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(appointment.effectiveStatus.color.opacity(0.12))
                .cornerRadius(8)
                
                Spacer()
                
                // Prazo regressivo para evitar empresas esperando no vácuo
                if appointment.effectiveStatus == .pending {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text(appointment.remainingTimeText)
                    }
                    .font(.caption2).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                }
            }
            
            // Dados da Vaga e Contato
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.jobTitle)
                    .font(.headline)
                    .bold()
                
                HStack(spacing: 6) {
                    Image(systemName: isCandidate ? "building.2.fill" : "person.fill")
                        .foregroundColor(.appPurple)
                        .font(.caption)
                    Text(otherPartyName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Data, Horário e Plataforma
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.appPurple)
                        .frame(width: 18)
                    Text(formattedDate)
                        .font(.subheadline).bold()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.appPurple)
                        .frame(width: 18)
                    Text(formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .foregroundColor(.blue)
                        .frame(width: 18)
                    Text(appointment.locationOrPlatform)
                        .font(.subheadline)
                    
                    if !appointment.meetingLink.isEmpty {
                        Button {
                            UIPasteboard.general.string = appointment.meetingLink
                            copiedLinkToast = true
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !appointment.notes.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "note.text")
                            .foregroundColor(.gray)
                            .frame(width: 18)
                        Text(appointment.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if copiedLinkToast {
                Text("Link da reunião copiado!")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
            
            // Ações / Botões
            Divider()
            
            if appointment.effectiveStatus == .pending && isCandidate {
                // Ações do Candidato: Aceitar vs Recusar para não deixar a empresa esperando
                HStack(spacing: 12) {
                    Button(action: {
                        vm.acceptInterview(appointmentId: appointment.id)
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirmar Horário")
                        }
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showDeclineAlert = true
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Recusar")
                        }
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemGray5))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
            } else if appointment.effectiveStatus == .confirmed {
                // Compromisso Confirmado: Botão Google Agenda e Link da Reunião
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        // Botão Oficial Google Agenda
                        Button(action: {
                            if let url = GoogleCalendarHelper.generateGoogleCalendarURL(appointment: appointment) {
                                openURL(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.plus")
                                Text("Adicionar ao Google Agenda")
                            }
                            .font(.subheadline).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // Botão Abrir Reunião (ex: Meet / Zoom)
                        if let meetURL = URL(string: appointment.meetingLink), !appointment.meetingLink.isEmpty {
                            Button(action: {
                                openURL(meetURL)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right.video.fill")
                                    Text("Entrar")
                                }
                                .font(.subheadline).bold()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.appPurple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                }
            } else if appointment.effectiveStatus == .expired {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.gray)
                    Text("O convite expirou sem resposta a tempo. O horário foi liberado.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .alert("Recusar Horário de Entrevista", isPresented: $showDeclineAlert) {
            Button("Confirmar Recusa", role: .destructive) {
                vm.declineInterview(appointmentId: appointment.id)
            }
            Button("Voltar", role: .cancel) { }
        } message: {
            Text("Ao recusar, a empresa será notificada imediatamente para que não precise esperar por você.")
        }
    }
}

// MARK: - Tela de Gestão de Disponibilidade do Candidato
struct CandidateAvailabilityView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    
    @State private var selectedShifts: Set<WorkShift> = []
    @State private var selectedDays: Set<String> = []
    @State private var showSavedAlert: Bool = false
    
    let allDays = ["Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Banner Explicativo
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.title)
                        .foregroundColor(.appPurple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Controle de Horários & Anti-Sobrecarga")
                            .font(.headline)
                        Text("Defina os turnos em que você realmente tem disponibilidade. O app evita que você se candidate a vagas incompatíveis e impede que empresas fiquem esperando no vácuo.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.appPurple.opacity(0.1))
                .cornerRadius(12)
                
                // Turnos Disponíveis
                VStack(alignment: .leading, spacing: 10) {
                    Text("Turnos que você pode trabalhar e fazer entrevistas:")
                        .font(.subheadline).bold()
                    
                    ForEach(WorkShift.allCases) { shift in
                        let isSelected = selectedShifts.contains(shift)
                        Button {
                            if isSelected {
                                if selectedShifts.count > 1 { selectedShifts.remove(shift) }
                            } else {
                                selectedShifts.insert(shift)
                            }
                        } label: {
                            HStack {
                                Image(systemName: shift.icon)
                                    .foregroundColor(.appPurple)
                                    .frame(width: 24)
                                
                                Text(shift.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isSelected ? .appPurple : .gray)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Dias da Semana Livres
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dias da semana disponíveis:")
                        .font(.subheadline).bold()
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(allDays, id: \.self) { day in
                            let isSelected = selectedDays.contains(day)
                            Button {
                                if isSelected {
                                    if selectedDays.count > 1 { selectedDays.remove(day) }
                                } else {
                                    selectedDays.insert(day)
                                }
                            } label: {
                                Text(day)
                                    .font(.caption).bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isSelected ? Color.appPurple : Color(UIColor.secondarySystemBackground))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Botão Salvar
                Button(action: saveAvailability) {
                    Text("Salvar Minha Disponibilidade")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPurple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .onAppear {
            if let user = vm.currentUser {
                selectedShifts = Set(user.availableShifts)
                selectedDays = Set(user.availableDays)
            }
        }
        .alert("Disponibilidade Atualizada!", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Sua agenda foi configurada com sucesso. As empresas e os filtros de vagas agora respeitarão seus horários.")
        }
    }
    
    private func saveAvailability() {
        vm.updateCandidateAvailability(
            shifts: Array(selectedShifts),
            days: Array(selectedDays)
        )
        showSavedAlert = true
    }
}

// MARK: - Modal de Agendamento de Entrevista (Empresa -> Candidato)
struct ScheduleInterviewSheet: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @Environment(\.dismiss) var dismiss
    
    // Parâmetros opcionais pré-preenchidos se chamado do Chat
    var preselectedCandidate: UserProfile? = nil
    var preselectedJobId: UUID? = nil
    var preselectedJobTitle: String? = nil
    var conversationId: UUID? = nil
    
    @State private var selectedCandidateId: UUID = UUID()
    @State private var selectedJobId: UUID = UUID()
    @State private var interviewDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var durationMinutes: Int = 45
    @State private var platform: String = "Google Meet"
    @State private var meetingLink: String = "https://meet.google.com/ember-" + String(Int.random(in: 1000...9999))
    @State private var deadlineHours: Int = 24
    @State private var notes: String = "Conversa inicial sobre competências técnicas e alinhamento com a equipe."
    @State private var resultMessage: String = ""
    @State private var showResultAlert: Bool = false
    @State private var isSuccess: Bool = false
    
    var companyJobs: [JobPosting] {
        guard let company = vm.currentUser else { return [] }
        return vm.jobs.filter { $0.companyId == company.id }
    }
    
    var availableCandidates: [UserProfile] {
        vm.candidates
    }
    
    var conflictCheck: (hasConflict: Bool, conflictingTitle: String?) {
        vm.hasScheduleConflict(candidateId: selectedCandidateId, targetDate: interviewDate, durationMinutes: durationMinutes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vaga & Candidato")) {
                    if let preJobTitle = preselectedJobTitle {
                        HStack {
                            Text("Vaga:")
                            Spacer()
                            Text(preJobTitle).bold()
                        }
                    } else if !companyJobs.isEmpty {
                        Picker("Vaga", selection: $selectedJobId) {
                            ForEach(companyJobs) { job in
                                Text(job.title).tag(job.id)
                            }
                        }
                    } else {
                        Text("Vaga Geral / Aberta").foregroundColor(.secondary)
                    }
                    
                    if let preCand = preselectedCandidate {
                        HStack {
                            Text("Candidato:")
                            Spacer()
                            Text(preCand.name).bold()
                        }
                    } else if !availableCandidates.isEmpty {
                        Picker("Candidato", selection: $selectedCandidateId) {
                            ForEach(availableCandidates) { cand in
                                Text(cand.name).tag(cand.id)
                            }
                        }
                    }
                }
                
                Section(header: Text("Data, Horário e Duração")) {
                    DatePicker("Data e Hora", selection: $interviewDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                    
                    Picker("Duração", selection: $durationMinutes) {
                        Text("30 minutos").tag(30)
                        Text("45 minutos").tag(45)
                        Text("60 minutos (1h)").tag(60)
                        Text("90 minutos").tag(90)
                    }
                    
                    // Alerta em tempo real de conflito de agenda
                    if conflictCheck.hasConflict {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Atenção: O candidato já possui outro compromisso (\(conflictCheck.conflictingTitle ?? "")) nesse horário!")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Prazo de Resposta (Anti-Vácuo)")) {
                    Picker("Tempo limite para resposta", selection: $deadlineHours) {
                        Text("12 horas").tag(12)
                        Text("24 horas (Recomendado)").tag(24)
                        Text("48 horas").tag(48)
                        Text("72 horas").tag(72)
                    }
                    
                    Text("💡 Se o candidato não responder dentro de \(deadlineHours) horas, o horário é liberado automaticamente na sua agenda, evitando que sua equipe fique esperando sem retorno.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Link ou Local da Entrevista")) {
                    Picker("Plataforma", selection: $platform) {
                        Text("Google Meet").tag("Google Meet")
                        Text("Microsoft Teams").tag("Microsoft Teams")
                        Text("Zoom").tag("Zoom")
                        Text("Presencial no Escritório").tag("Presencial no Escritório")
                    }
                    
                    TextField("Link da Reunião", text: $meetingLink)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Instruções / Pauta da Reunião", text: $notes)
                }
                
                Section {
                    Button(action: submitInterview) {
                        HStack {
                            Spacer()
                            Image(systemName: "paperplane.fill")
                            Text("Enviar Convite com Prazo")
                                .bold()
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.appPurple)
                }
            }
            .navigationTitle("Agendar Entrevista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .alert("Agendamento", isPresented: $showResultAlert) {
                Button("OK") {
                    if isSuccess { dismiss() }
                }
            } message: {
                Text(resultMessage)
            }
            .onAppear {
                if let preCand = preselectedCandidate {
                    selectedCandidateId = preCand.id
                } else if let first = availableCandidates.first {
                    selectedCandidateId = first.id
                }
                
                if let preJob = preselectedJobId {
                    selectedJobId = preJob
                } else if let firstJob = companyJobs.first {
                    selectedJobId = firstJob.id
                }
            }
        }
    }
    
    private func submitInterview() {
        guard let company = vm.currentUser else { return }
        let cand = preselectedCandidate ?? availableCandidates.first(where: { $0.id == selectedCandidateId })
        let job = companyJobs.first(where: { $0.id == selectedJobId })
        
        let targetCandidateId = cand?.id ?? selectedCandidateId
        let targetCandidateName = cand?.name ?? "Candidato"
        let targetJobId = job?.id ?? selectedJobId
        let targetJobTitle = preselectedJobTitle ?? job?.title ?? "Vaga em Seleção"
        
        let result = vm.scheduleInterview(
            conversationId: conversationId,
            jobId: targetJobId,
            jobTitle: targetJobTitle,
            companyId: company.id,
            companyName: company.tradeName ?? company.companyName ?? company.name,
            candidateId: targetCandidateId,
            candidateName: targetCandidateName,
            date: interviewDate,
            durationMinutes: durationMinutes,
            locationOrPlatform: platform,
            meetingLink: meetingLink,
            notes: notes,
            deadlineHours: deadlineHours
        )
        
        isSuccess = result.success
        resultMessage = result.message
        showResultAlert = true
    }
}

// MARK: - Banner de Entrevista Ativa no Chat
struct ActiveAppointmentBannerView: View {
    @EnvironmentObject var vm: JobTinderViewModel
    @Environment(\.openURL) var openURL
    let appointment: InterviewAppointment
    
    var isCandidate: Bool {
        vm.currentUser?.role == .candidate
    }
    
    var formattedDateStr: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM 'às' HH:mm"
        return formatter.string(from: appointment.scheduledDate)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: appointment.effectiveStatus.icon)
                    .foregroundColor(appointment.effectiveStatus.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Entrevista \(appointment.effectiveStatus.title)")
                            .font(.caption).bold()
                            .foregroundColor(appointment.effectiveStatus.color)
                        
                        Spacer()
                        
                        if appointment.effectiveStatus == .pending {
                            Text(appointment.remainingTimeText)
                                .font(.caption2).bold()
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("\(formattedDateStr) • \(appointment.locationOrPlatform)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Botões Rápidos
            if appointment.effectiveStatus == .pending && isCandidate {
                HStack(spacing: 8) {
                    Button {
                        vm.acceptInterview(appointmentId: appointment.id)
                    } label: {
                        Text("Confirmar")
                            .font(.caption).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        vm.declineInterview(appointmentId: appointment.id)
                    } label: {
                        Text("Recusar")
                            .font(.caption).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color(UIColor.systemGray4))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }
            } else if appointment.effectiveStatus == .confirmed {
                HStack(spacing: 8) {
                    Button {
                        if let url = GoogleCalendarHelper.generateGoogleCalendarURL(appointment: appointment) {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Google Agenda")
                        }
                        .font(.caption).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    if let meetURL = URL(string: appointment.meetingLink), !appointment.meetingLink.isEmpty {
                        Button {
                            openURL(meetURL)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "video.fill")
                                Text("Acessar Link")
                            }
                            .font(.caption).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.appPurple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(appointment.effectiveStatus.color.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
