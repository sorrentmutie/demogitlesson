-- =====================================================================
-- PKADM_IFRS_CONTA - CAMBIOS SUGERIDOS
-- Petición: P20260326_0017 - DECESOS - REASEGURO
-- Objetivo: adaptar PR_CONTABILIDAD_REA4 para conceptos 83 y 84 en REA2/REA3
-- Pendiente posterior: parametrización en CTA_IFRS_CODIGOS / CUENTA_IFRS
-- =====================================================================


/* =====================================================================
   CAMBIO 1 - Declaración de variables en PR_CONTABILIDAD_REA4
   Ubicación recomendada: después de WC_RREGAH_S.
   Nota: C_RREGAD700 no cabe en SUBCODIGO(10). Se propone C_RREG700.
   ===================================================================== */

      -- P20260326_0017 - DECESOS - REASEGURO
      WC_RPMATD          varchar2(15); --387000000 OTRAS PROV.TECN.REAS.CEDIDO
      WC_RPMATH          varchar2(15); --693870000 PARTIC.REASEG.DOT.OTRAS PROV.
      WC_RPMATH12        varchar2(15); --793870000 PARTIC.REASEG.APL.OTRAS PROV. REA3 enero
      WC_RREG700         varchar2(15); --710900700 COMISIONES PROV. MATEMATICA


/* =====================================================================
   CAMBIO 2 - Carga de cuentas en carga_cuentas
   Ubicación recomendada: dentro del IF/ELSIF de REG_CTAS_COM.TIPO.
   ===================================================================== */

          -- P20260326_0017 - DECESOS - REASEGURO
          elsif REG_CTAS_COM.TIPO = 'C_RPMATD' then
            WC_RPMATD := REG_CTAS_COM.CUENTA; --387000000
          elsif REG_CTAS_COM.TIPO = 'C_RPMATH' then
            WC_RPMATH := REG_CTAS_COM.CUENTA; --693870000
          elsif REG_CTAS_COM.TIPO = 'C_RPMATH12' then
            WC_RPMATH12 := REG_CTAS_COM.CUENTA; --793870000
          elsif REG_CTAS_COM.TIPO = 'C_RREG700' then
            WC_RREG700 := REG_CTAS_COM.CUENTA; --710900700


/* =====================================================================
   CAMBIO 3 - Evitar duplicidad en graba_resto
   Sustituir la condición actual a.cuenta NOT IN (...) por esta versión.
   Motivo: las nuevas cuentas se tratan explícitamente desde REA_ESTADISTICA.
   ===================================================================== */

            -- P20260326_0017 - DECESOS - REASEGURO
            AND a.cuenta NOT IN (
                  WC_ENCAPR,
                  WC_EMRECE,
                  WC_RECAPR,
                  WC_SOBRCO,
                  WC_MENOCO,
                  WC_SINITR,
                  WC_RREGAD,
                  WC_RREGAH_S,
                  WC_RREG700, --710900700 concepto 84
                  WC_RPMATH   --693870000 concepto 83
                )


/* =====================================================================
   CAMBIO 4 - Sustitución recomendada de la rama ELSIF p_asiento IN ('REA2','REA3')
   Reemplazar el bloque completo desde:
       ELSIF p_asiento IN ('REA2', 'REA3') THEN
   hasta antes de:
       END IF;
   que cierra PR_CONTABILIDAD_REA4.
   ===================================================================== */

      ELSIF p_asiento IN ('REA2', 'REA3') THEN
        carga_cuentas;

        /* -------------------------------------------------------------
           Conceptos 30/31 existentes + concepto 84 nuevo.
           30/31 mantienen WC_RREGAD = 710900000.
           84 usa WC_RREG700 = 710900700.
           ------------------------------------------------------------- */
        INSERT INTO CTA_IFRS_CONTA(
          idlote,
          numproceso,
          apunte,
          estado,
          poliza,
          cdprograma,
          cia_reaseg,
          cod_ramo_emi,
          ramodgs,
          cuenta,
          codorigen,
          -- Mod. MCAREAPROPORCIONAL 2024/09/10
          NUM_CONT,
          importe,
          signo,
          divisa,
          concepto,
          usuario)
        SELECT
          P_IDLOTE,
          v_numproceso,
          ROWNUM,
          NULL,
          null,
          decode(CDPROGRAMA,'FA','FA'||ANO||'_'||DECODE(cod.codigoifrs, TO_CHAR(rea.cia_reaseg), cod.subcodigoifrs, cod.subcodigoaire), CDPROGRAMA) CDPROGRAMA,
          TO_CHAR(rea.cia_reaseg),
          rea.COD_RAMO_EMI,
          DECODE(cod.codigoifrs, TO_CHAR(rea.cia_reaseg), cod.subcodigoifrs, cod.subcodigoaire),
          -- P20260326_0017 - DECESOS - REASEGURO
          DECODE(rea.COD_CONCEPTO,
                 84, WC_RREG700, --710900700 COMISIONES PROV. MATEMATICA
                 WC_RREGAD),     --710900000 conceptos 30/31 existentes
          rea.COD_CONCEPTO,
          rea.NUM_CONT,
          ABS(IMPORTE),
          decode(p_asiento,
                 'REA3', DECODE(greatest(IMPORTE,0),'0','D','H'),
                         DECODE(greatest(IMPORTE,0),'0','H','D')),
          'EUR',
          null,
          'PROASCON'
        FROM cta_ifrs_codigos COD, (
             SELECT decode(greatest(ano_cont,50),50,2000,1900)+ano_cont ANO,
                    COD_CIA,
                    CIA_REASEG,
                    COD_RAMO_EMI,
                    decode(CDPROGRAMA,'FACULTATIV','FA','FACXL','FA', CDPROGRAMA) CDPROGRAMA,
                    sum(nvl(IMPORTE_PRIMA,0)) IMPORTE,
                    COD_CONCEPTO,
                    NUM_CONT
               FROM REA_ESTADISTICA
              WHERE COD_CIA = p_empresa
                and ANO_OPERACION = TO_NUMBER(TO_CHAR(decode(p_asiento, 'REA3', add_months(p_fecasiento, -1), p_fecasiento),'yyyy'))
                and MES_OPERACION = TO_NUMBER(TO_CHAR(decode(p_asiento, 'REA3', add_months(p_fecasiento, -1), p_fecasiento),'mm'))
                and CIA_REASEG != 999
                and SERIE_CONT not in (25,57)
                -- P20260326_0017 - DECESOS - REASEGURO
                and COD_CONCEPTO IN (30, 31, 84)
              GROUP BY decode(greatest(ano_cont,50),50,2000,1900)+ano_cont,
                       COD_CIA,
                       CIA_REASEG,
                       COD_RAMO_EMI,
                       decode(CDPROGRAMA,'FACULTATIV','FA','FACXL','FA', CDPROGRAMA),
                       COD_CONCEPTO,
                       NUM_CONT
             ) REA
        WHERE cod.empresa     = cte_empresa_99
          AND cod.clavecodigo = cte_ramodgs
          AND cod.codigoaire  = rea.cod_ramo_emi;

        SELECT MAX(apunte)
          INTO vrow
          FROM CTA_IFRS_CONTA
         WHERE idlote = P_IDLOTE
           AND numproceso = v_numproceso;

        /* -------------------------------------------------------------
           Concepto 83 nuevo: PROVISION MATEMATICA.
           Se trata en bloque independiente porque el signo funcional es
           distinto al patrón 30/31/84.

           REA2:
             importe positivo -> H en 693870000
             importe negativo -> D en 693870000
           REA3:
             reversa del REA2.
           ------------------------------------------------------------- */
        -- P20260326_0017 - DECESOS - REASEGURO
        INSERT INTO CTA_IFRS_CONTA(
          idlote,
          numproceso,
          apunte,
          estado,
          poliza,
          cdprograma,
          cia_reaseg,
          cod_ramo_emi,
          ramodgs,
          cuenta,
          codorigen,
          -- Mod. MCAREAPROPORCIONAL 2024/09/10
          num_cont,
          importe,
          signo,
          divisa,
          concepto,
          usuario)
        SELECT
          P_IDLOTE,
          v_numproceso,
          vrow + ROWNUM,
          NULL,
          null,
          decode(CDPROGRAMA,'FA','FA'||ANO||'_'||DECODE(cod.codigoifrs, TO_CHAR(rea.cia_reaseg), cod.subcodigoifrs, cod.subcodigoaire), CDPROGRAMA) CDPROGRAMA,
          TO_CHAR(rea.cia_reaseg),
          rea.COD_RAMO_EMI,
          DECODE(cod.codigoifrs, TO_CHAR(rea.cia_reaseg), cod.subcodigoifrs, cod.subcodigoaire),
          WC_RPMATH, --693870000 PARTIC.REASEG.DOT.OTRAS PROV.
          rea.COD_CONCEPTO,
          rea.NUM_CONT,
          ABS(IMPORTE),
          decode(p_asiento,
                 'REA3', DECODE(greatest(IMPORTE,0),'0','H','D'),
                         DECODE(greatest(IMPORTE,0),'0','D','H')),
          'EUR',
          null,
          'PROASCON'
        FROM cta_ifrs_codigos COD, (
             SELECT decode(greatest(ano_cont,50),50,2000,1900)+ano_cont ANO,
                    COD_CIA,
                    CIA_REASEG,
                    COD_RAMO_EMI,
                    decode(CDPROGRAMA,'FACULTATIV','FA','FACXL','FA', CDPROGRAMA) CDPROGRAMA,
                    sum(nvl(IMPORTE_PRIMA,0)) IMPORTE,
                    COD_CONCEPTO,
                    NUM_CONT
               FROM REA_ESTADISTICA
              WHERE COD_CIA = p_empresa
                and ANO_OPERACION = TO_NUMBER(TO_CHAR(decode(p_asiento, 'REA3', add_months(p_fecasiento, -1), p_fecasiento),'yyyy'))
                and MES_OPERACION = TO_NUMBER(TO_CHAR(decode(p_asiento, 'REA3', add_months(p_fecasiento, -1), p_fecasiento),'mm'))
                and CIA_REASEG != 999
                and SERIE_CONT not in (25,57)
                and COD_CONCEPTO = 83
              GROUP BY decode(greatest(ano_cont,50),50,2000,1900)+ano_cont,
                       COD_CIA,
                       CIA_REASEG,
                       COD_RAMO_EMI,
                       decode(CDPROGRAMA,'FACULTATIV','FA','FACXL','FA', CDPROGRAMA),
                       COD_CONCEPTO,
                       NUM_CONT
             ) REA
        WHERE cod.empresa     = cte_empresa_99
          AND cod.clavecodigo = cte_ramodgs
          AND cod.codigoaire  = rea.cod_ramo_emi;

        -- P20260326_0017 - DECESOS - REASEGURO
        -- Recalcular vrow antes del bloque existente de concepto 82.
        SELECT MAX(apunte)
          INTO vrow
          FROM CTA_IFRS_CONTA
         WHERE idlote = P_IDLOTE
           AND numproceso = v_numproceso;

        /* -------------------------------------------------------------
           Bloque existente concepto 82.
           Se mantiene lógica actual con WC_RREGAH_S y filtro SALUD_SOLV2.
           ------------------------------------------------------------- */
        INSERT INTO CTA_IFRS_CONTA(
          idlote,
          numproceso,
          apunte,
          estado,
          poliza,
          cdprograma,
          cia_reaseg,
          cod_ramo_emi,
          ramodgs,
          cuenta,
          codorigen,
          -- Mod. MCAREAPROPORCIONAL 2024/09/10
          num_cont,
          importe,
          signo,
          divisa,
          concepto,
          usuario)
        SELECT
          P_IDLOTE,
          v_numproceso,
          vrow+ROWNUM,
          NULL,
          null,
          decode(CDPROGRAMA,'FA','FA'||ANO||'_'||DECODE(cod.codigoifrs, TO_CHAR(rea.cia_reaseg), cod.subcodigoifrs, cod.subcodigoaire), CDPROGRAMA) CDPROGRAMA,
          TO_CHAR(rea.cia_reaseg),
          rea.COD_RAMO_EMI,
          DECODE(cod.codigoifrs, TO_CHAR(rea.cia_reaseg), cod.subcodigoifrs, cod.subcodigoaire),
          WC_RREGAH_S,
          rea.COD_CONCEPTO,
          rea.NUM_CONT,
          ABS(IMPORTE),
          decode(p_asiento,
                 'REA3', DECODE(greatest(IMPORTE,0),'0','D','H'),
                         DECODE(greatest(IMPORTE,0),'0','H','D')),
          'EUR',
          null,
          'PROASCON'
        FROM cta_ifrs_codigos COD, (
             SELECT decode(greatest(ano_cont,50),50,2000,1900)+ano_cont ANO,
                    COD_CIA,
                    CIA_REASEG,
                    COD_RAMO_EMI,
                    decode(CDPROGRAMA,'FACULTATIV','FA','FACXL','FA', CDPROGRAMA) CDPROGRAMA,
                    sum(nvl(IMPORTE_PRIMA,0)) IMPORTE,
                    COD_CONCEPTO,
                    NUM_CONT
               FROM REA_ESTADISTICA r
              WHERE COD_CIA = p_empresa
                and ANO_OPERACION = TO_NUMBER(TO_CHAR(decode(p_asiento, 'REA3', add_months(p_fecasiento, -1), p_fecasiento),'yyyy'))
                and MES_OPERACION = TO_NUMBER(TO_CHAR(decode(p_asiento, 'REA3', add_months(p_fecasiento, -1), p_fecasiento),'mm'))
                and CIA_REASEG != 999
                and SERIE_CONT not in (25,57)
                and COD_CONCEPTO IN (82)
                AND EXISTS (SELECT 1
                              FROM xaco.COM_CODIGOS c
                             WHERE c.clavecodigo = cte_ct_ramoconta
                               and c.empresa = r.cod_cia
                               and c.codigo = r.cod_ramo_ctable
                               and nvl(c.valorasociado2,'N') = 'SALUD_SOLV2')
              GROUP BY decode(greatest(ano_cont,50),50,2000,1900)+ano_cont,
                       COD_CIA,
                       CIA_REASEG,
                       COD_RAMO_EMI,
                       decode(CDPROGRAMA,'FACULTATIV','FA','FACXL','FA', CDPROGRAMA),
                       COD_CONCEPTO,
                       NUM_CONT
             ) REA
        WHERE cod.empresa     = cte_empresa_99
          AND cod.clavecodigo = cte_ramodgs
          AND cod.codigoaire  = rea.cod_ramo_emi;

        valida_datos;
        graba_resto;


/* =====================================================================
   BLOQUE DE VALIDACIÓN POSTERIOR RECOMENDADO
   Ejecutar tras generar/reprocesar REA2/REA3 en entorno de pruebas.
   ===================================================================== */

-- 1) Verificar apuntes IFRS explícitos generados para conceptos 83/84.
SELECT idlote,
       numproceso,
       codorigen,
       cuenta,
       signo,
       COUNT(1) registros,
       SUM(importe) importe
  FROM xaco.cta_ifrs_conta
 WHERE codorigen IN ('83','84')
 GROUP BY idlote, numproceso, codorigen, cuenta, signo
 ORDER BY idlote, numproceso, codorigen, cuenta, signo;

-- 2) Verificar nulos funcionales que valida el propio procedimiento.
SELECT idlote,
       numproceso,
       codorigen,
       cuenta,
       COUNT(1) registros_con_nulos
  FROM xaco.cta_ifrs_conta
 WHERE codorigen IN ('83','84')
   AND (cdprograma IS NULL OR cia_reaseg IS NULL OR ramodgs IS NULL)
 GROUP BY idlote, numproceso, codorigen, cuenta;

-- 3) Validar que graba_resto no duplica las cuentas tratadas explícitamente.
SELECT idlote,
       numproceso,
       cuenta,
       codorigen,
       COUNT(1) registros
  FROM xaco.cta_ifrs_conta
 WHERE cuenta IN ('693870000','710900700')
 GROUP BY idlote, numproceso, cuenta, codorigen
 ORDER BY idlote, numproceso, cuenta, codorigen;
