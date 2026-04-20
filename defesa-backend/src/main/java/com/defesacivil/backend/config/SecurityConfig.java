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
            .csrf(csrf -> csrf.disable()) // Stateless, sem CSRF
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Endpoints públicos e Health Checks
                .requestMatchers("/", "/api/health", "/actuator/health").permitAll()
                .requestMatchers("/api/auth/**", "/api/usuarios/login").permitAll()
                
                // Pontos de interesse — TEMPORARIAMENTE permitindo qualquer autenticado para testes
                .requestMatchers(HttpMethod.POST, "/api/pontos-interesse").authenticated()
                .requestMatchers(HttpMethod.DELETE, "/api/pontos-interesse/*").hasRole("ADMINISTRADOR")
                
                // Cidades e Listagem de Pontos — Público (GET)
                .requestMatchers("/api/cidades", "/api/pontos-interesse").permitAll()
                .requestMatchers("/api/ocorrencias").permitAll()
                
                // Apenas Administradores podem promover usuários a agentes e deletar
                .requestMatchers("/api/usuarios/promover").hasRole("ADMINISTRADOR")
                .requestMatchers(HttpMethod.DELETE, "/api/ocorrencias/*").hasRole("ADMINISTRADOR")
                .requestMatchers(HttpMethod.DELETE, "/api/usuarios/*").hasRole("ADMINISTRADOR")

                // Apenas Agentes e Admins podem listar outros agentes
                .requestMatchers("/api/usuarios/agentes").hasAnyRole("AGENTE", "ADMINISTRADOR")
                
                // Gestão de Ocorrências (Aprovar, Chegada, Resolver, Reativar)
                .requestMatchers("/api/ocorrencias/*/aprovar").hasRole("ADMINISTRADOR")
                .requestMatchers("/api/ocorrencias/*/chegada").hasAnyRole("AGENTE", "ADMINISTRADOR")
                .requestMatchers("/api/ocorrencias/*/resolver").hasAnyRole("AGENTE", "ADMINISTRADOR")
                .requestMatchers("/api/ocorrencias/*/reativar").hasAnyRole("AGENTE", "ADMINISTRADOR")
                // Qualquer usuário autenticado pode ver ocorrências e criar
                .anyRequest().authenticated()
            )
            // Rate limiting aplicado antes do JWT
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
        
        // Ler do environment para flexibilidade
        String allowedOrigins = System.getenv("CORS_ALLOWED_ORIGINS");
        if (allowedOrigins == null || allowedOrigins.isEmpty()) {
            // Em desenvolvimento, permite todas as origens
            configuration.setAllowedOriginPatterns(List.of("*"));
        } else {
            // Em produção, usa as origens configuradas no ambiente
            configuration.setAllowedOriginPatterns(List.of(allowedOrigins.split(",")));
        }
        
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With", "X-User-Id"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
