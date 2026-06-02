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

    <link rel="stylesheet" href="style.css">
</head>
<body class="pagina-inicial">

<nav class="navbar-principal">
    <a href="index.jsp" class="logo">FelixUberShop</a>

    <div class="nav-menu">
        <a href="index.jsp">Início</a>
        <a href="produtos.jsp">Produtos</a>
        <a href="#contactos">Contactos</a>

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
        <a href="login.jsp" class="btn-hero secundario">Fazer Login</a>
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

<footer class="footer-principal">

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
        <p>&copy; 2026 FelixUberShop. Todos os direitos reservados.</p>
    </div>

</footer>

</body>
</html>