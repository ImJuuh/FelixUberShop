<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    String perfil = (String) session.getAttribute("perfil");
    String nomeSessao = (String) session.getAttribute("nome");
    Integer userId = (Integer) session.getAttribute("user_id");

    if (perfil == null || !perfil.equals("cliente") || userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    String erro = "";
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Minhas Encomendas - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="style.css">

    <style>
        /* Ajustes específicos para a fluidez da página de listagem */
        body {
            display: block;
            background: #f8fafc;
        }

        .navbar-encomendas {
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

        .navbar-encomendas .logo {
            font-size: 24px;
            font-weight: 700;
            color: #10b981;
            text-decoration: none;
        }

        .navbar-encomendas .user-info a {
            color: #ef4444;
            text-decoration: none;
            font-weight: 600;
            margin-left: 15px;
            font-size: 14px;
        }

        /* Sobrescreve margens para encaixar abaixo da navbar */
        .container-tabela {
            margin-top: 30px;
            margin-bottom: 50px;
        }
    </style>
</head>
<body>

    <nav class="navbar-encomendas">
        <a href="index.jsp" class="logo">FelixUberShop</a>
        <div class="user-info">
            <span>Olá, <strong><%= nomeSessao %></strong></span>
            <a href="logout.jsp">Terminar Sessão</a>
        </div>
    </nav>

    <div class="container-tabela">

        <div class="header" style="text-align: left; margin-bottom: 20px;">
            <h1 style="font-size: 24px; color: #1f2937;">Histórico de Encomendas</h1>
            <p style="color: #6b7280; font-size: 14px;">Consulte o estado e os detalhes das suas compras realizadas.</p>
        </div>

        <%
            try {
                conn = ligarBD();

                String sql =
                    "SELECT e.id, e.codigo_validacao, e.data_encomenda, e.estado, e.total, " +
                    "p.nome AS produto, ep.quantidade, ep.preco_unitario " +
                    "FROM encomendas e " +
                    "INNER JOIN encomenda_produtos ep ON e.id = ep.encomenda_id " +
                    "INNER JOIN produtos p ON ep.produto_id = p.id " +
                    "WHERE e.cliente_id = ? " +
                    "ORDER BY e.data_encomenda DESC";

                ps = conn.prepareStatement(sql);
                ps.setInt(1, userId);
                rs = ps.executeQuery();

                boolean temEncomendas = false;
        %>

        <table class="tabela">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Data</th>
                    <th>Produto</th>
                    <th style="text-align: center;">Qtd.</th>
                    <th>Preço Unit.</th>
                    <th>Total Pago</th>
                    <th>Estado</th>
                    <th style="text-align: center;">Ações</th>
                </tr>
            </thead>

            <tbody>

            <%
                while (rs.next()) {
                    temEncomendas = true;

                    int encomendaId = rs.getInt("id");
                    String codigo = rs.getString("codigo_validacao");
                    String data = rs.getString("data_encomenda");
                    String produto = rs.getString("produto");
                    int quantidade = rs.getInt("quantidade");
                    double preco = rs.getDouble("preco_unitario");
                    double total = rs.getDouble("total");
                    String estado = rs.getString("estado");
            %>

                <tr>
                    <td style="font-weight: 600; color: #10b981;">#<%= codigo %></td>
                    <td><%= data %></td>
                    <td><%= produto %></td>
                    <td style="text-align: center;"><%= quantidade %></td>
                    <td><%= String.format("%.2f", preco) %> €</td>
                    <td style="font-weight: 600;"><%= String.format("%.2f", total) %> €</td>
                    <td><span class="badge"><%= estado %></span></td>
                    <td style="text-align: center;">
                            <a class="btn-pequeno" href="editar_encomenda.jsp?id=<%= encomendaId %>">
                                Editar
                            </a>

                        <a class="btn-pequeno danger" href="cancelar_encomenda.jsp?id=<%= encomendaId %>" onclick="return confirm('Tem a certeza que deseja cancelar esta encomenda?');">
                                Cancelar
                        </a>
                    </td>
                </tr>

            <%
                }

                if (!temEncomendas) {
            %>

                <tr>
                    <td colspan="8" class="sem-dados">Ainda não realizou nenhuma encomenda no nosso sistema.</td>
                </tr>

            <%
                }
            %>

            </tbody>
        </table>

        <%
            } catch (Exception e) {
                erro = "Não foi possível carregar as suas encomendas de momento.";
                e.printStackTrace();
        %>

            <div class="erro"><%= erro %></div>

        <%
            } finally {
                try {
                    if (rs != null) rs.close();
                    if (ps != null) ps.close();
                    if (conn != null) conn.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        %>

        <div class="links" style="display: flex; justify-content: space-between; align-items: center; margin-top: 30px;">
            <a href="index.jsp" style="color: #6b7280;">← Continuar a Comprar</a>
            <a href="dashboard_cliente.jsp" class="btn-pequeno" style="padding: 10px 20px; box-shadow: none;">Ir para o Painel Geral</a>
        </div>

    </div>

</body>
</html>