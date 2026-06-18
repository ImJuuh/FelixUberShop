<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    String nomeUser = (String) session.getAttribute("nome");
    String perfil = (String) session.getAttribute("perfil");
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FelixUberShop - A sua Mercearia Online</title>

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">

    
</head>

<body>

<nav class="navbar-principal">
    <a href="index.jsp" class="logo">FelixUberShop</a>

    <div class="nav-menu">
        <a href="index.jsp">Início</a>
        <a href="produtos.jsp">Produtos</a>
        <a href="#footer">Contactos</a>

        <%
            if (nomeUser != null && perfil != null) {
                String dashboard = "dashboard_cliente.jsp";

                if (perfil.equals("funcionario")) {
                    dashboard = "dashboard_funcionario.jsp";
                } else if (perfil.equals("admin")) {
                    dashboard = "dashboard_admin.jsp";
                }
        %>
                <a href="<%= dashboard %>">A Minha Área (<strong><%= nomeUser %></strong>)</a>
                <a href="logout.jsp" class="btn-sair-nav">Sair</a>
        <%
            } else {
        %>
                <a href="registo.jsp">Registar</a>
                <a href="login.jsp" class="btn-login-nav">Entrar</a>
        <%
            }
        %>
    </div>
</nav>

<header class="hero-banner">
    <h2>Bem-vindo à FelixUberShop</h2>
    <p>A sua mercearia online de confiança. Produtos frescos, preços acessíveis e encomendas rápidas.</p>

    <div class="hero-botoes">
        <a href="produtos.jsp" class="btn-hero">Ver Produtos</a>

        <%
            if (nomeUser == null) {
        %>
            <a href="login.jsp" class="btn-hero secundario">Fazer Login</a>
        <%
            } else {
                String dashboardHero = "dashboard_cliente.jsp";

                if (perfil.equals("funcionario")) {
                    dashboardHero = "dashboard_funcionario.jsp";
                } else if (perfil.equals("admin")) {
                    dashboardHero = "dashboard_admin.jsp";
                }
        %>
            <a href="<%= dashboardHero %>" class="btn-hero secundario">A Minha Área</a>
        <%
            }
        %>
    </div>
</header>

<main>

    <section class="info-section">
        <div class="info-card">
            <h3>Localização</h3>
            <p>Rua Principal nº 25, Castelo Branco</p>
        </div>

        <div class="info-card">
            <h3>Horário</h3>
            <p>Segunda a sábado: 09h00 - 20h00</p>
            <p>Domingo: 09h00 - 13h00</p>
        </div>

        <div class="info-card">
            <h3>Contactos</h3>
            <p>Telefone: 272 000 000</p>
            <p>Email: geral@felixubershop.pt</p>
        </div>
    </section>

    <section class="container-produtos">

        <div class="topo-produtos">
            <h1>Promoções e Informações</h1>
            <p>Novidades definidas pela administração da FelixUberShop</p>
        </div>

        <div class="grelha-produtos">

            <%
                Connection connPromo = null;
                PreparedStatement psPromo = null;
                ResultSet rsPromo = null;

                try {
                    connPromo = ligarBD();

                    String sqlPromo =
                        "SELECT titulo, descricao, data_inicio, data_fim " +
                        "FROM promocoes " +
                        "WHERE ativo = TRUE " +
                        "AND (data_inicio IS NULL OR data_inicio <= CURDATE()) " +
                        "AND (data_fim IS NULL OR data_fim >= CURDATE()) " +
                        "ORDER BY id DESC";

                    psPromo = connPromo.prepareStatement(sqlPromo);
                    rsPromo = psPromo.executeQuery();

                    boolean temPromocoes = false;

                    while (rsPromo.next()) {
                        temPromocoes = true;

                        String titulo = rsPromo.getString("titulo");
                        String descricao = rsPromo.getString("descricao");
                        String dataInicio = rsPromo.getString("data_inicio");
                        String dataFim = rsPromo.getString("data_fim");
            %>

                <div class="produto-card promocao-card">
                    <span class="categoria">Promoção</span>
                    <h3><%= titulo %></h3>
                    <p class="descricao"><%= descricao %></p>

                    <%
                        if (dataInicio != null || dataFim != null) {
                    %>
                        <p class="stock">
                            Válida:
                            <%= dataInicio != null ? dataInicio : "sem início definido" %>
                            até
                            <%= dataFim != null ? dataFim : "sem fim definido" %>
                        </p>
                    <%
                        }
                    %>
                </div>

            <%
                    }

                    if (!temPromocoes) {
            %>

                <div class="sem-produtos">
                    <p>De momento não existem promoções ativas.</p>
                </div>

            <%
                    }

                } catch (Exception e) {
                    e.printStackTrace();
            %>

                <div class="erro">Erro ao carregar promoções.</div>

            <%
                } finally {
                    try {
                        if (rsPromo != null) rsPromo.close();
                        if (psPromo != null) psPromo.close();
                        if (connPromo != null) connPromo.close();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            %>

        </div>

    </section>

    <section class="container-produtos">

        <div class="topo-produtos">
            <h1>Alguns dos Nossos Produtos</h1>
            <p>Consulte produtos, preços e stock disponível</p>
        </div>

        <div class="grelha-produtos">

            <%
                Connection connProd = null;
                PreparedStatement psProd = null;
                ResultSet rsProd = null;

                try {
                    connProd = ligarBD();

                    String sqlProd =
                        "SELECT nome, descricao, preco, stock, categoria " +
                        "FROM produtos " +
                        "WHERE ativo = TRUE " +
                        "ORDER BY id DESC " +
                        "LIMIT 6";

                    psProd = connProd.prepareStatement(sqlProd);
                    rsProd = psProd.executeQuery();

                    boolean temProdutos = false;

                    while (rsProd.next()) {
                        temProdutos = true;

                        String nome = rsProd.getString("nome");
                        String descricao = rsProd.getString("descricao");
                        String categoria = rsProd.getString("categoria");
                        double preco = rsProd.getDouble("preco");
                        int stock = rsProd.getInt("stock");
            %>

                <div class="produto-card">
                    <span class="categoria"><%= categoria %></span>
                    <h3><%= nome %></h3>
                    <p class="descricao"><%= descricao %></p>
                    <p class="preco"><%= String.format("%.2f", preco) %> €</p>
                    <p class="stock">Stock disponível: <%= stock %> unidades</p>
                </div>

            <%
                    }

                    if (!temProdutos) {
            %>

                <div class="sem-produtos">
                    <p>De momento não existem produtos disponíveis.</p>
                </div>

            <%
                    }

                } catch (Exception e) {
                    e.printStackTrace();
            %>

                <div class="erro">Erro ao carregar produtos.</div>

            <%
                } finally {
                    try {
                        if (rsProd != null) rsProd.close();
                        if (psProd != null) psProd.close();
                        if (connProd != null) connProd.close();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            %>

        </div>

        <div class="nav-links">
            <a href="produtos.jsp">Ver todos os produtos</a>
        </div>

    </section>
</main>

<footer id="footer" class="footer-principal">

    <div class="footer-conteudo">

        <div class="footer-coluna">
            <h3>FelixUberShop</h3>
            <p>A sua mercearia online de confiança, com produtos frescos, preços acessíveis e encomendas rápidas.</p>
        </div>

        <div class="footer-coluna">
            <h4>Navegação</h4>
            <a href="index.jsp">Início</a>
            <a href="produtos.jsp">Produtos</a>
            <a href="registo.jsp">Registar</a>
            <a href="login.jsp">Entrar</a>
        </div>

        <div class="footer-coluna">
            <h4>Contactos</h4>
            <p>Rua Principal nº 25</p>
            <p>Castelo Branco</p>
            <p>Telefone: 272 000 000</p>
            <p>Email: geral@felixubershop.pt</p>
        </div>

        <div class="footer-coluna">
            <h4>Horário</h4>
            <p>Segunda a sábado</p>
            <p>09h00 - 20h00</p>
            <p>Domingo</p>
            <p>09h00 - 13h00</p>
        </div>

    </div>

    <div class="footer-bottom">
        <p>&copy; 2026 FelixUberShop. Julia Corrêa § Margarida Sampaio.</p>
    </div>

</footer>
<style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', Arial, sans-serif;
        }

        html,
        body {
            margin: 0;
            padding: 0;
            width: 100%;
            min-height: 100%;
            background: #f8fafc;
        }

        body {
            display: block;
        }

        /* NAVBAR */

        .navbar-principal {
            width: 100%;
            background: #ffffff;
            border-bottom: 1px solid #e5e7eb;
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .navbar-principal .logo {
            font-size: 24px;
            font-weight: 700;
            color: #10b981;
            text-decoration: none;
        }

        .nav-menu {
            display: flex;
            align-items: center;
            gap: 18px;
            flex-wrap: wrap;
        }

        .nav-menu a {
            color: #1f2937;
            text-decoration: none;
            font-weight: 500;
            font-size: 14px;
            transition: color 0.2s;
        }

        .nav-menu a:hover {
            color: #10b981;
        }

        .btn-login-nav {
            background: #10b981;
            color: white !important;
            padding: 8px 16px;
            border-radius: 6px;
        }

        .btn-login-nav:hover {
            background: #059669;
            color: white !important;
        }

        .btn-sair-nav {
            color: #ef4444 !important;
            font-weight: 700 !important;
        }

        /* HERO */

        .hero-banner {
            width: 100%;
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            text-align: center;
            padding: 75px 20px;
            margin: 0 0 35px 0;
        }

        .hero-banner h2 {
            font-size: 40px;
            font-weight: 700;
            margin-bottom: 12px;
        }

        .hero-banner p {
            font-size: 16px;
            opacity: 0.95;
            max-width: 650px;
            margin: 0 auto;
            line-height: 1.6;
        }

        .hero-botoes {
            margin-top: 28px;
            display: flex;
            justify-content: center;
            gap: 15px;
            flex-wrap: wrap;
        }

        .btn-hero {
            background: white;
            color: #059669;
            padding: 12px 24px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 700;
            transition: 0.2s;
        }

        .btn-hero:hover {
            background: #f0fdf4;
            transform: translateY(-2px);
        }

        .btn-hero.secundario {
            background: transparent;
            color: white;
            border: 2px solid white;
        }

        .btn-hero.secundario:hover {
            background: rgba(255, 255, 255, 0.15);
        }

        /* SECÇÕES */

        main {
            width: 100%;
        }

        .info-section {
            width: 1000px;
            max-width: 95%;
            margin: 35px auto;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
            gap: 20px;
        }

        .info-card {
            background: white;
            padding: 24px;
            border-radius: 16px;
            border: 1px solid #e5e7eb;
            box-shadow: 0 5px 18px rgba(0, 0, 0, 0.06);
        }

        .info-card h3 {
            color: #10b981;
            margin-bottom: 10px;
        }

        .info-card p {
            color: #4b5563;
            margin: 7px 0;
            line-height: 1.5;
        }

        .container-produtos {
            width: 1000px;
            max-width: 95%;
            margin: 40px auto;
            background: white;
            padding: 35px;
            border-radius: 18px;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.10);
        }

        .topo-produtos {
            text-align: center;
            margin-bottom: 30px;
        }

        .topo-produtos h1 {
            color: #2e7d32;
            margin-bottom: 8px;
            font-size: 28px;
        }

        .topo-produtos p {
            color: #666;
            font-size: 14px;
        }

        .grelha-produtos {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
            gap: 20px;
        }

        .produto-card {
            border: 1px solid #dbe8d8;
            border-radius: 14px;
            padding: 20px;
            background: #fbfffb;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .produto-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 18px rgba(0, 0, 0, 0.10);
        }

        .produto-card h3 {
            color: #2e7d32;
            margin-bottom: 10px;
        }

        .categoria {
            display: inline-block;
            background: #e8f5e9;
            color: #2e7d32;
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 13px;
            margin-bottom: 10px;
            font-weight: 600;
        }

        .descricao {
            color: #555;
            min-height: 45px;
            line-height: 1.5;
            font-size: 14px;
        }

        .preco {
            font-size: 22px;
            font-weight: 700;
            color: #1b5e20;
            margin-top: 15px;
        }

        .stock {
            font-size: 14px;
            color: #666;
            margin-top: 8px;
        }

        .promocao-card {
            border: 2px solid #a7f3d0;
            background: #f0fdf4;
        }

        .sem-produtos {
            text-align: center;
            padding: 25px;
            color: #777;
            grid-column: 1 / -1;
        }

        .erro {
            background: #fef2f2;
            color: #991b1b;
            border: 1px solid #fca5a5;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 24px;
            text-align: center;
            font-size: 13px;
            font-weight: 500;
            grid-column: 1 / -1;
        }

        .nav-links {
            text-align: center;
            margin-top: 30px;
        }

        .nav-links a {
            color: #2e7d32;
            text-decoration: none;
            font-weight: 700;
        }

        .nav-links a:hover {
            text-decoration: underline;
        }

        /* FOOTER */

        .footer-principal {
            width: 100%;
            background: #111827;
            color: #f9fafb;
            margin-top: 60px;
        }

        .footer-conteudo {
            width: 1100px;
            max-width: 95%;
            margin: 0 auto;
            padding: 45px 0;
            display: grid;
            grid-template-columns: 2fr 1fr 1.3fr 1fr;
            gap: 35px;
        }

        .footer-coluna h3 {
            color: #10b981;
            font-size: 24px;
            margin-bottom: 12px;
        }

        .footer-coluna h4 {
            color: #ffffff;
            font-size: 16px;
            margin-bottom: 14px;
        }

        .footer-coluna p {
            color: #d1d5db;
            font-size: 14px;
            line-height: 1.6;
            margin: 6px 0;
        }

        .footer-coluna a {
            display: block;
            color: #d1d5db;
            text-decoration: none;
            font-size: 14px;
            margin-bottom: 9px;
            transition: color 0.2s;
        }

        .footer-coluna a:hover {
            color: #10b981;
        }

        .footer-bottom {
            border-top: 1px solid #374151;
            text-align: center;
            padding: 18px 20px;
        }

        .footer-bottom p {
            margin: 0;
            color: #9ca3af;
            font-size: 13px;
        }

        /* RESPONSIVO */

        @media (max-width: 850px) {
            .footer-conteudo {
                grid-template-columns: 1fr 1fr;
            }
        }

        @media (max-width: 700px) {
            .navbar-principal {
                flex-direction: column;
                gap: 12px;
                text-align: center;
            }

            .nav-menu {
                justify-content: center;
            }

            .hero-banner h2 {
                font-size: 30px;
            }

            .hero-botoes {
                flex-direction: column;
                align-items: center;
            }

            .container-produtos {
                padding: 25px 18px;
            }
        }

        @media (max-width: 550px) {
            .footer-conteudo {
                grid-template-columns: 1fr;
                text-align: center;
            }
        }
    </style>
</body>
</html>