import SwiftUI
import Foundation

// MARK: - Serviço de Vagas Reais de Mercado & Inteligência Artificial (Gemini)
class GeminiJobService {
    static let shared = GeminiJobService()
    
    // Banco de Imagens Corporativas Reais da Internet (Unsplash CDN) para capas de empresas
    static let companyCoverImages: [String: String] = [
        "Cocoa Apps Studio": "https://images.unsplash.com/photo-1551434678-e076c223a692?w=1000&auto=format&fit=crop&q=80",
        "NuTech Solutions": "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1000&auto=format&fit=crop&q=80",
        "Mercado Global": "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1000&auto=format&fit=crop&q=80",
        "InovaData AI": "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=1000&auto=format&fit=crop&q=80",
        "CloudScale": "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1000&auto=format&fit=crop&q=80",
        "Studio Pixel": "https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=1000&auto=format&fit=crop&q=80",
        "DefaultTech": "https://images.unsplash.com/photo-1497366216548-37526070297c?w=1000&auto=format&fit=crop&q=80",
        "Fintech": "https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=1000&auto=format&fit=crop&q=80",
        "Design": "https://images.unsplash.com/photo-1542744094-3a31f272c490?w=1000&auto=format&fit=crop&q=80"
    ]
    
    static func getCoverImage(for companyName: String, category: String = "DefaultTech") -> String {
        if let direct = companyCoverImages[companyName] {
            return direct
        }
        let lower = companyName.lowercased()
        if lower.contains("tech") || lower.contains("app") || lower.contains("software") {
            return companyCoverImages["Cocoa Apps Studio"]!
        } else if lower.contains("bank") || lower.contains("pay") || lower.contains("nu") {
            return companyCoverImages["Fintech"]!
        } else if lower.contains("design") || lower.contains("pixel") || lower.contains("creative") {
            return companyCoverImages["Studio Pixel"]!
        } else if lower.contains("data") || lower.contains("ai") || lower.contains("ia") {
            return companyCoverImages["InovaData AI"]!
        }
        return companyCoverImages["DefaultTech"]!
    }
    
    // MARK: - Catálogo de Vagas Reais de Mercado (Baseadas no LinkedIn / Glassdoor Brasil)
    static func getRealMarketJobCatalog() -> [JobPosting] {
        let dummyCompanyId = UUID()
        
        return [
            JobPosting(
                id: UUID(),
                companyId: dummyCompanyId,
                companyName: "Nubank (Nu Pagamentos)",
                title: "Engenheiro de Software Mobile iOS (Swift & Concurrency)",
                location: "São Paulo - SP (Remoto Brasil)",
                modality: "Remoto",
                shift: .flexible,
                description: "Como Engenheiro iOS no Nu, você desenvolverá novas jornadas de crédito e investimentos para mais de 90 milhões de clientes na América Latina com alta resiliência e foco no usuário.",
                requiredSkills: ["Swift", "iOS", "SwiftUI", "Git", "Clean Architecture", "Unit Tests"],
                requirements: [
                    "Sólida experiência com Swift moderno e desenvolvimento nativo iOS",
                    "Domínio de arquiteturas modulares (MVVM, VIPER ou Clean)",
                    "Experiência com testes automatizados e integração contínua (CI/CD)",
                    "Conhecimento de acessibilidade nativa e internacionalização"
                ],
                salaryRange: "R$ 11.500 - R$ 16.000 (CLT) + Ações",
                coverImageURL: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1000&auto=format&fit=crop&q=80"
            ),
            JobPosting(
                id: UUID(),
                companyId: dummyCompanyId,
                companyName: "Mercado Livre Tech",
                title: "Desenvolvedor Frontend React & TypeScript Sênior",
                location: "Osasco - SP (Melicidade / Híbrido)",
                modality: "Híbrido",
                shift: .fullTime,
                description: "Venha acelerar o checkout do maior e-commerce da América Latina. Otimize tempo de carregamento de páginas críticas, microsserviços frontend e componentes acessíveis.",
                requiredSkills: ["React", "TypeScript", "JavaScript", "Next.js", "Performance Web", "Git"],
                requirements: [
                    "Experiência avançada em ecossistema React (Hooks, Context, SSR com Next.js)",
                    "Conhecimento profundo de Web Performance (Core Web Vitals)",
                    "Criação e manutenção de Design Systems compartilhados",
                    "Vivência com testes unitários em Jest e React Testing Library"
                ],
                salaryRange: "R$ 13.000 - R$ 18.000 (CLT) + Bônus",
                coverImageURL: "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1000&auto=format&fit=crop&q=80"
            ),
            JobPosting(
                id: UUID(),
                companyId: dummyCompanyId,
                companyName: "iFood Soluções",
                title: "Cientista de Dados & Machine Learning (Algoritmos de Recomendação)",
                location: "Campinas - SP (Remoto)",
                modality: "Remoto",
                shift: .flexible,
                description: "Construa e otimize modelos de recomendação em tempo real que entregam milhares de pedidos por segundo, prevendo tempo de entrega e roteamento inteligente.",
                requiredSkills: ["Python", "SQL", "Machine Learning", "Data Science", "Pandas", "PyTorch"],
                requirements: [
                    "Domínio de Python e bibliotecas de dados (Pandas, NumPy, Scikit-Learn)",
                    "Experiência comprovada em produção com frameworks de ML/DL",
                    "Familiaridade com pipelines de dados em nuvem (GCP / AWS / Databricks)",
                    "Capacidade de interpretar dados de negócio e métricas de impacto"
                ],
                salaryRange: "R$ 12.000 - R$ 17.500 (CLT)",
                coverImageURL: "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=1000&auto=format&fit=crop&q=80"
            ),
            JobPosting(
                id: UUID(),
                companyId: dummyCompanyId,
                companyName: "QuintoAndar",
                title: "Product Designer Pleno (UI/UX Mobile & Web)",
                location: "São Paulo - SP",
                modality: "Remoto",
                shift: .fullTime,
                description: "Lidere a criação de jornadas simples e encantadoras para inquilinos e proprietários. Crie protótipos navegáveis no Figma e colabore de perto com engenharia de produto.",
                requiredSkills: ["Figma", "UI/UX", "Design System", "Prototipagem", "Pesquisa com Usuários"],
                requirements: [
                    "Portfólio com estudos de caso detalhados de produtos digitais",
                    "Domínio profundo de Figma (Auto Layout, Tokens e Variáveis)",
                    "Prática em testes de usabilidade e discovery de produto",
                    "Visão analítica aliada a um apelo visual refinado"
                ],
                salaryRange: "R$ 8.500 - R$ 12.000 (CLT)",
                coverImageURL: "https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=1000&auto=format&fit=crop&q=80"
            ),
            JobPosting(
                id: UUID(),
                companyId: dummyCompanyId,
                companyName: "Stone Co.",
                title: "Engenheiro de Infraestrutura Cloud & DevOps (AWS / Kubernetes)",
                location: "Rio de Janeiro - RJ (Híbrido)",
                modality: "Híbrido",
                shift: .fullTime,
                description: "Garanta a disponibilidade de 99.99% dos serviços de pagamento de centenas de milhares de lojistas, construindo clusters resilientes de Kubernetes e esteiras de CI/CD.",
                requiredSkills: ["AWS", "Kubernetes", "Docker", "Terraform", "CI/CD", "Git"],
                requirements: [
                    "Sólida vivência com orquestração de containers em produção (EKS / GKE)",
                    "Automação e infraestrutura como código com Terraform",
                    "Experiência com observabilidade (Prometheus, Grafana, Datadog)",
                    "Conhecimento de segurança em nuvem e compliance bancário"
                ],
                salaryRange: "R$ 10.000 - R$ 15.000 (CLT)",
                coverImageURL: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1000&auto=format&fit=crop&q=80"
            ),
            JobPosting(
                id: UUID(),
                companyId: dummyCompanyId,
                companyName: "Globo Tecnologia",
                title: "Desenvolvedor Backend Python & Go (Streaming Globoplay)",
                location: "Rio de Janeiro - RJ (Remoto)",
                modality: "Remoto",
                shift: .fullTime,
                description: "Desenvolva microsserviços de alta escala para entrega de vídeos ao vivo e sob demanda para dezenas de milhões de espectadores simultâneos.",
                requiredSkills: ["Python", "SQL", "Docker", "Git", "APIs REST", "Microsserviços"],
                requirements: [
                    "Experiência com desenvolvimento backend de alta performance (Python / Go)",
                    "Design e arquitetura de microsserviços desacoplados",
                    "Conhecimento em filas e mensageria (Kafka / RabbitMQ)",
                    "Testes automatizados e monitoramento de latência"
                ],
                salaryRange: "R$ 9.000 - R$ 13.500 (CLT)",
                coverImageURL: "https://images.unsplash.com/photo-1497366216548-37526070297c?w=1000&auto=format&fit=crop&q=80"
            ),
            JobPosting(
                id: UUID(),
                companyId: dummyCompanyId,
                companyName: "Apple Developer Academy Partner",
                title: "Desenvolvedor iOS Júnior / Estagiário Avançado (SwiftUI & Swift)",
                location: "Curitiba - PR (Híbrido)",
                modality: "Híbrido",
                shift: .morning,
                description: "Oportunidade para talentos emergentes no desenvolvimento Apple. Construção de apps premiados para iOS, iPadOS e watchOS com mentoria técnica dedicada.",
                requiredSkills: ["Swift", "SwiftUI", "Git", "iOS", "Xcode"],
                requirements: [
                    "Conhecimento prático ou acadêmico em Swift e SwiftUI",
                    "Projetos pessoais publicados no GitHub ou App Store",
                    "Familiaridade com controle de versão Git",
                    "Entusiasmo e dedicação para aprender boas práticas arquiteturais"
                ],
                salaryRange: "R$ 4.500 - R$ 6.500 (CLT)",
                coverImageURL: "https://images.unsplash.com/photo-1551434678-e076c223a692?w=1000&auto=format&fit=crop&q=80"
            ),
            JobPosting(
                id: UUID(),
                companyId: dummyCompanyId,
                companyName: "PicPay",
                title: "Analista de Qualidade e Automação de Testes QA Mobile",
                location: "Vitória - ES (Remoto)",
                modality: "Remoto",
                shift: .fullTime,
                description: "Homologação e automação de fluxos críticos de pagamento, garantindo ausência de regressões e experiência impecável para o usuário final.",
                requiredSkills: ["QA", "Testes Automatizados", "Git", "Postman", "XCTest"],
                requirements: [
                    "Experiência em automação de testes para apps móveis (Appium / XCUITest)",
                    "Criação de planos de teste detalhados e reporte técnico de bugs",
                    "Conhecimento em testes de integração de APIs REST via Postman",
                    "Trabalho colaborativo com times ágeis de desenvolvimento"
                ],
                salaryRange: "R$ 6.500 - R$ 9.200 (CLT)",
                coverImageURL: "https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=1000&auto=format&fit=crop&q=80"
            )
        ]
    }
    
    // MARK: - Busca / Geração Inteligente com Gemini AI
    /// Busca vagas de mercado reais ou sintetiza via Gemini API caso haja chave configurada
    func fetchRealMarketJobs(
        query: String = "",
        category: String = "Todas",
        apiKey: String? = nil
    ) async -> [JobPosting] {
        // Se uma chave do Gemini estiver disponível, pode consultar a API oficial
        if let key = apiKey, !key.isEmpty {
            if let aiJobs = await callGeminiAPI(query: query, category: category, apiKey: key) {
                return aiJobs
            }
        }
        
        // Simulação de busca com latência de rede realista (1 segundo)
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        let allMarket = GeminiJobService.getRealMarketJobCatalog()
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if cleanQuery.isEmpty && (category == "Todas" || category.isEmpty) {
            return allMarket
        }
        
        return allMarket.filter { job in
            let matchesCategory: Bool
            switch category {
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
            default:
                matchesCategory = true
            }
            
            if cleanQuery.isEmpty { return matchesCategory }
            
            let matchesQuery = job.title.localizedCaseInsensitiveContains(cleanQuery) ||
                               job.companyName.localizedCaseInsensitiveContains(cleanQuery) ||
                               job.requiredSkills.contains { $0.localizedCaseInsensitiveContains(cleanQuery) }
            
            return matchesCategory && matchesQuery
        }
    }
    
    // Chamada REST à API do Gemini oficial
    private func callGeminiAPI(query: String, category: String, apiKey: String) async -> [JobPosting]? {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            return nil
        }
        
        let prompt = """
        Gere uma lista de 5 vagas de emprego reais e atuais do mercado de tecnologia brasileiro (formato JSON).
        Filtro de busca: "\(query)", categoria: "\(category)".
        Retorne estritamente um array JSON de objetos com:
        - companyName: string (nome de empresa brasileira real como Nubank, iFood, Mercado Livre, Stone, etc.)
        - title: string
        - location: string (ex: "São Paulo - SP (Remoto)")
        - modality: string ("Remoto", "Híbrido" ou "Presencial")
        - shift: string ("Comercial Integral (09h às 18h)" ou "Horário Flexível")
        - description: string
        - requiredSkills: array de strings
        - requirements: array de strings
        - salaryRange: string (ex: "R$ 8.000 - R$ 12.000 (CLT)")
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            // Parse simples do resultado do Gemini
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                
                // Extrai o bloco JSON
                let cleanJson = text
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let rawData = cleanJson.data(using: .utf8),
                   let array = try? JSONSerialization.jsonObject(with: rawData) as? [[String: Any]] {
                    return array.compactMap { dict in
                        guard let company = dict["companyName"] as? String,
                              let title = dict["title"] as? String,
                              let loc = dict["location"] as? String,
                              let desc = dict["description"] as? String,
                              let skills = dict["requiredSkills"] as? [String],
                              let salary = dict["salaryRange"] as? String else {
                            return nil
                        }
                        let mod = dict["modality"] as? String ?? "Remoto"
                        let reqs = dict["requirements"] as? [String] ?? []
                        let cover = GeminiJobService.getCoverImage(for: company)
                        return JobPosting(
                            companyId: UUID(),
                            companyName: company,
                            title: title,
                            location: loc,
                            modality: mod,
                            shift: .fullTime,
                            description: desc,
                            requiredSkills: skills,
                            requirements: reqs,
                            salaryRange: salary,
                            coverImageURL: cover
                        )
                    }
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}
