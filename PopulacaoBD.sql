

-- 1. PESSOAS 
INSERT INTO TB_PESSOA (NM_PESSOA_NOME, NM_PESSOA_SOBRENOME, NR_CPF, TX_EMAIL, TP_TITULACAO)
SELECT
    (ARRAY['Ana','Bruno','Carlos','Daniela','Eduardo','Fernanda','Gabriel','Helena','Igor','Julia'])[floor(random()*10+1)] || '_' || i,
    (ARRAY['Silva','Santos','Oliveira','Souza','Rodrigues','Ferreira','Almeida','Pereira','Lima','Gomes'])[floor(random()*10+1)] || '_' || (i % 1000),
    LPAD(i::text, 11, '0'), 'user_' || i || '@ufba.br',
    (ARRAY['Graduando', 'Mestrando', 'Doutorando', 'Professor', 'Pesquisador'])[floor(random()*5+1)]
FROM generate_series(1, 3000) AS i;

-- 2. FINANCIADORES
INSERT INTO TB_FINANCIADOR (NM_FINANCIADOR, TP_FINANCIADOR, NR_CNPJ, TX_EMAIL_CONTATO)
SELECT 'Financiador_' || i, (ARRAY['Publico', 'Privado'])[floor(random()*2+1)], LPAD(i::text, 14, '0'), 'contato_' || i || '@fin.com'
FROM generate_series(1, 50) AS i;

-- 3. PUBLICACOES 
INSERT INTO TB_PUBLICACAO (NM_TITULO_PUBLICACAO, NR_ANO, TP_PUBLICACAO)
SELECT 'Pub ' || md5(random()::text), floor(random() * (2025 - 2015 + 1) + 2015)::int,
       (ARRAY['Artigo', 'Conferencia', 'Livro'])[floor(random()*3+1)]
FROM generate_series(1, 4000) AS i;

-- 4. PROJETOS 
INSERT INTO TB_PROJETO (NM_TITULO_PROJETO, TX_DESCRICAO, DT_INICIO, DT_FIM, VL_ORCAMENTO_TOTAL, ID_COORDENADOR)
SELECT 'Proj ' || i, 'Desc...', CURRENT_DATE - (floor(random() * 1825) || ' days')::interval, 
       CASE WHEN random() > 0.5 THEN CURRENT_DATE - (floor(random() * 300) || ' days')::interval ELSE NULL END, 
       (random() * 800000 + 50000)::numeric(15,2),
       (floor(random() * 3000 + 1) + (i*0))::bigint 
FROM generate_series(1, 600) AS i;

-- 5. CONTRATOS (1 por projeto)
INSERT INTO TB_CONTRATO (NR_CONTRATO, TP_CONTRATO, VL_CONTRATO_TOTAL, DT_INICIO, DT_FIM, ID_PROJETO, ID_FINANCIADOR)
SELECT 'CTR-'||ID_PROJETO, 'Termo', VL_ORCAMENTO_TOTAL, DT_INICIO, DT_FIM, ID_PROJETO,
       (floor(random()*50+1) + (ID_PROJETO*0))::bigint
FROM TB_PROJETO;

-- 6. EQUIPAMENTOS 
INSERT INTO TB_EQUIPAMENTO (NM_EQUIPAMENTO, NR_SERIE, VL_COMPRA, ID_PROJETO, ID_RESPONSAVEL)
SELECT 'Equip '||md5(random()::text), md5(P.ID_PROJETO::text || G.i::text), (random()*20000+1000)::numeric(15,2),
       P.ID_PROJETO, P.ID_COORDENADOR
FROM TB_PROJETO P
CROSS JOIN generate_series(1, (floor(random()*5+1))::int) AS G(i) 
WHERE P.ID_PROJETO <= 500; 

-- 7. RELATORIOS
INSERT INTO TB_RELATORIO (TP_RELATORIO, DT_ENTREGA, TX_DESCRICAO, ID_PROJETO, ID_AUTOR)
SELECT (ARRAY['Parcial', 'Final'])[floor(random()*2+1)],
       P.DT_INICIO + (floor(random()*100)||' days')::interval, 'Relatorio...',
       P.ID_PROJETO, P.ID_COORDENADOR
FROM TB_PROJETO P
WHERE random() > 0.3; 

-- 8. TR_TRABALHA_EM
INSERT INTO TR_TRABALHA_EM (ID_PROJETO, ID_PESSOA, DT_INICIO_PARTICIPACAO, DT_FIM_PARTICIPACAO, DS_FUNCAO)
SELECT ID_PROJETO, ID_PESSOA_GERADO, DT_INICIO,
       CASE WHEN DT_FIM IS NOT NULL THEN DT_FIM 
            WHEN random() > 0.8 THEN CURRENT_DATE - INTERVAL '1 month' 
            ELSE NULL END,
       (ARRAY['Pesquisador','Bolsista','Tecnico'])[floor(random()*3+1)]
FROM (
    SELECT DISTINCT ON (PROJ.ID_PROJETO, P_GEN.ID_PESSOA_GERADO)
       PROJ.ID_PROJETO, PROJ.DT_INICIO, PROJ.DT_FIM, P_GEN.ID_PESSOA_GERADO
    FROM TB_PROJETO PROJ
    CROSS JOIN LATERAL (
        SELECT (floor(random() * 3000 + 1) + (PROJ.ID_PROJETO * 0))::bigint AS ID_PESSOA_GERADO
        FROM generate_series(1, 12) 
    ) P_GEN
    WHERE P_GEN.ID_PESSOA_GERADO != PROJ.ID_COORDENADOR
) sub;

-- 9. BOLSAS 
INSERT INTO TB_BOLSA (TP_BOLSA, VL_BOLSA_MENSAL, DT_INICIO, DT_FIM, ID_CONTRATO, ID_BOLSISTA)
SELECT DISTINCT ON (T.ID_PESSOA)
    (ARRAY['IC', 'Mestrado', 'Doutorado'])[floor(random()*3+1)],
    1500.00 + (random()*2000),
    T.DT_INICIO_PARTICIPACAO,
    CASE WHEN random() > 0.5 THEN T.DT_INICIO_PARTICIPACAO + INTERVAL '1 year' ELSE NULL END, 
    (SELECT ID_CONTRATO FROM TB_CONTRATO WHERE ID_PROJETO = T.ID_PROJETO LIMIT 1),
    T.ID_PESSOA
FROM TR_TRABALHA_EM T
WHERE random() < 0.4 
LIMIT 1000;

-- 10. AUTORIA E TELEFONE
INSERT INTO TR_AUTORIA (ID_PUBLICACAO, ID_PESSOA, NR_ORDEM_AUTORIA)
SELECT ID_PUBLICACAO, ID_PESSOA_GERADO, row_number() OVER (PARTITION BY ID_PUBLICACAO ORDER BY random())
FROM (
    SELECT DISTINCT ON (P.ID_PUBLICACAO, P_GEN.ID_PESSOA_GERADO) P.ID_PUBLICACAO, P_GEN.ID_PESSOA_GERADO
    FROM TB_PUBLICACAO P
    CROSS JOIN LATERAL (
        SELECT (floor(random() * 3000 + 1) + (P.ID_PUBLICACAO * 0))::bigint AS ID_PESSOA_GERADO
        FROM generate_series(1, (floor(random() * 6 + 1))::int)
    ) P_GEN
) sub;

INSERT INTO TB_TELEFONE (NR_DDD, NR_TELEFONE, ID_PESSOA)
SELECT 71, (floor(random()*90000000)+10000000)::text, ID_PESSOA FROM TB_PESSOA WHERE random() > 0.2;

COMMIT;