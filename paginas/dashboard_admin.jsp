<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    String perfil = (String) session.getAttribute("perfil");
    String nome = (String) session.getAttribute("nome");

    if (perfil == null || !perfil.equals("admin")) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Área Admin - FelixUberShop</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Área de Administração</h1>
        <p>Bem-vindo, <%= nome %></p>
    </div>

    <div class="admin-menu">

        <a class="admin-card" href="admin_produtos.jsp">
            <h3>Gerir Produtos</h3>
            <p>Inserir, editar, inativar e reativar produtos.</p>
        </a>

        <a class="admin-card" href="admin_utilizadores.jsp">
            <h3>Gerir Utilizadores</h3>
            <p>Consultar, editar e inativar contas de utilizadores.</p>
        </a>

        <a class="admin-card" href="admin_encomendas.jsp">
            <h3>Gerir Encomendas</h3>
            <p>Consultar e alterar o estado das encomendas.</p>
        </a>

        <a class="admin-card" href="admin_promocoes.jsp">
            <h3>Gerir Promoções</h3>
            <p>Criar e editar informações e promoções dinâmicas.</p>
        </a>

        <a class="admin-card" href="admin_carteiras.jsp">
            <h3>Gerir Carteiras</h3>
            <p>Consultar e gerir saldos dos clientes.</p>
        </a>

        <a class="admin-card" href="perfil_admin.jsp">
            <h3>Editar Perfil</h3>
            <p>Visualizar e editar os seus dados pessoais.</p>
        </a>

    </div>

    <div class="links">
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>

</div>

</body>
</html>