# **Indexações no Oracle Database: Teoria e Laboratório Prático no Oracle APEX**

# **1\. Fundamentos Teóricos de Indexação no Oracle Database**

## **O Conceito e o Mecanismo de Acesso**

A indexação em bancos de dados relacionais é uma estrutura de dados secundária cujo objetivo principal é minimizar as operações de E/S (*Input/Output* de disco) ao localizar registros. No Oracle Database, a recuperação de dados ocorre fundamentalmente através de dois mecanismos principais:

* **Full Table Scan (FTS)**: O mecanismo de otimização lê todos os blocos de dados alocados para a tabela abaixo da marca d'água (*High Water Mark* \- HWM). Todos os blocos são verificados sequencialmente, independentemente de haver apenas um registro correspondente. Esse processo é altamente eficiente para leitura sequencial maciça de grandes volumes, mas ineficiente para consultas pontuais.  
* **Acesso via Índice**: O otizador consulta a estrutura do índice para obter o **ROWID** direto do registro e realiza a leitura do bloco de dados específico.

### **A Anatomia do ROWID**

O `ROWID` é a representação física interna do endereço de cada linha gravada no banco de dados. Ele possui tamanho de 18 caracteres em formato base-64 (`OOOOOOFFFBBBPPPPRR`), dividido em 4 componentes essenciais:

| Componente | Tamanho | Descrição |
| :---- | :---- | :---- |
| **Data Object ID** | 6 caracteres | Identifica o objeto no dicionário de dados do Oracle. |
| **Datafile ID** | 3 caracteres | Identifica o arquivo de dados (*datafile*) relativo à *tablespace*. |
| **Block Number** | 6 caracteres | Identifica o bloco de dados exato contendo a linha. |
| **Row Number** | 3 caracteres | Identifica o número do *slot* (posição) da linha dentro do bloco. |

Quando a consulta executa o operador `TABLE ACCESS BY USER ROWID` ou `TABLE ACCESS BY INDEX ROWID`, o Oracle pula a varredura e acessa diretamente a posição de memória/disco em tempo constante \$O(1)\$.

```
   [ Consulta SQL ]
          │
          ▼
   [ Busca no Índice B-Tree ] ──(Localiza chave)──► [ ROWID: AAABBBCCC000111222 ]
                                                              │
                                                              ▼
   [ Registro Retornado ] ◄──(Acesso Direto)── [ TABLE ACCESS BY INDEX ROWID ]
```

---

## **Principais Tipos de Índices**

### **B-Tree (Balanced Tree)**

É a estrutura padrão do Oracle Database. Mantém-se balanceada de forma automática: a distância da raiz até qualquer bloco folha (*leaf block*) é estritamente idêntica.

* **Arquitetura**: Composta por um bloco Raiz (*Root*), blocos de Ramo (*Branch*) e blocos Folha (*Leaf*). Os blocos folha contêm a chave do índice e o respectivo `ROWID`, encadeados em lista duplamente ligada (permitindo varreduras ascendentes e descendentes).  
* **Comportamento de Busca**: A busca possui complexidade de tempo logarítmica \$O(\\log N)\$, onde \$N\$ é o número de blocos no índice.  
* **Recomendação**: Ideal para colunas com alta cardinalidade (muitos valores distintos), tais como CPF, Matrícula ou IDs primários em sistemas OLTP.

### **Function-Based Index (FBI)**

O otimizador do Oracle ignora índices B-Tree comuns quando a coluna indexada é envolvida por uma função determinística na cláusula `WHERE` (ex: `WHERE UPPER(nome) = 'ALICE'`).

* O **Function-Based Index** pré-calcula o resultado da função/expressão e armazena os valores pré-computados com seus respectivos `ROWID`s na estrutura da árvore B-Tree.  
* Permite otimizar cláusulas contendo `UPPER`, `LOWER`, `TRUNC`, `ROUND` ou expressões matemáticas.

### **Índice Composto (Composite Index)**

Índice criado sobre duas ou mais colunas de uma mesma tabela (limite de até 32 colunas).

* **Regra da *Leading Column* (Coluna Líder)**: O índice B-Tree composto é organizado primordialmente pela primeira coluna declarada na sua definição. Consultas que não utilizam a coluna líder na cláusula `WHERE` tendem a ignorar o índice ou demandam operações mais dispendiosas de varredura completa do índice (*Index Fast Full Scan* / *Index Skip Scan*).  
* **Index-Only Scan (Index Fast Full Scan)**: Ocorre quando a instrução `SELECT` requisita apenas colunas presentes na própria estrutura do índice. O Oracle satisfaz a consulta inteira acessando apenas os blocos do índice, eliminando a fase de acesso aos blocos da tabela (`TABLE ACCESS BY INDEX ROWID`).

### **Bitmap Index**

Substitui a lista de `ROWID` por representações compactas em vetor de bits (*bitmaps*).

* **Conceito**: Para cada valor distinto da coluna, cria-se uma chave contendo um bit (0 ou 1\) para cada linha da tabela.  
* **Recomendação**: Estrutura voltada para cenários de **baixa cardinalidade** (ex: Gênero, Status, Estado Civil) em ambientes de apoio à decisão (*Data Warehouse* / OLAP).  
* **Restrição Crítica**: Operações de escrita (`INSERT`, `UPDATE`, `DELETE`) bloqueiam a chave inteira do bitmap. Isso invalida a concorrência e gera travamentos (*deadlocks* ou *enqueue waits*) severos em ambientes OLTP de alta frequência transacional.

### **Index-Organized Tables (IOT)**

Ao contrário de uma *Heap Table* convencional (onde os dados são inseridos em qualquer bloco livre sem ordem garantida), a **Index-Organized Table** armazena a tabela inteira e seus dados diretamente dentro de uma estrutura B-Tree, ordenada pela chave primária. Reduz o espaço alocado e elimina a duplicação de `ROWID` \+ Chave.  
---

## **Custos, Manutenção e Boas Práticas**

Apesar das vantagens de desempenho em leitura (SELECT), os índices não são gratuitos e introduzem custos operacionais que devem ser balanceados pela engenharia do banco de dados:

* **Overhead em Operações DML**: Toda escrita (`INSERT`, `UPDATE`, `DELETE`) em uma tabela com múltiplos índices exige a atualização simultânea de cada estrutura de índice associada, aumentando o tempo total de transação e o volume de REDO/UNDO gerado.  
* **Divisão de Blocos Folha (*Leaf Block Split*)**: Quando um bloco folha atinge a capacidade máxima e um novo registro precisa ser indexado naquela posição, o Oracle divide o bloco folha em dois (*50-50 Split* ou *90-10 Split* para inserções sequenciais). Esse evento consome recurso computacional e pode levar à fragmentação do índice.  
* **Manutenção do Dicionário de Dados**: Acompanhar o estado e o uso das estruturas de indexação é feito via visões como `USER_INDEXES` e `USER_IND_COLUMNS`.

---

# **2\. Roteiro Prático: Laboratório de Indexação no Oracle APEX (SQL Workshop)**

**Ambiente**: Oracle Application Express (APEX) \-\> **SQL Workshop** \-\> **SQL Commands**.**Diretriz**: Em cada etapa, execute o comando SQL e clique no botão Explain Plan (ou utilize a sintaxe `EXPLAIN PLAN FOR`) para analisar as transformações na execução da consulta.

## **Etapa 1: Criação da Tabela Transacional e Carga em Lote**

Instalação de tabela de testes sem índices secundários e povoamento com 10.000 registros via gerador hierárquico.

```
-- 1. Criação da tabela sem índices secundários
CREATE TABLE tb_funcionarios (
    id_funcionario  NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    matricula       VARCHAR2(20) NOT NULL,
    nome            VARCHAR2(100) NOT NULL,
    email           VARCHAR2(100) NOT NULL,
    departamento    VARCHAR2(50) NOT NULL,
    cargo           VARCHAR2(50) NOT NULL,
    salario         NUMBER(10,2) NOT NULL,
    data_admissao   DATE DEFAULT SYSDATE NOT NULL,
    status          VARCHAR2(15) DEFAULT 'ATIVO' NOT NULL
);

-- 2. Carga volumosa de dados sintéticos (10.000 registros para evidenciar o plano de execução)
INSERT INTO tb_funcionarios (matricula, nome, email, departamento, cargo, salario, data_admissao, status)
SELECT 
    'MAT-' || LPAD(LEVEL, 6, '0'),
    'Funcionario ' || LEVEL,
    'user' || LEVEL || '@empresa.com.br',
    CASE MOD(LEVEL, 5)
        WHEN 0 THEN 'TI'
        WHEN 1 THEN 'RH'
        WHEN 2 THEN 'FINANCEIRO'
        WHEN 3 THEN 'VENDAS'
        ELSE 'OPERACAO'
    END,
    CASE MOD(LEVEL, 4)
        WHEN 0 THEN 'ANALISTA'
        WHEN 1 THEN 'COORDENADOR'
        WHEN 2 THEN 'GERENTE'
        ELSE 'ASSISTENTE'
    END,
    ROUND(DBMS_RANDOM.VALUE(2500, 18000), 2),
    SYSDATE - DBMS_RANDOM.VALUE(30, 3650),
    CASE WHEN MOD(LEVEL, 10) = 0 THEN 'INATIVO' ELSE 'ATIVO' END
FROM DUAL
CONNECT BY LEVEL <= 10000;

COMMIT;
```

---

## **Etapa 2: Análise da Consulta sem Índice (Full Table Scan)**

Consulta pontual executada sobre a coluna `matricula` antes da criação de um índice específico.

```
SELECT id_funcionario, nome, departamento, salario
FROM tb_funcionarios
WHERE matricula = 'MAT-005420';
```

### **Observação Didática no Explain Plan**

O otizador de consultas gera um plano apresentando o operador **`TABLE ACCESS FULL`**. O Oracle precisará ler sequencialmente todos os blocos de dados alocados para a tabela `TB_FUNCIONARIOS` a fim de encontrar uma única correspondência, resultando em maior custo de E/S.

---

## **Etapa 3: Aplicação de Índice B-Tree Único e Comparação de Custo**

Criação de restrição de unicidade indexada sobre a coluna de busca pontual `matricula`.

```
-- Criação do índice B-Tree Único
CREATE UNIQUE INDEX idx_func_matricula ON tb_funcionarios(matricula);

-- Reexecutar a consulta com Explain Plan no APEX
SELECT id_funcionario, nome, departamento, salario
FROM tb_funcionarios
WHERE matricula = 'MAT-005420';
```

### **Observação Didática no Explain Plan**

O plano de execução muda para **`INDEX UNIQUE SCAN`** apontando para `IDX_FUNC_MATRICULA`, seguido da operação **`TABLE ACCESS BY INDEX ROWID BATCHED`**. O custo de busca cai bruscamente (tipicamente de dezenas/centenas de blocos para apenas 2 ou 3 leituras).

---

## **Etapa 4: O Desafio do Function-Based Index (FBI)**

Demostração de inativação do índice padrão diante de funções na consulta e a devida resolução.

```
-- 1. Consulta aplicando função UPPER no nome (gera TABLE ACCESS FULL mesmo se houver índice comum no nome)
SELECT matricula, nome, cargo, salario
FROM tb_funcionarios
WHERE UPPER(nome) = 'FUNCIONARIO 2500';

-- 2. Criação do Function-Based Index
CREATE INDEX idx_func_nome_upper ON tb_funcionarios(UPPER(nome));

-- 3. Reavaliar com Explain Plan
SELECT matricula, nome, cargo, salario
FROM tb_funcionarios
WHERE UPPER(nome) = 'FUNCIONARIO 2500';
```

### **Observação Didática no Explain Plan**

A primeira consulta resulta em `TABLE ACCESS FULL` porque a função `UPPER` transforma o valor da coluna em tempo de execução, impedindo a comparação direta com a chave do índice B-Tree normal. Após a criação do índice funcional `idx_func_nome_upper`, o otizador utiliza a operação **`INDEX RANGE SCAN`**.

---

## **Etapa 5: Índice Composto e a Otimização de Cobertura (Index-Only Scan)**

Aplicação de índice muticoluna focado no padrão de filtragem e projeção.

```
-- 1. Criação de índice composto (departamento + cargo + salario)
CREATE INDEX idx_func_dep_cargo_sal ON tb_funcionarios(departamento, cargo, salario);

-- 2. Consulta filtrando pela coluna líder (departamento) e retornando apenas colunas do próprio índice
SELECT cargo, salario
FROM tb_funcionarios
WHERE departamento = 'TI' AND cargo = 'ANALISTA';
```

### **Observação Didática no Explain Plan**

Observe a ocorrência da operação **`INDEX RANGE SCAN`** sem a necessidade do nó posterior `TABLE ACCESS BY INDEX ROWID`. Como as colunas requisitadas na cláusula `SELECT` (`cargo`, `salario`) e nas cláusulas de filtro `WHERE` (`departamento`, `cargo`) pertencem todas ao índice, o Oracle encerra a busca no próprio bloco folha do índice (*Index-Only Scan*).

---

## **Etapa 6: Consulta ao Dicionário de Dados**

Auditoria e análise das propriedades das estruturas criadas via *Data Dictionary Views*.

```
-- Listar os índices criados pelo usuário e seu status
SELECT index_name, index_type, uniqueness, status
FROM user_indexes
WHERE table_name = 'TB_FUNCIONARIOS';

-- Detalhar as colunas e posições em índices compostos
SELECT index_name, column_name, column_position
FROM user_ind_columns
WHERE table_name = 'TB_FUNCIONARIOS'
ORDER BY index_name, column_position;
```

---

# **3\. Exercícios Práticos de Avaliação para os Alunos**

## **Exercício 1 (Seletividade e Leading Column)**

**Enunciado**: Execute a consulta abaixo no Oracle APEX e inspecione o plano de execução gerado via botão **Explain Plan**:

```
SELECT nome, salario
FROM tb_funcionarios
WHERE cargo = 'ANALISTA';
```

**Pergunta**: Explique detalhadamente por que o índice composto `idx_func_dep_cargo_sal` (criado na Etapa 5\) não gerou um `INDEX RANGE SCAN` direto e eficiente nesta instrução, e como a regra da *Leading Column* (coluna líder) fundamenta esse comportamento do otimizador Oracle.

---

## **Exercício 2 (Indexação Temporal)**

**Enunciado**: Suponha uma demanda em que o relatório de auditoria fiscal realiza consultas frequentes buscando funcionários admitidos em um determinado ano, utilizando a sintaxe:

```
SELECT * 
FROM tb_funcionarios 
WHERE EXTRACT(YEAR FROM data_admissao) = 2022;
```

**Tarefa**: Escreva a instrução SQL completa DDL para criar um **Function-Based Index** apropriado para essa consulta e apresente a sintaxe SQL de validação utilizando o Dicionário de Dados do Oracle (USER\_INDEXES).

---

## **Exercício 3 (Análise Crítica de Trade-offs)**

**Enunciado**: Um desenvolvedor júnior propôs a criação de índices individuais para todas as colunas da tabela tb\_funcionarios com o objetivo de "garantir que nenhuma consulta do sistema fique lenta".

**Tarefa**: Elabore uma justificativa técnica (mínimo de 2 parágrafos) desconstruindo essa abordagem para a equipe de arquitetura. Aborde os impactos físicos e de infraestrutura nos seguintes tópicos:

1. Desempenho e *overhead* em operações transacionais de escrita (`INSERT`, `UPDATE`, `DELETE`).  
2. Consumo de espaço em disco e comportamento do *Buffer Cache* em memória.  
3. Decisões do Otimizador Baseado em Custo (CBO \- *Cost-Based Optimizer*).

