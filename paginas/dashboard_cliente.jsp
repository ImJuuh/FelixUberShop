<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" %>

<%
    /*
     * Dashboard do cliente.
     * Apenas utilizadores com perfil "cliente" podem aceder.
     */

    request.setCharacterEncoding("UTF-8");

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

    <link rel="stylesheet" href="style.css">

    <style>
        /*
         * Estilos específicos da área do cliente.
         */
        body {
            display: block;
            background: #f8fafc;
            margin: 0;
            font-family: 'Inter', Arial, sans-serif;
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

        .navbar-dashboard .user-info {
            color: #374151;
            font-size: 14px;
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
            padding: 32px;
            border-radius: 14px;
            margin-bottom: 30px;
            box-shadow: 0 4px 15px rgba(16, 185, 129, 0.15);
        }

        .banner-cliente h2 {
            margin: 0 0 8px 0;
            font-weight: 700;
            font-size: 28px;
        }

        .banner-cliente p {
            margin: 0;
            opacity: 0.95;
        }

        /*
         * Grelha de opções da dashboard.
         */
        .menu-dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
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
            min-height: 165px;
        }

        .opcao-card:hover {
            transform: translateY(-4px);
            border-color: #10b981;
            box-shadow: 0 10px 20px rgba(0,0,0,0.06);
        }

        .opcao-card h3 {
            color: #2e7d32;
            margin: 0 0 10px 0;
            font-size: 18px;
        }

        .opcao-card p {
            color: #666;
            font-size: 14px;
            line-height: 1.5;
            margin: 0;
        }

        .opcao-card.destaque {
            border-color: #10b981;
            background: #ecfdf5;
        }

        .opcao-card.destaque h3 {
            color: #047857;
        }

        @media (max-width: 700px) {
            .navbar-dashboard {
                flex-direction: column;
                gap: 10px;
                text-align: center;
            }

            .navbar-dashboard .user-info a {
                display: block;
                margin-left: 0;
                margin-top: 8px;
            }

            .banner-cliente h2 {
                font-size: 23px;
            }
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
            <p>Faça a gestão das suas compras, consulte a carteira e acompanhe as suas encomendas.</p>
        </div>

        <div class="menu-dashboard">

            <a href="carteira.jsp" class="opcao-card destaque">
                <h3>💳 A Minha Carteira</h3>
                <p>Consulte o saldo disponível, adicione saldo, levante saldo e veja os movimentos realizados.</p>
            </a>

            <a href="nova_encomenda.jsp" class="opcao-card">
                <h3>🛒 Nova Encomenda</h3>
                <p>Escolha vários produtos por categoria, indique as quantidades pretendidas e crie uma nova encomenda.</p>
            </a>

            <a href="minhas_encomendas.jsp" class="opcao-card">
                <h3>📦 As Minhas Encomendas</h3>
                <p>Veja o estado das suas encomendas, consulte o histórico, edite encomendas pendentes ou cancele pedidos.</p>
            </a>

            <a href="perfil_cliente.jsp" class="opcao-card">
                <h3>👤 Dados da Conta</h3>
                <p>Consulte e atualize os seus dados pessoais, contactos, morada e palavra-passe.</p>
            </a>

            <a href="produtos.jsp" class="opcao-card">
                <h3>🥦 Consultar Produtos</h3>
                <p>Consulte os produtos disponíveis, preços, categorias e stock existente na mercearia.</p>
            </a>

            <a href="index.jsp" class="opcao-card">
                <h3>🏠 Página Inicial</h3>
                <p>Volte à página principal para consultar informações, promoções, contactos e horário da FelixUberShop.</p>
            </a>

        </div>

    </main>

</body>
</html>