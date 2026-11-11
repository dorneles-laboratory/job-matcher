import SwiftUI

// MARK: - Formatadores e Máscaras de Entrada (InputMask)
enum InputMask {
    /// Extrai apenas números de uma string
    nonisolated static func digitsOnly(_ string: String) -> String {
        return string.filter { $0.isNumber }
    }
    
    /// Máscara de CPF: 000.000.000-00 (máximo 11 dígitos)
    nonisolated static func cpf(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(11))
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 3 || index == 6 {
                result.append(".")
            } else if index == 9 {
                result.append("-")
            }
            result.append(char)
        }
        return result
    }
    
    /// Máscara de CNPJ: 00.000.000/0000-00 (máximo 14 dígitos)
    nonisolated static func cnpj(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(14))
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 2 || index == 5 {
                result.append(".")
            } else if index == 8 {
                result.append("/")
            } else if index == 12 {
                result.append("-")
            }
            result.append(char)
        }
        return result
    }
    
    /// Máscara de Telefone / Celular com DDD: (00) 00000-0000 ou (00) 0000-0000
    nonisolated static func phone(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(11))
        var result = ""
        let count = digits.count
        
        for (index, char) in digits.enumerated() {
            if index == 0 {
                result.append("(")
            }
            if index == 2 {
                result.append(") ")
            }
            if count <= 10 {
                if index == 6 {
                    result.append("-")
                }
            } else {
                if index == 7 {
                    result.append("-")
                }
            }
            result.append(char)
        }
        return result
    }
    
    /// Máscara de Data: DD/MM/AAAA (máximo 8 dígitos)
    nonisolated static func date(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(8))
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 2 || index == 4 {
                result.append("/")
            }
            result.append(char)
        }
        return result
    }
}

// MARK: - Campo de Texto Estilizado (EmberTextField)
struct EmberTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String = "pencil"
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var mask: ((String) -> String)? = nil
    var helperText: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .bold()
                    .foregroundColor(isFocused ? .appPurple : .secondary)
                
                if isRequired {
                    Text("*")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? .appPurple : .secondary)
                    .frame(width: 22)
                
                TextField(placeholder, text: Binding(
                    get: { text },
                    set: { newValue in
                        if let mask = mask {
                            text = mask(newValue)
                        } else {
                            text = newValue
                        }
                    }
                ))
                .focused($isFocused)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .font(.subheadline)
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.appPurple : Color(UIColor.systemGray4).opacity(0.5), lineWidth: isFocused ? 1.8 : 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            
            if let helper = helperText, !helper.isEmpty {
                Text(helper)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Campo de Senha Estilizado com Visualização Oculta/Visível (EmberSecureField)
struct EmberSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    var helperText: String? = nil
    
    @State private var isVisible: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .bold()
                    .foregroundColor(isFocused ? .appPurple : .secondary)
                
                if isRequired {
                    Text("*")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? .appPurple : .secondary)
                    .frame(width: 22)
                
                if isVisible {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.subheadline)
                } else {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                        .font(.subheadline)
                }
                
                Button(action: { isVisible.toggle() }) {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.appPurple : Color(UIColor.systemGray4).opacity(0.5), lineWidth: isFocused ? 1.8 : 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            
            if let helper = helperText, !helper.isEmpty {
                Text(helper)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Editor de Texto Multilinha Estilizado (EmberTextEditor)
struct EmberTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String = "text.alignleft"
    var isRequired: Bool = false
    var minHeight: CGFloat = 85
    var helperText: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .bold()
                    .foregroundColor(isFocused ? .appPurple : .secondary)
                
                if isRequired {
                    Text("*")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.red)
                }
            }
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.placeholderText))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $text)
                    .focused($isFocused)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.appPurple : Color(UIColor.systemGray4).opacity(0.5), lineWidth: isFocused ? 1.8 : 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            
            if let helper = helperText, !helper.isEmpty {
                Text(helper)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Seletor Interativo de Tags/Chips (SkillTagInputView)
struct SkillTagInputView: View {
    let title: String
    let placeholder: String
    @Binding var tags: [String]
    var suggestions: [String] = []
    var isRequired: Bool = false
    var accentColor: Color = .appPurple
    
    @State private var newTagText = ""
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                    if isRequired {
                        Text("*")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                Text("\(tags.count) adicionada\(tags.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Campo para digitar nova tag
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                        .foregroundColor(accentColor)
                    
                    TextField(placeholder, text: $newTagText)
                        .font(.subheadline)
                        .focused($isFieldFocused)
                        .onSubmit(addTag)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFieldFocused ? accentColor : Color(UIColor.systemGray4).opacity(0.4), lineWidth: 1)
                )
                
                Button(action: addTag) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Adicionar")
                    }
                    .font(.caption).bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(newTagText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.4) : accentColor)
                    .cornerRadius(10)
                }
                .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            // Sugestões Rápidas (caso haja)
            let unselectedSuggestions = suggestions.filter { sugg in
                !tags.contains(where: { $0.caseInsensitiveCompare(sugg) == .orderedSame })
            }
            if !unselectedSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sugestões Rápidas (toque para adicionar):")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(unselectedSuggestions.prefix(8), id: \.self) { sugg in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        tags.append(sugg)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 9, weight: .bold))
                                        Text(sugg)
                                            .font(.caption2)
                                            .bold()
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(accentColor.opacity(0.12))
                                    .foregroundColor(accentColor)
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            
            // Lista de Tags Selecionadas
            if !tags.isEmpty {
                TagFlowLayout(tags: tags) { tag in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        tags.removeAll { $0 == tag }
                    }
                }
            } else {
                Text("Nenhuma tag adicionada ainda.")
                    .font(.caption2)
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                tags.append(trimmed)
            }
        }
        newTagText = ""
    }
}

// MARK: - Flow Layout Flexível para Tags
struct TagFlowLayout: View {
    let tags: [String]
    let onRemove: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 6) {
                        Text(tag)
                            .font(.caption)
                            .bold()
                        
                        Button(action: { onRemove(tag) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.appPurple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Card de Seleção de Papel / Perfil (RoleSelectionCard)
struct RoleSelectionCard: View {
    let role: UserRole
    let isSelected: Bool
    let onSelect: () -> Void
    
    var iconName: String {
        switch role {
        case .candidate: return "person.crop.circle.badge.checkmark"
        case .company: return "building.2.crop.circle.fill"
        }
    }
    
    var title: String {
        switch role {
        case .candidate: return "Sou Candidato"
        case .company: return "Sou Empresa"
        }
    }
    
    var subtitle: String {
        switch role {
        case .candidate: return "Buscar vagas compatíveis, dar match e conversar direto com recrutadores."
        case .company: return "Publicar vagas, avaliar talentos e encontrar os melhores profissionais."
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.appPurple : Color(UIColor.systemGray5))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .bold()
                            .foregroundColor(isSelected ? .primary : .secondary)
                        
                        Spacer()
                        
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isSelected ? .appPurple : Color(UIColor.systemGray4))
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.appPurple : Color(UIColor.systemGray4).opacity(0.4), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.appPurple.opacity(0.18) : Color.black.opacity(0.04), radius: isSelected ? 8 : 4, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
