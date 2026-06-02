<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    /*
     * Página de administração de promoções/informações dinâmicas.
     * Permite ao administrador inserir, editar, visualizar, inativar e reativar promoções.
     */

    String perfil = (String) session.getAttribute("perfil");
    String nomeSessao = (String) session.getAttribute("nome");

    if (perfil == null || !perfil.equals("admin")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String erro = "";
    String sucesso = "";

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String acao = request.getParameter("acao");

    String editId = "";
    String editTitulo = "";
    String editDescricao = "";
    String editDataInicio = "";
    String editDataFim = "";

    try {
        conn = ligarBD();

        /*
         * Inativar promoção.
         */
        if ("inativar".equals(acao)) {
            String id = request.getParameter("id");

            String sql = "UPDATE promocoes SET ativo = FALSE WHERE id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(id));
            ps.executeUpdate();
            ps.close();

            sucesso = "Promoção inativada com sucesso.";
        }

        /*
         * Reativar promoção.
         */
        if ("reativar".equals(acao)) {
            String id = request.getParameter("id");

            String sql = "UPDATE promocoes SET ativo = TRUE WHERE id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(id));
            ps.executeUpdate();
            ps.close();

            sucesso = "Promoção reativada com sucesso.";
        }

        /*
         * Carregar promoção para edição.
         */
        if ("editar".equals(acao)) {
            String id = request.getParameter("id");

            String sql = "SELECT * FROM promocoes WHERE id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(id));
            rs = ps.executeQuery();

            if (rs.next()) {
                editId = rs.getString("id");
                editTitulo = rs.getString("titulo");
                editDescricao = rs.getString("descricao");
                editDataInicio = rs.getString("data_inicio");
                editDataFim = rs.getString("data_fim");
            }

            rs.close();
            ps.close();
        }

        /*
         * Inserir ou atualizar promoção.
         */
        if (request.getMethod().equalsIgnoreCase("POST")) {

            String idPromocao = request.getParameter("id_promocao");
            String titulo = request.getParameter("titulo");
            String descricao = request.getParameter("descricao");
            String dataInicio = request.getParameter("data_inicio");
            String dataFim = request.getParameter("data_fim");

            if (titulo == null || titulo.trim().isEmpty() ||
                descricao == null || descricao.trim().isEmpty()) {

                erro = "Preencha o título e a descrição.";

            } else {

                /*
                 * Atualizar promoção existente.
                 */
                if (idPromocao != null && !idPromocao.trim().isEmpty()) {

                    String sql =
                        "UPDATE promocoes SET titulo = ?, descricao = ?, data_inicio = ?, data_fim = ? " +
                        "WHERE id = ?";

                    ps = conn.prepareStatement(sql);
                    ps.setString(1, titulo);
                    ps.setString(2, descricao);

                    if (dataInicio == null || dataInicio.trim().isEmpty()) {
                        ps.setNull(3, java.sql.Types.DATE);
                    } else {
                        ps.setString(3, dataInicio);
                    }

                    if (dataFim == null || dataFim.trim().isEmpty()) {
                        ps.setNull(4, java.sql.Types.DATE);
                    } else {
                        ps.setString(4, dataFim);
                    }

                    ps.setInt(5, Integer.parseInt(idPromocao));

                    ps.executeUpdate();
                    ps.close();

                    sucesso = "Promoção atualizada com sucesso.";

                    editId = "";
                    editTitulo = "";
                    editDescricao = "";
                    editDataInicio = "";
                    editDataFim = "";

                } else {

                    /*
                     * Inserir nova promoção.
                     */
                    String sql =
                        "INSERT INTO promocoes (titulo, descricao, data_inicio, data_fim, ativo) " +
                        "VALUES (?, ?, ?, ?, TRUE)";

                    ps = conn.prepareStatement(sql);
                    ps.setString(1, titulo);
                    ps.setString(2, descricao);

                    if (dataInicio == null || dataInicio.trim().isEmpty()) {
                        ps.setNull(3, java.sql.Types.DATE);
                    } else {
                        ps.setString(3, dataInicio);
                    }

                    if (dataFim == null || dataFim.trim().isEmpty()) {
                        ps.setNull(4, java.sql.Types.DATE);
                    } else {
                        ps.setString(4, dataFim);
                    }

                    ps.executeUpdate();
                    ps.close();

                    sucesso = "Promoção inserida com sucesso.";
                }
            }
        }

    } catch (Exception e) {
        erro = "Erro ao gerir promoções.";
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Gestão de Promoções - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Gestão de Promoções</h1>
        <p>Olá, <%= nomeSessao %>. Aqui pode gerir promoções e informações dinâmicas.</p>
    </div>

    <% if (!erro.equals("")) { %>
        <div class="erro"><%= erro %></div>
    <% } %>

    <% if (!sucesso.equals("")) { %>
        <div class="sucesso"><%= sucesso %></div>
    <% } %>

    <div class="form-admin-box">

        <% if (!editId.equals("")) { %>
            <h2>Editar Promoção</h2>
        <% } else { %>
            <h2>Inserir Nova Promoção</h2>
        <% } %>

        <form method="post" action="admin_promocoes.jsp">

            <input type="hidden" name="id_promocao" value="<%= editId %>">

            <div class="form-group">
                <label for="titulo">Título *</label>
                <input type="text" id="titulo" name="titulo" value="<%= editTitulo %>" placeholder="Ex: Promoção da semana">
            </div>

            <div class="form-group">
                <label for="descricao">Descrição *</label>
                <textarea id="descricao" name="descricao" rows="4" placeholder="Descrição da promoção"><%= editDescricao %></textarea>
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label for="data_inicio">Data de início</label>
                    <input type="date" id="data_inicio" name="data_inicio" value="<%= editDataInicio %>">
                </div>

                <div class="form-group">
                    <label for="data_fim">Data de fim</label>
                    <input type="date" id="data_fim" name="data_fim" value="<%= editDataFim %>">
                </div>
            </div>

            <% if (!editId.equals("")) { %>
                <input type="submit" value="Guardar Alterações">

                <div class="links">
                    <p><a href="admin_promocoes.jsp">Cancelar edição</a></p>
                </div>
            <% } else { %>
                <input type="submit" value="Inserir Promoção">
            <% } %>

        </form>
    </div>

    <h2>Lista de Promoções</h2>

    <table class="tabela">
        <thead>
            <tr>
                <th>ID</th>
                <th>Título</th>
                <th>Descrição</th>
                <th>Início</th>
                <th>Fim</th>
                <th>Estado</th>
                <th>Ações</th>
            </tr>
        </thead>

        <tbody>

        <%
            try {
                String sqlLista = "SELECT * FROM promocoes ORDER BY id DESC";
                ps = conn.prepareStatement(sqlLista);
                rs = ps.executeQuery();

                boolean temPromocoes = false;

                while (rs.next()) {
                    temPromocoes = true;

                    int id = rs.getInt("id");
                    String titulo = rs.getString("titulo");
                    String descricao = rs.getString("descricao");
                    String dataInicio = rs.getString("data_inicio");
                    String dataFim = rs.getString("data_fim");
                    boolean ativo = rs.getBoolean("ativo");
        %>

            <tr>
                <td><%= id %></td>
                <td><%= titulo %></td>
                <td><%= descricao %></td>
                <td><%= dataInicio != null ? dataInicio : "-" %></td>
                <td><%= dataFim != null ? dataFim : "-" %></td>
                <td>
                    <% if (ativo) { %>
                        <span class="badge">Ativa</span>
                    <% } else { %>
                        <span class="badge badge-inativo">Inativa</span>
                    <% } %>
                </td>
                <td>
                    <a class="btn-pequeno" href="admin_promocoes.jsp?acao=editar&id=<%= id %>">Editar</a>

                    <% if (ativo) { %>
                        <a class="btn-pequeno danger"
                           href="admin_promocoes.jsp?acao=inativar&id=<%= id %>"
                           onclick="return confirm('Tem a certeza que deseja inativar esta promoção?');">
                            Inativar
                        </a>
                    <% } else { %>
                        <a class="btn-pequeno"
                           href="admin_promocoes.jsp?acao=reativar&id=<%= id %>"
                           onclick="return confirm('Tem a certeza que deseja reativar esta promoção?');">
                            Reativar
                        </a>
                    <% } %>
                </td>
            </tr>

        <%
                }

                if (!temPromocoes) {
        %>

            <tr>
                <td colspan="7" class="sem-dados">Não existem promoções registadas.</td>
            </tr>

        <%
                }

            } catch (Exception e) {
                e.printStackTrace();
        %>

            <tr>
                <td colspan="7" class="sem-dados">Erro ao carregar promoções.</td>
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
        <p><a href="dashboard_admin.jsp">Voltar à administração</a></p>
        <p><a href="index.jsp">Ver página inicial</a></p>
        <p><a href="logout.jsp">Terminar sessão</a></p>
    </div>

</div>

</body>
</html>