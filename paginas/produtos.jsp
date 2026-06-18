<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="../basedados/basedados.h" %>

<%
    String perfil = (String) session.getAttribute("perfil");
    String nomeSessao = (String) session.getAttribute("nome");

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String erro = "";

    // 1. PEGAR OS PARÂMETROS DA PESQUISA E FILTRO
    String pesquisa = request.getParameter("pesquisa");
    String catSelecionada = request.getParameter("categoria_filtro");

    if (pesquisa == null) pesquisa = "";
    if (catSelecionada == null) catSelecionada = "";

    // --- LOGICA DA PAGINAÇÃO ---
    int produtosPorPagina = 6; // Máximo de 6 quadradinhos por página
    int paginaAtual = 1;
    
    // Se o utilizador mudou de página, apanha a página nova pela URL
    String paramPagina = request.getParameter("pagina");
    if (paramPagina != null && !paramPagina.isEmpty()) {
        paginaAtual = Integer.parseInt(paramPagina);
    }
    
    // O OFFSET diz ao SQL a partir de qual registo ele deve começar a ler
    int offset = (paginaAtual - 1) * produtosPorPagina;
    int totalProdutos = 0;
    int totalPaginas = 1;
%>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>Produtos - FelixUberShop</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="style.css">

    <style>
        .container-produtos {
            max-width: 1000px !important;
            width: 95% !important;
            margin: 30px auto;
            padding: 20px;
            font-family: sans-serif;
        }

        .topo-produtos { text-align: center; margin-bottom: 30px; }

        .seccao-pesquisa {
            background: #f5f5f5; padding: 15px; border-radius: 8px;
            margin-bottom: 30px; display: flex; justify-content: center; gap: 10px; flex-wrap: wrap;
        }
        .seccao-pesquisa input[type="text"], .seccao-pesquisa select {
            padding: 8px 12px; border: 1px solid #ccc; border-radius: 4px; font-size: 14px; min-width: 180px;
        }
        .seccao-pesquisa input[type="submit"] {
            padding: 8px 18px; background: #2e7d32; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;
        }
        .seccao-pesquisa .btn-limpar {
            padding: 8px 14px; background: #777; color: white; text-decoration: none; border-radius: 4px; font-size: 14px; line-height: 20px;
        }

        .grelha-produtos {
            display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 25px; margin-bottom: 40px;
        }

        .produto-card {
            background: #ffffff; border: 1px solid #e1e1e1; border-radius: 12px; padding: 20px;
            display: flex; flex-direction: column; justify-content: space-between;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05); transition: transform 0.2s, box-shadow 0.2s;
        }
        .produto-card:hover { transform: translateY(-5px); box-shadow: 0 8px 15px rgba(0, 0, 0, 0.1); }

        .categoria {
            align-self: flex-start; background: #e3f2fd; color: #0d47a1; padding: 4px 10px; font-size: 11px; font-weight: bold; text-transform: uppercase; border-radius: 20px; margin-bottom: 12px;
        }

        .produto-card h3 { margin: 0 0 10px 0; font-size: 18px; color: #333; }
        .descricao { color: #777; font-size: 14px; margin: 0 0 15px 0; flex-grow: 1; }
        .preco { font-size: 20px; font-weight: bold; color: #2e7d32; margin: 0 0 8px 0; }
        .stock { font-size: 13px; color: #666; margin: 0; border-top: 1px solid #f0f0f0; padding-top: 8px; }
        .sem-stock { color: #d32f2f !important; font-weight: bold; }

        /* --- BOTÕES DA PAGINAÇÃO --- */
        .paginacao {
            display: flex; justify-content: center; gap: 8px; margin: 30px 0 40px 0;
        }
        .paginacao a {
            padding: 8px 14px; border: 1px solid #ccc; text-decoration: none; color: #333; border-radius: 4px; font-weight: bold;
        }
        .paginacao a.ativa {
            background: #2e7d32; color: white; border-color: #2e7d32;
        }
        .paginacao a:hover:not(.ativa) { background: #eee; }

        .nav-links { text-align: center; border-top: 1px solid #eee; padding-top: 25px; }
        .nav-links a { display: inline-block; margin: 5px 15px; text-decoration: none; color: #0288d1; font-weight: bold; }
        .sem-produtos, .erro { grid-column: 1 / -1; text-align: center; padding: 30px; color: #666; }
    </style>
</head>
<body>

<div class="container-produtos">

    <div class="topo-produtos">
        <h1>Produtos da FelixUberShop</h1>
        <% if (perfil != null) { %>
            <p>Olá, <strong><%= nomeSessao %></strong>. Encontre o que procura abaixo.</p>
        <% } else { %>
            <p>Consulte os produtos disponíveis na nossa mercearia.</p>
        <% } %>
    </div>

    <form method="get" action="produtos.jsp" class="seccao-pesquisa">
        <input type="text" name="pesquisa" placeholder="Pesquisar por nome..." value="<%= pesquisa %>">
        
        <select name="categoria_filtro">
            <option value="">-- Todas as Categorias --</option>
            <option value="Mercearia" <%= catSelecionada.equals("Mercearia") ? "selected" : "" %>>Mercearia</option>
            <option value="Bebidas" <%= catSelecionada.equals("Bebidas") ? "selected" : "" %>>Bebidas</option>
            <option value="Talho" <%= catSelecionada.equals("Talho") ? "selected" : "" %>>Talho</option>
            <option value="Peixaria" <%= catSelecionada.equals("Peixaria") ? "selected" : "" %>>Peixaria</option>
            <option value="Hortícolas" <%= catSelecionada.equals("Hortícolas") ? "selected" : "" %>>Hortícolas/Fruta</option>
        </select>

        <input type="submit" value="Procurar">
        
        <% if (!pesquisa.isEmpty() || !catSelecionada.isEmpty()) { %>
            <a href="produtos.jsp" class="btn-limpar">Limpar</a>
        <% } %>
    </form>

    <%
        try {
            conn = ligarBD();

            // 2. PRIMEIRO CONTAMOS QUANTOS PRODUTOS EXISTEM NO TOTAL (Para saber quantas páginas criar)
            String sqlCount = "SELECT COUNT(*) FROM produtos WHERE ativo = TRUE";
            if (!pesquisa.trim().isEmpty()) sqlCount += " AND nome LIKE ?";
            if (!catSelecionada.isEmpty()) sqlCount += " AND categoria = ?";
            
            ps = conn.prepareStatement(sqlCount);
            int idx = 1;
            if (!pesquisa.trim().isEmpty()) ps.setString(idx++, "%" + pesquisa + "%");
            if (!catSelecionada.isEmpty()) ps.setString(idx++, catSelecionada);
            
            rs = ps.executeQuery();
            if (rs.next()) {
                totalProdutos = rs.getInt(1);
            }
            rs.close();
            ps.close();

            // Calcula o número total de páginas arredondando para cima
            totalPaginas = (int) Math.ceil((double) totalProdutos / produtosPorPagina);
            if (totalPaginas == 0) totalPaginas = 1;


            // 3. AGORA BUSCAMOS APENAS OS 6 PRODUTOS DA PÁGINA ATUAL
            String sql = "SELECT * FROM produtos WHERE ativo = TRUE";
            if (!pesquisa.trim().isEmpty()) sql += " AND nome LIKE ?";
            if (!catSelecionada.isEmpty()) sql += " AND categoria = ?";
            
            // LIMIT indica a quantidade e OFFSET indica onde começa
            sql += " ORDER BY categoria, nome LIMIT ? OFFSET ?";
            
            ps = conn.prepareStatement(sql);
            idx = 1;
            if (!pesquisa.trim().isEmpty()) ps.setString(idx++, "%" + pesquisa + "%");
            if (!catSelecionada.isEmpty()) ps.setString(idx++, catSelecionada);
            
            ps.setInt(idx++, produtosPorPagina); // LIMIT
            ps.setInt(idx++, offset);            // OFFSET

            rs = ps.executeQuery();
    %>

    <div class="grelha-produtos">

        <%
            boolean temProdutos = false;

            while (rs.next()) {
                temProdutos = true;

                String nome = rs.getString("nome");
                String descricao = rs.getString("descricao");
                String categoria = rs.getString("categoria");
                double preco = rs.getDouble("preco");
                int stock = rs.getInt("stock");
                
                if (descricao == null) descricao = "Sem descrição disponível.";
        %>

            <div class="produto-card">
                <div>
                    <span class="categoria"><%= categoria %></span>
                    <h3><%= nome %></h3>
                    <p class="descricao"><%= descricao %></p>
                </div>
                <div>
                    <p class="preco"><%= String.format("%.2f", preco) %> €</p>
                    <% if (stock > 0) { %>
                        <p class="stock">Stock: <strong><%= stock %></strong> un.</p>
                    <% } else { %>
                        <p class="stock sem-stock">Esgotado</p>
                    <% } %>
                </div>
            </div>

        <%
            }

            if (!temProdutos) {
        %>
            <div class="sem-produtos">
                <p>Nenhum produto encontrado.</p>
            </div>
        <%
            }
        %>

    </div>

    <% if (totalPaginas > 1) { %>
        <div class="paginacao">
            <% for (int i = 1; i <= totalPaginas; i++) { %>
                <a href="produtos.jsp?pagina=<%= i %>&pesquisa=<%= pesquisa %>&categoria_filtro=<%= catSelecionada %>" 
                   class="<%= (i == paginaAtual) ? "ativa" : "" %>">
                    <%= i %>
                </a>
            <% } %>
        </div>
    <% } %>

    <%
        } catch (Exception e) {
            erro = "Erro ao carregar os produtos.";
    %>
        <div class="erro" style="color: red; font-weight: bold;"><%= erro %></div>
    <%
        } finally {
            try {
                if (rs != null) rs.close();
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            } catch (Exception e) {}
        }
    %>

    <div class="nav-links">
        <% if (perfil == null) { %>
            <a href="index.jsp">← Voltar ao Início</a>
            <a href="login.jsp">Fazer Login</a>
        <% } else if (perfil.equals("cliente")) { %>
            <a href="dashboard_cliente.jsp">← Área do Cliente</a>
            <a href="nova_encomenda.jsp" style="color: #2e7d32;">🛒 Fazer Encomenda</a>
        <% } else if (perfil.equals("funcionario")) { %>
            <a href="dashboard_funcionario.jsp">← Área do Funcionário</a>
        <% } else if (perfil.equals("admin")) { %>
            <a href="dashboard_admin.jsp">← Administração</a>
            <a href="admin_produtos.jsp">⚙️ Gerir Produtos</a>
        <% } %>
    </div>

</div>

</body>
</html>