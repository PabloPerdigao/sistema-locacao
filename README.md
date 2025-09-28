# Sistema de Locação de Filmes

Essa solução implementa um sistema de banco de dados para uma locadora que trabalha com filmes, desenvolvido usando Oracle SQL e o que aprendi até agora sobre PL/SQL. 
<br>
O sistema permite cadastrar clientes, itens e locações, além de registrar e validar regras de locação e devolução, com mensagens predefinidas.

## 📁 Estrutura do Repositório

```
sistema-locadora/
├── scripts/
│   └── sistema_locadora_filmes.sql    #script do banco de dados
├── docs/
│   └── modelo_relacional.png        #arquivos do diagrama de modelo relacional
└── README.md                        #Este arquivo
```

## 🛠️ Tecnologias Utilizadas

- **Oracle SQL Data Modeler**: Modelo de relacionamento do sistema
- **SQL | PL/SQP**: Scripts para consultas e manipulação dos dados 


## 📊 Modelo Relacional

O diagrama do modelo relacional está disponível em `docs/modelo_relacional.png`, mostrando todas as entidades, atributos e relacionamentos do sistema.

## 🗒️ Como Usar

### 1. Execução do Script
```sql
-- Execute o script principal no Oracle SQL Developer
@C:\scripts\sistema_locadora_filmes.sql
```

## 🗄️ Estrutura do Banco de Dados

O sistema é composto pelas seguintes entidades principais:

### Tabelas
- **CLIENTES**: Cadastro de clientes da locadora
- **ITENS**: Catálogo de filmes e jogos disponíveis
- **LOCAÇÕES**: Registro das locações realizadas

Obedecendo as seguintes regras de validação:

### Validação
- Um **cliente**: só pode ter até 3 locações ativas ao mesmo tempo.
- A **data prevista de devolução:** deve ser no máximo 7 dias após a retirada.
- **Não é possível:** alugar um item sem cópias disponíveis.
