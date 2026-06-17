<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    // Proteção da página: se não for cliente, volta para o login
    String perfil = (String) session.getAttribute("perfil");
    String nome = (String) session.getAttribute("nome");

    if (perfil == null || !perfil.equals("cliente")) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Área do Cliente - FelixUberShop</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <link rel="stylesheet" href="css/style.css">
    
    <style>
        /* Estilos específicos para organizar o Painel de Controlo */
        body {
            display: block;
            background: #f8fafc;
        }

        .navbar-dashboard {
            background: #ffffff;
            border-bottom: 1px solid #e5e7eb;
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .navbar-dashboard .logo {
            font-size: 24px;
            font-weight: 700;
            color: #10b981;
            text-decoration: none;
        }

        .navbar-dashboard .user-info a {
            color: #ef4444;
            text-decoration: none;
            font-weight: 600;
            margin-left: 15px;
            font-size: 14px;
        }

        .conteudo-painel {
            max-width: 1100px;
            margin: 40px auto;
            padding: 0 20px;
        }

        .banner-cliente {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            padding: 30px;
            border-radius: 14px;
            margin-bottom: 30px;
            box-shadow: 0 4px 15px rgba(16, 185, 129, 0.1);
        }

        .banner-cliente h2 {
            margin-bottom: 5px;
            font-weight: 700;
        }

        .banner-cliente p {
            opacity: 0.9;
        }

        /* Grelha de opções da Dashboard */
        .menu-dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
        }

        .opcao-card {
            background: white;
            border: 1px solid #e5e7eb;
            border-radius: 12px;
            padding: 25px;
            transition: transform 0.2s, border-color 0.2s, box-shadow 0.2s;
            text-decoration: none;
            color: inherit;
        }

        .opcao-card:hover {
            transform: translateY(-4px);
            border-color: #10b981;
            box-shadow: 0 10px 20px rgba(0,0,0,0.05);
        }

        .opcao-card h3 {
            color: #2e7d32; /* Cor idêntica aos títulos originais */
            margin-bottom: 8px;
            font-size: 18px;
        }

        .opcao-card p {
            color: #666;
            font-size: 14px;
            line-height: 1.5;
        }
    </style>
</head>
<body>

    <nav class="navbar-dashboard">
        <a href="index.jsp" class="logo">FelixUberShop</a>
        <div class="user-info">
            <span>Bem-vindo, <strong><%= nome %></strong></span>
            <a href="logout.jsp">Terminar Sessão</a>
        </div>
    </nav>

    <main class="conteudo-painel">
        
        <div class="banner-cliente">
            <h2>Área do Cliente</h2>
            <p>Faça a gestão das suas compras, acompanhe encomendas e consulte o seu histórico.</p>
        </div>

        <div class="menu-dashboard">
            
            <a href="minhas_encomendas.jsp" class="opcao-card">
                <h3>📦 As Minhas Encomendas</h3>
                <p>Veja o estado dos seus pedidos ativos e consulte todo o seu histórico de compras anterior.</p>
            </a>

            <a href="index.jsp" class="opcao-card">
                <h3>🛒 Voltar às Compras</h3>
                <p>Navegue pela página principal para ver o catálogo de produtos e adicionar novos itens ao carrinho.</p>
            </a>

            <a href="perfil_cliente.jsp" class="opcao-card">
                <h3>👤 Dados da Conta</h3>
                <p>Atualize as suas informações pessoais, gerencie as suas moradas de entrega ou altere a password.</p>
            </a>

        </div>

    </main>

</body>
</html>