package com.defesacivil.backend.security;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.function.Function;

@Service
public class JwtService {

    @Value("${app.jwt.secret:}")
    private String secret;

    private SecretKey signingKey;

    // Redução da expiração de 30 para 7 dias (equilíbrio entre segurança e usabilidade no mobile)
    private static final long EXPIRATION_TIME = 1000L * 60 * 60 * 24 * 7; // 7 dias

    // Blacklist em memória de tokens revogados com TTL de 7 dias
    private final Cache<String, Boolean> revokedTokens = Caffeine.newBuilder()
            .expireAfterWrite(7, TimeUnit.DAYS)
            .maximumSize(50000)
            .build();

    public void revokeToken(String token) {
        if (token != null && !token.isBlank()) {
            revokedTokens.put(token, true);
        }
    }

    public boolean isTokenRevoked(String token) {
        return token != null && Boolean.TRUE.equals(revokedTokens.getIfPresent(token));
    }

    @PostConstruct
    public void init() {
        if (secret == null || secret.isBlank() || secret.length() < 32) {
            throw new IllegalStateException("app.jwt.secret deve conter pelo menos 32 caracteres e ser configurado via variável de ambiente.");
        }
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String generateToken(String email, String role) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", role);
        return createToken(claims, email);
    }

    private String createToken(Map<String, Object> claims, String subject) {
        return Jwts.builder()
                .claims(claims)
                .subject(subject)
                .issuedAt(new Date(System.currentTimeMillis()))
                .expiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(signingKey)
                .compact();
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public String extractRole(String token) {
        return (String) extractAllClaims(token).get("role");
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public boolean isTokenValid(String token, String userEmail) {
        if (isTokenRevoked(token)) {
            return false;
        }
        final String username = extractUsername(token);
        return (username.equals(userEmail) && !isTokenExpired(token));
    }

    private boolean isTokenExpired(String token) {
        return extractClaim(token, Claims::getExpiration).before(new Date());
    }
}
