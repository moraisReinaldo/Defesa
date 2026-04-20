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

import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;
    private final RateLimitingFilter rateLimitingFilter;

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
                .requestMatchers("/api/cidades").permitAll()

                // Listagem pública de ocorrências e POIs (GET) — serviço filtra internamente por role
                .requestMatchers(HttpMethod.GET, "/api/ocorrencias").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/marcacoes").permitAll()

                // ===== ROTAS DE ADMINISTRADOR =====
                .requestMatchers(HttpMethod.POST,   "/api/marcacoes").hasRole("ADMINISTRADOR")
                .requestMatchers(HttpMethod.DELETE, "/api/marcacoes/{id}").hasRole("ADMINISTRADOR")
                .requestMatchers(HttpMethod.DELETE, "/api/ocorrencias/{id}").hasRole("ADMINISTRADOR")
                .requestMatchers(HttpMethod.DELETE, "/api/usuarios/{id}").hasRole("ADMINISTRADOR")
                .requestMatchers("/api/usuarios/promover").hasRole("ADMINISTRADOR")
                .requestMatchers("/api/ocorrencias/{id}/aprovar").hasRole("ADMINISTRADOR")

                // ===== ROTAS DE AGENTE E ADMINISTRADOR =====
                .requestMatchers("/api/usuarios/agentes").hasAnyRole("AGENTE", "ADMINISTRADOR")
                .requestMatchers("/api/ocorrencias/{id}/chegada").hasAnyRole("AGENTE", "ADMINISTRADOR")
                .requestMatchers("/api/ocorrencias/{id}/resolver").hasAnyRole("AGENTE", "ADMINISTRADOR")
                .requestMatchers("/api/ocorrencias/{id}/reativar").hasAnyRole("AGENTE", "ADMINISTRADOR")

                // ===== QUALQUER USUÁRIO AUTENTICADO =====
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

        // App Flutter mobile não usa cookies/credentials — wildcard é seguro aqui
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        // IMPORTANTE: allowCredentials=false permite o uso de wildcard em allowedOriginPatterns
        // O app Flutter envia o JWT no header Authorization, não em cookies
        configuration.setAllowCredentials(false);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
