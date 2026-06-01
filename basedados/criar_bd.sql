DROP DATABASE IF EXISTS felixubershop;
CREATE DATABASE felixubershop CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
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
    tipo_operacao ENUM('adicionar', 'levantar', 'pagamento', 'devolucao') NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_movimento DATETIME DEFAULT CURRENT_TIMESTAMP,
    descricao VARCHAR(255),
    FOREIGN KEY (carteira_origem_id) REFERENCES carteiras(id),
    FOREIGN KEY (carteira_destino_id) REFERENCES carteiras(id)
);

INSERT INTO utilizadores (username, password, nome, email, telefone, morada, perfil)
VALUES
('cliente', 'cliente', 'Cliente Teste', 'cliente@felix.pt', '910000001', 'Rua do Cliente', 'cliente'),
('funcionario', 'funcionario', 'Funcionário Teste', 'funcionario@felix.pt', '910000002', 'Rua do Funcionário', 'funcionario'),
('admin', 'admin', 'Administrador Teste', 'admin@felix.pt', '910000003', 'Rua do Admin', 'admin');

INSERT INTO carteiras (utilizador_id, nome, saldo, tipo)
VALUES
(1, 'Carteira Cliente Teste', 50.00, 'cliente');

INSERT INTO carteiras (utilizador_id, nome, saldo, tipo)
VALUES
(NULL, 'Carteira FelixUberShop', 0.00, 'loja');

INSERT INTO produtos (nome, descricao, preco, stock, categoria)
VALUES
('Arroz Carolino 1kg', 'Arroz branco carolino de qualidade.', 1.49, 50, 'Mercearia'),
('Massa Esparguete 500g', 'Massa esparguete ideal para refeições rápidas.', 0.99, 80, 'Mercearia'),
('Leite Meio Gordo 1L', 'Leite meio gordo embalado.', 0.89, 100, 'Laticínios'),
('Maçã Vermelha 1kg', 'Maçã fresca nacional.', 1.79, 40, 'Fruta'),
('Pão de Forma', 'Pão de forma familiar.', 1.25, 30, 'Padaria');

INSERT INTO promocoes (titulo, descricao, data_inicio, data_fim, ativo)
VALUES
('Promoção da Semana', 'Na compra de 2 embalagens de massa, receba 10% de desconto.', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY), TRUE),
('Fruta Fresca', 'Maçã vermelha nacional com preço especial esta semana.', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 5 DAY), TRUE);