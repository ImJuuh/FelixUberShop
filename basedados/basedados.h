<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>

<%!
    /*
     * Função para ligar à base de dados FelixUberShop.
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

    /*
     * Função para gerar hash SHA-256 da palavra-passe.
     * Assim a password não fica guardada em texto normal na base de dados.
     */
    public String gerarHash(String password) {
        String hash = "";

        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] bytes = md.digest(password.getBytes("UTF-8"));

            StringBuilder sb = new StringBuilder();

            for (int i = 0; i < bytes.length; i++) {
                sb.append(String.format("%02x", bytes[i]));
            }

            hash = sb.toString();

        } catch (Exception e) {
            e.printStackTrace();
        }

        return hash;
    }
%>