package com.defesacivil.backend.controller;

import com.defesacivil.backend.dto.ClimaDto;
import com.defesacivil.backend.service.ClimaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/clima")
public class ClimaController {

    private final ClimaService climaService;

    public ClimaController(ClimaService climaService) {
        this.climaService = climaService;
    }

    @GetMapping
    public ResponseEntity<ClimaDto> obterClima(
            @RequestParam double lat,
            @RequestParam double lng) {
        
        ClimaDto clima = climaService.obterClimaPorCoordenadas(lat, lng);
        return ResponseEntity.ok(clima);
    }
}
