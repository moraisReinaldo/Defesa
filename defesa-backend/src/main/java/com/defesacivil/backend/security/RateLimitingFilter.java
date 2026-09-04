package com.defesacivil.backend.security;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.concurrent.TimeUnit;

@Component
public class RateLimitingFilter extends OncePerRequestFilter {

    private final Cache<String, Bucket> cache = Caffeine.newBuilder()
            .expireAfterAccess(1, TimeUnit.HOURS)
            .maximumSize(10000) // Proteção contra DDoS de IPs únicos massivos
            .build();

    // Cache separado para o endpoint admin-login — limite muito mais restritivo
    private final Cache<String, Bucket> adminLoginCache = Caffeine.newBuilder()
            .expireAfterAccess(30, TimeUnit.MINUTES)
            .maximumSize(5000)
            .build();

    // Cache separado para endpoints de autenticação e reset de senha sensíveis
    private final Cache<String, Bucket> authSensitiveCache = Caffeine.newBuilder()
            .expireAfterAccess(15, TimeUnit.MINUTES)
            .maximumSize(5000)
            .build();

    private Bucket createNewBucket() {
        // Limite de 100 requisições por minuto por IP para requisições comuns
        Bandwidth limit = Bandwidth.builder()
                .capacity(100)
                .refillGreedy(100, Duration.ofMinutes(1))
                .build();
        return Bucket.builder().addLimit(limit).build();
    }

    private Bucket createAdminLoginBucket() {
        // Limite de 5 tentativas a cada 15 minutos por IP — proteção anti brute-force
        Bandwidth limit = Bandwidth.builder()
                .capacity(5)
                .refillGreedy(5, Duration.ofMinutes(15))
                .build();
        return Bucket.builder().addLimit(limit).build();
    }

    private Bucket createAuthSensitiveBucket() {
        // Limite de 15 tentativas por minuto para login e 5 por 10 minutos para reset de senha
        Bandwidth limit = Bandwidth.builder()
                .capacity(15)
                .refillGreedy(15, Duration.ofMinutes(1))
                .build();
        return Bucket.builder().addLimit(limit).build();
    }

    /**
     * Resolve o IP real do cliente prevenindo IP spoofing:
     * Headers como CF-Connecting-IP ou X-Forwarded-For só são aceitos
     * se a requisição vier de um proxy local/reverso confiável (localhost, docker, rede privada).
     */
    private String resolveClientIp(HttpServletRequest request) {
        String remoteAddr = request.getRemoteAddr();
        boolean isTrustedProxy = isPrivateOrLocalAddress(remoteAddr);

        if (isTrustedProxy) {
            String cfIp = request.getHeader("CF-Connecting-IP");
            if (cfIp != null && !cfIp.isBlank()) {
                return cfIp.trim();
            }

            String xff = request.getHeader("X-Forwarded-For");
            if (xff != null && !xff.isBlank()) {
                // O primeiro endereço da lista é o cliente original
                String clientIp = xff.contains(",") ? xff.split(",")[0].trim() : xff.trim();
                if (!clientIp.isBlank()) {
                    return clientIp;
                }
            }
        }

        return (remoteAddr != null && !remoteAddr.isBlank()) ? remoteAddr : "0.0.0.0";
    }

    private boolean isPrivateOrLocalAddress(String ip) {
        if (ip == null || ip.isBlank()) return false;
        return ip.equals("127.0.0.1") ||
               ip.equals("0:0:0:0:0:0:0:1") ||
               ip.startsWith("10.") ||
               ip.startsWith("192.168.") ||
               ip.startsWith("172.16.") ||
               ip.startsWith("172.17.") ||
               ip.startsWith("172.18.") ||
               ip.startsWith("172.19.") ||
               ip.startsWith("172.2") ||
               ip.startsWith("172.30.") ||
               ip.startsWith("172.31.");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String ip = resolveClientIp(request);
        String uri = request.getRequestURI();

        // 1. Rate limiting específico para admin-login (5 req / 15 min)
        if ("/api/auth/admin-login".equals(uri)) {
            Bucket adminBucket = adminLoginCache.get(ip, k -> createAdminLoginBucket());
            if (!adminBucket.tryConsume(1)) {
                sendRateLimitResponse(response, "Muitas tentativas de acesso. Aguarde 15 minutos antes de tentar novamente.");
                return;
            }
        }

        // 2. Rate limiting para login de usuários e esqueci/resetar senha (15 req / 1 min)
        if ("/api/usuarios/login".equals(uri) ||
            "/api/usuarios/esqueci-senha".equals(uri) ||
            "/api/usuarios/resetar-senha".equals(uri)) {
            Bucket sensitiveBucket = authSensitiveCache.get(ip, k -> createAuthSensitiveBucket());
            if (!sensitiveBucket.tryConsume(1)) {
                sendRateLimitResponse(response, "Limite de tentativas de autenticação excedido. Aguarde antes de tentar novamente.");
                return;
            }
        }

        // 3. Rate limiting geral (100 req / min)
        Bucket bucket = cache.get(ip, k -> createNewBucket());

        if (bucket.tryConsume(1)) {
            filterChain.doFilter(request, response);
        } else {
            sendRateLimitResponse(response, "Muitas requisições. Tente novamente mais tarde.");
        }
    }

    private void sendRateLimitResponse(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"message\": \"" + message + "\"}");
    }
}
