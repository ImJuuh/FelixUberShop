<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    /*
     * Página de gestão de encomendas para funcionários.
     * Permite visualizar encomendas, validar encomendas pendentes
     * e marcar encomendas validadas como entregues.
     */

    String perfil = (String) session.getAttribute("perfil");
    String nomeSessao = (String) session.getAttribute("nome");

    if (perfil == null || !perfil.equals("funcionario")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String erro = "";
    String sucesso = "";

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String acao = request.getParameter("acao");
    String idTexto = request.getParameter("id");

    try {
        conn = ligarBD();

        /*
         * Validar encomenda pendente.
         */
        if ("validar".equals(acao) && idTexto != null) {

            String sql = "UPDATE encomendas SET estado = 'validada' WHERE id = ? AND estado = 'pendente'";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(idTexto));

            int linhas = ps.executeUpdate();
            ps.close();

            if (linhas > 0) {
                sucesso = "Encomenda validada com sucesso.";
            } else {
                erro = "Não foi possível validar a encomenda.";
            }
        }

        /*
         * Marcar encomenda como entregue.
         */
        if ("entregar".equals(acao) && idTexto != null) {

            String sql = "UPDATE encomendas SET estado = 'entregue' WHERE id = ? AND estado = 'validada'";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(idTexto));

            int linhas = ps.executeUpdate();
            ps.close();

            if (linhas > 0) {
                sucesso = "Encomenda marcada como entregue.";
            } else {
                erro = "Só é possível entregar encomendas validadas.";
            }
        }

    } catch (Exception e) {
        erro = "Erro ao atualizar encomenda.";
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Gestão de Encomendas - Funcionário</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Gestão de Encomendas</h1>
        <p>Olá, <%= nomeSessao %>. Aqui pode consultar, validar e entregar encomendas.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <table class="tabela">
        <thead>
            <tr>
                <th>ID</th>
                <th>Código</th>
                <th>Cliente</th>
                <th>Produto</th>
                <th>Qtd.</th>
                <th>Preço Unit.</th>
                <th>Total</th>
                <th>Data</th>
                <th>Estado</th>
                <th>Ações</th>
            </tr>
        </thead>

        <tbody>

        <%
            try {
                String sql =
                    "SELECT e.id, e.codigo_validacao, e.data_encomenda, e.estado, e.total, " +
                    "u.nome AS cliente, p.nome AS produto, ep.quantidade, ep.preco_unitario " +
                    "FROM encomendas e " +
                    "INNER JOIN utilizadores u ON e.cliente_id = u.id " +
                    "INNER JOIN encomenda_produtos ep ON e.id = ep.encomenda_id " +
                    "INNER JOIN produtos p ON ep.produto_id = p.id " +
                    "ORDER BY e.data_encomenda DESC";

                ps = conn.prepareStatement(sql);
                rs = ps.executeQuery();

                boolean temEncomendas = false;

                while (rs.next()) {
                    temEncomendas = true;

                    int id = rs.getInt("id");
                    String codigo = rs.getString("codigo_validacao");
                    String cliente = rs.getString("cliente");
                    String produto = rs.getString("produto");
                    int quantidade = rs.getInt("quantidade");
                    double precoUnitario = rs.getDouble("preco_unitario");
                    double total = rs.getDouble("total");
                    String data = rs.getString("data_encomenda");
                    String estado = rs.getString("estado");
        %>

            <tr>
                <td><%= id %></td>
                <td><%= codigo %></td>
                <td><%= cliente %></td>
                <td><%= produto %></td>
                <td><%= quantidade %></td>
                <td><%= String.format("%.2f", precoUnitario) %> €</td>
                <td><%= String.format("%.2f", total) %> €</td>
                <td><%= data %></td>

                <td>
                    <% if (estado.equals("pendente")) { %>
                        <span class="badge badge-pendente">Pendente</span>
                    <% } else if (estado.equals("validada")) { %>
                        <span class="badge badge-validada">Validada</span>
                    <% } else if (estado.equals("entregue")) { %>
                        <span class="badge badge-entregue">Entregue</span>
                    <% } else if (estado.equals("cancelada")) { %>
                        <span class="badge badge-cancelada">Cancelada</span>
                    <% } else { %>
                        <span class="badge"><%= estado %></span>
                    <% } %>
                </td>

                <td>
                    <% if (estado.equals("pendente")) { %>

                        <a class="btn-pequeno"
                           href="func_encomendas.jsp?acao=validar&id=<%= id %>"
                           onclick="return confirm('Deseja validar esta encomenda?');">
                            Validar
                        </a>

                    <% } else if (estado.equals("validada")) { %>

                        <a class="btn-pequeno"
                           href="func_encomendas.jsp?acao=entregar&id=<%= id %>"
                           onclick="return confirm('Deseja marcar esta encomenda como entregue?');">
                            Entregar
                        </a>

                    <% } else { %>

                        <span class="sem-acao">Sem ações</span>

                    <% } %>
                </td>
            </tr>

        <%
                }

                if (!temEncomendas) {
        %>

            <tr>
                <td colspan="10" class="sem-dados">Ainda não existem encomendas registadas.</td>
            </tr>

        <%
                }

            } catch (Exception e) {
                e.printStackTrace();
        %>

            <tr>
                <td colspan="10" class="sem-dados">Erro ao carregar encomendas.</td>
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
        <p><a href="dashboard_funcionario.jsp">Voltar à área do funcionário</a></p>
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>

</div>

</body>
</html>