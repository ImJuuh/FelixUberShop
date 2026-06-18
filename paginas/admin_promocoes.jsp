<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    /*
     * Página de administração de promoções/informações dinâmicas.
     * Permite ao administrador inserir, editar, visualizar, inativar e reativar promoções com paginação.
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

    // --- CONFIGURAÇÃO DA PAGINAÇÃO ---
    int itensPorPagina = 5; 
    int paginaAtual = 1;
    String paramPag = request.getParameter("pag");
    if (paramPag != null && !paramPag.isEmpty()) {
        paginaAtual = Integer.parseInt(paramPag);
    }
    int offset = (paginaAtual - 1) * itensPorPagina;
    int totalPromocoes = 0;
    int totalPaginas = 1;

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

                    editId = ""; editTitulo = ""; editDescricao = ""; editDataInicio = ""; editDataFim = "";

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

    <style>
        .container-tabela {
            max-width: 1000px !important;
            width: 95% !important;
            margin: 30px auto;
            padding: 25px;
            font-family: sans-serif;
        }

        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { margin: 0 0 5px 0; }
        .header p { margin: 0; color: #666; }

        h2 { margin: 35px 0 15px 0; padding-bottom: 8px; border-bottom: 2px solid #eee; color: #333; }

        /* --- CAIXA DO FORMULÁRIO --- */
        .form-admin-box {
            background: #f9f9f9; padding: 20px; border-radius: 8px; border: 1px solid #e3e3e3; margin-bottom: 20px;
        }
        .form-admin-box h2 { margin-top: 0; border: none; padding: 0; }

        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-top: 15px; }
        
        .form-group input[type="text"], .form-group textarea, .form-group input[type="date"] {
            width: 100%; padding: 10px; box-sizing: border-box; border: 1px solid #ccc; border-radius: 4px; margin-top: 5px; font-family: sans-serif;
        }
        
        input[type="submit"] {
            width: 100%; padding: 12px; background: #0288d1; color: white; border: none; border-radius: 4px; font-weight: bold; cursor: pointer; margin-top: 15px;
        }
        input[type="submit"]:hover { background: #01579b; }

        /* Estilo específico para tornar o botão de inserir verde */
        .btn-inserir-verde {
            background: #4caf50 !important;
        }
        .btn-inserir-verde:hover {
            background: #388e3c !important;
        }

        /* --- DESIGN DA TABELA --- */
        .tabela { width: 100%; border-collapse: collapse; margin-bottom: 15px; background: #fff; }
        .tabela th, .tabela td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; vertical-align: middle; }
        .tabela th { background: #f4f4f4; color: #333; font-weight: bold; }
        .tabela tr:hover { background: #fdfdfd; }

        .badge {
            display: inline-block; background: #e8f5e9; color: #2e7d32; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: bold;
        }
        .badge-inativo { background: #ffebee; color: #c62828; }

        /* --- CORREÇÃO DOS BOTÕES EM LINHA (FLEXBOX) --- */
        .acoes-flex {
            display: flex;
            gap: 6px;
            align-items: center;
            flex-wrap: nowrap;
        }

        .btn-pequeno {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 6px 12px;
            background: #0288d1;
            color: white !important;
            text-decoration: none;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
            white-space: nowrap;
            transition: background 0.2s ease;
        }
        .btn-pequeno:hover { background: #01579b; }
        .btn-pequeno.danger { background: #e53935; }
        .btn-pequeno.danger:hover { background: #b71c1c; }
        .btn-pequeno.success { background: #4caf50; }
        .btn-pequeno.success:hover { background: #388e3c; }

        /* --- PAGINAÇÃO --- */
        .paginacao { display: flex; justify-content: center; gap: 5px; margin: 15px 0 30px 0; }
        .paginacao a { padding: 6px 12px; border: 1px solid #ddd; text-decoration: none; color: #333; border-radius: 4px; font-size: 13px; }
        .paginacao a.ativa { background: #0288d1; color: white; border-color: #0288d1; }
        .paginacao a:hover:not(.ativa) { background: #eee; }

        .links { text-align: center; margin-top: 25px; }
        .links a { margin: 0 10px; color: #0288d1; text-decoration: none; font-weight: bold; }
        .sem-dados { text-align: center; color: #888; font-style: italic; }
    </style>
</head>
<body>

<div class="container-tabela">

    <div class="header">
        <h1>Gestão de Promoções</h1>
        <p>Olá, <strong><%= nomeSessao %></strong>. Painel administrativo para controlar anúncios e destaques.</p>
    </div>

    <% if (!erro.equals("")) { %> <div class="erro"><%= erro %></div> <% } %>
    <% if (!sucesso.equals("")) { %> <div class="sucesso"><%= sucesso %></div> <% } %>

    <div class="form-admin-box">
        <% if (!editId.equals("")) { %>
            <h2>Editar Promoção</h2>
        <% } else { %>
            <h2>Inserir Nova Promoção</h2>
        <% } %>

        <form method="post" action="admin_promocoes.jsp?pag=<%= paginaAtual %>">
            <input type="hidden" name="id_promocao" value="<%= editId %>">

            <div class="form-group">
                <label for="titulo">Título *</label>
                <input type="text" id="titulo" name="titulo" value="<%= editTitulo %>" placeholder="Ex: Campanha de Portes Grátis" required>
            </div>

            <div class="form-group" style="margin-top: 15px;">
                <label for="descricao">Descrição *</label>
                <textarea id="descricao" name="descricao" rows="3" placeholder="Insira o texto completo da promoção..." required><%= editDescricao %></textarea>
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
                <input type="submit" value="💥 Guardar Alterações" style="background: #2e7d32;">
                <div class="links" style="margin-top: 10px;">
                    <a href="admin_promocoes.jsp?pag=<%= paginaAtual %>" style="color: #666; font-size: 14px;">Cancelar Edição</a>
                </div>
            <% } else { %>
                <input type="submit" value="🚀 Inserir Promoção" class="btn-inserir-verde">
            <% } %>
        </form>
    </div>

    <h2>Lista de Promoções</h2>

    <%
        try {
            if (conn == null || conn.isClosed()) {
                conn = ligarBD();
            }

            String sqlCount = "SELECT COUNT(*) FROM promocoes";
            ps = conn.prepareStatement(sqlCount);
            rs = ps.executeQuery();
            if (rs.next()) {
                totalPromocoes = rs.getInt(1);
            }
            rs.close(); ps.close();

            totalPaginas = (int) Math.ceil((double) totalPromocoes / itensPorPagina);

            String sqlLista = "SELECT id, titulo, descricao, data_inicio, data_fim, ativo FROM promocoes ORDER BY id DESC LIMIT ? OFFSET ?";
            ps = conn.prepareStatement(sqlLista);
            ps.setInt(1, itensPorPagina);
            ps.setInt(2, offset);
            rs = ps.executeQuery();
    %>

    <table class="tabela">
        <thead>
            <tr>
                <th style="width: 22%;">Título</th>
                <th style="width: 33%;">Descrição</th>
                <th style="width: 12%;">Início</th>
                <th style="width: 12%;">Fim</th>
                <th style="width: 10%;">Estado</th>
                <th style="width: 11%;">Ações</th>
            </tr>
        </thead>
        <tbody>
        <%
            boolean temPromocoes = false;
            while (rs.next()) {
                temPromocoes = true;
                int id = rs.getInt("id");
                boolean ativo = rs.getBoolean("ativo");
        %>
            <tr>
                <td><strong><%= rs.getString("titulo") %></strong></td>
                <td style="font-size: 13px; color: #555;"><%= rs.getString("descricao") %></td>
                <td><%= rs.getString("data_inicio") != null ? rs.getString("data_inicio") : "-" %></td>
                <td><%= rs.getString("data_fim") != null ? rs.getString("data_fim") : "-" %></td>
                <td>
                    <span class="badge <%= !ativo ? "badge-inativo" : "" %>">
                        <%= ativo ? "Ativa" : "Inativa" %>
                    </span>
                </td>
                <td>
                    <div class="acoes-flex">
                        <a class="btn-pequeno" href="admin_promocoes.jsp?acao=editar&id=<%= id %>&pag=<%= paginaAtual %>">Editar</a>
                        <% if (ativo) { %>
                            <a class="btn-pequeno danger" href="admin_promocoes.jsp?acao=inativar&id=<%= id %>&pag=<%= paginaAtual %>" onclick="return confirm('Tem a certeza que deseja inativar esta promoção?');">Inativar</a>
                        <% } else { %>
                            <a class="btn-pequeno success" href="admin_promocoes.jsp?acao=reativar&id=<%= id %>&pag=<%= paginaAtual %>" onclick="return confirm('Tem a certeza que deseja reativar esta promoção?');">Reativar</a>
                        <% } %>
                    </div>
                </td>
            </tr>
        <% 
            } 
            if (!temPromocoes) { 
        %>
            <tr>
                <td colspan="6" class="sem-dados">Não existem promoções registadas.</td>
            </tr>
        <% } %>
        </tbody>
    </table>

    <% if (totalPaginas > 1) { %>
        <div class="paginacao">
            <% for (int i = 1; i <= totalPaginas; i++) { %>
                <a href="admin_promocoes.jsp?pag=<%= i %>" class="<%= (i == paginaAtual) ? "ativa" : "" %>"><%= i %></a>
            <% } %>
        </div>
    <% } %>

    <%
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (rs != null) rs.close();
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            } catch (Exception e) {}
        }
    %>

    <div class="links">
        <hr style="border: 0; border-top: 1px solid #eee; margin-bottom: 20px;">
        <a href="dashboard_admin.jsp">← Painel de Administração</a> | 
        <a href="index.jsp" target="_blank">Ver Loja Virtual</a> | 
        <a href="logout.jsp" style="color: #d32f2f;">Terminar Sessão</a>
    </div>

</div>

</body>
</html>