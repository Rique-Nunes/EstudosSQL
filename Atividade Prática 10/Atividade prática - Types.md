# **User-Defined Types (UDTs) no Oracle Database: Conceitos, Arquitetura Objeto-Relacional e Laboratório no Oracle APEX**

# **1\. Fundamentos Teóricos: Tipos de Dados Definidos pelo Usuário (UDTs)**

## **O Paradigma Objeto-Relacional (ORDBMS)**

O Oracle Database estende o modelo relacional tradicional incorporando conceitos fundamentais do paradigma orientado a objetos. Essa arquitetura objeto-relacional permite o encapsulamento de dados e comportamentos, a definição de tipos estruturados complexos, o uso de métodos membros e a manipulação de coleções diretamente no nível do catálogo do banco de dados (DDL).

## **Categorias Principais de Tipos**

### **1\. Object Types (Tipos de Objeto)**

* **Estrutura e Comportamento**: Consistem em uma estrutura de dados composta por atributos simples ou complexos e métodos operacionais (`MEMBER`, `STATIC` e `CONSTRUCTOR`).  
* **Divisão de Declaração**:  
  * Especificação (`CREATE OR REPLACE TYPE`): Define a interface pública, incluindo atributos e assinaturas de métodos.  
  * Corpo (`CREATE OR REPLACE TYPE BODY`): Implementa a lógica dos métodos declarados na especificação.  
* **Persistência**: Podem ser reutilizados como tipos de colunas em tabelas relacionais convencionais ou utilizados para instanciar *Object Tables* (`CREATE TABLE OF tipo_obj`).

### **2\. Collection Types (Coleções no Nível de Esquema)**

* **VARRAY (Variable-Size Array)**: Coleção ordered com limite máximo estático fixado em sua definição. Quando armazenada em tabelas, seus elementos são mantidos na mesma linha (*inline*) no bloco de dados principal, contanto que o tamanho total não ultrapasse o limite de LOBs.  
* **Nested Table (Tabela Aninhada)**: Coleção dinâmica sem limitação superior de elementos. Fisicamente, os dados de uma Nested Table são armazenados fora de linha (*out-of-line*) em uma tabela de armazenamento auxiliar transparente vinculada à tabela pai via chave primária/estrangeira oculta.  
* **Associative Arrays (Index-by Tables)**: Estruturas de chave-valor destinadas exclusivamente ao processamento em memória dentro de blocos PL/SQL. Não podem ser declaradas no schema via DDL nem armazenadas como colunas de tabelas.

## **Construtores e Funções de Coleção**

* **Construtor Padrão**: Toda declaração de UDT gera automaticamente um método construtor com o mesmo nome do tipo, aceitando parâmetros correspondentes à ordem e tipo dos seus atributos.  
* **Operador `TABLE()`**: Permite que o mecanismo SQL converta uma coleção (armazenada ou em memória) em um conjunto relacional (linhas e colunas), tornando-a passível de junções, filtros e agregações em comandos SQL tradicionais.

## **Comparação e Ordenação de Objetos**

Para permitir cláusulas como `ORDER BY`, `GROUP BY` ou operações de comparação (`<`, `>`, `=`) entre instâncias de tipos complexos, o Oracle exige a definição de um método de ordenação:

| Método | Funcionamento | Uso Recomendado |
| :---- | :---- | :---- |
| **MAP** | Transforma o objeto complexo em um tipo escalar simples (ex: `NUMBER`, `VARCHAR2`, `DATE`). O Oracle compara os escalares resultantes. | Eficiente para ordenações frequentes de múltiplos objetos (invocado uma vez por objeto). |
| **ORDER** | Recebe outra instância do mesmo objeto como parâmetro e retorna `-1`, `0` ou `1` com base na comparação direta entre `SELF` e o objeto recebido. | Útil quando a regra de comparação envolve lógica complexa não conversível para escalar simples. |

## **Vantagens e Desafios de Engenharia**

### **Vantagens**

* **Reutilização Semântica**: Padronização de estruturas recorrentes (ex: Tipo Endereço, Tipo Telefone, Tipo Documento) em múltiplos esquemas e tabelas.  
* **Integridade de Domínio**: Garantia de que estruturas de dados e regras de negócio associadas sejam aplicadas de forma consistente na camada de persistência.

### **Desafios**

* **Indexação**: Exige criação de índices de função ou em colunas virtuais para otimizar pesquisas em atributos aninhados.  
* **Mapeamento ORM**: Mapeadores Objeto-Relacionais de mercado (como Hibernate ou Entity Framework) frequentemente apresentam limitações ao lidar com UDTs nativos do Oracle.  
* **Desempenho de DML**: Operações massivas de gravação e atualização em coleções aninhadas podem gerar overhead de I/O na tabela de armazenamento auxiliar.

---

# **2\. Roteiro Prático: Laboratório no Oracle APEX (SQL Workshop)**

**Ambiente**: Oracle Application Express (APEX) \$\\rightarrow\$ SQL Workshop \$\\rightarrow\$ SQL Commands.

## **Etapa 1: Criação de um Object Type com Atributos e Métodos**

Criação dos tipos de objeto t\_endereco e implementação de sua Member Function para formatação de dados.

```
-- 1. Criação da especificação do tipo de objeto t_endereco
CREATE OR REPLACE TYPE t_endereco AS OBJECT (
    logradouro  VARCHAR2(100),
    numero      VARCHAR2(10),
    bairro      VARCHAR2(50),
    cidade      VARCHAR2(50),
    uf          VARCHAR2(2),
    cep         VARCHAR2(9),
    MEMBER FUNCTION get_endereco_completo RETURN VARCHAR2
);
/

-- 2. Implementação do corpo do tipo t_endereco
CREATE OR REPLACE TYPE BODY t_endereco AS
    MEMBER FUNCTION get_endereco_completo RETURN VARCHAR2 IS
    BEGIN
        RETURN logradouro || ', ' || numero || ' - ' || bairro || ', ' || cidade || '/' || uf || ' (CEP: ' || cep || ')';
    END;
END;
/
```

## **Etapa 2: Criação de Coleções (VARRAY e Nested Table)**

Declaração de tipos de coleção no nível de esquema para manipular múltiplos telefones e estruturas complexas de dependentes.

```
-- 1. Criação de um VARRAY para telefones (máximo de 3 números)
CREATE OR REPLACE TYPE t_telefones_varray AS VARRAY(3) OF VARCHAR2(20);
/

-- 2. Criação da estrutura de objeto para Dependente
CREATE OR REPLACE TYPE t_dependente AS OBJECT (
    nome_dependente VARCHAR2(80),
    grau_parentesco VARCHAR2(30),
    data_nascimento DATE
);
/

-- 3. Criação da Nested Table baseada no objeto t_dependente
CREATE OR REPLACE TYPE t_dependentes_nested AS TABLE OF t_dependente;
/
```

## **Etapa 3: Criação de Tabela com Colunas de Tipos Customizados**

Criação da tabela principal `tb_clientes_corporativos`, integrando tipos escalares, tipos de objeto e coleções com definição da cláusula `STORE AS`.

```
CREATE TABLE tb_clientes_corporativos (
    id_cliente      NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    razao_social    VARCHAR2(100) NOT NULL,
    endereco        t_endereco NOT NULL,
    telefones       t_telefones_varray,
    dependentes     t_dependentes_nested
) NESTED TABLE dependentes STORE AS tb_dependentes_store;
```

## **Etapa 4: Inserção de Registros com Construtores de Objetos**

Inserção de dados demonstrando a inicialização de tipos complexos através dos seus construtores implícitos.

```
INSERT INTO tb_clientes_corporativos (
    razao_social,
    endereco,
    telefones,
    dependentes
) VALUES (
    'Louzada Tech Consultoria',
    t_endereco('Avenida Rio Branco', '156', 'Centro', 'Rio de Janeiro', 'RJ', '20040-002'),
    t_telefones_varray('(21) 98888-1111', '(21) 2222-3333'),
    t_dependentes_nested(
        t_dependente('Tiago Louzada', 'FILHO', TO_DATE('2015-05-10', 'YYYY-MM-DD')),
        t_dependente('Mariana Louzada', 'CONJUGE', TO_DATE('1988-11-20', 'YYYY-MM-DD'))
    )
);

INSERT INTO tb_clientes_corporativos (
    razao_social,
    endereco,
    telefones,
    dependentes
) VALUES (
    'Inovação Digital Brasil',
    t_endereco('Avenida Paulista', '1000', 'Bela Vista', 'São Paulo', 'SP', '01310-100'),
    t_telefones_varray('(11) 97777-4444'),
    t_dependentes_nested(
        t_dependente('Lucas Silva', 'FILHO', TO_DATE('2018-02-15', 'YYYY-MM-DD'))
    )
);

COMMIT;
```

## **Etapa 5: Consultas Avançadas, Execução de Métodos e Operador TABLE()**

Execução de consultas SQL utilizando sintaxe de qualificação pontual, invocação de métodos membros e desaninhamento de coleções com o operador `TABLE()`.

```
-- 1. Acesso a atributos específicos do objeto e chamada da Member Function
-- NOTA: O uso do alias da tabela (c) é obrigatório ao referenciar métodos e atributos de UDTs
SELECT 
    c.id_cliente,
    c.razao_social,
    c.endereco.cidade AS cidade,
    c.endereco.uf AS estado,
    c.endereco.get_endereco_completo() AS endereco_formatado
FROM tb_clientes_corporativos c;

-- 2. Desaninhar a Nested Table com o operador TABLE() para visualização relacional
SELECT 
    c.razao_social,
    d.nome_dependente,
    d.grau_parentesco,
    d.data_nascimento
FROM tb_clientes_corporativos c,
     TABLE(c.dependentes) d;

-- 3. Consultar elementos do VARRAY
SELECT 
    c.razao_social,
    t.COLUMN_VALUE AS numero_telefone
FROM tb_clientes_corporativos c,
     TABLE(c.telefones) t;
```

## **Etapa 6: Consulta ao Dicionário de Dados**

Inspeção das visões do dicionário de dados do Oracle para auditoria dos tipos e atributos criados.l  
\-- Listar tipos cadastrados no esquema do usuário  
SELECT type\_name, typecode, attributes, methods  
FROM user\_types  
ORDER BY type\_name;

\-- Detalhar os atributos de cada tipo  
SELECT type\_name, attr\_name, attr\_type\_name, length  
FROM user\_type\_attrs  
ORDER BY type\_name, attr\_no;

```

---

## 3. Exercícios Práticos de Fixação

1. **Exercício 1 (Métodos Construtores Personalizados)**  
   Crie um tipo de objeto chamado `t_retangulo` com os atributos `largura` (NUMBER) e `altura` (NUMBER). Adicione duas funções ao tipo: `MEMBER FUNCTION calcular_area RETURN NUMBER` e `MEMBER FUNCTION calcular_perimetro RETURN NUMBER`. Escreva a especificação, o corpo (`BODY`) e execute um bloco anônimo PL/SQL ou comando `SELECT` para testar a instanciação e o cálculo das funções.

2. **Exercício 2 (Método MAP para Ordenação)**  
   Modifique a especificação e o corpo do tipo `t_retangulo` criado no Exercício 1 para incluir um método `MAP MEMBER FUNCTION ordenar RETURN NUMBER`. A função deve retornar a área total do retângulo. Teste a ordenação criando uma tabela simples de retângulos e executando uma consulta com a cláusula `ORDER BY` diretamente sobre a coluna do tipo objeto.

3. **Exercício 3 (Análise Crítica de Engenharia)**  
   Considere o cenário de modelagem de dados para um sistema corporativo. Elabore um texto comparativo analisando o uso de `Nested Tables` como colunas versus a modelagem relacional tradicional (duas tabelas distintas vinculadas por Foreign Key de 1:N). Enderece em sua resposta:
   * Flexibilidade de consulta SQL.
   * Manutenção de integridade referencial.
   * Suporte por ferramentas de integração/ORM.
   * Performance em cargas massivas (ETL).

---

## 4. Checklist de Boas Práticas e Arquitetura Objeto-Relacional

* **Uso Obrigatório de Aliases**: O mecanismo SQL do Oracle exige o uso de um alias para a tabela ao acessar qualquer atributo ou método de um UDT (ex: `c.endereco.cidade` funciona; `tb_clientes.endereco.cidade` gera erro de sintaxe).
* **Limitação de Profundidade de Aninhamento**: Evite aninhar tipos dentro de outros tipos com mais de dois níveis de profundidade, pois isso pode dificultar a escrita de consultas e degradar a eficiência do otimizador de consultas (CBO).
* **Dimensionamento do VARRAY**: Utilize `VARRAY` apenas quando houver certeza absoluta de que o limite superior de elementos é fixo e pequeno (ex: meses do ano, trimestres, limites de telefones). Para coleções de tamanho indeterminado, utilize `Nested Tables`.
* **Gerenciamento de Dependências (DDL)**: Lembre-se de que alterações em tipos base invalidam objetos e tabelas dependentes. Antes de utilizar a cláusula `DROP TYPE ... FORCE`, verifique os impactos no dicionário de dados via visão `USER_DEPENDENCIES`.
```

