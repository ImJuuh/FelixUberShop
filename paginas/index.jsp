<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FelixUberShop - A sua Loja Online</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <link rel="stylesheet" href="css/style.css">
    
    <style>
        /* Estilos específicos para a estrutura da Página Principal que não estavam no CSS global */
        body {
            display: block; /* Sobrescreve o flex do login para a página fluir verticalmente */
            background: #f8fafc; /* Fundo ligeiramente acinzentado para destacar os cards */
        }
        
        .navbar-principal {
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

        .navbar-principal .nav-menu a {
            color: #1f2937;
            text-decoration: none;
            font-weight: 500;
            margin-left: 20px;
            font-size: 14px;
            transition: color 0.2s;
        }

        .navbar-principal .nav-menu a:hover {
            color: #10b981;
        }

        .navbar-principal .nav-menu a.btn-login-nav {
            background: #10b981;
            color: white;
            padding: 8px 16px;
            border-radius: 6px;
        }

        .navbar-principal .nav-menu a.btn-login-nav:hover {
            background: #059669;
        }

        .hero-banner {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            text-align: center;
            padding: 60px 20px;
            margin-bottom: 20px;
        }

        .hero-banner h2 {
            font-size: 36px;
            font-weight: 700;
            margin-bottom: 10px;
        }

        .hero-banner p {
            font-size: 16px;
            opacity: 0.9;
            max-width: 600px;
            margin: 0 auto;
        }
    </style>
</head>
<body>

    <nav class="navbar-principal">
        <a href="index.jsp" class="logo">FelixUberShop</a>
        <div class="nav-menu">
            <a href="index.jsp">Início</a>
            <a href="aboutus.jsp">Sobre Nós</a>
            <% 
                // Validação simples para mostrar o perfil ou o botão de Login na barra
                String nomeUser = (String) session.getAttribute("nome");
                if (nomeUser != null) {
            %>
                <a href="dashboard_cliente.jsp">A Minha Área (<strong><%= nomeUser %></strong>)</a>
            <% } else { %>
                <a href="login.jsp" class="btn-login-nav">Entrar</a>
            <% } %>
        </div>
    </nav>

    <header class="hero-banner">
        <h2>Bem-vindo à FelixUberShop</h2>
        <p>Explore as melhores ofertas com a qualidade e rapidez que merece. Encontre tudo o que procura abaixo.</p>
    </header>

    <main class="container-produtos">
        
        <div class="topo-produtos">
            <h1>Os Nossos Produtos</h1>
            <p>Descubra as novidades do nosso catálogo tecnológico e muito mais</p>
        </div>

        <div class="grelha-produtos">
    

        </div>

    </main>

</body>
</html>