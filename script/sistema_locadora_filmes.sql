SET SERVEROUTPUT ON;


-- CRIAÇÃO DAS TABELAS

CREATE TABLE T_CLIENTE (
    id_cliente NUMBER(3) PRIMARY KEY,
    nm_cliente VARCHAR2(30) NOT NULL,
    cpf_cliente VARCHAR2(11) NOT NULL UNIQUE,
    tel_cliente VARCHAR2(20),
    email_cliente VARCHAR2(50)
);

CREATE TABLE T_ITENS (
    id_item NUMBER(3) PRIMARY KEY,
    titulo_item VARCHAR2(50) NOT NULL,
    ctg_item VARCHAR2(30),
    ano_lancamento DATE,
    fx_etaria NUMBER(2),
    qtd_copias_total NUMBER(5) NOT NULL,
    qtd_copias_disponiveis NUMBER(5) NOT NULL
);

CREATE TABLE T_LOCACAO (
    id_locacao NUMBER(6) PRIMARY KEY,
    id_cliente NUMBER(3) NOT NULL,
    id_item NUMBER(3) NOT NULL,
    dt_locacao DATE NOT NULL,
    dt_prevista DATE NOT NULL,
    dt_devolucao DATE,
    sts_locacao CHAR(10) DEFAULT 'Alugada'
        CHECK (sts_locacao IN ('Alugada','Devolvida','Atrasada')),
    CONSTRAINT FK_LOCACAO_CLIENTE FOREIGN KEY (id_cliente)
        REFERENCES T_CLIENTE(id_cliente),
    CONSTRAINT FK_LOCACAO_ITEM FOREIGN KEY (id_item)
        REFERENCES T_ITENS(id_item),
    CHECK (dt_prevista <= dt_locacao + 7)  -- prazo máximo de 7 dias
);


-- SEQUENCE PARA GERAR o id_locacao

CREATE SEQUENCE T_LOCACAO_SEQ
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- POPULANDO COM OS DADO PRA TESTES

-- Clientes 
INSERT INTO T_CLIENTE (id_cliente, nm_cliente, cpf_cliente, tel_cliente, email_cliente)
VALUES (1, 'Matheus', '12345678901', '11999998888', 'mth@email.com');

INSERT INTO T_CLIENTE (id_cliente, nm_cliente, cpf_cliente, tel_cliente, email_cliente)
VALUES (2, 'Julio', '11223344556', '31988887777', 'julios@email.com');

INSERT INTO T_CLIENTE (id_cliente, nm_cliente, cpf_cliente, tel_cliente, email_cliente)
VALUES (3, 'Tiago', '10987654321', '31988887777', 'tiagao@email.com');

-- Itens
INSERT INTO T_ITENS (id_item, titulo_item, ctg_item, ano_lancamento, fx_etaria, qtd_copias_total, qtd_copias_disponiveis)
VALUES (10, 'Xeque-mate', 'Ação', TO_DATE('2006-09-15','YYYY-MM-DD'), 16, 5, 5);

INSERT INTO T_ITENS (id_item, titulo_item, ctg_item, ano_lancamento, fx_etaria, qtd_copias_total, qtd_copias_disponiveis)
VALUES (11, 'Anjos da Lei', 'Comédia', TO_DATE('2012-05-04','YYYY-MM-DD'), 18, 2, 2);

INSERT INTO T_ITENS (id_item, titulo_item, ctg_item, ano_lancamento, fx_etaria, qtd_copias_total, qtd_copias_disponiveis)
VALUES (12, 'O Exterminador do Futuro', 'Ação/Ficção', TO_DATE('1985-03-25','YYYY-MM-DD'), 14, 2, 0);

COMMIT;


-- BLOCO PL/SQL  PRA REGISTRAR UMA LOCAÇÃO
-- obs: ao rodar o último bloco de código(SIMULAR CASO "CLIENTE COM 3 LOCAÇÕES ATIVAS"), rode este bloco novamente

    DECLARE
      v_id_cliente NUMBER := 1;         -- ALTERE AQUI para testar outros clientes 
      v_id_item   NUMBER := 10;         -- ALTERE AQUI para testar outros itens 
      v_dt_loc    DATE   := SYSDATE;    -- data da retirada 
      v_dt_prev   DATE   := SYSDATE + 5; -- data prevista 
      v_qtd_ativas NUMBER;
      v_copias     NUMBER;
      v_nm_cliente VARCHAR2(60);
      v_titulo     VARCHAR2(100);
      
BEGIN
      -- Busca o cliente, se não existir, informa e sai
      BEGIN
        SELECT nm_cliente INTO v_nm_cliente FROM T_CLIENTE WHERE id_cliente = v_id_cliente;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          DBMS_OUTPUT.PUT_LINE('Cliente não encontrado (id ' || v_id_cliente || ').');
          RETURN;
      END;
    
      -- Buscar título do item, se não existir, informa e sai
      BEGIN
        SELECT titulo_item INTO v_titulo FROM T_ITENS WHERE id_item = v_id_item;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          DBMS_OUTPUT.PUT_LINE('Item não encontrado (id ' || v_id_item || ').');
          RETURN;
      END;
    
      -- Verifica a qtd locações ativas por cliente
      SELECT COUNT(*) INTO v_qtd_ativas
      FROM T_LOCACAO
      WHERE id_cliente = v_id_cliente
        AND sts_locacao = 'Alugada';
    
      IF v_qtd_ativas >= 3 THEN
        DBMS_OUTPUT.PUT_LINE('O cliente ' || v_nm_cliente || ' já possui 3 locações ativas.');
        RETURN;
      END IF;
    
    
      --  Verificar se tem cópias disponíveis 
      SELECT qtd_copias_disponiveis INTO v_copias
      FROM T_ITENS
      WHERE id_item = v_id_item;
    
    
      IF v_copias <= 0 THEN
        DBMS_OUTPUT.PUT_LINE('O item ' || '"' || v_titulo || '"' || ' não possui cópias disponíveis.');
        RETURN;
      END IF;
    
    
      -- Verificar o prazo de 7 dias 
      IF v_dt_prev > v_dt_loc + 7 THEN
        DBMS_OUTPUT.PUT_LINE('A data prevista de devolução deve ser no máximo 7 dias após a retirada.');
        RETURN;
      END IF;
    
      -- Validar e inserir uma locação e diminuir copias
      INSERT INTO T_LOCACAO (id_locacao, id_cliente, id_item, dt_locacao, dt_prevista, sts_locacao)
        VALUES (T_LOCACAO_SEQ.NEXTVAL, v_id_cliente, v_id_item, v_dt_loc, v_dt_prev, 'Alugada');
    
      UPDATE T_ITENS
      SET qtd_copias_disponiveis = qtd_copias_disponiveis - 1
      WHERE id_item = v_id_item;
    
      COMMIT;
    
      DBMS_OUTPUT.PUT_LINE('Locação registrada com sucesso para ' || v_nm_cliente || '.');
    
      EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erro ao tentar registrar locação: ' || SQLERRM);
        ROLLBACK;
END;
/


-- BLOCO PRA REGISTRAR A DEVOLUÇÃO DO ITEM

    DECLARE
      v_id_locacao NUMBER := 1;  
      v_id_item NUMBER;
      v_id_cliente NUMBER;
      v_nm_cliente VARCHAR2(60);
BEGIN
    
      -- Verificar locação
      BEGIN
        SELECT id_item, id_cliente INTO v_id_item, v_id_cliente
        FROM T_LOCACAO
        WHERE id_locacao = v_id_locacao;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          DBMS_OUTPUT.PUT_LINE('Locação não encontrada (id ' || v_id_locacao || ').');
          RETURN;
      END;
    
    
      BEGIN
        SELECT nm_cliente INTO v_nm_cliente FROM T_CLIENTE WHERE id_cliente = v_id_cliente;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_nm_cliente := 'Cliente desconhecido';
      END;
    
      -- Atualiza locação para devolvida
      UPDATE T_LOCACAO
      SET dt_devolucao = SYSDATE,
          sts_locacao = 'Devolvida'
      WHERE id_locacao = v_id_locacao;
    
      -- Incrementa cópias disponíveis
      UPDATE T_ITENS
      SET qtd_copias_disponiveis = qtd_copias_disponiveis + 1
      WHERE id_item = v_id_item;
    
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Locação ' || v_id_locacao || ' marcada como Devolvida para ' || v_nm_cliente || '.');
    
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao registrar devolução: ' || SQLERRM);
        ROLLBACK;
END;
/


-- BLOCO PRA SIMULAR O CASO "CLIENTE COM 3 LOCAÇÕES ATIVAS" 

BEGIN
      INSERT INTO T_LOCACAO (id_locacao, id_cliente, id_item, dt_locacao, dt_prevista, sts_locacao)
      VALUES (T_LOCACAO_SEQ.NEXTVAL, 1, 10, SYSDATE, SYSDATE+3, 'Alugada');
      UPDATE T_ITENS SET qtd_copias_disponiveis = qtd_copias_disponiveis - 1 WHERE id_item = 10;
    
      INSERT INTO T_LOCACAO (id_locacao, id_cliente, id_item, dt_locacao, dt_prevista, sts_locacao)
      VALUES (T_LOCACAO_SEQ.NEXTVAL, 1, 11, SYSDATE, SYSDATE+3, 'Alugada');
      UPDATE T_ITENS SET qtd_copias_disponiveis = qtd_copias_disponiveis - 1 WHERE id_item = 11;
    
      INSERT INTO T_LOCACAO (id_locacao, id_cliente, id_item, dt_locacao, dt_prevista, sts_locacao)
      VALUES (T_LOCACAO_SEQ.NEXTVAL, 1, 10, SYSDATE, SYSDATE+3, 'Alugada');
      UPDATE T_ITENS SET qtd_copias_disponiveis = qtd_copias_disponiveis - 1 WHERE id_item = 10;
    
      COMMIT;
END;
/

-- Depois de rodar o bloco acima, execute NOVAMENTE o bloco da obs: "PRA REGISTRAR UMA LOCAÇÃO" para retornar: "O cliente Matheus já possui 3 locações ativas."



