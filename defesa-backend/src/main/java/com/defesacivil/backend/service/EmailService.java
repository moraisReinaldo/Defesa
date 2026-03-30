package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Usuario;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Async;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @Async
    public void enviarEmailAprovacaoAdmin(Usuario admin) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo("reinaldoinfra07@gmail.com");
        message.setSubject("Aprovação de Novo Administrador: " + admin.getCidade());
        message.setText("Olá,\n\n" +
                "Um novo usuário solicitou acesso como ADMINISTRADOR.\n\n" +
                "Nome: " + admin.getNome() + "\n" +
                "E-mail: " + admin.getEmail() + "\n" +
                "Cidade: " + admin.getCidade() + "\n\n" +
                "Acesse o sistema para aprovar ou rejeitar a solicitação.\n\n" +
                "Atenciosamente,\n" +
                "Equipe Defesa Civil");
        
        // Em um ambiente sem internet ou credenciais corretas, isso pode falhar.
        // É recomendável prever um try/catch em producão ou log.
        try {
            mailSender.send(message);
            System.out.println("E-mail de aprovação enviado com sucesso para reinaldoinfra07@gmail.com!");
        } catch(Exception e) {
            System.err.println("Falha ao enviar e-mail. Verifique as configurações de SMTP no application.properties.");
            e.printStackTrace();
        }
    }
}
