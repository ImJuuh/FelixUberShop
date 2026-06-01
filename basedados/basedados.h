<%@ page import="java.sql.*" %>

<%!
    /*
     * Função responsável por criar a ligação à base de dados MySQL.
     * Todas as páginas da aplicação devem usar esta função para aceder à BD.
     */
    public Connection ligarBD() {
        Connection conn = null;

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/felixubershop?useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC",
                "root",
                ""
            );

        } catch (ClassNotFoundException e) {
            System.out.println("ERRO: Driver MySQL não encontrado.");
            e.printStackTrace();

        } catch (SQLException e) {
            System.out.println("ERRO: Não foi possível ligar à base de dados.");
            e.printStackTrace();

        } catch (Exception e) {
            System.out.println("ERRO geral na ligação à base de dados.");
            e.printStackTrace();
        }

        return conn;
    }
%>