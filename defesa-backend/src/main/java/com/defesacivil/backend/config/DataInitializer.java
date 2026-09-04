package com.defesacivil.backend.config;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.repository.CidadeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Inicializador de dados de inicializacao (Seed).
 * Garante a presenca das cidades atendidas caso o banco de dados seja resetado.
 *
 * SUPER_ADMIN: promovido diretamente via SQL no banco:
 *   UPDATE usuarios SET role = 'SUPER_ADMIN' WHERE email = 'reinaldohm07@gmail.com';
 */
@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final CidadeRepository cidadeRepository;

    public DataInitializer(CidadeRepository cidadeRepository) {
        this.cidadeRepository = cidadeRepository;
    }

    @Override
    public void run(String... args) {
        inicializarCidades();
    }

    private void inicializarCidades() {
        List<Cidade> cidadesPadrao = List.of(
            new Cidade("BP", "Braganca Paulista"),
            new Cidade("PIR", "Piracaia"),
            new Cidade("JOA", "Joanopolis")
        );

        for (Cidade c : cidadesPadrao) {
            boolean existe = cidadeRepository.findByCodigoIgnoreCase(c.getCodigo()).isPresent()
                    || cidadeRepository.findByNomeIgnoreCase(c.getNome()).isPresent();
            if (!existe) {
                cidadeRepository.save(c);
                log.info("Cidade '{}' ({}) cadastrada com sucesso.", c.getNome(), c.getCodigo());
            }
        }
    }
}
