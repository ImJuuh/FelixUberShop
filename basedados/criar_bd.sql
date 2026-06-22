DROP DATABASE IF EXISTS felixubershop;

CREATE DATABASE felixubershop
CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci;

USE felixubershop;

CREATE TABLE utilizadores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    telefone VARCHAR(20),
    morada VARCHAR(200),
    perfil ENUM('cliente', 'funcionario', 'admin') NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE carteiras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilizador_id INT NULL,
    nome VARCHAR(100) NOT NULL,
    saldo DECIMAL(10,2) DEFAULT 0.00,
    tipo ENUM('cliente', 'loja') NOT NULL,
    FOREIGN KEY (utilizador_id) REFERENCES utilizadores(id)
);

CREATE TABLE produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    categoria VARCHAR(50),
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE promocoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descricao TEXT NOT NULL,
    data_inicio DATE,
    data_fim DATE,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE encomendas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_validacao VARCHAR(50) NOT NULL UNIQUE,
    cliente_id INT NOT NULL,
    data_encomenda DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendente', 'validada', 'cancelada', 'entregue') DEFAULT 'pendente',
    total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES utilizadores(id)
);

CREATE TABLE encomenda_produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    encomenda_id INT NOT NULL,
    produto_id INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (encomenda_id) REFERENCES encomendas(id),
    FOREIGN KEY (produto_id) REFERENCES produtos(id)
);

CREATE TABLE movimentos_carteira (
    id INT AUTO_INCREMENT PRIMARY KEY,
    carteira_origem_id INT NULL,
    carteira_destino_id INT NULL,
    tipo_operacao ENUM(
        'adicionar',
        'levantar',
        'adicionar_saldo',
        'retirar_saldo',
        'pagamento',
        'devolucao'
    ) NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_movimento DATETIME DEFAULT CURRENT_TIMESTAMP,
    descricao VARCHAR(255),
    FOREIGN KEY (carteira_origem_id) REFERENCES carteiras(id),
    FOREIGN KEY (carteira_destino_id) REFERENCES carteiras(id)
);

-- UTILIZADORES OBRIGATÓRIOS 
INSERT INTO utilizadores (username, password, nome, email, telefone, morada, perfil, ativo)
VALUES
('cliente', SHA2('cliente', 256), 'Cliente', 'cliente@felixubershop.pt', '910000001', 'Rua do Cliente', 'cliente', TRUE),
('funcionario', SHA2('funcionario', 256), 'Funcionário', 'funcionario@felixubershop.pt', '910000002', 'Rua do Funcionário', 'funcionario', TRUE),
('admin', SHA2('admin', 256), 'Administrador', 'admin@felixubershop.pt', '910000003', 'Rua do Administrador', 'admin', TRUE);

-- CARTEIRA DO CLIENTE
INSERT INTO carteiras (utilizador_id, nome, saldo, tipo)
VALUES
(1, 'Carteira Cliente Teste', 100.00, 'cliente');

-- CARTEIRA DA FELIXUBERSHOP
INSERT INTO carteiras (utilizador_id, nome, saldo, tipo)
VALUES
(NULL, 'Carteira FelixUberShop', 0.00, 'loja');

-- PRODUTOS
INSERT INTO produtos (nome, descricao, preco, stock, categoria, ativo)
VALUES
('Arroz Carolino 1kg', 'Arroz branco carolino de qualidade.', 1.49, 50, 'Mercearia', TRUE),
('Arroz Agulha 1kg', 'Arroz agulha embalado para refeições do dia a dia.', 1.35, 70, 'Mercearia', TRUE),
('Massa Esparguete 500g', 'Massa esparguete ideal para refeições rápidas.', 0.99, 80, 'Mercearia', TRUE),
('Massa Cotovelos 500g', 'Massa cotovelos para sopas e pratos variados.', 0.89, 65, 'Mercearia', TRUE),
('Azeite Virgem 750ml', 'Azeite virgem para cozinhar e temperar.', 5.99, 30, 'Mercearia', TRUE),
('Atum em Lata', 'Lata de atum em óleo vegetal.', 1.10, 120, 'Mercearia', TRUE),
('Feijão Encarnado 500g', 'Feijão encarnado seco embalado.', 1.29, 55, 'Mercearia', TRUE),

('Leite Meio Gordo 1L', 'Leite meio gordo embalado.', 0.89, 100, 'Laticínios', TRUE),
('Leite Magro 1L', 'Leite magro embalado.', 0.85, 90, 'Laticínios', TRUE),
('Queijo Flamengo 200g', 'Queijo flamengo fatiado.', 2.49, 35, 'Laticínios', TRUE),
('Iogurte Natural', 'Iogurte natural individual.', 0.55, 90, 'Laticínios', TRUE),
('Manteiga 250g', 'Manteiga para barrar e cozinhar.', 1.89, 40, 'Laticínios', TRUE),

('Maçã Vermelha 1kg', 'Maçã fresca nacional.', 1.79, 40, 'Fruta', TRUE),
('Maçã Golden 1kg', 'Maçã golden fresca vendida ao quilo.', 1.49, 50, 'Fruta', TRUE),
('Banana 1kg', 'Banana madura vendida ao quilo.', 1.29, 60, 'Fruta', TRUE),
('Laranja 1kg', 'Laranja fresca para consumo ou sumo.', 1.39, 45, 'Fruta', TRUE),
('Pera Rocha 1kg', 'Pera rocha nacional.', 1.69, 35, 'Fruta', TRUE),

('Batata Branca 1kg', 'Batata branca para cozinhar.', 1.20, 80, 'Legumes', TRUE),
('Cenoura 1kg', 'Cenoura fresca embalada.', 0.99, 70, 'Legumes', TRUE),
('Tomate 1kg', 'Tomate fresco para saladas e cozinhados.', 1.79, 40, 'Legumes', TRUE),
('Alface', 'Alface fresca para saladas.', 0.95, 50, 'Legumes', TRUE),
('Cebola 1kg', 'Cebola seca embalada.', 1.15, 60, 'Legumes', TRUE),

('Pão de Forma', 'Pão de forma familiar.', 1.25, 30, 'Padaria', TRUE),
('Carcaças Pack 6', 'Conjunto de seis carcaças frescas.', 1.50, 45, 'Padaria', TRUE),
('Bolo Simples', 'Bolo simples para pequeno-almoço ou lanche.', 2.99, 20, 'Padaria', TRUE),

('Água 1.5L', 'Garrafa de água mineral.', 0.39, 150, 'Bebidas', TRUE),
('Sumo de Laranja 1L', 'Sumo de laranja embalado.', 1.29, 60, 'Bebidas', TRUE),
('Ice Tea Pêssego 1.5L', 'Bebida refrescante de chá com sabor a pêssego.', 1.49, 50, 'Bebidas', TRUE),

('Detergente Roupa', 'Detergente líquido para roupa.', 4.99, 25, 'Limpeza', TRUE),
('Papel Higiénico', 'Embalagem de papel higiénico.', 3.49, 45, 'Limpeza', TRUE),
('Lava Tudo', 'Produto de limpeza multiusos.', 1.99, 40, 'Limpeza', TRUE);

-- PROMOÇÕES
INSERT INTO promocoes (titulo, descricao, data_inicio, data_fim, ativo)
VALUES
('Promoção da Semana', 'Na compra de 2 embalagens de massa, receba 10% de desconto.', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY), TRUE),
('Fruta Fresca', 'Maçã vermelha nacional com preço especial esta semana.', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 5 DAY), TRUE),
('Campanha Mercearia', 'Produtos de mercearia selecionados com preços especiais.', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 DAY), TRUE),
('Limpeza da Casa', 'Descontos em produtos de limpeza selecionados.', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 6 DAY), TRUE);