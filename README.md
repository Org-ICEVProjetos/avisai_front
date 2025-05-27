# Avisaí - Identificador de Irregularidades Urbanas

O **Avisaí** é um aplicativo móvel desenvolvido em Flutter que permite aos cidadãos identificar e reportar irregularidades urbanas em sua cidade, como buracos na via, postes defeituosos e descarte irregular de lixo.

## 📱 Funcionalidades

### 🔍 **Identificação de Irregularidades**
- **Buracos na via**: Reporte buracos e problemas no asfalto
- **Postes defeituosos**: Identifique postes de iluminação com problemas
- **Descarte irregular de lixo**: Reporte lixo descartado inadequadamente

### 📸 **Captura e Registro**
- Capture fotos diretamente pelo aplicativo ou selecione da galeria
- Geolocalização automática dos registros
- Validação de proximidade (raio de 10 metros)
- Obtenção automática de endereço via OpenStreetMap

### 🌐 **Funcionamento Online/Offline**
- **Modo Online**: Sincronização imediata com servidor
- **Modo Offline**: Armazenamento local com sincronização posterior
- Cache inteligente de dados e imagens
- Indicadores visuais de status de conectividade

### 👥 **Sistema de Validação**
- Registros são validados por outros usuários
- Sistema de proximidade para evitar duplicatas
- Status de validação em tempo real
- Histórico de validações

### 🗺️ **Mapa Interativo**
- Visualização de irregularidades no mapa (OpenStreetMap)
- Localização em tempo real do usuário
- Filtros por categoria de irregularidade
- Marcadores coloridos por tipo de problema

## 🛠️ **Tecnologias Utilizadas**

### **Frontend**
- **Flutter 3.x**: Framework para desenvolvimento multiplataforma
- **Dart**: Linguagem de programação
- **BLoC Pattern**: Gerenciamento de estado reativo

### **Armazenamento**
- **SQLite**: Banco de dados local
- **SharedPreferences**: Armazenamento de configurações

### **Mapas e Localização**
- **OpenStreetMap**: Mapas e tiles
- **flutter_map**: Widget de mapa para Flutter
- **Geolocator**: Obtenção de coordenadas GPS
- **Nominatim API**: Geocodificação reversa

### **Câmera e Mídia**
- **Camera Plugin**: Captura de fotos
- **Permission Handler**: Gerenciamento de permissões

### **Conectividade**
- **HTTP**: Requisições para API
- **Connectivity Plus**: Monitoramento de conectividade

## 📋 **Pré-requisitos**

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 2.17.0)
- Android Studio ou VS Code
- Android SDK (API level 21+) para Android
- Xcode (para iOS)

## 📁 Estrutura do Projeto

lib/
├── bloc/ # Gerenciamento de estado (BLoC)
│ ├── auth/ # Autenticação
│ ├── registro/ # Registros de irregularidades
│ └── connectivity/ # Conectividade de rede
├── data/
│ ├── models/ # Modelos de dados
│ ├── providers/ # Provedores de API
│ └── repositories/ # Repositórios de dados
├── services/ # Serviços auxiliares
│ ├── location_service.dart
│ ├── connectivity_service.dart
│ ├── tutorial_manager.dart
│ ├── user_storage_service.dart
│ └── local_storage_service.dart
├── presentation/
│ └── screens/ # Telas da aplicação
│ ├── auth/ # Telas de autenticação
│ ├── home/ # Tela principal
│ ├── registro/ # Telas de registro
│ ├── mapa/ # Telas do mapa
│ └── widgets/ # Widgets reutilizáveis
└── config/ # Configurações


---

## 🤝 Como Usar

1. **Cadastro/Login:** Crie uma conta ou faça login  
2. **Permissões:** Conceda as permissões necessárias  
3. **Registro:** Tire uma foto da irregularidade  
4. **Categoria:** Selecione o tipo de problema  
5. **Envio:** Confirme o registro  
6. **Visualização:** Veja seus registros e os de outros usuários no mapa  

---

## 🔒 Segurança e Privacidade

- Senhas não são armazenadas localmente  
- Imagens codificadas em Base64 para segurança  
- Autenticação via token JWT  
- Validação de permissões em tempo de execução  

---
