package com.defesacivil.backend.config;

import com.defesacivil.backend.security.JwtAuthenticationFilter;
import com.defesacivil.backend.security.RateLimitingFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.beans.factory.annotation.Value;

import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;
    private final RateLimitingFilter rateLimitingFilter;

    @Value("${spring.web.cors.allowed-origin-patterns:http://localhost:3000,http://localhost:8080,http://localhost:5173,https://localhost:3000,https://localhost:8080,https://localhost:5173,http://127.0.0.1:3000,http://127.0.0.1:8080,http://127.0.0.1:5173}")
    private String allowedOrigins;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthFilter, RateLimitingFilter rateLimitingFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
        this.rateLimitingFilter = rateLimitingFilter;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable()) // API Stateless — CSRF não se aplica
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // ===== ROTAS PÚBLICAS (sem token) =====
                .requestMatchers("/", "/api/health", "/actuator/health").permitAll()
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/usuarios/login").permitAll()
                .requestMatchers("/api/usuarios/esqueci-senha").permitAll()
                .requestMatchers("/api/usuarios/resetar-senha").permitAll()
                .requestMatchers("/api/cidades").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/alertas").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/alertas/*").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/ocorrencias").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/ocorrencias/*").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/marcacoes").permitAll()
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                // ===== REGISTRO DE OCORRÊNCIA (Público) =====
                .requestMatchers(HttpMethod.POST, "/api/ocorrencias").permitAll()

                // ===== ROTAS DE ADMINISTRADOR =====
                .requestMatchers(HttpMethod.GET, "/api/usuarios").hasRole("ADMINISTRADOR")
                .requestMatchers("/api/usuarios/pendentes", "/api/usuarios/*/aprovar", "/api/usuarios/promover").hasRole("ADMINISTRADOR")
                .requestMatchers(HttpMethod.DELETE, "/api/ocorrencias/**").hasRole("ADMINISTRADOR")
                .requestMatchers(HttpMethod.DELETE, "/api/marcacoes/**").hasRole("ADMINISTRADOR")
                // Excluir própria conta — qualquer autenticado (ANTES da regra admin wildcard)
                .requestMatchers(HttpMethod.DELETE, "/api/usuarios/minha-conta").authenticated()
                .requestMatchers(HttpMethod.DELETE, "/api/usuarios/**").hasRole("ADMINISTRADOR")

                // ===== ROTAS DE AGENTE E ADMINISTRADOR =====
                .requestMatchers(HttpMethod.POST, "/api/ocorrencias/*/aprovar").hasAnyRole("ADMINISTRADOR", "AGENTE")
                .requestMatchers(HttpMethod.POST, "/api/ocorrencias/*/chegada").hasAnyRole("AGENTE", "ADMINISTRADOR")
                .requestMatchers(HttpMethod.POST, "/api/ocorrencias/*/resolver").hasAnyRole("AGENTE", "ADMINISTRADOR")
                .requestMatchers(HttpMethod.POST, "/api/ocorrencias/*/reativar").hasAnyRole("AGENTE", "ADMINISTRADOR")
                .requestMatchers(HttpMethod.PATCH, "/api/ocorrencias/**").authenticated()
                .requestMatchers(HttpMethod.POST, "/api/marcacoes").hasAnyRole("ADMINISTRADOR", "AGENTE")
                .requestMatchers(HttpMethod.PUT, "/api/marcacoes/**").hasAnyRole("ADMINISTRADOR", "AGENTE")
                .requestMatchers(HttpMethod.POST, "/api/alertas").hasAnyRole("ADMINISTRADOR", "AGENTE")
                .requestMatchers(HttpMethod.DELETE, "/api/alertas/**").hasAnyRole("ADMINISTRADOR", "AGENTE")
                .requestMatchers("/api/usuarios/agentes").hasAnyRole("AGENTE", "ADMINISTRADOR")

                // ===== DEMAIS ROTAS (Perfil, Edição, etc.) =====
                .anyRequest().authenticated()
            )
            .addFilterBefore(rateLimitingFilter, UsernamePasswordAuthenticationFilter.class)
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        List<String> origins = List.of(allowedOrigins.split(",")).stream()
            .map(String::trim)
            .filter(origin -> !origin.isEmpty())
            .toList();

        if (!origins.isEmpty()) {
            configuration.setAllowedOriginPatterns(origins);
        } else {
            configuration.setAllowedOriginPatterns(List.of(
                "http://localhost:3000",
                "http://localhost:8080",
                "http://localhost:5173",
                "https://localhost:3000",
                "https://localhost:8080",
                "https://localhost:5173",
                "http://127.0.0.1:3000",
                "http://127.0.0.1:8080",
                "http://127.0.0.1:5173"
            ));
        }

        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(false);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
