<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    /*
     * Página principal da área do funcionário.
     * Apenas utilizadores com perfil funcionário podem aceder.
     */

    String perfil = (String) session.getAttribute("perfil");
    String nome = (String) session.getAttribute("nome");

    if (perfil == null || !perfil.equals("funcionario")) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Área do Funcionário - FelixUberShop</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Área do Funcionário</h1>
        <p>Bem-vindo, <%= nome %></p>
    </div>

    <div class="admin-menu">

        <a class="admin-card" href="func_encomendas.jsp">
            <h3>Gerir Encomendas</h3>
            <p>Consultar, validar e marcar encomendas como entregues.</p>
        </a>

        <a class="admin-card" href="func_carteiras.jsp">
            <h3>Gerir Saldos</h3>
            <p>Consultar carteiras e alterar saldo dos clientes.</p>
        </a>

        <a class="admin-card" href="perfil_funcionario.jsp">
            <h3>Editar Perfil</h3>
            <p>Visualizar e editar os seus dados pessoais.</p>
        </a>

        <a class="admin-card" href="produtos.jsp">
            <h3>Consultar Produtos</h3>
            <p>Ver produtos disponíveis na mercearia.</p>
        </a>

    </div>

    <div class="links">
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>

</div>

</body>
</html>