<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    request.setCharacterEncoding("UTF-8");

    String perfil = (String) session.getAttribute("perfil");
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
    <title>As Minhas Encomendas - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">

    <style>
        body {
            display: block !important;
            padding: 20px;
            background: #f8fafc;
        }

        .container-historico {
            width: 1200px;
            max-width: 95%;
            margin: 30px auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.08);
        }

        .topo-historico h1 {
            margin: 0;
            color: #1f2937;
        }

        .topo-historico p {
            color: #6b7280;
            margin-top: 8px;
        }

        .tabela {
            width: 100%;
            border-collapse: collapse;
            margin-top: 25px;
            font-size: 14px;
        }

        .tabela th {
            background: #2e7d32;
            color: white;
            padding: 14px;
            text-align: left;
        }

        .tabela td {
            padding: 14px;
            border-bottom: 1px solid #e5e7eb;
            vertical-align: top;
        }

        .codigo {
            color: #10b981;
            font-weight: bold;
        }

        .lista-produtos {
            line-height: 1.7;
        }

        .produto-item {
            display: block;
            color: #111827;
        }

        .total {
            font-weight: bold;
            color: #111827;
        }

        .badge {
            display: inline-block;
            padding: 7px 13px;
            border-radius: 20px;
            font-weight: bold;
            font-size: 13px;
        }

        .badge-pendente {
            background: #e8f5e9;
            color: #2e7d32;
        }

        .badge-validada {
            background: #e0f2fe;
            color: #0369a1;
        }

        .badge-entregue {
            background: #dcfce7;
            color: #166534;
        }

        .badge-cancelada {
            background: #fee2e2;
            color: #991b1b;
        }

        .btn-pequeno {
            display: inline-block;
            padding: 8px 13px;
            border-radius: 6px;
            text-decoration: none;
            font-size: 13px;
            font-weight: bold;
            background: #2e7d32;
            color: white;
            margin-right: 5px;
            margin-bottom: 5px;
        }

        .btn-pequeno.danger {
            background: #c62828;
        }

        .sem-dados {
            text-align: center;
            padding: 25px;
            color: #777;
        }

        .links {
            text-align: center;
            margin-top: 25px;
        }

        .links a {
            color: #10b981;
            font-weight: bold;
            text-decoration: none;
            margin: 0 8px;
        }

        @media (max-width: 800px) {
            .tabela {
                font-size: 12px;
            }

            .tabela th,
            .tabela td {
                padding: 8px;
            }
        }
    </style>
</head>
<body>

<div class="container-historico">

    <div class="topo-historico">
        <h1>Histórico de Encomendas</h1>
        <p>Consulte o estado e os detalhes das suas compras realizadas.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <table class="tabela">
        <thead>
            <tr>
                <th>Código</th>
                <th>Data</th>
                <th>Produtos</th>
                <th>Total Pago</th>
                <th>Estado</th>
                <th>Ações</th>
            </tr>
        </thead>

        <tbody>

        <%
            try {
                conn = ligarBD();

                /*
                 * Agora agrupamos por encomenda.
                 * Assim aparece uma linha por encomenda,
                 * e dentro dessa linha aparecem todos os produtos.
                 */
                String sql =
                    "SELECT e.id, e.codigo_validacao, e.data_encomenda, e.estado, e.total, " +
                    "GROUP_CONCAT(CONCAT(p.nome, ' x', ep.quantidade, ' — ', FORMAT(ep.preco_unitario, 2), ' €') SEPARATOR '<br>') AS produtos " +
                    "FROM encomendas e " +
                    "INNER JOIN encomenda_produtos ep ON e.id = ep.encomenda_id " +
                    "INNER JOIN produtos p ON ep.produto_id = p.id " +
                    "WHERE e.cliente_id = ? " +
                    "GROUP BY e.id, e.codigo_validacao, e.data_encomenda, e.estado, e.total " +
                    "ORDER BY e.data_encomenda DESC";

                ps = conn.prepareStatement(sql);
                ps.setInt(1, userId);
                rs = ps.executeQuery();

                boolean temEncomendas = false;

                while (rs.next()) {
                    temEncomendas = true;

                    int encomendaId = rs.getInt("id");
                    String codigo = rs.getString("codigo_validacao");
                    String data = rs.getString("data_encomenda");
                    String estado = rs.getString("estado");
                    double total = rs.getDouble("total");
                    String produtos = rs.getString("produtos");

                    String classeEstado = "badge-pendente";

                    if (estado.equals("validada")) {
                        classeEstado = "badge-validada";
                    } else if (estado.equals("entregue")) {
                        classeEstado = "badge-entregue";
                    } else if (estado.equals("cancelada")) {
                        classeEstado = "badge-cancelada";
                    }
        %>

            <tr>
                <td class="codigo">#<%= codigo %></td>

                <td><%= data %></td>

                <td class="lista-produtos">
                    <%= produtos %>
                </td>

                <td class="total"><%= String.format("%.2f", total) %> €</td>

                <td>
                    <span class="badge <%= classeEstado %>">
                        <%= estado %>
                    </span>
                </td>

                <td>
                    <% if (estado.equals("pendente")) { %>

                        <a class="btn-pequeno" href="editar_encomenda.jsp?id=<%= encomendaId %>">
                            Editar
                        </a>

                        <a class="btn-pequeno danger"
                           href="cancelar_encomenda.jsp?id=<%= encomendaId %>"
                           onclick="return confirm('Tem a certeza que deseja cancelar esta encomenda?');">
                            Cancelar
                        </a>

                    <% } else { %>
                        <span style="color:#9ca3af;">Sem ações</span>
                    <% } %>
                </td>
            </tr>

        <%
                }

                if (!temEncomendas) {
        %>

            <tr>
                <td colspan="6" class="sem-dados">
                    Ainda não realizou nenhuma encomenda.
                </td>
            </tr>

        <%
                }

            } catch (Exception e) {
                e.printStackTrace();
        %>

            <tr>
                <td colspan="6" class="sem-dados">
                    Erro ao carregar encomendas.
                </td>
            </tr>

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

        </tbody>
    </table>

    <div class="links">
        <a href="nova_encomenda.jsp">Nova Encomenda</a>
        |
        <a href="dashboard_cliente.jsp">Voltar à área do cliente</a>
    </div>

</div>

</body>
</html>