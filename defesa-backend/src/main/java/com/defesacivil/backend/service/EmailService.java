package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Usuario;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Async;
import org.springframework.beans.factory.annotation.Value;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;

    @Value("${app.admin.notification.email}")
    private String adminNotificationEmail;

    @Value("${spring.mail.username:noreply@defesacivil.gov.br}")
    private String mailFrom;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Async
    public void enviarEmailAprovacaoAdmin(Usuario admin) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(adminNotificationEmail);
        message.setSubject("Aprovação de Novo Administrador: " + admin.getCidade());
        message.setText("Olá,\n\n" +
                "Um novo usuário solicitou acesso como ADMINISTRADOR.\n\n" +
                "Nome: " + admin.getNome() + "\n" +
                "E-mail: " + admin.getEmail() + "\n" +
                "Cidade: " + admin.getCidade() + "\n\n" +
                "Acesse o sistema para aprovar a solicitação.\n\n" +
                "Atenciosamente,\n" +
                "Equipe Defesa Civil");
        
        try {
            message.setFrom(mailFrom);
            mailSender.send(message);
            log.info("E-mail de aprovação enviado com sucesso para: {}", adminNotificationEmail);
        } catch(Exception e) {
            log.error("Falha ao enviar e-mail. Verifique as configurações de SMTP.", e);
        }
    }
    @Async
    public void enviarEmailRecuperacaoSenha(String email, String codigo) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(email);
        message.setSubject("Código de Recuperação: Defesa Civil");
        message.setText("Olá,\n\n" +
                "Você solicitou a recuperação de senha no app Defesa Civil.\n\n" +
                "Seu código de acesso é: " + codigo + "\n\n" +
                "Este código expira em 15 minutos.\n\n" +
                "Se você não solicitou isso, ignore este e-mail.\n\n" +
                "Atenciosamente,\n" +
                "Equipe Defesa Civil");
        
        try {
            message.setFrom(mailFrom);
            mailSender.send(message);
            log.info("E-mail de recuperação enviado para: {}", email);
        } catch(Exception e) {
            log.error("Falha ao enviar e-mail de recuperação.", e);
        }
    }
}
